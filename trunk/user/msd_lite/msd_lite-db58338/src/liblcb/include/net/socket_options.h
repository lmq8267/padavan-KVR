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


#ifndef __SOCKET_OPTIONS_H__
#define __SOCKET_OPTIONS_H__

#include <sys/types.h>
#include <inttypes.h>
#include "net/socket.h"


typedef struct socket_options_s {
	uint32_t	mask;		/* Flags: mask to set */
	uint32_t	bit_vals;	/* Bitmask values for: SO_F_BIT_VAL_MASK */
/* Socket level. */
	int		backlog;	/* Listen queue len. */
	uint32_t	rcv_buf;	/* SO_RCVBUF kb */
	uint32_t	rcv_lowat;	/* SO_RCVLOWAT kb */
	uint64_t	rcv_timeout;	/* SO_RCVTIMEO sec */
	uint32_t	snd_buf;	/* SO_SNDBUF kb */
	uint32_t	snd_lowat;	/* SO_SNDLOWAT kb */
	uint64_t	snd_timeout;	/* SO_SNDTIMEO sec */
/* IP level. */
	uint8_t		hop_limit_u;	/* IP_TTL / IPV6_UNICAST_HOPS count. */
	uint8_t		hop_limit_m;	/* IP_MULTICAST_TTL / IPV6_MULTICAST_HOPS count. */
/* Proto level. */
#ifdef SO_ACCEPTFILTER
	struct accept_filter_arg tcp_acc_filter; /* SO_ACCEPTFILTER */
#elif defined(TCP_DEFER_ACCEPT)
	uint32_t	tcp_acc_defer;	/* TCP_DEFER_ACCEPT sec */
#endif
	uint32_t	tcp_keep_idle;	/* TCP_KEEPIDLE only if SO_KEEPALIVE set */
	uint32_t	tcp_keep_intvl;	/* TCP_KEEPINTVL only if SO_KEEPALIVE set */
	uint32_t	tcp_keep_cnt;	/* TCP_KEEPCNT only if SO_KEEPALIVE set */
	char 		tcp_cc[TCP_CA_NAME_MAX]; /* TCP congestion control TCP_CONGESTION. */
	socklen_t	tcp_cc_size;
} skt_opts_t, *skt_opts_p;

/* Continue, first flags see in net/socket.h. */
/* Socket level. */
#define SO_F_HALFCLOSE_RD	(((uint32_t)1) <<  5) /* shutdown(SHUT_RD) */
#define SO_F_HALFCLOSE_WR	(((uint32_t)1) <<  6) /* shutdown(SHUT_WR) */
#define SO_F_HALFCLOSE_RDWR	(SO_F_HALFCLOSE_RD | SO_F_HALFCLOSE_WR) /* shutdown(SHUT_RDWR) */
#define SO_F_BACKLOG		(((uint32_t)1) <<  7) /* backlog is readed from config. */
#define SO_F_KEEPALIVE		(((uint32_t)1) <<  8) /* SO_KEEPALIVE */
#define SO_F_RCVBUF		(((uint32_t)1) <<  9) /* SO_RCVBUF */
#define SO_F_RCVLOWAT		(((uint32_t)1) << 10) /* SO_RCVLOWAT */
#define SO_F_RCVTIMEO		(((uint32_t)1) << 11) /* SO_RCVTIMEO - no set to skt */
#define SO_F_SNDBUF		(((uint32_t)1) << 12) /* SO_SNDBUF */
#define SO_F_SNDLOWAT		(((uint32_t)1) << 13) /* SO_SNDLOWAT */
#define SO_F_SNDTIMEO		(((uint32_t)1) << 14) /* SO_SNDTIMEO - no set to skt */
/* IP level. */
#define SO_F_IP_HOPLIM_U	(((uint32_t)1) << 16) /* IP_TTL / IPV6_UNICAST_HOPS */
#define SO_F_IP_HOPLIM_M	(((uint32_t)1) << 17) /* IP_MULTICAST_TTL / IPV6_MULTICAST_HOPS */
#define SO_F_IP_MULTICAST_LOOP	(((uint32_t)1) << 18) /* IP_MULTICAST_LOOP / IPV6_MULTICAST_LOOP */
/* Proto level. */
#define SO_F_ACC_FILTER		(((uint32_t)1) << 24) /* SO_ACCEPTFILTER(httpready) / TCP_DEFER_ACCEPT */
#define SO_F_TCP_KEEPIDLE	(((uint32_t)1) << 25) /* TCP_KEEPIDLE only if SO_KEEPALIVE set */
#define SO_F_TCP_KEEPINTVL	(((uint32_t)1) << 26) /* TCP_KEEPINTVL only if SO_KEEPALIVE set */
#define SO_F_TCP_KEEPCNT	(((uint32_t)1) << 27) /* TCP_KEEPCNT only if SO_KEEPALIVE set */
#define SO_F_TCP_NODELAY	(((uint32_t)1) << 28) /* TCP_NODELAY */
#define SO_F_TCP_NOPUSH		(((uint32_t)1) << 29) /* TCP_NOPUSH / TCP_CORK */
#define SO_F_TCP_CONGESTION	(((uint32_t)1) << 30) /* TCP_CONGESTION */

#define SO_F_FAIL_ON_ERR	(((uint32_t)1) << 31) /* Return on first set error. */

#define SO_F_IP_MASK		(SO_F_IP_HOPLIM_U | SO_F_IP_HOPLIM_M |	\
				SO_F_IP_MULTICAST_LOOP)
#define SO_F_KEEPALIVE_MASK	(SO_F_KEEPALIVE | SO_F_TCP_KEEPIDLE |	\
				SO_F_TCP_KEEPINTVL | SO_F_TCP_KEEPCNT)

#define SO_F_BIT_VALS_MASK	(SO_F_CLOEXEC | SO_F_NONBLOCK | 	\
				SO_F_BROADCAST |			\
				SO_F_REUSEADDR | SO_F_REUSEPORT | 	\
				SO_F_KEEPALIVE | 			\
				SO_F_IP_MULTICAST_LOOP |		\
				SO_F_ACC_FILTER |			\
				SO_F_TCP_NODELAY | SO_F_TCP_NOPUSH)
#define SO_F_ALL_MASK		(0xffffffff & ~SO_F_FAIL_ON_ERR)

/* Apply masks. */
#define SO_F_RCV_MASK		(SO_F_RCVBUF | SO_F_RCVLOWAT | SO_F_RCVTIMEO)
#define SO_F_SND_MASK		(SO_F_SNDBUF | SO_F_SNDLOWAT | SO_F_SNDTIMEO)
/* AF = after bind */
#define SO_F_UDP_BIND_AF_MASK	(SO_F_RCV_MASK |			\
				SO_F_SND_MASK |				\
				SO_F_IP_HOPLIM_U |			\
				SO_F_IP_HOPLIM_M |			\
				SO_F_IP_MULTICAST_LOOP)
/* AF = after listen */
#define SO_F_TCP_LISTEN_AF_MASK	(SO_F_IP_HOPLIM_U |			\
				SO_F_ACC_FILTER |			\
				SO_F_KEEPALIVE_MASK)
/* ES = after connection. */
#define SO_F_TCP_ES_CONN_MASK	(SO_F_HALFCLOSE_RDWR |			\
				SO_F_KEEPALIVE_MASK |			\
				SO_F_RCV_MASK |				\
				SO_F_SND_MASK |				\
				SO_F_IP_HOPLIM_U |			\
				SO_F_TCP_NODELAY |			\
				SO_F_TCP_NOPUSH |			\
				SO_F_TCP_CONGESTION)


#ifdef SOCKET_XML_CONFIG
int	skt_opts_xml_load(const uint8_t *buf, const size_t buf_size,
	    const uint32_t mask, skt_opts_p opts);
#endif
void	skt_opts_init(const uint32_t mask, const uint32_t bit_vals,
	    skt_opts_p opts);
void	skt_opts_cvt(const int mult, skt_opts_p opts);
#define SKT_OPTS_MULT_NONE	0
#define SKT_OPTS_MULT_K		1
#define SKT_OPTS_MULT_M		2
#define SKT_OPTS_MULT_G		3

/* family = AF_UNSPEC - to try aplly IPv6 and then IPv4 proto level options. */
int	skt_opts_apply_ex(const uintptr_t skt, const uint32_t mask,
	    const skt_opts_p opts, const sa_family_t family,
	    uint32_t *err_mask);
int	skt_opts_apply(const uintptr_t skt, const uint32_t mask,
	    const uint32_t bit_vals, const sa_family_t family);
/* Set only SO_F_BIT_VALS_MASK. */

#define SKT_OPTS_GET_FLAGS_VALS(__opts, __fmask)			\
	    ((__fmask) & SO_F_BIT_VALS_MASK & (__opts)->mask & (__opts)->bit_vals)
#define SKT_OPTS_IS_FLAG_ACTIVE(__opts, __flag)				\
	    (0 != ((__flag) & (__opts)->mask & (__opts)->bit_vals))


#endif /* __SOCKET_OPTIONS_H__ */
