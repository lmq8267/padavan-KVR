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

#if defined(__APPLE__) && !defined(__APPLE_USE_RFC_3542)
#	define __APPLE_USE_RFC_3542	1 /* IPV6_PKTINFO */
#endif

#include <sys/param.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/ioctl.h>
#include <net/if.h>
#include <sys/stat.h>
#include <netdb.h>

#ifdef BSD /* BSD specific code. */
#	include <sys/uio.h> /* sendfile */
#	include <net/if_dl.h>
#endif /* BSD specific code. */

#ifdef __linux__ /* Linux specific code. */
#	include <sys/sendfile.h>
//	#include <linux/ipv6.h>
#endif /* Linux specific code. */

#include <netinet/in.h>
#include <netinet/tcp.h>

#include <inttypes.h>
#include <unistd.h> /* close, write, sysconf */
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <stdio.h>  /* snprintf, fprintf */
#include <errno.h>

#include "utils/macro.h"
#include "utils/num2str.h"

#include "al/os.h"
#include "net/socket_address.h"
#include "net/socket.h"


int
skt_rcv_tune(uintptr_t skt, uint32_t buf_size, uint32_t lowat) {

	if (0 == lowat) { /* LOWAT can not be 0. */
		lowat = 1;
	}
	if (0 != setsockopt((int)skt, SOL_SOCKET, SO_RCVBUF, &buf_size, sizeof(uint32_t)))
		return (errno);
	if (0 != setsockopt((int)skt, SOL_SOCKET, SO_RCVLOWAT, &lowat, sizeof(uint32_t)))
		return (errno);

	return (0);
}

int
skt_snd_tune(uintptr_t skt, uint32_t buf_size, uint32_t lowat) {

	if (0 != setsockopt((int)skt, SOL_SOCKET, SO_SNDBUF, &buf_size, sizeof(uint32_t)))
		return (errno);
#ifdef BSD /* Linux allways fail on set SO_SNDLOWAT. */
	if (0 == lowat) { /* LOWAT can not be 0. */
		lowat = 1;
	}
	if (0 != setsockopt((int)skt, SOL_SOCKET, SO_SNDLOWAT, &lowat, sizeof(uint32_t)))
		return (errno);
#endif /* BSD specific code. */

	return (0);
}

/* Set congestion control algorithm for socket. */
int
skt_set_tcp_cc(uintptr_t skt, const char *cc, size_t cc_size) {

	if (NULL == cc || 0 == cc_size || TCP_CA_NAME_MAX <= cc_size)
		return (EINVAL);

#ifdef TCP_CONGESTION
	if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_CONGESTION,
	    cc, (socklen_t)cc_size))
		return (errno);

	return (0);
#else
	return (ENOSYS);
#endif
}

int
skt_get_tcp_cc(uintptr_t skt, char *cc, size_t cc_size, size_t *cc_size_ret) {
#ifdef TCP_CONGESTION
	socklen_t optlen;
#endif

	if (NULL == cc || 0 == cc_size)
		return (EINVAL);

#ifdef TCP_CONGESTION
	optlen = (socklen_t)cc_size;
	if (0 != getsockopt((int)skt, IPPROTO_TCP, TCP_CONGESTION,
	    cc, &optlen))
		return (errno);
	if (NULL != cc_size_ret) {
		(*cc_size_ret) = optlen;
	}

	return (0);
#else
	return (ENOSYS);
#endif
}

/* Check is congestion control algorithm available. */
int
skt_is_tcp_cc_avail(const char *cc, size_t cc_size) {
#ifdef TCP_CONGESTION
	int skt, res = 0;
#endif

	if (NULL == cc || 0 == cc_size || TCP_CA_NAME_MAX <= cc_size)
		return (0);

#ifdef TCP_CONGESTION
	skt = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (-1 == skt) {
		skt = socket(AF_INET6, SOCK_STREAM, IPPROTO_TCP); /* Re try with IPv6 socket. */
	}
	if (-1 == skt)
		return (0);
	res = (0 == setsockopt(skt, IPPROTO_TCP, TCP_CONGESTION,
	    cc, (socklen_t)cc_size));
	close(skt);

	return (res);
#else
	return (ENOSYS);
#endif
}

int
skt_get_tcp_maxseg(uintptr_t skt, int *val_ret) {
	socklen_t optlen;

	if (NULL == val_ret)
		return (EINVAL);

	optlen = sizeof(int);
	if (0 != getsockopt((int)skt, IPPROTO_TCP, TCP_MAXSEG, val_ret, &optlen))
		return (errno);

	return (0);
}

int
skt_get_addr_family(uintptr_t skt, sa_family_t *family) {
	socklen_t addrlen;
	sockaddr_storage_t ssaddr;

	if (NULL == family)
		return (EINVAL);

	memset(&ssaddr, 0x00, sizeof(ssaddr));
	addrlen = sizeof(ssaddr);
	if (0 != getsockname((int)skt, (sockaddr_p)&ssaddr, &addrlen))
		return (errno);
	(*family) = ssaddr.ss_family;

	return (0);
}

int
skt_set_tcp_nodelay(uintptr_t skt, int val) {

	if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_NODELAY, &val, sizeof(val)))
		return (errno);

	return (0);
}

int
skt_set_tcp_nopush(uintptr_t skt, int val) {

#ifdef TCP_NOPUSH
	if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_NOPUSH, &val, sizeof(val)))
		return (errno);
#endif
#ifdef TCP_CORK
	if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_CORK, &val, sizeof(val)))
		return (errno);
#endif
	return (0);
}

int
skt_set_accept_filter(uintptr_t skt, const char *accf, size_t accf_size) {
#ifdef SO_ACCEPTFILTER
	struct accept_filter_arg afa;
#endif
#ifdef TCP_DEFER_ACCEPT
	int ival = (int)accf_size;
#endif

	if (NULL == accf || 0 == accf_size)
		return (EINVAL);

#ifdef SO_ACCEPTFILTER
	accf_size = ((sizeof(afa.af_name) - 1) > accf_size) ?
	    accf_size : (sizeof(afa.af_name) - 1);
	memcpy(afa.af_name, accf, accf_size);
	afa.af_name[accf_size] = 0;
	afa.af_arg[0] = 0;
	if (0 != setsockopt((int)skt, SOL_SOCKET, SO_ACCEPTFILTER, &afa, sizeof(afa)))
		return (errno);
#endif
#ifdef TCP_DEFER_ACCEPT
	if (0 != setsockopt((int)skt, IPPROTO_TCP, TCP_DEFER_ACCEPT, &ival, sizeof(int)))
		return (errno);
#endif
	return (0);
}


int
skt_mc_join(uintptr_t skt, int join, uint32_t if_index,
    const sockaddr_storage_t *mc_addr) {
	struct group_req mc_group;

	if (NULL == mc_addr)
		return (EINVAL);
	if (AF_INET != mc_addr->ss_family && AF_INET6 != mc_addr->ss_family)
		return (EAFNOSUPPORT);

	/* Join/leave to multicast group. */
	memset(&mc_group, 0x00, sizeof(mc_group));
	mc_group.gr_interface = if_index;
	sa_copy(mc_addr, &mc_group.gr_group);
	if (0 != setsockopt((int)skt,
	    ((AF_INET == mc_addr->ss_family) ? IPPROTO_IP : IPPROTO_IPV6),
	    ((0 != join) ? MCAST_JOIN_GROUP : MCAST_LEAVE_GROUP),
	    &mc_group, sizeof(mc_group)))
		return (errno);

	return (0);
}

int
skt_mc_join_ifname(uintptr_t skt, int join, const char *ifname,
    size_t ifname_size, const sockaddr_storage_t *mc_addr) {
	unsigned int ifindex;
#ifdef SIOCGIFINDEX
	struct ifreq ifr;
#endif

	if (NULL == ifname || IFNAMSIZ <= ifname_size)
		return (EINVAL);
	/* if_nametoindex(ifname), but faster - we already have a socket. */
	if (0 == ifname_size) {
		ifname_size = strnlen(ifname, (IFNAMSIZ - 1));
	}

#ifdef SIOCGIFINDEX
	memset(&ifr, 0x00, sizeof(ifr));
	memcpy(ifr.ifr_name, ifname, ifname_size);
	ifr.ifr_name[ifname_size] = 0;
	if (-1 == ioctl((int)skt, SIOCGIFINDEX, &ifr))
		return (errno); /* Cant get if index */
	ifindex = (unsigned int)ifr.ifr_ifindex;
#else
	char ifname_buf[IFNAMSIZ];

	memcpy(ifname_buf, ifname, ifname_size);
	ifname_buf[ifname_size] = 0;

	ifindex = if_nametoindex(ifname_buf);
	if (0 == ifindex)
		return (errno);
#endif

	return (skt_mc_join(skt, join, (uint32_t)ifindex, mc_addr));
}

int
skt_enable_recv_ifindex(uintptr_t skt, int enable) {
	int error;
	sa_family_t sa_family;

	/* First, we detect socket address family: ipv4 or ipv6. */
	error = skt_get_addr_family(skt, &sa_family);
	if (0 != error)
		return (error);

	switch (sa_family) {
	case AF_INET:
#if (defined(IP_RECVIF) || defined(IP_PKTINFO))
		if (
#	ifdef IP_RECVIF /* FreeBSD */
		    0 != setsockopt((int)skt, IPPROTO_IP, IP_RECVIF, &enable, sizeof(int))
#	endif
#	if (defined(IP_RECVIF) && defined(IP_PKTINFO))
		    &&
#	endif
#	ifdef IP_PKTINFO /* Linux/win */
		    0 != setsockopt((int)skt, IPPROTO_IP, IP_PKTINFO, &enable, sizeof(int))
#	endif
		)
			return (errno);
		break;
#else
		return (ENOTSUP);
#endif
	case AF_INET6:
#if (defined(IPV6_RECVPKTINFO) || defined(IPV6_PKTINFO) || defined(IPV6_2292PKTINFO))
		if (
#	ifdef IPV6_RECVPKTINFO /* Not exist in old versions. */
		    0 != setsockopt((int)skt, IPPROTO_IPV6, IPV6_RECVPKTINFO, &enable, sizeof(int))
#	else /* old adv. API */
		    0 != setsockopt((int)skt, IPPROTO_IPV6, IPV6_PKTINFO, &enable, sizeof(int))
#	endif
#	ifdef IPV6_2292PKTINFO /* "backup", avail in linux. */
		    && 0 != setsockopt((int)skt, IPPROTO_IPV6, IPV6_2292PKTINFO, &enable, sizeof(int))
#	endif
		)
			return (errno);
		break;
#else
		return (ENOTSUP);
#endif
	default:
		return (EAFNOSUPPORT);
	}

	return (0);
}



int
skt_create(int domain, int type, int protocol, uint32_t flags,
    uintptr_t *skt_ret) {
	uintptr_t skt;
	int error, on = 1;

	if (NULL == skt_ret)
		return (EINVAL);

#ifdef HAVE_SOCK_CLOEXEC
	if (0 != (SO_F_CLOEXEC & flags)) {
		type |= SOCK_CLOEXEC;
	} else {
		type &= ~SOCK_CLOEXEC;
	}
#endif
#ifdef HAVE_SOCK_NONBLOCK
	if (0 != (SO_F_NONBLOCK & flags)) {
		type |= SOCK_NONBLOCK;
	} else {
		type &= ~SOCK_NONBLOCK;
	}
#endif

	skt = (uintptr_t)socket(domain, type, protocol);
	if ((uintptr_t)-1 == skt)
		goto err_out;

#ifndef HAVE_SOCK_CLOEXEC
	if (0 != (SO_F_CLOEXEC & flags)) {
		/* For old BSD and linux only FD_CLOEXEC was defined for 
		 * F_SETFD, no additional code required. */
		if (-1 == fcntl((int)skt, F_SETFD, FD_CLOEXEC))
			goto err_out;
	}
#endif
#ifndef HAVE_SOCK_NONBLOCK
	if (0 != (SO_F_NONBLOCK & flags)) {
		/* Old BSD and linux have no other meaning flags for sockets,
		 * no additional code required. */
		if (-1 == fcntl((int)skt, F_SETFL, O_NONBLOCK))
			goto err_out;
	}
#endif

	/* Tune socket. */
	if (0 != (SO_F_BROADCAST & flags)) {
		if (0 != setsockopt((int)skt, SOL_SOCKET, SO_BROADCAST,
		    &on, sizeof(int)))
			goto err_out;
	}
#ifdef SO_NOSIGPIPE
	setsockopt((int)skt, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof(int));
#endif
	if (AF_INET6 == domain) { /* Disable IPv4 via IPv6 socket. */
		setsockopt((int)skt, IPPROTO_IPV6, IPV6_V6ONLY, &on, sizeof(int));
	}

	(*skt_ret) = skt;

	return (0);

err_out:
	/* Error. */
	error = errno;
	close((int)skt);
	(*skt_ret) = (uintptr_t)-1;

	return (error);
}

int
skt_accept(uintptr_t skt, sockaddr_storage_t *addr, socklen_t *addrlen,
    uint32_t flags, uintptr_t *skt_ret) {
	uintptr_t s;
#ifdef SO_NOSIGPIPE
	int on = 1;
#endif

	if (NULL == skt_ret)
		return (EINVAL);
	s = (uintptr_t)accept4((int)skt, (sockaddr_p)addr, addrlen,
	    (((0 != (SO_F_CLOEXEC & flags)) ? SOCK_CLOEXEC : 0) |
	     ((0 != (SO_F_NONBLOCK & flags)) ? SOCK_NONBLOCK : 0)));
	if ((uintptr_t)-1 == s)
		return (errno);
#ifdef SO_NOSIGPIPE
	setsockopt((int)s, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof(int));
#endif
	(*skt_ret) = s;

	return (0);
}

int
skt_bind(const sockaddr_storage_t *addr, int type, int protocol,
    uint32_t flags, uintptr_t *skt_ret) {
	uintptr_t skt;
	int error, on = 1;
	struct stat sb;

	if (NULL == addr || NULL == skt_ret)
		return (EINVAL);

	/* Make reusable for AF_UNIX: we can do it before socket create. */
	if (0 != (SO_F_REUSEADDR & flags) && AF_UNIX == addr->ss_family) {
		if (0 == stat(((const sockaddr_un_t*)addr)->sun_path, &sb)) {
			if (0 == S_ISSOCK(sb.st_mode)) /* Not socket, do not remove. */
				return (EADDRINUSE);
			if (0 != unlink(((const sockaddr_un_t*)addr)->sun_path))
				return (errno);
		}
	}

	error = skt_create(addr->ss_family, type, protocol, flags, &skt);
	if (0 != error)
		goto err_out;

	/* Make reusable: we can fail here, but bind() may success. */
	if (0 != (SO_F_REUSEADDR & flags)) {
		switch (addr->ss_family) {
		case AF_INET:
		case AF_INET6:
			setsockopt((int)skt, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(int));
			break;
		}
	}
#if defined(SO_REUSEPORT) || defined(SO_REUSEPORT_LB)
	if (0 != (SO_F_REUSEPORT & flags)) {
		setsockopt((int)skt, SOL_SOCKET,
#ifdef SO_REUSEPORT_LB
		    SO_REUSEPORT_LB,
#else
		    SO_REUSEPORT,
#endif
		    &on, sizeof(int));
	}
#endif
	if (-1 == bind((int)skt, (const sockaddr_t*)addr, sa_size(addr))) { /* Error. */
		error = errno;
		close((int)skt);
		skt = (uintptr_t)-1;
	}

err_out: /* Error. */
	(*skt_ret) = skt;

	return (error);
}

int
skt_bind_ap(const sa_family_t family, void *addr, uint16_t port,
    int type, int protocol, uint32_t flags, uintptr_t *skt_ret) {
	int error;
	sockaddr_storage_t sa;

	error = sa_init(&sa, family, addr, port);
	if (0 != error)
		return (error);

	return (skt_bind(&sa, type, protocol, flags, skt_ret));
}

ssize_t
skt_recvfrom(uintptr_t skt, void *buf, size_t buf_size, int flags,
    sockaddr_storage_t *from, uint32_t *if_index) {
	ssize_t transfered_size;
	struct msghdr mhdr;
	struct iovec rcviov[4];
	struct cmsghdr *cm;
	uint8_t rcvcmsgbuf[1024 +
#if defined(IP_RECVIF) /* FreeBSD */
		CMSG_SPACE(sizeof(struct sockaddr_dl)) +
#endif
#if defined(IP_PKTINFO) /* Linux/win */
		CMSG_SPACE(sizeof(struct in_pktinfo)) +
#endif
		CMSG_SPACE(sizeof(struct in6_pktinfo))
	];

	/* Initialize msghdr for receiving packets. */
	//memset(&rcvcmsgbuf, 0x00, sizeof(struct cmsghdr));
	rcviov[0].iov_base = buf;
	rcviov[0].iov_len = buf_size;
	mhdr.msg_name = from; /* dst addr. */
	mhdr.msg_namelen = ((NULL == from) ? 0 : sizeof(sockaddr_storage_t));
	mhdr.msg_iov = rcviov;
	mhdr.msg_iovlen = 1;
	mhdr.msg_control = rcvcmsgbuf;
	mhdr.msg_controllen = sizeof(rcvcmsgbuf);
	mhdr.msg_flags = 0;

	transfered_size = recvmsg((int)skt, &mhdr, flags);
	if (-1 == transfered_size || NULL == if_index)
		return (transfered_size);
	(*if_index) = 0;
	/* Handle additional IP packet data. */
	for (cm = CMSG_FIRSTHDR(&mhdr); NULL != cm; cm = CMSG_NXTHDR(&mhdr, cm)) {
#ifdef IP_RECVIF /* FreeBSD */
		if (IPPROTO_IP == cm->cmsg_level &&
		    IP_RECVIF == cm->cmsg_type &&
		    CMSG_LEN(sizeof(struct sockaddr_dl)) <= cm->cmsg_len) {
			MEMCPY_STRUCT_FIELD(if_index, CMSG_DATA(cm),
			    struct sockaddr_dl, sdl_index);
			break;
		}
#endif
#ifdef IP_PKTINFO /* Linux/win */
		if (IPPROTO_IP == cm->cmsg_level &&
		    IP_PKTINFO == cm->cmsg_type &&
		    CMSG_LEN(sizeof(struct in_pktinfo)) <= cm->cmsg_len) {
			MEMCPY_STRUCT_FIELD(if_index, CMSG_DATA(cm),
			    struct in_pktinfo, ipi_ifindex);
			break;
		}
#endif
		if (IPPROTO_IPV6 == cm->cmsg_level && (
#ifdef IPV6_2292PKTINFO
		    IPV6_2292PKTINFO == cm->cmsg_type ||
#endif
		    IPV6_PKTINFO == cm->cmsg_type) &&
		    CMSG_LEN(sizeof(struct in6_pktinfo)) <= cm->cmsg_len) {
			MEMCPY_STRUCT_FIELD(if_index, CMSG_DATA(cm),
			    struct in6_pktinfo, ipi6_ifindex);
			break;
		}
	}

	return (transfered_size);
}


int
skt_sendfile(uintptr_t fd, uintptr_t skt, off_t offset, size_t size, int flags,
    off_t *transfered_size) {
	int error = 0;

	/* This is for Linux behavour: zero size - do nothing.
	 * Under Linux save 1 syscall. */
	if (0 == size)
		goto err_out;

#ifdef BSD /* BSD specific code. */
#ifdef DARWIN
	off_t tr_size = (off_t)size;
	if (0 == sendfile((int)fd, (int)skt, offset, &tr_size, NULL, flags)) { /* OK. */
		if (NULL != transfered_size) {
			(*transfered_size) = tr_size;
		}
		return (0);
	}
#else
	if (0 == sendfile((int)fd, (int)skt, offset, size, NULL, transfered_size, flags))
		return (0); /* OK. */
#endif
	/* Error, but some data possible transfered. */
	/* transfered_size - is set by sendfile() */
	return (errno);
#endif /* BSD specific code. */
#ifdef __linux__ /* Linux specific code. */
	ssize_t ios = sendfile((int)skt, (int)fd, &offset, size);
	if (-1 != ios) { /* OK. */
		if (NULL != transfered_size) {
			(*transfered_size) = (off_t)ios;
		}
		return (0);
	}
	/* Error. */
	error = errno;
#endif /* Linux specific code. */

err_out:
	if (NULL != transfered_size) {
		(*transfered_size) = 0;
	}

	return (error);
}


int
skt_listen(uintptr_t skt, int backlog) {

	if (1 > backlog) { /* Force apply system wide limit. */
		backlog = INT_MAX;
	}
	if (-1 == listen((int)skt, backlog))
		return (errno);

	return (0);
}

int
skt_connect(const sockaddr_storage_t *addr, int type, int protocol,
    uint32_t flags, uintptr_t *skt_ret) {
	uintptr_t skt;
	int error;

	if (NULL == addr || NULL == skt_ret)
		return (EINVAL);

	error = skt_create(addr->ss_family, type, protocol, flags, &skt);
	if (0 != error)
		goto err_out;
	if (-1 == connect((int)skt, (const sockaddr_t*)addr, sa_size(addr))) {
		error = errno;
		if (EINPROGRESS != error && EINTR != error) { /* Error. */
			close((int)skt);
			skt = (uintptr_t)-1;
			goto err_out;
		}
		error = 0;
	}

err_out: /* Error. */
	(*skt_ret) = skt;

	return (error);
}

int
skt_is_connect_error(int error) {

	switch (error) {
#ifdef BSD /* BSD specific code. */
	case EADDRNOTAVAIL:
	case ECONNRESET:
	case EHOSTUNREACH:
#endif /* BSD specific code. */
	case EADDRINUSE:
	case ETIMEDOUT:
	case ENETUNREACH:
	case EALREADY:
	case ECONNREFUSED:
	case EISCONN:
		return (1);
	}

	return (0);
}


/*
 * Very simple resolver
 * work slow, block thread, has no cache
 * ai_family: PF_UNSPEC, AF_INET, AF_INET6
 */
int
skt_sync_resolv(const char *hname, uint16_t port, int ai_family,
    sockaddr_storage_t *addrs, size_t addrs_count, size_t *addrs_count_ret) {
	int error;
	size_t i;
	struct addrinfo hints, *res, *res0;
	char servname[8];

	if (NULL == hname)
		return (EINVAL);

	memset(&hints, 0x00, sizeof(hints));
	hints.ai_family = ai_family;
	hints.ai_flags = AI_NUMERICSERV;
	u162str(port, servname, sizeof(servname), NULL); /* Should not fail. */
	error = getaddrinfo(hname, servname, &hints, &res0);
	if (0 != error)  /* NOTREACHED */
		return (error);
	for (i = 0, res = res0; NULL != res && i < addrs_count; res = res->ai_next, i ++) {
		if (AF_INET != res->ai_family &&
		    AF_INET6 != res->ai_family)
			continue;
		sa_copy(res->ai_addr, &addrs[i]);
	}
	freeaddrinfo(res0);
	if (NULL != addrs_count_ret) {
		(*addrs_count_ret) = i;
	}

	return (0);
}

int
skt_sync_resolv_connect(const char *hname, uint16_t port,
    int domain, int type, int protocol, uintptr_t *skt_ret) {
	int error = 0;
	uintptr_t skt = (uintptr_t)-1;
	struct addrinfo hints, *res, *res0;
	char servname[8];

	if (NULL == hname || NULL == skt_ret)
		return (EINVAL);

	memset(&hints, 0x00, sizeof(hints));
	hints.ai_family = domain;
	hints.ai_flags = AI_NUMERICSERV;
	hints.ai_socktype = type;
	hints.ai_protocol = protocol;
	u162str(port, servname, sizeof(servname), NULL); /* Should not fail. */
	error = getaddrinfo(hname, servname, &hints, &res0);
	if (0 != error)  /* NOTREACHED */
		goto err_out;
	for (res = res0; NULL != res; res = res->ai_next) {
		error = skt_connect((sockaddr_storage_p)(void*)res->ai_addr,
		    res->ai_socktype, res->ai_protocol, 0, &skt);
		if (0 == error)
			break; /* okay we got one */
	}
	freeaddrinfo(res0);
	if ((uintptr_t)-1 != skt) {
		(*skt_ret) = skt;
		return (0);
	}

err_out: /* Error. */
	close((int)skt);
	(*skt_ret) = (uintptr_t)-1;

	return (error);
}


int
skt_tcp_stat_text(uintptr_t skt, const char *tabs,
    char *buf, size_t buf_size, size_t *buf_size_ret) {
#ifdef TCP_INFO
	int rc = 0;
	socklen_t optlen;
	struct tcp_info info;
	char topts[128];
	size_t i, topts_used = 0;
	const uint8_t tcpi_options_flags[] = {
		TCPI_OPT_TIMESTAMPS,
		TCPI_OPT_SACK,
		TCPI_OPT_WSCALE,
		TCPI_OPT_ECN,
#ifdef BSD
		TCPI_OPT_TOE,
#endif
	};
	const char *tcpi_options_flags_str[] = {
		"TIMESTAMPS",
		"SACK",
		"WSCALE",
		"ECN",
#ifdef BSD
		"TOE"
#endif
	};
#ifdef BSD /* BSD specific code. */
	const char *tcpi_state[] = {
		"CLOSED",
		"LISTEN",
		"SYN_SENT",
		"SYN_RECEIVED",
		"ESTABLISHED",
		"CLOSE_WAIT",
		"FIN_WAIT_1",
		"CLOSING",
		"LAST_ACK",
		"FIN_WAIT_2",
		"TIME_WAIT",
		"UNKNOWN"
	};
#endif
#ifdef __linux__ /* Linux specific code. */
	const char *tcpi_state[] = {
		"ESTABLISHED",
		"SYN_SENT",
		"SYN_RECEIVED",
		"FIN_WAIT_1",
		"FIN_WAIT_2",
		"TIME_WAIT",
		"CLOSED",
		"CLOSE_WAIT",
		"LAST_ACK",
		"LISTEN",
		"CLOSING",
		"UNKNOWN"
	};
#endif

	if (NULL == buf || NULL == buf_size_ret)
		return (EINVAL);

	optlen = sizeof(info);
	memset(&info, 0x00, sizeof(info));
	if (0 != getsockopt((int)skt, IPPROTO_TCP, TCP_INFO, &info, &optlen)) {
		(*buf_size_ret) = 0;
		return (errno);
	}
	if (10 < info.tcpi_state) {
		info.tcpi_state = 11; /* UNKNOWN */
	}

	/* Generate string with TCP options flags. */
	for (i = 0; i < nitems(tcpi_options_flags); i ++) {
		if (0 == (info.tcpi_options & tcpi_options_flags[i]))
			continue;
		topts_used += strlcpy((topts + topts_used),
		    tcpi_options_flags_str[i], (sizeof(topts) - topts_used));
		if ((sizeof(topts) - 2) < topts_used) {
			(*buf_size_ret) = topts_used;
			return (ENOSPC);
		}
		topts[topts_used ++] = ' ';
	}
	/* Remove trailing space and make sure that 0x00 at the end of string. */
	if (0 != topts_used) {
		topts_used --;
	}
	topts[topts_used] = 0x00;

#ifdef BSD /* BSD specific code. */
	rc = snprintf(buf, buf_size,
	    "%sTCP FSM state: %s\r\n"
	    "%sOptions enabled on conn: %s\r\n"
	    "%sRFC1323 send shift value: %"PRIu8"\r\n"
	    "%sRFC1323 recv shift value: %"PRIu8"\r\n"
	    "%sRetransmission timeout (usec): %"PRIu32"\r\n"
	    "%sMax segment size for send: %"PRIu32"\r\n"
	    "%sMax segment size for receive: %"PRIu32"\r\n"
	    "%sTime since last recv data (usec): %"PRIu32"\r\n"
	    "%sSmoothed RTT in usecs: %"PRIu32"\r\n"
	    "%sRTT variance in usecs: %"PRIu32"\r\n"
	    "%sSlow start threshold: %"PRIu32"\r\n"
	    "%sSend congestion window: %"PRIu32"\r\n"
	    "%sAdvertised recv window: %"PRIu32"\r\n"
	    "%sAdvertised send window: %"PRIu32"\r\n"
	    "%sNext egress seqno: %"PRIu32"\r\n"
	    "%sNext ingress seqno: %"PRIu32"\r\n"
	    "%sHWTID for TOE endpoints: %"PRIu32"\r\n"
	    "%sRetransmitted packets: %"PRIu32"\r\n"
	    "%sOut-of-order packets: %"PRIu32"\r\n"
	    "%sZero-sized windows sent: %"PRIu32"\r\n",
	    tabs, tcpi_state[info.tcpi_state], tabs, topts,
	    tabs, info.tcpi_snd_wscale, tabs, info.tcpi_rcv_wscale,
	    tabs, info.tcpi_rto, tabs, info.tcpi_snd_mss, tabs, info.tcpi_rcv_mss,
	    tabs, info.tcpi_last_data_recv,
	    tabs, info.tcpi_rtt, tabs, info.tcpi_rttvar,
	    tabs, info.tcpi_snd_ssthresh, tabs, info.tcpi_snd_cwnd, 
	    tabs, info.tcpi_rcv_space,
	    tabs, info.tcpi_snd_wnd,
	    tabs, info.tcpi_snd_nxt, tabs, info.tcpi_rcv_nxt,
	    tabs, info.tcpi_toe_tid, tabs, info.tcpi_snd_rexmitpack,
	    tabs, info.tcpi_rcv_ooopack, tabs, info.tcpi_snd_zerowin);
#endif /* BSD specific code. */
#ifdef __linux__ /* Linux specific code. */
	rc = snprintf(buf, buf_size,
	    "%sTCP FSM state: %s\r\n"
	    "%sca_state: %"PRIu8"\r\n"
	    "%sretransmits: %"PRIu8"\r\n"
	    "%sprobes: %"PRIu8"\r\n"
	    "%sbackoff: %"PRIu8"\r\n"
	    "%sOptions enabled on conn: %s\r\n"
	    "%sRFC1323 send shift value: %"PRIu8"\r\n"
	    "%sRFC1323 recv shift value: %"PRIu8"\r\n"
	    "%sRetransmission timeout (usec): %"PRIu32"\r\n"
	    "%sato (usec): %"PRIu32"\r\n"
	    "%sMax segment size for send: %"PRIu32"\r\n"
	    "%sMax segment size for receive: %"PRIu32"\r\n"
	    "%sunacked: %"PRIu32"\r\n"
	    "%ssacked: %"PRIu32"\r\n"
	    "%slost: %"PRIu32"\r\n"
	    "%sretrans: %"PRIu32"\r\n"
	    "%sfackets: %"PRIu32"\r\n"
	    "%slast_data_sent: %"PRIu32"\r\n"
	    "%slast_ack_sent: %"PRIu32"\r\n"
	    "%sTime since last recv data (usec): %"PRIu32"\r\n"
	    "%slast_ack_recv: %"PRIu32"\r\n"
	    "%spmtu: %"PRIu32"\r\n"
	    "%srcv_ssthresh: %"PRIu32"\r\n"
	    "%srtt: %"PRIu32"\r\n"
	    "%srttvar: %"PRIu32"\r\n"
	    "%ssnd_ssthresh: %"PRIu32"\r\n"
	    "%ssnd_cwnd: %"PRIu32"\r\n"
	    "%sadvmss: %"PRIu32"\r\n"
	    "%sreordering: %"PRIu32"\r\n"
	    "%srcv_rtt: %"PRIu32"\r\n"
	    "%srcv_space: %"PRIu32"\r\n"
	    "%stotal_retrans: %"PRIu32"\r\n",
	    tabs, tcpi_state[info.tcpi_state], tabs, info.tcpi_ca_state,
	    tabs, info.tcpi_retransmits, tabs, info.tcpi_probes,
	    tabs, info.tcpi_backoff, tabs, topts,
	    tabs, info.tcpi_snd_wscale, tabs, info.tcpi_rcv_wscale,
	    tabs, info.tcpi_rto, tabs, info.tcpi_ato,
	    tabs, info.tcpi_snd_mss, tabs, info.tcpi_rcv_mss,
	    tabs, info.tcpi_unacked, tabs, info.tcpi_sacked,
	    tabs, info.tcpi_lost, tabs, info.tcpi_retrans,
	    tabs, info.tcpi_fackets, tabs, info.tcpi_last_data_sent,
	    tabs, info.tcpi_last_ack_sent, tabs, info.tcpi_last_data_recv,
	    tabs, info.tcpi_last_ack_recv, tabs, info.tcpi_pmtu,
	    tabs, info.tcpi_rcv_ssthresh,
	    tabs, info.tcpi_rtt, tabs, info.tcpi_rttvar,
	    tabs, info.tcpi_snd_ssthresh, tabs, info.tcpi_snd_cwnd,
	    tabs, info.tcpi_advmss,
	    tabs, info.tcpi_reordering, tabs, info.tcpi_rcv_rtt,
	    tabs, info.tcpi_rcv_space, tabs, info.tcpi_total_retrans
	    );
#endif /* Linux specific code. */

	if (0 > rc) { /* Error. */
		(*buf_size_ret) = 0;
		return (EFAULT);
	}
	(*buf_size_ret) = (size_t)rc;
	if (buf_size <= (size_t)rc) /* Truncated. */
		return (ENOSPC);
	return (0);
#else
	return (ENOSYS);
#endif
}
