/*-
 * Copyright (c) 2013-2024 Rozhuk Ivan <rozhuk.im@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 * Author: Rozhuk Ivan <rozhuk.im@gmail.com>
 *
 */


#include <sys/param.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <net/if.h>

#include <inttypes.h>
#include <stdlib.h> /* malloc, exit */
#include <unistd.h> /* close, write, sysconf */
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <stdio.h> /* snprintf, fprintf */
#include <time.h>
#include <errno.h>

#include "utils/mem_utils.h"
#include "utils/str2num.h"
#include "proto/http.h"

#include "utils/macro.h"
#include "utils/io_buf.h"
#include "utils/info.h"
#include "threadpool/threadpool_task.h"
#include "net/socket.h"
#include "net/socket_address.h"
#include "net/utils.h"
#include "proto/upnp_ssdp.h"


#define PRODUCT				"SSDP announcer by Rozhuk Ivan"
#define PRODUCT_VER			"1.0"
#define PRODUCT_SRV_STR_PART		"UPnP/1.1 "PRODUCT"/"PRODUCT_VER

#define UPNP_UUID_SIZE			36
#define UPNP_NT_UUID_SIZE		(5 + UPNP_UUID_SIZE) /* uuid:... */
#define UPNP_NOTIFY_TYPE_MAX_SIZE	(5 + 256 + 10 + 64 + 16) /* Notification Type. */
#define UPNP_SSDP_V4_ADDR		"239.255.255.250"
#define UPNP_SSDP_V6_ADDR_LINK_LOCAL	"FF02::C" /* Link local scope. */
#define UPNP_SSDP_V6_ADDR_SITE_LOCAL	"FF05::C" /* Site local scope. */
#define UPNP_SSDP_V6_ADDR_LINK_LOCAL_EV	"FF02::130" /* For link local multicast eventing. */
#define UPNP_SSDP_V6_ADDR_SITE_LOCAL_EV	"FF05::130" /* For site local multicast eventing. */
#define UPNP_SSDP_PORT			1900	/* Default value for ssdp unicast, const for multicast. */
#define UPNP_SSDP_UC_PORT_MIN		49152	/* Unicast search port min. */
#define UPNP_SSDP_UC_PORT_MAX		65535	/* Unicast search port max. */
#define UPNP_SSDP_V6_EVENT_PORT		7900



static const char *ssdp_v4_addr = UPNP_SSDP_V4_ADDR;
static const char *ssdp_v6_addr_link_local = "["UPNP_SSDP_V6_ADDR_LINK_LOCAL"]";
static const char *ssdp_v6_addr_site_local = "["UPNP_SSDP_V6_ADDR_SITE_LOCAL"]";

static sockaddr_storage_t ssdp_v4_mc_addr;
static sockaddr_storage_t ssdp_v6_mc_addr_link_local;
static sockaddr_storage_t ssdp_v6_mc_addr_site_local;
static sockaddr_storage_t ssdp_v6_mc_addr_event;
static int ssdp_static_initialized = 0;


typedef struct upnp_ssdp_svc_s *upnp_ssdp_svc_p;
typedef struct upnp_ssdp_dev_if_s *upnp_ssdp_dev_if_p;


typedef struct upnp_ssdp_if_s {
	uint32_t	if_index;
	uint32_t	dev_ifs_cnt;
	upnp_ssdp_dev_if_p *dev_ifs;	/* Associated devices. */
} upnp_ssdp_if_t, *upnp_ssdp_if_p;


typedef struct upnp_ssdp_dev_if_s { /* Link UPnP-SSDP device and networt interface together. */
	upnp_ssdp_if_p	s_if;
	upnp_ssdp_dev_p	dev;
	char		*url4;		/* URL to dev description for this iface. */
	size_t		url4_size;
	char		*url6;		/* URL to dev description for this iface. */
	size_t		url6_size;
} upnp_ssdp_dev_if_t;


typedef struct upnp_ssdp_svc_s { /* UPnP-SSDP service. */
	uint8_t		*domain_name;	/* domain-name */
	size_t		domain_name_size;
	uint8_t		*type;		/* serviceType */
	size_t		type_size;
	uint32_t	ver;		/* version */
	/* One time generated. */
	uint8_t		*nt;		/* Notification Type: urn:domain-name:service:serviceType:ver */
	size_t		nt_size;
} upnp_ssdp_svc_t;


typedef struct upnp_ssdp_dev_s {
	uint8_t		*uuid;		/* device-UUID */
	uint8_t		*domain_name;	/* domain-name */
	size_t		domain_name_size;
	uint8_t		*type;		/* serviceType */
	size_t		type_size;
	uint32_t	ver;		/* version */
	upnp_ssdp_svc_p	*serviceList;
	uint32_t	serviceList_cnt;
	upnp_ssdp_dev_p	*deviceList;	/* embedded deviceList */
	uint32_t	deviceList_cnt;
	uint32_t	boot_id;	/* UPnP 1.1: BOOTID.UPNP.ORG, NEXTBOOTID.UPNP.ORG */
	uint32_t	config_id;	/* UPnP 1.1: CONFIGID.UPNP.ORG */
	/* One time generated. */
	uint8_t		*nt_uuid;	/* Notification Type: uuid:device-UUID */
	uint8_t		*nt;		/* Notification Type: urn:domain-name:service:serviceType:ver */
	size_t		nt_size;
	/*  */
	uint32_t	max_age;
	uint32_t	ann_interval;
	/* Internal data. */
	uint32_t	dev_ifs_cnt;
	upnp_ssdp_dev_if_p *dev_ifs;	/* Associated interfaces. */
	tp_udata_t	ann_tmr;	/* Announce send timer. */
	upnp_ssdp_p	ssdp;		/* Need in timer proc. */
} upnp_ssdp_dev_t;


typedef struct upnp_ssdp_s {
	tp_p		tp;
	upnp_ssdp_if_p	*s_ifs;		/* Interfaces. */
	uint32_t	s_ifs_cnt;	/*  */
	upnp_ssdp_dev_p	*root_devs;
	uint32_t	root_devs_cnt;	/*  */
	tp_task_p	mc_rcvr_v4;	/* MC packets receiver: one for all ifaces. */
	tp_task_p	mc_rcvr_v6;	/* MC packets receiver: one for all ifaces. */
	/* 1. Discovery / SSDP */
	uint16_t	search_port;	/* UPnP 1.1: SEARCHPORT.UPNP.ORG: (49152-65535) identifies the port at which the device listens to unicast M-SEARCH messages */
	char		http_server[256]; /* 'OS/version UPnP/1.1 product/version' */
	/* */
	int		byebye;
} upnp_ssdp_t;


void	upnp_ssdp_init__int(void);

void	upnp_ssdp_dev_if_del(upnp_ssdp_dev_if_p dev_if);

upnp_ssdp_if_p	upnp_ssdp_get_if_by_index(upnp_ssdp_p ssdp, uint32_t if_index);


int	upnp_ssdp_if_add(upnp_ssdp_p ssdp, const char *if_name,
	    size_t if_name_size, upnp_ssdp_if_p *s_if_ret);
void	upnp_ssdp_if_del(upnp_ssdp_p ssdp, upnp_ssdp_if_p s_if);

/* 1. Discovery / SSDP */
void	upnp_ssdp_timer_cb(tp_event_p ev, tp_udata_p tp_udata);
int	upnp_ssdp_mc_recv_cb(tp_task_p tptask, int error, uint32_t eof,
	    size_t data2transfer_size, void *arg);
int	upnp_ssdp_iface_notify_ex(upnp_ssdp_p ssdp, upnp_ssdp_if_p s_if,
	    sockaddr_storage_p addr, int action,
	    const uint8_t *search_target, size_t search_target_size);
int	upnp_ssdp_dev_notify_sendto_mc(upnp_ssdp_p ssdp, upnp_ssdp_dev_p dev,
	    int action);
int	upnp_ssdp_dev_notify_sendto(upnp_ssdp_p ssdp, upnp_ssdp_dev_p dev,
	    sockaddr_storage_p addr, int action);
int	upnp_ssdp_send(upnp_ssdp_p ssdp, upnp_ssdp_if_p s_if,
	    sockaddr_storage_p addr, int action,
	    upnp_ssdp_dev_if_p dev_if, const uint8_t *nt, size_t nt_size);
#define UPNP_SSDP_S_A_BYEBYE	0
#define UPNP_SSDP_S_A_ALIVE	1
#define UPNP_SSDP_S_A_UPDATE	2
#define UPNP_SSDP_S_A_SRESPONSE	255


void
upnp_ssdp_init__int(void) {
	int error;

	if (0 != ssdp_static_initialized)
		return;
	/* Init static global constants. */
	error = sa_addr_port_from_str(&ssdp_v4_mc_addr, UPNP_SSDP_V4_ADDR,
	    (sizeof(UPNP_SSDP_V4_ADDR) - 1));
	sa_port_set(&ssdp_v4_mc_addr, UPNP_SSDP_PORT);
	SYSLOG_ERR(LOG_CRIT, error,
	    "sa_addr_port_from_str(UPNP_SSDP_V4_ADDR).");

	error = sa_addr_port_from_str(&ssdp_v6_mc_addr_link_local,
	    UPNP_SSDP_V6_ADDR_LINK_LOCAL,
	    (sizeof(UPNP_SSDP_V6_ADDR_LINK_LOCAL) - 1));
	sa_port_set(&ssdp_v6_mc_addr_link_local, UPNP_SSDP_PORT);
	SYSLOG_ERR(LOG_CRIT, error,
	    "sa_addr_port_from_str(UPNP_SSDP_V6_ADDR_LINK_LOCAL).");
	
	error = sa_addr_port_from_str(&ssdp_v6_mc_addr_site_local,
	    UPNP_SSDP_V6_ADDR_SITE_LOCAL,
	    (sizeof(UPNP_SSDP_V6_ADDR_SITE_LOCAL) - 1));
	sa_port_set(&ssdp_v6_mc_addr_site_local, UPNP_SSDP_PORT);
	SYSLOG_ERR(LOG_CRIT, error,
	    "sa_addr_port_from_str(UPNP_SSDP_V6_ADDR_SITE_LOCAL).");

	error = sa_addr_port_from_str(&ssdp_v6_mc_addr_event,
	    UPNP_SSDP_V6_ADDR_LINK_LOCAL_EV,
	    (sizeof(UPNP_SSDP_V6_ADDR_LINK_LOCAL_EV) - 1));
	sa_port_set(&ssdp_v6_mc_addr_event, UPNP_SSDP_V6_EVENT_PORT);
	SYSLOG_ERR(LOG_CRIT, error,
	    "sa_addr_port_from_str(UPNP_SSDP_V6_ADDR_LINK_LOCAL_EV).");

	ssdp_static_initialized ++;
}


void
upnp_ssdp_def_settings(upnp_ssdp_settings_p s_ret) {
	size_t tm;

	if (NULL == s_ret)
		return;
	memset(s_ret, 0x00, sizeof(upnp_ssdp_settings_t));
	/* Default settings. */
	s_ret->skt_opts.mask |= UPNP_SSDP_S_DEF_SKT_OPTS_MASK;
	s_ret->skt_opts.bit_vals |= UPNP_SSDP_S_DEF_SKT_OPTS_VALS;
	s_ret->skt_opts.hop_limit_u = UPNP_SSDP_DEF_HOP_LIMIT;
	s_ret->skt_opts.hop_limit_m = UPNP_SSDP_DEF_HOP_LIMIT;
	s_ret->search_port = UPNP_SSDP_DEF_SEARCH_PORT;
	s_ret->flags = UPNP_SSDP_DEF_FLAGS;

	/* 'OS/version UPnP/1.1 product/version' */
	if (0 == info_get_os_ver("/", 1, s_ret->http_server,
	    (sizeof(s_ret->http_server) - 1), &tm)) {
		s_ret->http_server_size = tm;
	} else {
		memcpy(s_ret->http_server, "Generic OS/1.0", 15);
		s_ret->http_server_size = 14;
	}
	if ((sizeof(s_ret->http_server) - 2) > sizeof(PRODUCT_SRV_STR_PART)) {
		if (0 != s_ret->http_server_size) {
			s_ret->http_server[s_ret->http_server_size ++] = ' ';
		}
		memcpy(s_ret->http_server, PRODUCT_SRV_STR_PART,
		    sizeof(PRODUCT_SRV_STR_PART));
		s_ret->http_server_size = (sizeof(PRODUCT_SRV_STR_PART) - 1);
	}
	s_ret->http_server[s_ret->http_server_size] = 0;
}

int
upnp_ssdp_create(tp_p tp, upnp_ssdp_settings_p s, upnp_ssdp_p *ussdp_ret) {
	upnp_ssdp_p ssdp;
	uintptr_t skt;
	int error;
	upnp_ssdp_settings_t s_def;

	/* Init static global constants. */
	upnp_ssdp_init__int();

	if (NULL == ussdp_ret)
		return (EINVAL);
	if (NULL == s) { /* Apply default settings. */
		upnp_ssdp_def_settings(&s_def);
	} else {
		if (0 == ((UPNP_SSDP_S_F_IPV4 | UPNP_SSDP_S_F_IPV6) & s->flags))
			return (EINVAL);
		memcpy(&s_def, s, sizeof(s_def));
	}

	ssdp = calloc(1, sizeof(upnp_ssdp_t));
	if (NULL == ssdp)
		return (ENOMEM);
	s = &s_def;
	/* kb -> bytes */
	skt_opts_cvt(SKT_OPTS_MULT_K, &s->skt_opts);
	/* Force MULTICAST_LOOP off. */
	s->skt_opts.mask |= SO_F_IP_MULTICAST_LOOP;
	s->skt_opts.bit_vals &= ~SO_F_IP_MULTICAST_LOOP;

	ssdp->tp = tp;
	ssdp->search_port = s->search_port;
	memcpy(ssdp->http_server, s->http_server, s->http_server_size);
	ssdp->http_server[s->http_server_size] = 0;
	ssdp->byebye = (0 != (UPNP_SSDP_S_F_BYEBYE & s->flags));

	/* IPv4. */
	if (0 == (UPNP_SSDP_S_F_IPV4 & s->flags))
		goto skip_ipv4;
	error = skt_bind_ap(AF_INET, NULL, UPNP_SSDP_PORT,
	    SOCK_DGRAM, IPPROTO_UDP,
	    (SO_F_NONBLOCK | SO_F_REUSEADDR | SO_F_REUSEPORT),
	    &skt);
	if (0 != error) {
		SYSLOG_ERR(LOG_CRIT, error, "skt_bind_ap().");
		goto err_out;
	}
	/* Tune socket. */
	error = skt_opts_apply_ex(skt, SO_F_UDP_BIND_AF_MASK,
	    &s->skt_opts, AF_INET, NULL);
	SYSLOG_ERR(LOG_NOTICE, error, "skt_opts_apply_ex(), this is not fatal.");

	error = skt_enable_recv_ifindex(skt, 1);
	if (0 != error) {
		SYSLOG_ERR(LOG_CRIT, error, "skt_enable_recv_ifindex().");
		goto err_out;
	}
	error = tp_task_notify_create(tp_thread_get_rr(tp), skt,
	    TP_TASK_F_CLOSE_ON_DESTROY, TP_EV_READ, 0,
	    upnp_ssdp_mc_recv_cb, ssdp, &ssdp->mc_rcvr_v4);
	if (0 != error)
		goto err_out;
skip_ipv4:

	/* IPv6. */
	if (0 == (UPNP_SSDP_S_F_IPV6 & s->flags))
		goto skip_ipv6;
	error = skt_bind_ap(AF_INET6, NULL, UPNP_SSDP_PORT,
	    SOCK_DGRAM, IPPROTO_UDP,
	    (SO_F_NONBLOCK | SO_F_REUSEADDR | SO_F_REUSEPORT),
	    &skt);
	if (0 != error) {
		SYSLOG_ERR(LOG_CRIT, error, "skt_bind_ap().");
		goto err_out;
	}
	/* Tune socket. */
	error = skt_opts_apply_ex(skt, SO_F_UDP_BIND_AF_MASK,
	    &s->skt_opts, AF_INET6, NULL);
	SYSLOG_ERR(LOG_NOTICE, error, "skt_opts_apply_ex(), this is not fatal.");

	error = skt_enable_recv_ifindex(skt, 1);
	if (0 != error) {
		SYSLOG_ERR(LOG_CRIT, error, "skt_enable_recv_ifindex().");
		goto err_out;
	}
	error = tp_task_notify_create(tp_thread_get_rr(tp), skt,
	    TP_TASK_F_CLOSE_ON_DESTROY, TP_EV_READ, 0,
	    upnp_ssdp_mc_recv_cb, ssdp, &ssdp->mc_rcvr_v6);
	if (0 != error)
		goto err_out;
skip_ipv6:

	(*ussdp_ret) = ssdp;

	return (0);

err_out:
	/* Error. */
	close((int)skt);
	upnp_ssdp_destroy(ssdp);

	return (error);
}

void
upnp_ssdp_destroy(upnp_ssdp_p ssdp) {
	uint32_t i;

	if (NULL == ssdp)
		return;
	/* Destroy all upnp devices and services. */
	if (NULL != ssdp->root_devs) {
		for (i = 0; i < ssdp->root_devs_cnt; i ++) {
			upnp_ssdp_dev_del(ssdp, ssdp->root_devs[i]);
		}
		free(ssdp->root_devs);
	}
	/* Destroy all ifaces. */
	if (NULL != ssdp->s_ifs) {
		for (i = 0; i < ssdp->s_ifs_cnt; i ++) {
			upnp_ssdp_if_del(ssdp, ssdp->s_ifs[i]);
		}
		free(ssdp->s_ifs);
	}
	tp_task_destroy(ssdp->mc_rcvr_v4);
	tp_task_destroy(ssdp->mc_rcvr_v6);
	free(ssdp);
}



int
upnp_ssdp_dev_add(upnp_ssdp_p ssdp, const char *uuid,
    const char *domain_name, size_t domain_name_size,
    const char *type, size_t type_size, const uint32_t ver,
    uint32_t boot_id, uint32_t config_id, uint32_t max_age, uint32_t ann_interval,
    upnp_ssdp_dev_p *dev_ret) {
	int error, rc;
	upnp_ssdp_dev_p dev, *root_devs_new;
	size_t nt_size, tot_size;

	if (NULL == ssdp || NULL == uuid || NULL == domain_name ||
	    NULL == type ||
	    NULL == dev_ret)
		return (EINVAL);

	if (0 == domain_name_size) {
		domain_name_size = strlen(domain_name);
	}
	if (0 == type_size) {
		type_size = strlen(type);
	}
	nt_size = (4 + domain_name_size + 8 + type_size + 16);
	tot_size = (sizeof(upnp_ssdp_dev_t) + UPNP_NT_UUID_SIZE + domain_name_size + type_size + nt_size + 8);
	dev = calloc(1, tot_size);
	if (NULL == dev)
		return (ENOMEM);
	/* Defaults. */
	if (0 == max_age) {
		max_age = UPNP_SSDP_DEF_MAX_AGE;
	}
	if (0 == ann_interval) {
		ann_interval = UPNP_SSDP_DEF_ANNOUNCE_INTERVAL;
	}
	/* sec->ms. */
	ann_interval *= 1000;

	/* UUID point to UUID in nt_uuid. */
	dev->nt_uuid = (uint8_t*)(dev + 1);
	dev->uuid = (dev->nt_uuid + 5);
	dev->domain_name = (dev->uuid + UPNP_UUID_SIZE + 2);
	dev->domain_name_size = domain_name_size;
	dev->type = (dev->domain_name + domain_name_size + 2);
	dev->type_size = type_size;
	dev->ver = ver;
	//dev->serviceList = NULL;
	//dev->serviceList_cnt = 0;
	//dev->deviceList;
	//dev->deviceList_cnt;
	dev->boot_id = boot_id;
	dev->config_id = config_id;
	//dev->nt_uuid = (char*)(dev + 1);
	dev->nt = (dev->type + type_size + 2);
	//dev->nt_size;
	dev->max_age = max_age;
	dev->ann_interval = ann_interval;
	//dev->dev_ifs_cnt;
	//dev->dev_ifs;
	//dev->ann_tmr;
	dev->ssdp = ssdp;
	memcpy(dev->nt_uuid, "uuid:", 5);
	memcpy(dev->uuid, uuid, UPNP_UUID_SIZE);
	memcpy(dev->domain_name, domain_name, domain_name_size);
	memcpy(dev->type, type, type_size);
	rc = snprintf((char*)dev->nt, nt_size, "urn:%s:device:%s:%"PRIu32,
	    dev->domain_name, dev->type, dev->ver);
	if (IS_SNPRINTF_FAIL(rc, nt_size)) {
		error = EFAULT;
		goto err_out;
	}
	dev->nt_size = (size_t)rc;
	/* Timer. */
	dev->ann_tmr.cb_func = upnp_ssdp_timer_cb;
	dev->ann_tmr.ident = (uintptr_t)dev;
	error = tpt_ev_add_args(tp_thread_get_pvt(ssdp->tp),
	    TP_EV_TIMER, 0, TP_FF_T_MSEC, dev->ann_interval, &dev->ann_tmr);
	if (0 != error)
		goto err_out;
	/* Send announces. */
	//upnp_ssdp_timer_cb(NULL, &dev->ann_tmr);

	/* Need more space? */
	root_devs_new = reallocarray(ssdp->root_devs,
	    (ssdp->root_devs_cnt + 4), sizeof(upnp_ssdp_dev_p));
	if (NULL == root_devs_new) { /* Reallocate failed. */
		error = ENOMEM;
		goto err_out;
	}
	ssdp->root_devs = root_devs_new;
	ssdp->root_devs[ssdp->root_devs_cnt] = dev;
	ssdp->root_devs_cnt ++;
	(*dev_ret) = dev;

	return (0);

err_out:
	free(dev);
	return (error);
}

void
upnp_ssdp_dev_del(upnp_ssdp_p ssdp, upnp_ssdp_dev_p dev) {
	uint32_t i;

	if (NULL == ssdp || NULL == dev)
		return;
	/* Destroy announce timer. */
	tpt_ev_del_args1(TP_EV_TIMER, &dev->ann_tmr);
	/* Notify all. */
	if (ssdp->byebye) {
		upnp_ssdp_dev_notify_sendto_mc(ssdp, dev, UPNP_SSDP_S_A_BYEBYE);
	}
	/* Remove from global ifaces array. */
	for (i = 0; i < ssdp->root_devs_cnt; i ++) {
		if (ssdp->root_devs[i] != dev)
			continue;
		ssdp->root_devs_cnt --;
		ssdp->root_devs[i] = ssdp->root_devs[ssdp->root_devs_cnt];
		ssdp->root_devs[ssdp->root_devs_cnt] = NULL;
		break;
	}
	/* Remove from ifaces links lists. */
	if (NULL != dev->dev_ifs) {
		for (i = 0; i < dev->dev_ifs_cnt; i ++) {
			dev->dev_ifs[i]->dev = NULL;
			upnp_ssdp_dev_if_del(dev->dev_ifs[i]);
		}
		free(dev->dev_ifs);
	}
	/* Destroy services. */
	if (NULL != dev->serviceList) {
		for (i = 0; i < dev->serviceList_cnt; i ++) {
			free(dev->serviceList[i]);
		}
		free(dev->serviceList);
	}
	free(dev);
}

size_t
upnp_ssdp_root_dev_count(upnp_ssdp_p ssdp) {

	if (NULL == ssdp)
		return (0);
	return (ssdp->root_devs_cnt);
}


int
upnp_ssdp_svc_add(upnp_ssdp_dev_p dev,
    const char *domain_name, size_t domain_name_size,
    const char *type, size_t type_size, const uint32_t ver) {
	int error, rc;
	upnp_ssdp_svc_p svc, *serviceList_new;
	size_t nt_size, tot_size;

	if (NULL == dev || NULL == domain_name || NULL == type)
		return (EINVAL);
	if (0 == domain_name_size) {
		domain_name_size = strlen(domain_name);
	}
	if (0 == type_size) {
		type_size = strlen(type);
	}
	nt_size = (4 + domain_name_size + 9 + type_size + 16);
	tot_size = (sizeof(upnp_ssdp_svc_t) + domain_name_size + type_size + nt_size + 8);
	svc = calloc(1, tot_size);
	if (NULL == svc)
		return (ENOMEM);
	svc->domain_name = (uint8_t*)(svc + 1);
	svc->domain_name_size = domain_name_size;
	svc->type = (svc->domain_name + domain_name_size + 2);
	svc->type_size = type_size;
	svc->ver = ver;
	svc->nt = (svc->type + type_size + 2);
	//svc->nt_size;
	memcpy(svc->domain_name, domain_name, domain_name_size);
	memcpy(svc->type, type, type_size);
	rc = snprintf((char*)svc->nt, nt_size, "urn:%s:service:%s:%"PRIu32,
	    svc->domain_name, svc->type, svc->ver);
	if (IS_SNPRINTF_FAIL(rc, nt_size)) {
		error = EFAULT;
		goto err_out;
	}
	svc->nt_size = (size_t)rc;
	/* Need more space? */
	serviceList_new = reallocarray(dev->serviceList,
	    (dev->serviceList_cnt + 4), sizeof(upnp_ssdp_svc_p));
	if (NULL == serviceList_new) { /* Reallocate failed. */
		error = ENOMEM;
		goto err_out;
	}
	dev->serviceList = serviceList_new;
	dev->serviceList[dev->serviceList_cnt] = svc;
	dev->serviceList_cnt ++;

	return (0);

err_out:
	free(svc);
	return (error);
}


int
upnp_ssdp_dev_if_add(upnp_ssdp_p ssdp, upnp_ssdp_dev_p dev,
    const char *if_name, size_t if_name_size, const char *url4, size_t url4_size,
    const char *url6, size_t url6_size) {
	upnp_ssdp_if_p s_if;
	upnp_ssdp_dev_if_p dev_if, *dev_ifs_new;
	uint32_t if_index;
	char ifname[IFNAMSIZ];
	int error;

	if (NULL == ssdp || NULL == dev ||
	    NULL == if_name || 0 == if_name_size ||
	    (NULL == url4 && NULL == url6) || (0 == url4_size && 0 == url6_size))
		return (EINVAL);
	if (IFNAMSIZ <= if_name_size)
		return (EINVAL);
	if (0 == if_name_size) {
		if_name_size = strnlen(if_name, (IFNAMSIZ - 1));
	}

	memcpy(ifname, if_name, if_name_size);
	ifname[if_name_size] = 0;
	if_index = if_nametoindex(ifname);
	s_if = upnp_ssdp_get_if_by_index(ssdp, if_index);
	if (NULL == s_if) {
		error = upnp_ssdp_if_add(ssdp, if_name, if_name_size, &s_if);
		if (0 != error)
			return (error);
	}
	dev_if = calloc(1, (sizeof(upnp_ssdp_dev_t) + url4_size + url6_size + 8));
	if (NULL == dev_if)
		return (ENOMEM);
	dev_if->s_if = s_if;
	dev_if->dev = dev;
	dev_if->url4 = (char*)(dev_if + 1);
	dev_if->url4_size = url4_size;
	dev_if->url6 = (dev_if->url4 + url4_size + 2);
	dev_if->url6_size = url6_size;
	memcpy(dev_if->url4, url4, url4_size);
	memcpy(dev_if->url6, url6, url6_size);
	SYSLOGD_EX(LOG_DEBUG, "url4 (%zu) = %s, url6 (%zu) = %s",
	    url4_size, dev_if->url4, url6_size, dev_if->url6);
	/* Add to device dev_ifs list. */
	dev_ifs_new = reallocarray(dev->dev_ifs, (dev->dev_ifs_cnt + 4),
	    sizeof(upnp_ssdp_dev_if_p));
	if (NULL == dev_ifs_new) { /* Reallocate failed. */
		free(dev_if);
		return (ENOMEM);
	}
	dev->dev_ifs = dev_ifs_new;
	dev->dev_ifs[dev->dev_ifs_cnt] = dev_if;
	dev->dev_ifs_cnt ++;
	/* Add to iface dev_ifs list. */
	dev_ifs_new = reallocarray(s_if->dev_ifs, (s_if->dev_ifs_cnt + 4),
	    sizeof(upnp_ssdp_dev_if_p));
	if (NULL == dev_ifs_new) { /* Reallocate failed. */
		dev->dev_ifs_cnt --;
		free(dev_if);
		return (ENOMEM);
	}
	s_if->dev_ifs = dev_ifs_new;
	s_if->dev_ifs[s_if->dev_ifs_cnt] = dev_if;
	s_if->dev_ifs_cnt ++;

	return (0);
}

void
upnp_ssdp_dev_if_del(upnp_ssdp_dev_if_p dev_if) {
	uint32_t i;

	if (NULL == dev_if)
		return;
	/* Remove frome dev_ifs list in iface. */
	if (NULL != dev_if->s_if) {
		for (i = 0; i < dev_if->s_if->dev_ifs_cnt; i ++) {
			if (dev_if->s_if->dev_ifs[i] != dev_if)
				continue;
			dev_if->s_if->dev_ifs_cnt --;
			dev_if->s_if->dev_ifs[i] = dev_if->s_if->dev_ifs[dev_if->s_if->dev_ifs_cnt];
			dev_if->s_if->dev_ifs[dev_if->s_if->dev_ifs_cnt] = NULL;
			break;
		}
	}
	/* Remove frome dev_ifs list in dev. */
	if (NULL != dev_if->dev) {
		for (i = 0; i < dev_if->dev->dev_ifs_cnt; i ++) {
			if (dev_if->dev->dev_ifs[i] != dev_if)
				continue;
			dev_if->dev->dev_ifs_cnt --;
			dev_if->dev->dev_ifs[i] = dev_if->dev->dev_ifs[dev_if->dev->dev_ifs_cnt];
			dev_if->dev->dev_ifs[dev_if->dev->dev_ifs_cnt] = NULL;
			break;
		}
	}
	free(dev_if);
}


upnp_ssdp_if_p
upnp_ssdp_get_if_by_index(upnp_ssdp_p ssdp, uint32_t if_index) {
	uint32_t i;

	if (NULL == ssdp)
		return (NULL);

	for (i = 0; i < ssdp->s_ifs_cnt; i ++) {
		if (ssdp->s_ifs[i]->if_index == if_index)
			return (ssdp->s_ifs[i]);
	}

	return (NULL);
}


int
upnp_ssdp_if_add(upnp_ssdp_p ssdp, const char *if_name, size_t if_name_size,
    upnp_ssdp_if_p *s_if_ret) {
	int error;
	upnp_ssdp_if_p s_if, *s_ifs_new;
	uint32_t if_index;
	char ifname[IFNAMSIZ];

	if (NULL == ssdp ||
	    NULL == if_name || IFNAMSIZ <= if_name_size)
		return (EINVAL);
	if (0 == if_name_size) {
		if_name_size = strnlen(if_name, (IFNAMSIZ - 1));
	}
	memcpy(ifname, if_name, if_name_size);
	ifname[if_name_size] = 0;
	if_index = if_nametoindex(ifname);
	if (0 == if_index)
		return (ESPIPE);
	s_if = calloc(1, sizeof(upnp_ssdp_if_t));
	if (NULL == s_if)
		return (ENOMEM);
	s_if->if_index = if_index;

	/* Join to multicast groups. */
	if (NULL != ssdp->mc_rcvr_v4) {
		error = skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v4),
		    1, if_index, &ssdp_v4_mc_addr);
		if (0 != error) {
			SYSLOG_ERR(LOG_CRIT, error, "skt_mc_join(IPv4).");
			goto err_out;
		}
	}
	if (NULL != ssdp->mc_rcvr_v6) {
		error = skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v6),
		    1, if_index, &ssdp_v6_mc_addr_link_local);
		if (0 != error) {
			SYSLOG_ERR(LOG_CRIT, error, "skt_mc_join(IPv6, link_local).");
			goto err_out;
		}
		error = skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v6),
		    1, if_index, &ssdp_v6_mc_addr_site_local);
		if (0 != error) {
			SYSLOG_ERR(LOG_CRIT, error, "skt_mc_join(IPv6, site_local).");
			goto err_out;
		}
	}

	/* Need more space? */
	s_ifs_new = reallocarray(ssdp->s_ifs, (ssdp->s_ifs_cnt + 4),
	    sizeof(upnp_ssdp_if_p));
	if (NULL == s_ifs_new) { /* Reallocate failed. */
		error = ENOMEM;
		goto err_out;
	}
	ssdp->s_ifs = s_ifs_new;
	ssdp->s_ifs[ssdp->s_ifs_cnt] = s_if;
	ssdp->s_ifs_cnt ++;
	if (NULL != s_if_ret) {
		(*s_if_ret) = s_if;
	}

	return (0);

err_out:
	/* Error. */
	/* Leave multicast groups. */
	if (NULL != ssdp->mc_rcvr_v4) {
		skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v4), 0,
		    if_index, &ssdp_v4_mc_addr);
	}
	if (NULL != ssdp->mc_rcvr_v6) {
		skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v6), 0,
		    if_index, &ssdp_v6_mc_addr_site_local);
		skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v6), 0,
		    if_index, &ssdp_v6_mc_addr_link_local);
	}
	free(s_if);

	return (error);
}

void
upnp_ssdp_if_del(upnp_ssdp_p ssdp, upnp_ssdp_if_p s_if) {
	uint32_t i;

	if (NULL == ssdp || NULL == s_if)
		return;
	/* Notify all. */
	/* Leave multicast groups. */
	if (NULL != ssdp->mc_rcvr_v4) {
		if (ssdp->byebye) {
			upnp_ssdp_iface_notify_ex(ssdp, s_if,
			    &ssdp_v4_mc_addr,
			    UPNP_SSDP_S_A_BYEBYE, NULL, 0);
		}
		skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v4), 0,
		    s_if->if_index, &ssdp_v4_mc_addr);
	}
	if (NULL != ssdp->mc_rcvr_v6) {
		if (ssdp->byebye) {
			upnp_ssdp_iface_notify_ex(ssdp, s_if,
			    &ssdp_v6_mc_addr_site_local,
			    UPNP_SSDP_S_A_BYEBYE, NULL, 0);
		}
		skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v6), 0,
		    s_if->if_index, &ssdp_v6_mc_addr_site_local);

		if (ssdp->byebye) {
			upnp_ssdp_iface_notify_ex(ssdp, s_if,
			    &ssdp_v6_mc_addr_link_local,
			    UPNP_SSDP_S_A_BYEBYE, NULL, 0);
		}
		skt_mc_join(tp_task_ident_get(ssdp->mc_rcvr_v6), 0,
		    s_if->if_index, &ssdp_v6_mc_addr_link_local);
	}
	/* Remove frome ifaces list. */
	for (i = 0; i < ssdp->s_ifs_cnt; i ++) {
		if (ssdp->s_ifs[i] == s_if) {
			ssdp->s_ifs_cnt --;
			ssdp->s_ifs[i] = ssdp->s_ifs[ssdp->s_ifs_cnt];
			ssdp->s_ifs[ssdp->s_ifs_cnt] = NULL;
			break;
		}
	}
	/* Remove from devices links lists. */
	if (NULL != s_if->dev_ifs) {
		for (i = 0; i < s_if->dev_ifs_cnt; i ++) {
			s_if->dev_ifs[i]->s_if = NULL;
			upnp_ssdp_dev_if_del(s_if->dev_ifs[i]);
		}
		free(s_if->dev_ifs);
	}
	free(s_if);
}

size_t
upnp_ssdp_if_count(upnp_ssdp_p ssdp) {

	if (NULL == ssdp)
		return (0);
	return (ssdp->s_ifs_cnt);
}


void
upnp_ssdp_send_notify(upnp_ssdp_p ssdp) {
	uint32_t i;

	if (NULL == ssdp)
		return;
	/* Notify all!!! */
	for (i = 0; i < ssdp->root_devs_cnt; i ++) {
		upnp_ssdp_dev_notify_sendto_mc(ssdp, ssdp->root_devs[i], UPNP_SSDP_S_A_ALIVE);
	}
}

void
upnp_ssdp_timer_cb(tp_event_p ev __unused, tp_udata_p tp_udata) {
	upnp_ssdp_dev_p dev = (upnp_ssdp_dev_p)tp_udata->ident;

	if (NULL == dev)
		return;
	/* Notify all. */
	upnp_ssdp_dev_notify_sendto_mc(dev->ssdp, dev, UPNP_SSDP_S_A_ALIVE);

	/* Individual unicast clients. */
	//for (size_t i = 0; i < ...; i ++) {
	//	upnp_ssdp_dev_notify_sendto(dev->ssdp, dev,
	//	    sockaddr_storage_p addr, UPNP_SSDP_S_A_SRESPONSE);
	//}
}

int
upnp_ssdp_mc_recv_cb(tp_task_p tptask, int error, uint32_t eof __unused,
    size_t data2transfer_size, void *arg) {
	upnp_ssdp_p ssdp = arg;
	uint32_t if_index = 0;
	size_t transfered_size = 0;
	uintptr_t ident;
	ssize_t ios;
	upnp_ssdp_if_p s_if;
	char straddr[STR_ADDR_LEN];
	sockaddr_storage_t caddr, *addr = &caddr;
	const uint8_t *ptm;
	uint8_t *req_hdr, buf[65536];
	size_t tm, req_hdr_len;
	http_req_line_data_t req_data;

	if (0 != error) {
		SYSLOG_ERR(LOG_DEBUG, error, "On receive.");
		return (TP_TASK_CB_CONTINUE);
	}

	ident = tp_task_ident_get(tptask);
	while (transfered_size < data2transfer_size) { /* Recv loop. */
		ios = skt_recvfrom(ident, buf, sizeof(buf), MSG_DONTWAIT,
		    addr, &if_index);
		if (-1 == ios) {
			error = errno;
			if (0 == error) {
				error = EINVAL;
			}
			error = SKT_ERR_FILTER(error);
			SYSLOG_ERR(LOG_NOTICE, error, "recvmsg().");
			break;
		}
		if (0 == ios)
			break;
		transfered_size += (size_t)ios;
		/* Get iface data. */
		s_if = upnp_ssdp_get_if_by_index(ssdp, if_index);
		if (NULL == s_if) {
			syslog(LOG_INFO, "No configured iface for this packet. (%i)",
			    if_index);
			continue;
		}
#ifdef DEBUG
		buf[ios] = 0;
		sa_addr_port_to_str(addr, straddr, sizeof(straddr), NULL);
		syslog(LOG_DEBUG, "recvfrom ip: %s (%i) - %zu bytes.\n%s",
		    straddr, if_index, ios, buf);
#endif
		ptm = mem_find_cstr(buf, (size_t)ios, CRLFCRLF);
		/* no/bad request. */
		if (NULL == ptm) {
			sa_addr_port_to_str(addr, straddr, sizeof(straddr), NULL);
			syslog(LOG_DEBUG, "No http header, client ip: %s.", straddr);
			continue;
		}
		req_hdr = buf;
		req_hdr_len = (size_t)(ptm - buf);

		if (0 != http_parse_req_line(req_hdr, req_hdr_len, &req_data)) {
			sa_addr_port_to_str(addr, straddr,
			    sizeof(straddr), NULL);
			syslog(LOG_NOTICE,
			    "Bad http header or request, client ip: %s.",
			    straddr);
			continue;
		}
		if (HTTP_REQ_METHOD_M_SEARCH != req_data.method_code ||
		    1 != req_data.abs_path_size || req_data.abs_path[0] != '*')
			continue;
		if (0 != http_req_sec_chk(req_hdr, req_hdr_len, req_data.method_code)) {
			/* Something wrong in headers. */
			SYSLOGD(LOG_WARNING, "http_req_sec_chk() !!! bad http header or request, client ip: %s.", straddr);
			continue;
		}
#if 0
		if (0 != http_hdr_val_get(req_hdr, req_hdr_len,
		    (uint8_t*)"host", 4, &ptm, &tm) || 15 > tm ||
		    0 != memcmp(ptm, UPNP_SSDP_V4_ADDR, 15)) {
			sa_addr_port_to_str(addr, straddr, sizeof(straddr), NULL);
			syslog(LOG_NOTICE, "Bad http HOST (%s) in request, client ip: %s.", ptm, straddr);
			continue;
		}
#endif
		if (0 != http_hdr_val_get(req_hdr, req_hdr_len,
		    (const uint8_t*)"man", 3, &ptm, &tm) ||
		    0 != mem_cmpn_cstr("\"ssdp:discover\"", ptm, tm)) {
			sa_addr_port_to_str(addr, straddr, sizeof(straddr), NULL);
			syslog(LOG_WARNING, "Bad http MAN in request, client ip: %s.",
			    straddr);
			continue;
		}
		if (0 != http_hdr_val_get(req_hdr, req_hdr_len,
		    (const uint8_t*)"mx", 2, &ptm, &tm)) {
			sa_addr_port_to_str(addr, straddr, sizeof(straddr), NULL);
			syslog(LOG_WARNING, "Bad http MX in request, client ip: %s.",
			    straddr);
			continue;
		}
		if (0 != http_hdr_val_get(req_hdr, req_hdr_len,
		    (const uint8_t*)"st", 2, &ptm, &tm)) {
			sa_addr_port_to_str(addr, straddr, sizeof(straddr), NULL);
			syslog(LOG_WARNING, "Bad http ST in request, client ip: %s.",
			    straddr);
			continue;
		}
		upnp_ssdp_iface_notify_ex(ssdp, s_if, addr, UPNP_SSDP_S_A_SRESPONSE,
		    ptm, tm);
	} /* End recv loop. */

	return (TP_TASK_CB_CONTINUE);
}


int
upnp_ssdp_iface_notify_ex(upnp_ssdp_p ssdp, upnp_ssdp_if_p s_if,
    sockaddr_storage_p addr, int action,
    const uint8_t *search_target, size_t search_target_size) {
	const uint8_t *st;
	size_t st_size;
	uint32_t i, j, ver;
	int root_dev_only = 0;
	upnp_ssdp_dev_if_p dev_if;
	upnp_ssdp_dev_p dev/*, edev */;
	upnp_ssdp_svc_p svc;

	if (NULL == ssdp ||
	    NULL == s_if || NULL == s_if->dev_ifs ||
	    NULL == addr ||
	    (NULL == search_target && 0 != search_target_size) ||
	    (UPNP_NOTIFY_TYPE_MAX_SIZE - 1) < search_target_size) /* Search target size too big. */
		return (EINVAL);

	/* Check: is ip proto enabled? */
	switch (addr->ss_family) {
	case AF_INET:
		if (NULL == ssdp->mc_rcvr_v4)
			return (0); /* IPv4 disabled. */
		break;
	case AF_INET6:
		if (NULL == ssdp->mc_rcvr_v6)
			return (0); /* IPv6 disabled. */
		break;
	default:
		return (EINVAL);
	}

	if (0 == mem_cmpn_cstr("ssdp:all", search_target, search_target_size)) {
		search_target = NULL;
		search_target_size = 0;
	} else if (0 == mem_cmpn_cstr("upnp:rootdevice", search_target, search_target_size)) {
		root_dev_only = 1;
	}

	for (i = 0; i < s_if->dev_ifs_cnt; i ++) {
		dev_if = s_if->dev_ifs[i];
		if (NULL == dev_if ||
		    NULL == dev_if->dev)
			continue;
		dev = dev_if->dev;
		/* Device is root. */
		if (NULL == search_target ||
		    0 != root_dev_only) {
			upnp_ssdp_send(ssdp, s_if, addr, action, dev_if,
			     (const uint8_t*)"upnp:rootdevice", 15);
			if (0 != root_dev_only)
				continue;
		}
		/* Device uuid. */
		if (NULL == search_target ||  /* st = "ssdp:all" */
		    (UPNP_NT_UUID_SIZE == search_target_size &&
		    0 == memcmp(search_target, dev->nt_uuid, UPNP_NT_UUID_SIZE))) {
			upnp_ssdp_send(ssdp, s_if, addr, action, dev_if,
			    dev->nt_uuid, UPNP_NT_UUID_SIZE);
		}
		/* Device type. */
		if (NULL == search_target) {
			upnp_ssdp_send(ssdp, s_if, addr, action, dev_if,
			    dev->nt, dev->nt_size);
			goto dev_no_match;
		}
		/* "urn:%s:device:%s:" */
		st = search_target;
		st_size = search_target_size;
		if (4 > st_size || 0 != memcmp(st, "urn:", 4))
			goto dev_no_match;
		st += 4;
		st_size -= 4;
		if (dev->domain_name_size > st_size ||
		    0 != memcmp(st, dev->domain_name, dev->domain_name_size))
			goto dev_no_match;
		st += dev->domain_name_size;
		st_size -= dev->domain_name_size;
		if (8 > st_size || 0 != memcmp(st, ":device:", 8))
			goto dev_no_match;
		st += 8;
		st_size -= 8;
		if (dev->type_size > st_size ||
		    0 != memcmp(st, dev->type, dev->type_size))
			goto dev_no_match;
		st += dev->type_size;
		st_size -= dev->type_size;
		if (2 > st_size || ':' != (*st))
			goto dev_no_match; /* No ver. */
		st += 1;
		st_size -= 1;
		ver = ustr2u32(st, st_size);
		if (ver > dev->ver)
			goto dev_no_match; /* We have older version than required. */
		upnp_ssdp_send(ssdp, s_if, addr, action, dev_if,
		    search_target, search_target_size);

dev_no_match:
		/* Device serviceList. */
		for (j = 0; j < dev->serviceList_cnt && NULL != dev->serviceList; j ++) {
			svc = dev->serviceList[j];
			if (NULL == svc)
				continue;
			if (NULL == search_target) {
				upnp_ssdp_send(ssdp, s_if, addr, action,
				    dev_if, svc->nt, svc->nt_size);
				continue;
			}
			/* "urn:%s:service:%s:" */
			st = search_target;
			st_size = search_target_size;
			if (4 > st_size || 0 != memcmp(st, "urn:", 4))
				continue;
			st += 4;
			st_size -= 4;
			if (svc->domain_name_size > st_size ||
			    0 != memcmp(st, svc->domain_name, svc->domain_name_size))
				continue;
			st += svc->domain_name_size;
			st_size -= svc->domain_name_size;
			if (9 > st_size || 0 != memcmp(st, ":service:", 9))
				continue;
			st += 9;
			st_size -= 9;
			if (svc->type_size > st_size ||
			    0 != memcmp(st, svc->type, svc->type_size))
				continue;
			st += svc->type_size;
			st_size -= svc->type_size;
			if (2 > st_size || ':' != (*st))
				continue; /* No ver. */
			st += 1;
			st_size -= 1;
			ver = ustr2u32(st, st_size);
			if (ver > svc->ver)
				continue; /* We have older version than required. */
			upnp_ssdp_send(ssdp, s_if, addr, action, dev_if,
			    search_target, search_target_size);
		}
		/* XXX todo: enum embeded deviceList. */
		//edev = dev->deviceList;
	}

	return (0);
}

int
upnp_ssdp_dev_notify_sendto_mc(upnp_ssdp_p ssdp, upnp_ssdp_dev_p dev, int action) {

	/* Notify all. */
	if (NULL != ssdp->mc_rcvr_v4) {
		upnp_ssdp_dev_notify_sendto(ssdp, dev,
		    &ssdp_v4_mc_addr, action);
	}
	if (NULL != ssdp->mc_rcvr_v6) {
		upnp_ssdp_dev_notify_sendto(ssdp, dev,
		    &ssdp_v6_mc_addr_site_local, action);
		upnp_ssdp_dev_notify_sendto(ssdp, dev,
		    &ssdp_v6_mc_addr_link_local, action);
	}

	return (0);
}

int
upnp_ssdp_dev_notify_sendto(upnp_ssdp_p ssdp, upnp_ssdp_dev_p dev,
    sockaddr_storage_p addr, int action) {
	uint32_t i, j;
	upnp_ssdp_dev_if_p dev_if;
	upnp_ssdp_if_p s_if;
	//upnp_ssdp_dev_p edev;
	upnp_ssdp_svc_p svc;

	if (NULL == ssdp ||
	    NULL == dev ||
	    NULL == addr)
		return (EINVAL);
	if (NULL == dev->dev_ifs)
		return (0);
	/* Check: is ip proto enabled? */
	switch (addr->ss_family) {
	case AF_INET:
		if (NULL == ssdp->mc_rcvr_v4)
			return (0); /* IPv4 disabled. */
		break;
	case AF_INET6:
		if (NULL == ssdp->mc_rcvr_v6)
			return (0); /* IPv6 disabled. */
		break;
	default:
		SYSLOGD_EX(LOG_DEBUG, "Bad addr->ss_family.");
		return (EINVAL);
	}
	for (i = 0; i < dev->dev_ifs_cnt; i ++) { /* Send to all associated ifaces. */
		dev_if = dev->dev_ifs[i];
		if (NULL == dev_if ||
		    NULL == dev_if->s_if)
			continue;
		s_if = dev_if->s_if;
		/* Device is root. */
		upnp_ssdp_send(ssdp, s_if, addr, action, dev_if,
		    (const uint8_t*)"upnp:rootdevice", 15);
		/* Device uuid. */
		upnp_ssdp_send(ssdp, s_if, addr, action, dev_if,
		    dev->nt_uuid, UPNP_NT_UUID_SIZE);
		/* Device type. */
		upnp_ssdp_send(ssdp, s_if, addr, action, dev_if,
		    dev->nt, dev->nt_size);
		/* Device serviceList. */
		if (NULL == dev->serviceList)
			continue;
		for (j = 0; j < dev->serviceList_cnt; j ++) {
			svc = dev->serviceList[j];
			if (NULL == svc)
				continue;
			upnp_ssdp_send(ssdp, s_if, addr, action,
			    dev_if, svc->nt, svc->nt_size);
		}
	}
	/* XXX todo: enum embeded deviceList. */
	//edev = dev->deviceList;
	return (0);
}

int
upnp_ssdp_send(upnp_ssdp_p ssdp, upnp_ssdp_if_p s_if, sockaddr_storage_p addr, int action,
    upnp_ssdp_dev_if_p dev_if, const uint8_t *nt, size_t nt_size) {
	int error;
	const char *dhost_addr, *usn_pre_nt, *usn_nt;
	char *url, nt_loc[UPNP_NOTIFY_TYPE_MAX_SIZE];
	io_buf_t buf;
	upnp_ssdp_dev_p dev;
	int add_search_port = 0;
	uintptr_t skt;
	size_t url_size;
	struct ip_mreqn ipmrn; 
	sockaddr_storage_t v6_mc_addr;
	char straddr[STR_ADDR_LEN];
	uint8_t buf_data[4096];

	if (NULL == ssdp || NULL == addr || NULL == dev_if ||
	    (NULL == nt && 0 != nt_size))
		return (EINVAL);
	if (sizeof(nt_loc) <= nt_size)
		return (0); /* Search target size too big. */
	if (0 == nt_size) {
		nt_size = strnlen((const char*)nt, (sizeof(nt_loc) - 1));
	}

	dev = dev_if->dev;
	io_buf_init(&buf, 0, buf_data, sizeof(buf_data));

	switch (addr->ss_family) {
	case AF_INET:
		if (NULL == ssdp->mc_rcvr_v4)
			return (0); /* IPv4 disabled. */
		skt = tp_task_ident_get(ssdp->mc_rcvr_v4);
		if (NULL != s_if) {
			memset(&ipmrn, 0x00, sizeof(ipmrn));
			ipmrn.imr_ifindex = (int)s_if->if_index;
			if (0 != setsockopt((int)skt, IPPROTO_IP, IP_MULTICAST_IF,
			    &ipmrn, sizeof(ipmrn))) {
				SYSLOG_ERR(LOG_ERR, errno, "setsockopt(IP_MULTICAST_IF)");
			}
		}
		url = dev_if->url4;
		url_size = dev_if->url4_size;
		dhost_addr = ssdp_v4_addr;
#if 0
		if (UPNP_SSDP_S_A_SRESPONSE != action)
			addr = &ssdp_v4_mc_addr;
#endif
		break;
	case AF_INET6:
		if (NULL == ssdp->mc_rcvr_v6)
			return (0); /* IPv6 disabled. */
		skt = tp_task_ident_get(ssdp->mc_rcvr_v6);
		if (NULL != s_if) {
			if (0 != setsockopt((int)skt, IPPROTO_IPV6, IPV6_MULTICAST_IF,
			    &s_if->if_index, sizeof(uint32_t))) {
				SYSLOG_ERR(LOG_ERR, errno, "setsockopt(IPV6_MULTICAST_IF)");
			}
		}
		url = dev_if->url6;
		url_size = dev_if->url6_size;
#if 0
		if (UPNP_SSDP_S_A_SRESPONSE != action)
			addr = &ssdp_v6_mc_addr_link_local;
#endif
		/* Make copy of addr, update ptr and edit. */
		memcpy(&v6_mc_addr, addr, sizeof(v6_mc_addr));
		addr = &v6_mc_addr;
		if (IN6_IS_ADDR_MC_LINKLOCAL(&((sockaddr_in6_p)addr)->sin6_addr)) {
			dhost_addr = ssdp_v6_addr_link_local;
			if (NULL != s_if) {
				((sockaddr_in6_p)addr)->sin6_scope_id = s_if->if_index;
			}
		} else {
			dhost_addr = ssdp_v6_addr_site_local;
		}
		break;
	default:
		return (EINVAL);
	}
	if (0 == url_size) /* No IPv4/6 config for this iface. */
		return (0);
	memcpy(nt_loc, nt, nt_size);
	nt_loc[nt_size] = 0;
	usn_nt = nt_loc;
	usn_pre_nt = "::";
	if (5 < nt_size && 0 == memcmp(nt, "uuid:", 5)) { /* Device uuid. */
		usn_pre_nt = usn_nt = "";
	}

	switch (action) {
	case UPNP_SSDP_S_A_BYEBYE: /* 1.2.3 Device unavailable -- NOTIFY with ssdp:byebye. */
		error = io_buf_printf(&buf,
		    "NOTIFY * HTTP/1.1\r\n"
		    "HOST: %s:1900\r\n"
		    "NT: %s\r\n"
		    "OPT: \"http://schemas.upnp.org/upnp/1/0/\"; ns=01\r\n" /* For backward compatibility. */
		    "01-NLS: %"PRIu32"\r\n" /* For backward compatibility. */
		    "NTS: ssdp:byebye\r\n"
		    "USN: uuid:%s%s%s\r\n"
		    "BOOTID.UPNP.ORG: %"PRIu32"\r\n"
		    "CONFIGID.UPNP.ORG: %"PRIu32"\r\n",
		    dhost_addr, nt_loc, dev->boot_id, dev->uuid, usn_pre_nt, usn_nt,
		    dev->boot_id, dev->config_id);
		if (0 != error)
			return (error);
		break;
	case UPNP_SSDP_S_A_ALIVE: /* 1.2.2 Device available - NOTIFY with ssdp:alive. */
		add_search_port = (UPNP_SSDP_PORT != ssdp->search_port);
		error = io_buf_printf(&buf,
		    "NOTIFY * HTTP/1.1\r\n"
		    "HOST: %s:1900\r\n"
		    "CACHE-CONTROL: max-age=%"PRIu32"\r\n"
		    "LOCATION: %s\r\n"
		    "OPT: \"http://schemas.upnp.org/upnp/1/0/\"; ns=01\r\n" /* For backward compatibility. */
		    "01-NLS: %"PRIu32"\r\n" /* For backward compatibility. */
		    "NT: %s\r\n"
		    "NTS: ssdp:alive\r\n"
		    "SERVER: %s\r\n"
		    "USN: uuid:%s%s%s\r\n"
		    "BOOTID.UPNP.ORG: %"PRIu32"\r\n"
		    "CONFIGID.UPNP.ORG: %"PRIu32"\r\n",
		    dhost_addr, dev->max_age, url,
		    dev->boot_id, nt_loc, ssdp->http_server,
		    dev->uuid, usn_pre_nt, usn_nt, dev->boot_id, dev->config_id);
		if (0 != error)
			return (error);
		break;
	case UPNP_SSDP_S_A_UPDATE: /* 1.2.4 Device Update NOTIFY with ssdp:update. */
		add_search_port = (UPNP_SSDP_PORT != ssdp->search_port);
		error = io_buf_printf(&buf,
		    "NOTIFY * HTTP/1.1\r\n"
		    "HOST: %s:1900\r\n"
		    "LOCATION: %s\r\n"
		    "NT: %s\r\n"
		    "OPT: \"http://schemas.upnp.org/upnp/1/0/\"; ns=01\r\n" /* For backward compatibility. */
		    "01-NLS: %"PRIu32"\r\n" /* For backward compatibility. */
		    "NTS: ssdp:update\r\n"
		    "USN: uuid:%s%s%s\r\n"
		    "BOOTID.UPNP.ORG: %"PRIu32"\r\n"
		    "CONFIGID.UPNP.ORG: %"PRIu32"\r\n"
		    "NEXTBOOTID.UPNP.ORG: %"PRIu32"\r\n",
		    dhost_addr, url, nt_loc, dev->boot_id, dev->uuid, usn_pre_nt, usn_nt,
		    dev->boot_id,
		    dev->config_id, (dev->boot_id + 1));
		if (0 != error)
			return (error);
		break;
	case UPNP_SSDP_S_A_SRESPONSE: /* 1.3.3 Discovery: Search: Response. */
		add_search_port = (UPNP_SSDP_PORT != ssdp->search_port);
		error = io_buf_printf(&buf,
		    "HTTP/1.1 200 OK\r\n"
		    "CACHE-CONTROL: max-age=%"PRIu32"\r\n"
		    "EXT:\r\n"
		    "LOCATION: %s\r\n"
		    "SERVER: %s\r\n"
		    "OPT: \"http://schemas.upnp.org/upnp/1/0/\"; ns=01\r\n" /* For backward compatibility. */
		    "01-NLS: %"PRIu32"\r\n" /* For backward compatibility. */
		    "ST: %s\r\n"
		    "USN: uuid:%s%s%s\r\n"
		    "BOOTID.UPNP.ORG: %"PRIu32"\r\n"
		    "CONFIGID.UPNP.ORG: %"PRIu32"\r\n",
		    dev->max_age, url, ssdp->http_server,
		    dev->boot_id, nt_loc, dev->uuid, usn_pre_nt, usn_nt, dev->boot_id,
		    dev->config_id);
		if (0 != error)
			return (error);
		break;
	}
	if (0 != add_search_port) {
		error = io_buf_printf(&buf,
		    "SEARCHPORT.UPNP.ORG: %"PRIu32"\r\n",
		    ssdp->search_port);
		if (0 != error)
			return (error);
	}
	error = IO_BUF_COPYIN_CSTR(&buf,
	    "CONTENT-LENGTH: 0\r\n\r\n");
	if (0 != error)
		return (error);

	if (-1 == sendto((int)skt, buf.data, buf.used, (MSG_DONTWAIT | MSG_NOSIGNAL),
	    (sockaddr_p)addr, sa_size(addr))) {
		error = errno;
		sa_addr_port_to_str(addr, straddr, sizeof(straddr), NULL);
		SYSLOG_ERR(LOG_ERR, error, "sendto(%s, size = %zu).", straddr, buf.used);
		return (error);
	}

	return (0);
}
