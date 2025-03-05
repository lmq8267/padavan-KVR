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


#ifndef __SOCKET_H__
#define __SOCKET_H__

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <inttypes.h>
#include "net/socket_address.h"


#ifndef TCP_CA_NAME_MAX /* For stupid linux. */
#	define TCP_CA_NAME_MAX		((size_t)16)
#endif

/* EBUSY - for sendfile() */
#define SKT_ERR_FILTER(__error)						\
    ((EAGAIN == (__error) ||						\
      EWOULDBLOCK == (__error) ||					\
      EBUSY == (__error) ||						\
      EINTR == (__error)) ?						\
     0 : (__error))


#define SO_F_CLOEXEC		(((uint32_t)1) <<  0) /* SOCK_CLOEXEC */
#define SO_F_NONBLOCK		(((uint32_t)1) <<  1) /* SOCK_NONBLOCK */
#define SO_F_BROADCAST		(((uint32_t)1) <<  2) /* SO_BROADCAST */
#define SO_F_REUSEADDR		(((uint32_t)1) <<  3) /* SO_REUSEADDR */
#define SO_F_REUSEPORT		(((uint32_t)1) <<  4) /* SO_REUSEPORT / SO_REUSEPORT_LB */
/* Other flags in net/socket_options.h. */


int	skt_rcv_tune(uintptr_t skt, uint32_t buf_size, uint32_t lowat);
int	skt_snd_tune(uintptr_t skt, uint32_t buf_size, uint32_t lowat);
int	skt_set_tcp_cc(uintptr_t skt, const char *cc, size_t cc_size);
int	skt_get_tcp_cc(uintptr_t skt, char *cc, size_t cc_size, size_t *cc_size_ret);
int	skt_is_tcp_cc_avail(const char *cc, size_t cc_size);
int	skt_get_tcp_maxseg(uintptr_t skt, int *val_ret);
int	skt_get_addr_family(uintptr_t skt, sa_family_t *family);
int	skt_set_tcp_nodelay(uintptr_t skt, int val);
int	skt_set_tcp_nopush(uintptr_t skt, int val);
int	skt_set_accept_filter(uintptr_t skt, const char *accf, size_t accf_size);
int	skt_mc_join(uintptr_t skt, int join, uint32_t if_index,
	    const sockaddr_storage_t *mc_addr);
int	skt_mc_join_ifname(uintptr_t skt, int join, const char *ifname,
	    size_t ifname_size, const sockaddr_storage_t *mc_addr);

int	skt_enable_recv_ifindex(uintptr_t skt, int enable);


int	skt_create(int domain, int type, int protocol, uint32_t flags,
	    uintptr_t *skt_ret);
int	skt_accept(uintptr_t skt, sockaddr_storage_p addr,
	    socklen_t *addrlen, uint32_t flags, uintptr_t *skt_ret);
#define SKT_CREATE_FLAG_MASK	(SO_F_CLOEXEC | SO_F_NONBLOCK | SO_F_BROADCAST)

int	skt_bind(const sockaddr_storage_t *addr, int type, int protocol,
	    uint32_t flags, uintptr_t *skt_ret);
int	skt_bind_ap(const sa_family_t family, void *addr, uint16_t port,
	    int type, int protocol, uint32_t flags, uintptr_t *skt_ret);
#define SKT_BIND_FLAG_MASK	(SKT_CREATE_FLAG_MASK | SO_F_REUSEADDR | SO_F_REUSEPORT)

ssize_t	skt_recvfrom(uintptr_t skt, void *buf, size_t buf_size, int flags,
	    sockaddr_storage_p from, uint32_t *if_index);

int	skt_sendfile(uintptr_t fd, uintptr_t skt, off_t offset, size_t size,
	    int flags, off_t *transfered_size);

/* Auto flags, to allow build on Linux and MacOS. */
#ifndef SF_NODISKIO
#define SF_NODISKIO 0
#endif
#ifndef SF_MNOWAIT
#define SF_MNOWAIT 0
#endif
#ifndef SF_SYNC
#define SF_SYNC 0
#endif

#define SKT_SF_F_NODISKIO	SF_NODISKIO
#define SKT_SF_F_MNOWAIT	SF_MNOWAIT
#define SKT_SF_F_SYNC		SF_SYNC

int	skt_listen(uintptr_t skt, int backlog);

int	skt_connect(const sockaddr_storage_t *addr, int type, int protocol,
	    uint32_t flags, uintptr_t *skt_ret);
int	skt_is_connect_error(int error);

int	skt_sync_resolv(const char *hname, uint16_t port, int ai_family,
	    sockaddr_storage_p addrs, size_t addrs_count,
	    size_t *addrs_count_ret);
int	skt_sync_resolv_connect(const char *hname, uint16_t port,
	    int domain, int type, int protocol, uintptr_t *skt_ret);

int	skt_tcp_stat_text(uintptr_t skt, const char *tabs,
	    char *buf, size_t buf_size, size_t *buf_size_ret);


#endif /* __SOCKET_H__ */
