/*-
 * Copyright (c) 2011 - 2018 Rozhuk Ivan <rozhuk.im@gmail.com>
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
#include <ifaddrs.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <errno.h>
#include <stdio.h> /* snprintf, fprintf */
#include <string.h> /* memcpy, memmove, memset, strerror... */

#include "utils/macro.h"
#include "utils/mem_utils.h"
#include "utils/str2num.h"
#include "net/socket_address.h"
#include "net/utils.h"


/* For convert netmask <-> prefix len. */
static const uint32_t pref_to_mask[33] = {				/* bits set */
	0x0,								/* none */
	0x80,		0xc0,		0xe0,		0xf0,		/* 1 - 4 */
	0xf8,		0xfc,		0xfe,		0xff,		/* 5 - 8 */
	0x80ff,		0xc0ff,		0xe0ff,		0xf0ff,		/* 9 - 12 */
	0xf8ff,		0xfcff,		0xfeff,		0xffff,		/* 13 - 16 */
	0x80ffff,	0xc0ffff,	0xe0ffff,	0xf0ffff,	/* 17 - 20 */
	0xf8ffff,	0xfcffff,	0xfeffff,	0xffffff,	/* 21 - 24 */
	0x80ffffff,	0xc0ffffff,	0xe0ffffff,	0xf0ffffff,	/* 25 - 28 */
	0xf8ffffff,	0xfcffffff,	0xfeffffff,	0xffffffff	/* 29 - 32 */
};

/* Ex:
 * 127.0.0.0/8
 * [2001:4f8:fff6::]/32
 * 2001:4f8:fff6::28/32
 */
int
str_net_to_ss(const char *buf, size_t buf_size, sockaddr_storage_p addr,
    uint16_t *preflen_ret) {
	int error;
	const char *ptm;
	uint16_t preflen;

	if (NULL == buf || 0 == buf_size || NULL == addr)
		return (EINVAL);

	ptm = mem_rchr(buf, buf_size, '/'); /* net-preflen delimiter. */
	if (NULL != ptm) {
		ptm ++;
		preflen = str2u16(ptm, (size_t)(buf_size - (size_t)(ptm - buf)));
		ptm --;
	} else {
		ptm = (const char*)(buf + buf_size);
		preflen = 0xffff;
	}

	error = sa_addr_from_str(addr, buf, (size_t)(ptm - buf));
	if (0 != error)
		return (error);

	switch (addr->ss_family) {
	case AF_INET:
		if (0xffff == preflen) {
			preflen = 32;
		}
		break;
	case AF_INET6:
		if (0xffff == preflen) {
			preflen = 128;
		}
		break;
	}
	if (NULL != preflen_ret) {
		(*preflen_ret) = preflen;
	}

	return (0);
}

/*
 * Silently truncate prefixes that seem to  have an inconsistent
 * prefix: e.g. an input prefix 203.97.2.226/24 would be truncated to 203.97.2.0/24.
 */
void
net_addr_truncate_preflen(sockaddr_storage_p net_addr, uint16_t preflen) {
	uint32_t *net, mask[4];
	size_t i, addr_len;

	if (NULL == net_addr)
		return;

	switch (net_addr->ss_family) {
	case AF_INET:
		if (0 != inet_len2mask(preflen, (in_addr_p)&mask))
			return;
		net = (uint32_t*)&((sockaddr_in_p)net_addr)->sin_addr;
		addr_len = 1;
		break;
	case AF_INET6:
		if (0 != inet6_len2mask(preflen, (in6_addr_p)&mask))
			return;
		net = (uint32_t*)&((sockaddr_in6_p)net_addr)->sin6_addr;
		addr_len = 4;
		break;
	default:
		return; // dont know how compare
	}
	for (i = 0; i < addr_len; i ++) {
		net[i] &= mask[i];
	}
}

void
net_addr_truncate_mask(sa_family_t family, uint32_t *net, uint32_t *mask) {
	size_t i, addr_len;

	if (NULL == net || NULL == mask)
		return;

	switch (family) {
	case AF_INET:
		addr_len = 1;
		break;
	case AF_INET6:
		addr_len = 4;
		break;
	default:
		return; // dont know how compare
	}

	for (i = 0; i < addr_len; i ++) {
		net[i] &= mask[i];
	}
}


// compares two sockaddr struct, ONLY address fields
int
is_addr_in_net(sa_family_t family, const uint32_t *net, const uint32_t *mask,
    const uint32_t *addr) {
	size_t i, addr_len;

	if (NULL == net || NULL == mask || NULL == addr)
		return (0);

	switch (family) {
	case AF_INET:
		addr_len = 1;
		break;
	case AF_INET6:
		addr_len = 4;
		break;
	default:
		return (0); // dont know how compare
	}

	for (i = 0; i < addr_len; i ++) {
		if ((addr[i] & mask[i]) != net[i])
			return (0);
	}

	return (1);
}


/* in_len2mask */
int
inet_len2mask(size_t len, in_addr_p mask) {

	if (32 < len || NULL == mask)
		return (EINVAL);

	mask->s_addr = pref_to_mask[len];

	return (0);
}

/* in_mask2len */
int
inet_mask2len(const in__addr_t *mask) {
	int i;

	for (i = 32; -1 < i && mask->s_addr < pref_to_mask[i]; i --)
		;
	if (-1 < i && mask->s_addr == pref_to_mask[i])
		return (i);

	return (0);
}

int
inet6_len2mask(size_t len, in6_addr_p mask) {
	size_t i, cnt;

	if (128 < len || NULL == mask)
		return (EINVAL);

	cnt = (len / 32); /* dword (uint32) count */
	for (i = 0; cnt > i; i ++) {
		mask->s6_addr32[i] = 0xffffffff;
	}
	if (128 == len)
		return (0);
	mask->s6_addr32[cnt] = pref_to_mask[(len % 32)];
	for (i = (cnt + 1); 4 > i; i ++) {
		mask->s6_addr32[i] = 0;
	}

	return (0);
}

/* in6_mask2len */
int
inet6_mask2len(const in6_addr_t *mask) {
	int i, j;

	if (NULL == mask)
		return (0);

	for (j = 0; 4 > j; j ++) {
		if (mask->s6_addr32[j] != 0xffffffff)
			break;
	}
	if (4 == j)
		return (128); // = 4 * 32

	for (i = 32; -1 != i && mask->s6_addr32[j] < pref_to_mask[i]; i --)
		;

	if (-1 < i && mask->s6_addr32[j] == pref_to_mask[i])
		return (((j * 32) + i));

	return (0);
}


int
get_if_addr_by_name(const char *if_name, size_t if_name_size,
    sa_family_t family, sockaddr_storage_p addr) {
	struct ifaddrs *ifap, *ifaptm;

	if (NULL == if_name || IFNAMSIZ < if_name_size || NULL == addr)
		return (EINVAL);

	if (0 != getifaddrs(&ifap))
		return (errno);
	for (ifaptm = ifap; NULL != ifaptm; ifaptm = ifaptm->ifa_next) {
		if (NULL != ifaptm->ifa_addr &&
		    family == ifaptm->ifa_addr->sa_family &&
		    0 == strncmp(if_name, ifaptm->ifa_name, if_name_size)) {
			sa_copy(ifaptm->ifa_addr, addr);
			freeifaddrs(ifap);
			return (0);
		}
	}
	freeifaddrs(ifap);

	return (ESPIPE);
}

int
get_if_addr_by_idx(uint32_t if_index, sa_family_t family,
    sockaddr_storage_p addr) {
	char if_name[(IFNAMSIZ + 1)];

	if (NULL == addr)
		return (EINVAL);

	if (NULL == if_indextoname(if_index, if_name))
		return (errno);

	return (get_if_addr_by_name(if_name, 
	    strnlen(if_name, sizeof(if_name)), family, addr));
}

int
is_host_addr(const sockaddr_storage_t *addr) {
	struct ifaddrs *ifap, *ifaptm;
	sockaddr_storage_t addrtm;

	if (NULL == addr)
		return (EINVAL);

	if (0 != getifaddrs(&ifap))
		return (errno);
	for (ifaptm = ifap; NULL != ifaptm; ifaptm = ifaptm->ifa_next) {
		if (NULL == ifaptm->ifa_addr)
			continue;
		sa_copy(ifaptm->ifa_addr, &addrtm); /* Copy to aligned mem. */
		if (0 != sa_addr_is_eq(&addrtm, addr)) {
			freeifaddrs(ifap);
			return (1);
		}
	}
	freeifaddrs(ifap);

	return (0);
}

/* data - cache getifaddrs() result to improve perfomance. */
int
is_host_addr_ex(const sockaddr_storage_t *addr, void **data) {
	struct ifaddrs *ifap = NULL, *ifaptm;
	sockaddr_storage_t addrtm;

	if (NULL == addr)
		return (EINVAL);

	if (NULL != data) {
		ifap = (struct ifaddrs*)(*data);
	}
	if (NULL == ifap) {
		if (0 != getifaddrs(&ifap))
			return (errno);
		if (NULL != data) {
			(*data) = ifap;
		}
	}
	for (ifaptm = ifap; NULL != ifaptm; ifaptm = ifaptm->ifa_next) {
		if (NULL == ifaptm->ifa_addr)
			continue;
		sa_copy(ifaptm->ifa_addr, &addrtm); /* Copy to aligned mem. */
		if (0 != sa_addr_is_eq(&addrtm, addr))
			return (1);
	}

	return (0);
}

void
is_host_addr_ex_free(void *data) {

	if (NULL != data) {
		freeifaddrs((struct ifaddrs*)data);
	}
}


size_t
iovec_calc_size(struct iovec *iov, size_t iov_cnt) {
	register size_t i, size_ret = 0;

	if (NULL == iov || 0 == iov_cnt)
		return (size_ret);
	for (i = 0; i < iov_cnt; i ++) {
		size_ret += iov[i].iov_len;
	}

	return (size_ret);
}

void
iovec_set_offset(struct iovec *iov, size_t iov_cnt, size_t iov_off) {
	register size_t i;

	if (NULL == iov || 0 == iov_cnt || 0 == iov_off)
		return;

	for (i = 0; i < iov_cnt; i ++) {
		if (iov[i].iov_len > iov_off) { /* Skip part of block. */
			iov[i].iov_base = (((uint8_t*)iov[i].iov_base) + iov_off);
			iov[i].iov_len -= iov_off;
		} else { /* Skip block. */
			iov_off -= iov[i].iov_len;
			iov[i].iov_len = 0;
		}
	}
}
