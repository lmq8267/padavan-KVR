/*-
 * Copyright (c) 2011-2024 Rozhuk Ivan <rozhuk.im@gmail.com>
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
#include <inttypes.h>
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <errno.h>
#include <time.h>

#include "proto/sap.h"
#include "proto/sdp.h"
#include "utils/mem_utils.h"
#include "utils/str2num.h"
#include "utils/macro.h"
#include "threadpool/threadpool.h"
#include "threadpool/threadpool_task.h"
#include "net/socket.h"
#include "net/socket_address.h"
#include "net/utils.h"
#include "proto/sap_rcvr.h"
#include "utils/data_cache.h"

#define RECV_BUF_SIZE	4096


typedef struct sap_rcvr_s {
	tp_task_p	io_pkt_rcvr4;	/* Packer receiver IPv4 skt. */
	//tp_task_p	io_pkt_rcvr6;	/* Packer receiver IPv4 skt. */
	data_cache_p	dcache;		/* Cache received records. */
	uint32_t	cache_time;	/* Cache time for item. */
	uintptr_t	sktv4;		/* IPv4 UDP socket. */
	//uintptr_t	sktv6;		/* IPv6 UDP socket. */
} sap_rcvr_t;


typedef struct sdp_lite_s {
	uint8_t		*id;		/* o= */
	uint8_t		*name;		/* s= */
	uint16_t	id_size;
	uint16_t	name_size;
	uint16_t	media_proto;	/* udp/rtp/srtp */
	uint16_t	flags;		/* non zero if initialized. */
	uint32_t	if_index;	/* Interface index, were first time received. */
	sockaddr_storage_t addr;	/* connection addr type (IPv4/IPv6), addr, port. */
} sdp_lite_t, *sdp_lite_p;


sdp_lite_p	sdp_lite_alloc(const uint8_t *id, uint16_t id_size, uint16_t name_size);
void		sdp_lite_free(sdp_lite_p sdpl);
int		data_cache_enum_cb_fn(void *udata, data_cache_item_p dc_item);
static int 	sap_receiver_recv_cb(tp_task_p tptask, int error,
		    uint32_t eof __unused,
		    size_t data2transfer_size __unused, void *arg);



/* Staff for data_cache. */
uint32_t	sap_data_cache_hash(const uint8_t *key, size_t key_size);
void 		*sap_data_cache_alloc_data(const uint8_t *key, size_t key_size);
void		sap_data_cache_free_data(void *data);
int		sap_data_cache_cmp_data(const uint8_t *key, size_t key_size,
		    void *data);

uint32_t
sap_data_cache_hash(const uint8_t *key, size_t key_size) {
	register uint32_t ret = 0;
	register size_t i;

	key_size = LOWORD(key_size);
	if (NULL == key || 0 == key_size)
		return (ret);

	for (i = 0; i < key_size; i ++) {
		ret ^= (uint8_t)key[i];
	}

	return (ret);
}

void *
sap_data_cache_alloc_data(const uint8_t *key, size_t key_size) {

	return (sdp_lite_alloc(key, LOWORD(key_size), HIWORD(key_size)));
}

void
sap_data_cache_free_data(void *data) {

	sdp_lite_free((sdp_lite_p)data);
}

int
sap_data_cache_cmp_data(const uint8_t *key, size_t key_size, void *data) {

	key_size = LOWORD(key_size);
	if (((sdp_lite_p)data)->id_size != key_size) {
		if (key_size > ((sdp_lite_p)data)->id_size)
			return (1);
		return (-1);
	}

	return (memcmp(key, ((sdp_lite_p)data)->id, key_size));
}



sdp_lite_p
sdp_lite_alloc(const uint8_t *id, uint16_t id_size, uint16_t name_size) {
	sdp_lite_p sdpl;

	if (NULL == id || 0 == id_size)
		return (NULL);

	sdpl = calloc(1, (sizeof(sdp_lite_t) + id_size + sizeof(void*) + name_size + sizeof(void*)));
	if (NULL == sdpl)
		return (sdpl);
	sdpl->id = (uint8_t*)(sdpl + 1);
	sdpl->name = (uint8_t*)(sdpl->id + id_size + 2);
	memcpy(sdpl->id, id, id_size);
	sdpl->id[id_size] = 0;
	sdpl->id_size = id_size;

	return (sdpl);
}

void
sdp_lite_free(sdp_lite_p sdpl) {

	if (NULL == sdpl)
		return;

	free(sdpl);
}


int
sap_receiver_create(tp_p thp, uint32_t skt_recv_buf_size,
    uint32_t cache_time, uint32_t cache_clean_interval,
    sap_rcvr_p *sap_rcvr_ret) {
	sap_rcvr_p srcvr;
	int error;

	if (NULL == thp || NULL == sap_rcvr_ret)
		return (EINVAL);
		
	srcvr = calloc(1, sizeof(sap_rcvr_t));
	if (NULL == srcvr)
		return (errno);
	error = skt_bind_ap(AF_INET, NULL, SAP_PORT,
	    SOCK_DGRAM, IPPROTO_UDP,
	    (SO_F_NONBLOCK | SO_F_REUSEADDR | SO_F_REUSEPORT),
	    &srcvr->sktv4);
	if (0 != error)
		goto err_out;
	/* Tune socket. */
	/* kb -> bytes */
	skt_recv_buf_size *= 1024;
	if (0 != skt_rcv_tune(srcvr->sktv4, skt_recv_buf_size, 1)) {
		error = errno;
		goto err_out;
	}
	error = skt_enable_recv_ifindex(srcvr->sktv4, 1);
	if (0 != error)
		goto err_out;

	srcvr->cache_time = cache_time;
	data_cache_create(&srcvr->dcache, sap_data_cache_alloc_data,
	    sap_data_cache_free_data, sap_data_cache_hash, sap_data_cache_cmp_data,
	    (cache_clean_interval * 1000));

	error = tp_task_notify_create(tp_thread_get_rr(thp), srcvr->sktv4,
	    TP_TASK_F_CLOSE_ON_DESTROY, TP_EV_READ, 0, sap_receiver_recv_cb,
	    srcvr, &srcvr->io_pkt_rcvr4);
	if (0 != error)
		goto err_out;

	(*sap_rcvr_ret) = srcvr;
	return (0);

err_out:
	/* Error. */
	sap_receiver_destroy(srcvr);
	return (error);
}

void
sap_receiver_destroy(sap_rcvr_p srcvr) {

	if (NULL == srcvr)
		return;

	tp_task_destroy(srcvr->io_pkt_rcvr4);
	//tp_task_destroy(srcvr->io_pkt_rcvr6);
	data_cache_destroy(srcvr->dcache);
	free(srcvr);
}

int
sap_receiver_listener_add4(sap_rcvr_p srcvr, const char *ifname, size_t ifname_size,
    const char *mcaddr, size_t mcaddr_size) {
	char mcaddrstr[INET_ADDRSTRLEN];
	sockaddr_storage_t mc_addr;
	in_addr_t sin_addr;

	if (NULL == srcvr || NULL == mcaddr || sizeof(mcaddrstr) <= mcaddr_size)
		return (EINVAL);
	if (0 == mcaddr_size) {
		mcaddr_size = strnlen(mcaddr, (sizeof(mcaddrstr) - 1));
	}
	memcpy(mcaddrstr, mcaddr, mcaddr_size);
	mcaddrstr[mcaddr_size] = 0;

	sin_addr = inet_addr(mcaddrstr);

	sa_init(&mc_addr, AF_INET, &sin_addr, 0);

	return (skt_mc_join_ifname(srcvr->sktv4, 1, ifname, ifname_size, &mc_addr));
}


static int
sap_receiver_recv_cb(tp_task_p tptask, int error,
    uint32_t eof __unused, size_t data2transfer_size __unused, void *arg) {
	sap_rcvr_p srcvr = arg;
	uint32_t if_index = 0xffffffff;
	uint8_t *sdp_msg;
	ssize_t ios;
	size_t transfered_size, sdp_msg_size;
	uint8_t *origin = NULL, *sess_name = NULL, *media = NULL, *conn = NULL, *ptm;
	size_t origin_size = 0, sess_name_size = 0, media_size = 0, conn_size = 0;
	char straddr[INET6_ADDRSTRLEN];
	data_cache_item_p dc_item;
	sdp_lite_p sdpl;
	uint8_t buf[RECV_BUF_SIZE];
	sap_hdr_p sap_hdr = (sap_hdr_p)buf;
	uint8_t *feilds[8];
	size_t feilds_sizes[8], cnt;
	uint16_t port, media_proto = 0; /* udp/rtp/srtp*/

	if (0 != error) {
		SYSLOG_ERR(LOG_DEBUG, error, "On receive.");
		goto rcv_next;
	}

	ios = skt_recvfrom(tp_task_ident_get(tptask),
	    buf, sizeof(buf), MSG_DONTWAIT, NULL, &if_index);
	if (-1 == ios) {
		error = errno;
		if (0 == error) {
			error = EINVAL;
		}
		error = SKT_ERR_FILTER(error);
		SYSLOG_ERR(LOG_NOTICE, error, "recvmsg().");
		goto rcv_next;
	}
	transfered_size = (size_t)ios;
	if (0 == sap_packet_is_valid(buf, transfered_size)) {
		syslog(LOG_NOTICE, "SAP bad packet.");
		goto rcv_next;
	}
	SYSLOGD_EX(LOG_DEBUG, "SAP: size=%zu, flags: [V:%i,A:%i,R:%i,T:%i,E:%i,C:%i], "
	    "auth len = %i, msg id hash = %i",
	    transfered_size,
	    sap_hdr->flags.bits.v, sap_hdr->flags.bits.a, sap_hdr->flags.bits.r,
	    sap_hdr->flags.bits.t, sap_hdr->flags.bits.e, sap_hdr->flags.bits.c,
	    sap_hdr->auth_len, sap_hdr->msg_id_hash);
	if (0 != sap_hdr->flags.bits.e || 0 != sap_hdr->flags.bits.c) {
		syslog(LOG_INFO, "SAP data encrypted or/and compressed.");
		goto rcv_next;
	}

	sdp_msg = sap_packet_get_payload(buf, transfered_size);
	sdp_msg_size = (transfered_size - (size_t)(sdp_msg - buf));
	buf[transfered_size] = 0;
	if (0 != sdp_msg_sec_chk(sdp_msg, sdp_msg_size)) {
		syslog(LOG_NOTICE, "SAP data: BAD!!!");
		goto rcv_next;
	}
	//SYSLOGD_EX(LOG_DEBUG, "SAP data: (%zu) %s", sdp_msg_size, sdp_msg);
	
	sdp_msg_type_get(sdp_msg, sdp_msg_size, 'm', NULL, &media, &media_size);
	if (8 > media_size ||
	    (0 != memcmp("video ", media, 6) && 0 != memcmp("audio ", media, 6)))
		goto rcv_next; /* Bad/unknown/unwanted media type. */
	sdp_msg_type_get(sdp_msg, sdp_msg_size, 'o', NULL, &origin, &origin_size);
	sdp_msg_type_get(sdp_msg, sdp_msg_size, 's', NULL, &sess_name, &sess_name_size);
	if (0 != data_cache_item_add(srcvr->dcache, origin,
	    MAKEDWORD(origin_size, sess_name_size), &dc_item))
		goto rcv_next; /* Some error on cache add/extract. */
	sdpl = ((sdp_lite_p)dc_item->data);
	dc_item->valid_untill = (time(NULL) + srcvr->cache_time);
	dc_item->returned_count ++;

	if (0 != sdpl->flags) {
		data_cache_item_unlock(dc_item);
		goto rcv_next; /* No need to write data. */
	}

	/* Handle: m= (media). */
	cnt = sdp_msg_feilds_get(media, media_size, 8,
	    (uint8_t**)&feilds, (size_t*)&feilds_sizes);
	if (4 > cnt) { /* Invalid num of feilds. */
		data_cache_item_unlock(dc_item);
		goto rcv_next;
	}
	port = ustr2u16(feilds[1], feilds_sizes[1]);
	if (3 == feilds_sizes[2] &&
	    0 == memcmp("udp", feilds[2], feilds_sizes[2])) {
		media_proto = 1;
	} else if (7 == feilds_sizes[2] &&
	     0 == memcmp("RTP/AVP", feilds[2], feilds_sizes[2])) {
		media_proto = 2;
	} else if (8 == feilds_sizes[2] &&
	     0 == memcmp("RTP/SAVP", feilds[2], feilds_sizes[2])) {
		media_proto = 3;
	}

	/* Handle c= (connection). */
	sdp_msg_type_get(sdp_msg, sdp_msg_size, 'c', NULL, &conn, &conn_size);
	cnt = sdp_msg_feilds_get(conn, conn_size, 8,
	    (uint8_t**)&feilds, (size_t*)&feilds_sizes);
	if (3 > cnt) { /* Invalid num of feilds. */
		data_cache_item_unlock(dc_item);
		goto rcv_next;
	}
	if (2 != feilds_sizes[0] ||
	    0 != memcmp("IN", feilds[0], feilds_sizes[0]) ||
	    3 != feilds_sizes[1] ||
	    7 > feilds_sizes[2]) { /* Invalid feils. */
		data_cache_item_unlock(dc_item);
		goto rcv_next;
	}
	/* Prepare ip address. */
	ptm = mem_chr(feilds[2], feilds_sizes[2], '/');
	if (NULL == ptm) {
		ptm = (feilds[2] + feilds_sizes[2]);
	}
	memcpy(straddr, feilds[2], (size_t)(ptm - feilds[2]));
	straddr[(ptm - feilds[2])] = 0;
	/* Try convert into binary form. */
	if (0 == memcmp("IP4", feilds[1], 3) || /* IPv4 addr. */
	    0 == memcmp("IP6", feilds[1], 3)) { /* IPv6 addr. */
		sa_init(&sdpl->addr,
		    (('4' == feilds[1][2]) ? AF_INET : AF_INET6),
		    NULL, 0);
		if (1 != inet_pton(sa_family(&sdpl->addr), straddr,
		    sa_addr_get(&sdpl->addr))) { /* Addr format err.*/
			data_cache_item_unlock(dc_item);
			goto rcv_next;
		}
		sa_port_set(&sdpl->addr, port);
	} else { /* Unknown/invalid addr type. */
		data_cache_item_unlock(dc_item);
		goto rcv_next;
	}
	memcpy(sdpl->name, sess_name, sess_name_size); // XXX
	sdpl->name[sess_name_size] = 0;
	sdpl->name_size = (uint16_t)sess_name_size;
	sdpl->media_proto = media_proto;
	sdpl->flags = 1;
	sdpl->if_index = if_index;

	SYSLOGD_EX(LOG_DEBUG, "SAP data: (%zu) %s", sdp_msg_size, sdp_msg);
	data_cache_item_unlock(dc_item);


	data_cache_clean(srcvr->dcache);

rcv_next:
	return (TP_TASK_CB_CONTINUE);
}
