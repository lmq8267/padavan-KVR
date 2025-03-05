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
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <sys/stat.h>
#include <netdb.h>

#include <netinet/in.h>
#include <netinet/tcp.h>

#include <inttypes.h>
#include <unistd.h> /* close, write, sysconf */
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <stdio.h>  /* snprintf, fprintf */
#include <errno.h>

#include "utils/macro.h"
#include "al/os.h"
#include "utils/sys.h"
#include "net/socket_address.h"
#include "net/socket.h"
#include "net/socket_options.h"
#ifdef SOCKET_XML_CONFIG
#	include "utils/xml.h"
#	include "utils/buf_str.h"
#endif


#ifdef SOCKET_XML_CONFIG
int
skt_opts_xml_load(const uint8_t *buf, const size_t buf_size,
    const uint32_t mask, skt_opts_p opts) {
	const uint8_t *data;
	size_t data_size;
	uint32_t u32tm;

	if (NULL == buf || 0 == buf_size || NULL == opts)
		return (EINVAL);
	/* Read from config. */

	/* SO_F_CLOEXEC, SO_F_NONBLOCK: never read, app internal. */
	/* SO_F_HALFCLOSE_RD */
	if (0 != (SO_F_HALFCLOSE_RD & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fHalfClosedRcv", NULL)) {
			yn_set_flag32(data, data_size, SO_F_HALFCLOSE_RD, &opts->bit_vals);
			opts->mask |= SO_F_HALFCLOSE_RD;
		}
	}
	/* SO_F_HALFCLOSE_WR */
	if (0 != (SO_F_HALFCLOSE_WR & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fHalfClosedSnd", NULL)) {
			yn_set_flag32(data, data_size, SO_F_HALFCLOSE_WR, &opts->bit_vals);
			opts->mask |= SO_F_HALFCLOSE_WR;
		}
	}
	/* SO_F_BACKLOG */
	if (0 != (SO_F_BACKLOG & mask)) {
		if (0 == xml_get_val_int32_args(buf, buf_size, NULL,
		    &opts->backlog,
		    (const uint8_t*)"backlog", NULL)) {
			if (1 > opts->backlog) { /* Force apply system wide limit. */
				opts->backlog = INT_MAX;
			}
			opts->mask |= SO_F_BACKLOG;
		}
	}
	/* SO_F_BROADCAST: never read, app internal. */
	/* SO_F_REUSEADDR */
	if (0 != (SO_F_REUSEADDR & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fReuseAddr", NULL)) {
			yn_set_flag32(data, data_size, SO_F_REUSEADDR, &opts->bit_vals);
			opts->mask |= SO_F_REUSEADDR;
		}
	}
	/* SO_F_REUSEPORT */
	if (0 != (SO_F_REUSEPORT & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fReusePort", NULL)) {
			yn_set_flag32(data, data_size, SO_F_REUSEPORT, &opts->bit_vals);
			opts->mask |= SO_F_REUSEPORT;
		}
	}
	/* SO_F_KEEPALIVE */
	if (0 != (SO_F_KEEPALIVE & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fKeepAlive", NULL)) {
			yn_set_flag32(data, data_size, SO_F_KEEPALIVE, &opts->bit_vals);
			opts->mask |= SO_F_KEEPALIVE;
		}
		if (SKT_OPTS_IS_FLAG_ACTIVE(opts, SO_F_KEEPALIVE)) {
			/* SO_F_TCP_KEEPIDLE */
			if (0 != (SO_F_TCP_KEEPIDLE & mask)) {
				if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
				    &opts->tcp_keep_idle,
				    (const uint8_t*)"keepAliveIDLEtime", NULL)) {
					if (0 != opts->tcp_keep_idle) {
						opts->mask |= SO_F_TCP_KEEPIDLE;
					}
				}
			}
			/* SO_F_TCP_KEEPINTVL */
			if (0 != (SO_F_TCP_KEEPINTVL & mask)) {
				if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
				    &opts->tcp_keep_intvl,
				    (const uint8_t*)"keepAliveProbesInterval", NULL)) {
					if (0 != opts->tcp_keep_intvl) {
						opts->mask |= SO_F_TCP_KEEPINTVL;
					}
				}
			}
			/* SO_F_TCP_KEEPCNT */
			if (0 != (SO_F_TCP_KEEPCNT & mask)) {
				if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
				    &opts->tcp_keep_cnt,
				    (const uint8_t*)"keepAliveNumberOfProbes", NULL)) {
					if (0 != opts->tcp_keep_cnt) {
						opts->mask |= SO_F_TCP_KEEPCNT;
					}
				}
			}
		}
	} /* SO_F_KEEPALIVE */
	/* SO_F_RCVBUF */
	if (0 != (SO_F_RCVBUF & mask)) {
		if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &opts->rcv_buf,
		    (const uint8_t*)"rcvBuf", NULL)) {
			if (0 != opts->rcv_buf) {
				opts->mask |= SO_F_RCVBUF;
			}
		}
	}
	/* SO_F_RCVLOWAT */
	if (0 != (SO_F_RCVLOWAT & mask)) {
		if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &opts->rcv_lowat,
		    (const uint8_t*)"rcvLoWatermark", NULL)) {
			if (0 != opts->rcv_lowat) {
				opts->mask |= SO_F_RCVLOWAT;
			}
		}
	}
	/* SO_F_RCVTIMEO */
	if (0 != (SO_F_RCVTIMEO & mask)) {
		if (0 == xml_get_val_uint64_args(buf, buf_size, NULL,
		    &opts->rcv_timeout,
		    (const uint8_t*)"rcvTimeout", NULL)) {
			opts->mask |= SO_F_RCVTIMEO;
		}
	}
	/* SO_F_SNDBUF */
	if (0 != (SO_F_SNDBUF & mask)) {
		if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &opts->snd_buf,
		    (const uint8_t*)"sndBuf", NULL)) {
			if (0 != opts->snd_buf) {
				opts->mask |= SO_F_SNDBUF;
			}
		}
	}
	/* SO_F_SNDLOWAT */
	if (0 != (SO_F_SNDLOWAT & mask)) {
		if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &opts->snd_lowat,
		    (const uint8_t*)"sndLoWatermark", NULL)) {
			if (0 != opts->snd_buf) {
				opts->mask |= SO_F_SNDLOWAT;
			}
		}
	}
	/* SO_F_SNDTIMEO */
	if (0 != (SO_F_SNDTIMEO & mask)) {
		if (0 == xml_get_val_uint64_args(buf, buf_size, NULL,
		    &opts->snd_timeout,
		    (const uint8_t*)"sndTimeout", NULL)) {
			opts->mask |= SO_F_SNDTIMEO;
		}
	}

	/* SO_F_ACC_FILTER */
	if (0 != (SO_F_ACC_FILTER & mask)) {
#ifdef SO_ACCEPTFILTER
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"AcceptFilterName", NULL)) {
			if (0 != data_size &&
			    sizeof(opts->tcp_acc_filter.af_name) > data_size) {
				memset(&opts->tcp_acc_filter, 0x00,
				    sizeof(struct accept_filter_arg));
				memcpy(opts->tcp_acc_filter.af_name, data, data_size);
				opts->mask |= SO_F_ACC_FILTER;
			}
		}
#elif defined(TCP_DEFER_ACCEPT)
		if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &opts->tcp_acc_defer,
		    (const uint8_t*)"AcceptFilterDeferTime", NULL)) {
			if (0 != opts->tcp_acc_defer) {
				opts->mask |= SO_F_ACC_FILTER;
			}
		}
#endif
		/* accept flags */
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fAcceptFilter", NULL)) {
			yn_set_flag32(data, data_size, SO_F_ACC_FILTER, &opts->bit_vals);
		}
	}

	/* SO_F_IP_HOPLIM_U */
	if (0 != (SO_F_IP_HOPLIM_U & mask)) {
		if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &u32tm, (const uint8_t*)"hopLimitUnicast", NULL) ||
		    0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &u32tm, (const uint8_t*)"hopLimit", NULL)) {
			opts->hop_limit_u = (uint8_t)u32tm;
			opts->mask |= SO_F_IP_HOPLIM_U;
		}
	}
	/* SO_F_IP_HOPLIM_M */
	if (0 != (SO_F_IP_HOPLIM_M & mask)) {
		if (0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &u32tm, (const uint8_t*)"hopLimitMulticast", NULL) ||
		    0 == xml_get_val_uint32_args(buf, buf_size, NULL,
		    &u32tm, (const uint8_t*)"hopLimit", NULL)) {
			opts->hop_limit_m = (uint8_t)u32tm;
			opts->mask |= SO_F_IP_HOPLIM_M;
		}
	}
	/* SO_F_IP_MULTICAST_LOOP */
	if (0 != (SO_F_IP_MULTICAST_LOOP & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fMulticastLoop", NULL)) {
			yn_set_flag32(data, data_size, SO_F_IP_MULTICAST_LOOP, &opts->bit_vals);
			opts->mask |= SO_F_IP_MULTICAST_LOOP;
		}
	}

	/* SO_F_TCP_NODELAY */
	if (0 != (SO_F_TCP_NODELAY & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fTCPNoDelay", NULL)) {
			yn_set_flag32(data, data_size, SO_F_TCP_NODELAY, &opts->bit_vals);
			opts->mask |= SO_F_TCP_NODELAY;
		}
	}
	/* SO_F_TCP_NOPUSH */
	if (0 != (SO_F_TCP_NOPUSH & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"fTCPNoPush", NULL)) {
			yn_set_flag32(data, data_size, SO_F_TCP_NOPUSH, &opts->bit_vals);
			opts->mask |= SO_F_TCP_NOPUSH;
		}
	}
	/* SO_F_TCP_CONGESTION */
	if (0 != (SO_F_TCP_CONGESTION & mask)) {
		if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
		    &data, &data_size,
		    (const uint8_t*)"congestionControl", NULL)) {
			if (0 != data_size && TCP_CA_NAME_MAX > data_size) {
				memcpy(opts->tcp_cc, data, data_size);
				opts->tcp_cc[data_size] = 0;
				opts->tcp_cc_size = (socklen_t)data_size;
				opts->mask |= SO_F_TCP_CONGESTION;
			}
		}
	}

	return (0);
}
#endif /* SOCKET_XML_CONFIG */

void
skt_opts_init(const uint32_t mask, const uint32_t bit_vals,
    skt_opts_p opts) {

	if (NULL == opts)
		return;
	memset(opts, 0x00, sizeof(skt_opts_t));
	opts->mask = (SO_F_BIT_VALS_MASK & mask);
	opts->bit_vals = bit_vals;
	opts->backlog = INT_MAX;
}

void
skt_opts_cvt(const int mult, skt_opts_p opts) {
	uint32_t dtbl[4] = { 1, 1000, 1000000, 1000000000 };
	uint32_t btbl[4] = { 1, 1024, 1048576, 1073741824 };

	if (NULL == opts || 3 < mult)
		return;
	opts->rcv_buf		*= btbl[mult];
	opts->rcv_lowat		*= btbl[mult];
	opts->rcv_timeout	*= dtbl[mult];
	opts->snd_buf		*= btbl[mult];
	opts->snd_lowat		*= btbl[mult];
	opts->snd_timeout	*= dtbl[mult];
#if defined(TCP_DEFER_ACCEPT)
	//opts->tcp_acc_defer	*= dtbl[mult];
#endif
	//opts->tcp_keep_idle	*= dtbl[mult];
	//opts->tcp_keep_intvl	*= dtbl[mult];
	//opts->tcp_keep_cnt;
}

int
skt_opts_apply_ex(const uintptr_t skt, const uint32_t mask,
    const skt_opts_p opts, const sa_family_t family, uint32_t *err_mask) {
	int error = 0, ival;
	uint32_t _mask, error_mask = 0;
	sa_family_t sa_family = family;
	u_char ucvar;

	if ((uintptr_t)-1 == skt || NULL == opts)
		return (EINVAL);
	_mask = (mask & (opts->mask | SO_F_FAIL_ON_ERR));

	/* SO_F_CLOEXEC */
	if (0 != (SO_F_CLOEXEC & _mask)) {
		error = fd_set_cloexec(skt, (SO_F_CLOEXEC & opts->bit_vals));
		if (0 != error) {
			error_mask |= SO_F_CLOEXEC;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_NONBLOCK */
	if (0 != (SO_F_NONBLOCK & _mask)) {
		error = fd_set_nonblocking(skt, (SO_F_NONBLOCK & opts->bit_vals));
		if (0 != error) {
			error_mask |= SO_F_NONBLOCK;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_HALFCLOSE_RD */
	/* SO_F_HALFCLOSE_WR */
	if (0 != (SO_F_HALFCLOSE_RDWR & _mask)) {
		switch ((SO_F_HALFCLOSE_RDWR & _mask & opts->bit_vals)) {
		case SO_F_HALFCLOSE_RD:
			ival = shutdown((int)skt, SHUT_RD);
			break;
		case SO_F_HALFCLOSE_WR:
			ival = shutdown((int)skt, SHUT_WR);
			break;
		case SO_F_HALFCLOSE_RDWR:
			ival = shutdown((int)skt, SHUT_RDWR);
			break;
		default:
			ival = 0;
			break;
		}
		if (0 != ival) {
			error = errno;
			error_mask |= (SO_F_HALFCLOSE_RDWR & _mask & opts->bit_vals);
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_BACKLOG - not aplly here. */
	/* SO_F_BROADCAST */
	if (0 != (SO_F_BROADCAST & _mask)) {
		ival = ((SO_F_BROADCAST & opts->bit_vals) ? 1 : 0);
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_BROADCAST,
		    &ival, sizeof(ival))) {
			error = errno;
			error_mask |= SO_F_BROADCAST;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_REUSEADDR */
	if (0 != (SO_F_REUSEADDR & _mask)) {
		ival = ((SO_F_REUSEADDR & opts->bit_vals) ? 1 : 0);
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_REUSEADDR,
		    &ival, sizeof(ival))) {
			error = errno;
			error_mask |= SO_F_REUSEADDR;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_REUSEPORT */
#ifdef SO_REUSEPORT
	if (0 != (SO_F_REUSEPORT & _mask)) {
		ival = ((SO_F_REUSEPORT & opts->bit_vals) ? 1 : 0);
		if (0 != setsockopt((int)skt, SOL_SOCKET,
#ifdef SO_REUSEPORT_LB
		    SO_REUSEPORT_LB,
#else
		    SO_REUSEPORT,
#endif
		    &ival, sizeof(ival))) {
			error = errno;
			error_mask |= SO_F_REUSEPORT;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
#endif
	/* SO_F_KEEPALIVE */
	if (0 != (SO_F_KEEPALIVE & _mask)) {
		ival = ((SO_F_KEEPALIVE & opts->bit_vals) ? 1 : 0);
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_KEEPALIVE,
		    &ival, sizeof(ival))) {
			error = errno;
			error_mask |= SO_F_KEEPALIVE;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
		/* SO_F_TCP_KEEPIDLE */
		if (0 != (SO_F_TCP_KEEPIDLE & _mask) &&
		    0 != opts->tcp_keep_idle) {
#ifdef TCP_KEEPIDLE
			if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_KEEPIDLE,
			    &opts->tcp_keep_idle, sizeof(uint32_t))) {
#else
			if (0) {
#endif
				error = errno;
				error_mask |= SO_F_TCP_KEEPIDLE;
				if (0 != (SO_F_FAIL_ON_ERR & _mask))
					goto err_out;
			}
		}
		/* SO_F_TCP_KEEPINTVL */
		if (0 != (SO_F_TCP_KEEPINTVL & _mask) &&
		    0 != opts->tcp_keep_intvl) {
#ifdef TCP_KEEPINTVL
			if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_KEEPINTVL,
			    &opts->tcp_keep_intvl, sizeof(uint32_t))) {
#else
			if (0) {
#endif
				error = errno;
				error_mask |= SO_F_TCP_KEEPINTVL;
				if (0 != (SO_F_FAIL_ON_ERR & _mask))
					goto err_out;
			}
		}
		/* SO_F_TCP_KEEPCNT */
		if (0 != (SO_F_TCP_KEEPCNT & _mask) &&
		    0 != opts->tcp_keep_cnt) {
#ifdef TCP_KEEPCNT
			if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_KEEPCNT,
			    &opts->tcp_keep_cnt, sizeof(uint32_t))) {
#else
			if (0) {
#endif
				error = errno;
				error_mask |= SO_F_TCP_KEEPCNT;
				if (0 != (SO_F_FAIL_ON_ERR & _mask))
					goto err_out;
			}
		}
	} /* SO_F_KEEPALIVE */
	/* SO_F_RCVBUF */
	if (0 != (SO_F_RCVBUF & _mask) &&
	    0 != opts->rcv_buf) {
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_RCVBUF,
		    &opts->rcv_buf, sizeof(uint32_t))) {
			error = errno;
			error_mask |= SO_F_RCVBUF;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_RCVLOWAT */
	if (0 != (SO_F_RCVLOWAT & _mask) &&
	    0 != opts->rcv_lowat) {
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_RCVLOWAT,
		    &opts->rcv_lowat, sizeof(uint32_t))) {
			error = errno;
			error_mask |= SO_F_RCVLOWAT;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_RCVTIMEO - no set to skt */
	/* SO_F_SNDBUF */
	if (0 != (SO_F_SNDBUF & _mask) &&
	    0 != opts->snd_buf) {
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_SNDBUF,
		    &opts->snd_buf, sizeof(uint32_t))) {
			error = errno;
			error_mask |= SO_F_SNDBUF;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
#ifdef BSD /* Linux allways fail on set SO_SNDLOWAT. */
	/* SO_F_SNDLOWAT */
	if (0 != (SO_F_SNDLOWAT & _mask) &&
	    0 != opts->snd_lowat) {
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_SNDLOWAT,
		    &opts->snd_lowat, sizeof(uint32_t))) {
			error = errno;
			error_mask |= SO_F_SNDLOWAT;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
#endif /* BSD specific code. */
	/* SO_F_SNDTIMEO - no set to skt */

	/* Autodetect socket family if required. */
	if (0 != (SO_F_IP_MASK & _mask) && 0 == family) {
		skt_get_addr_family(skt, &sa_family);
	}
	/* Prefer IPv6 to not rewrite code in future. */
	/* SO_F_IP_HOPLIM_U */
	if (0 != (SO_F_IP_HOPLIM_U & _mask)) {
		ival = opts->hop_limit_u;
		for (;;) {
			/* Try aplly to IPv6. */
			if ((0 == sa_family || AF_INET6 == sa_family) &&
			    0 == setsockopt((int)skt, IPPROTO_IPV6, IPV6_UNICAST_HOPS,
			    &ival, sizeof(ival)))
				break;
			/* Try aplly to IPv4. */
			if ((0 == sa_family || AF_INET == sa_family) &&
			    0 == setsockopt((int)skt, IPPROTO_IP, IP_TTL,
			    &ival, sizeof(ival)))
				break;
			/* Fail. */
			error = errno;
			error_mask |= SO_F_IP_HOPLIM_U;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
			break;
		}
	}
	/* SO_F_IP_HOPLIM_M */
	if (0 != (SO_F_IP_HOPLIM_M & _mask)) {
		ival = opts->hop_limit_m;
		ucvar = (u_char)opts->hop_limit_m;
		for (;;) {
			/* Try aplly to IPv6. */
			if ((0 == sa_family || AF_INET6 == sa_family) &&
			    0 == setsockopt((int)skt, IPPROTO_IPV6, IPV6_MULTICAST_HOPS,
			    &ival, sizeof(ival)))
				break;
			/* Try aplly to IPv4. */
			if ((0 == sa_family || AF_INET == sa_family) &&
			    0 == setsockopt((int)skt, IPPROTO_IP, IP_MULTICAST_TTL,
			    &ucvar, sizeof(ucvar)))
				break;
			/* Fail. */
			error = errno;
			error_mask |= SO_F_IP_HOPLIM_M;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
			break;
		}
	}
	/* SO_F_IP_MULTICAST_LOOP */
	if (0 != (SO_F_IP_MULTICAST_LOOP & _mask)) {
		ival = ((SO_F_IP_MULTICAST_LOOP & opts->bit_vals) ? 1 : 0);
		ucvar = (u_char)ival;
		for (;;) {
			/* Try aplly to IPv6. */
			if ((0 == sa_family || AF_INET6 == sa_family) &&
			    0 == setsockopt((int)skt, IPPROTO_IPV6, IPV6_MULTICAST_LOOP,
			    &ival, sizeof(ival)))
				break;
			/* Try aplly to IPv4. */
			if ((0 == sa_family || AF_INET == sa_family) &&
			    0 == setsockopt((int)skt, IPPROTO_IP, IP_MULTICAST_LOOP,
			    &ucvar, sizeof(ucvar)))
				break;
			/* Fail. */
			error = errno;
			error_mask |= SO_F_IP_MULTICAST_LOOP;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
			break;
		}
	}

	/* SO_F_ACC_FILTER */
	if (0 != (SO_F_ACC_FILTER & _mask) &&
	    SKT_OPTS_IS_FLAG_ACTIVE(opts, SO_F_ACC_FILTER)) {
#ifdef SO_ACCEPTFILTER
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_ACCEPTFILTER,
		    &opts->tcp_acc_filter, sizeof(struct accept_filter_arg))) {
#elif defined(TCP_DEFER_ACCEPT)
		if (0 != opts->tcp_acc_defer &&
		    0 != setsockopt((int)skt, IPPROTO_TCP, TCP_DEFER_ACCEPT,
		    &opts->tcp_acc_defer, sizeof(uint32_t))) {
#else
		if (0) {
#endif
			error = errno;
			error_mask |= SO_F_ACC_FILTER;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_TCP_NODELAY */
	if (0 != (SO_F_TCP_NODELAY & _mask)) {
		ival = ((SO_F_TCP_NODELAY & opts->bit_vals) ? 1 : 0);
		if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_NODELAY,
		    &ival, sizeof(ival))) {
			error = errno;
			error_mask |= SO_F_TCP_NODELAY;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_TCP_NOPUSH */
	if (0 != (SO_F_TCP_NOPUSH & _mask)) {
		ival = ((SO_F_TCP_NOPUSH & opts->bit_vals) ? 1 : 0);
#ifdef TCP_NOPUSH
		if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_NOPUSH,
		    &ival, sizeof(ival))) {
#elif defined(TCP_CORK)
		if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_CORK,
		    &ival, sizeof(ival))) {
#else
		if (0) {
#endif
			error = errno;
			error_mask |= SO_F_TCP_NOPUSH;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}
	/* SO_F_TCP_CONGESTION */
	if (0 != (SO_F_TCP_CONGESTION & _mask) &&
	    0 != opts->tcp_cc_size) {
#ifdef TCP_CONGESTION
		if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_CONGESTION,
		    &opts->tcp_cc, opts->tcp_cc_size)) {
#else
		if (0) {
#endif
			error = errno;
			error_mask |= SO_F_TCP_CONGESTION;
			if (0 != (SO_F_FAIL_ON_ERR & _mask))
				goto err_out;
		}
	}

	return (0);

err_out:
	if (NULL != err_mask) {
		(*err_mask) = error_mask;
	}

	return (error);
}

int
skt_opts_apply(const uintptr_t skt, const uint32_t mask,
    const uint32_t bit_vals, const sa_family_t family) {
	skt_opts_t opts;

	opts.mask = (SO_F_BIT_VALS_MASK & mask);
	opts.bit_vals = bit_vals;
	
	return (skt_opts_apply_ex(skt, mask, &opts, family, NULL));
}
