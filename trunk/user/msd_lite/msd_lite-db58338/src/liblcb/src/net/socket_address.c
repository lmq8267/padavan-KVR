/*-
 * Copyright (c) 2011 - 2020 Rozhuk Ivan <rozhuk.im@gmail.com>
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
#include <string.h> /* memcpy, memmove, memset, strerror... */

#include "utils/macro.h"
#include "utils/mem_utils.h"
#include "utils/num2str.h"
#include "utils/str2num.h"
#include "net/socket_address.h"


static const sa_family_t family_list[] = {
	AF_INET, AF_INET6
};


/* Copy sockaddr_storage struct. */
void
sa_copy(const void *src, void *dst) {

	if (NULL == src || NULL == dst || src == dst)
		return;
	memcpy(dst, src, sa_size((const sockaddr_storage_t*)src));
}

int
sa_init(sockaddr_storage_p addr, const sa_family_t family,
    const void *sin_addr, const uint16_t port) {

	if (NULL == addr)
		return (EINVAL);

	switch (family) {
	case AF_UNIX:
		memset(addr, 0x00, sizeof(sockaddr_un_t));
#ifdef BSD /* BSD specific code. */
		((sockaddr_un_p)addr)->sun_len = sizeof(sockaddr_un_t);
#endif
		((sockaddr_un_p)addr)->sun_family = AF_UNIX;
		//addr->sun_path[] = 0;
		break;
	case AF_INET:
		memset(addr, 0x00, sizeof(sockaddr_in_t));
#ifdef BSD /* BSD specific code. */
		((sockaddr_in_p)addr)->sin_len = sizeof(sockaddr_in_t);
#endif
		((sockaddr_in_p)addr)->sin_family = AF_INET;
		//addr->sin_port = 0;
		//addr->sin_addr.s_addr = 0;
		break;
	case AF_INET6:
		memset(addr, 0x00, sizeof(sockaddr_in6_t));
#ifdef BSD /* BSD specific code. */
		((sockaddr_in6_p)addr)->sin6_len = sizeof(sockaddr_in6_t);
#endif
		((sockaddr_in6_p)addr)->sin6_family = AF_INET6;
		//((sockaddr_in6_p)addr)->sin6_port = 0;
		//((sockaddr_in6_p)addr)->sin6_flowinfo = 0;
		//((sockaddr_in6_p)addr)->sin6_addr[] = 0;
		//((sockaddr_in6_p)addr)->sin6_scope_id = 0;
		break;
	default:
		return (EAFNOSUPPORT);
	}

	sa_addr_set(addr, sin_addr);
	if (0 == port)
		return (0);

	return (sa_port_set(addr, port));
}

sa_family_t
sa_family(const sockaddr_storage_t *addr) {

	if (NULL == addr)
		return (0);

	switch (addr->ss_family) {
	case AF_UNIX:
	case AF_INET:
	case AF_INET6:
		return (addr->ss_family);
	}

	return (0);
}

socklen_t
sa_size(const sockaddr_storage_t *addr) {

	if (NULL == addr)
		return (0);

	switch (addr->ss_family) {
	case AF_UNIX:
		return (sizeof(sockaddr_un_t));
	case AF_INET:
		return (sizeof(sockaddr_in_t));
	case AF_INET6:
		return (sizeof(sockaddr_in6_t));
	}

	return (sizeof(sockaddr_storage_t));
}

uint16_t
sa_port_get(const sockaddr_storage_t *addr) {

	if (NULL == addr)
		return (0);

	switch (addr->ss_family) {
	case AF_INET:
		return (ntohs(((const sockaddr_in_t*)addr)->sin_port));
	case AF_INET6:
		return (ntohs(((const sockaddr_in6_t*)addr)->sin6_port));
	}

	return (0);
}

int
sa_port_set(sockaddr_storage_p addr, const uint16_t port) {

	if (NULL == addr)
		return (EINVAL);

	switch (addr->ss_family) {
	case AF_UNIX:
		break;
	case AF_INET:
		((sockaddr_in_p)addr)->sin_port = htons(port);
		break;
	case AF_INET6:
		((sockaddr_in6_p)addr)->sin6_port = htons(port);
		break;
	default:
		return (EAFNOSUPPORT);
	}

	return (0);
}

void *
sa_addr_get(const sockaddr_storage_t *addr) {

	if (NULL == addr)
		return (NULL);

	switch (addr->ss_family) {
	case AF_UNIX:
		return (MK_RW_PTR(&((const sockaddr_un_t*)addr)->sun_path));
	case AF_INET:
		return (MK_RW_PTR(&((const sockaddr_in_t*)addr)->sin_addr));
	case AF_INET6:
		return (MK_RW_PTR(&((const sockaddr_in6_t*)addr)->sin6_addr));
	}

	return (NULL);
}

int
sa_addr_set(sockaddr_storage_p addr, const void *sin_addr) {

	if (NULL == addr || NULL == sin_addr)
		return (EINVAL);

	switch (addr->ss_family) {
	case AF_UNIX:
		strlcpy(((sockaddr_un_p)addr)->sun_path, (const char*)sin_addr,
		    sizeof(((sockaddr_un_p)addr)->sun_path));
		break;
	case AF_INET:
		memcpy(&((sockaddr_in_p)addr)->sin_addr, sin_addr,
		    sizeof(in__addr_t));
		break;
	case AF_INET6:
		memcpy(&((sockaddr_in6_p)addr)->sin6_addr, sin_addr,
		    sizeof(in6_addr_t));
		break;
	default:
		return (EAFNOSUPPORT);
	}

	return (0);
}

int
sa_addr_is_specified(const sockaddr_storage_t *addr) {

	if (NULL == addr)
		return (0);

	switch (addr->ss_family) {
	case AF_UNIX:
		return (0 != ((const sockaddr_un_t*)addr)->sun_path[0]);
	case AF_INET:
		return (INADDR_ANY != ((const sockaddr_in_t*)addr)->sin_addr.s_addr);
	case AF_INET6:
		return (0 == IN6_IS_ADDR_UNSPECIFIED(&((const sockaddr_in6_t*)addr)->sin6_addr));
	}

	return (0);
}

int
sa_addr_is_loopback(const sockaddr_storage_t *addr) {

	if (NULL == addr)
		return (0);

	switch (addr->ss_family) {
	case AF_INET:
		return (IN_LOOPBACK(ntohl(((const sockaddr_in_t*)addr)->sin_addr.s_addr)));
	case AF_INET6:
		return (IN6_IS_ADDR_LOOPBACK(&((const sockaddr_in6_t*)addr)->sin6_addr));
	}

	return (0);
}

int
sa_addr_is_multicast(const sockaddr_storage_t *addr) {

	if (NULL == addr)
		return (0);

	switch (addr->ss_family) {
	case AF_INET:
		return (IN_MULTICAST(ntohl(((const sockaddr_in_t*)addr)->sin_addr.s_addr)));
	case AF_INET6:
		return (IN6_IS_ADDR_MULTICAST(&((const sockaddr_in6_t*)addr)->sin6_addr));
	}

	return (0);
}

int
sa_addr_is_broadcast(const sockaddr_storage_t *addr) {

	if (NULL == addr)
		return (0);

	switch (addr->ss_family) {
	case AF_INET:
		return (IN_BROADCAST(((const sockaddr_in_t*)addr)->sin_addr.s_addr));
	}

	return (0);
}


/* Compares two sockaddr_storage struct, address and port fields. */
int
sa_addr_port_is_eq(const sockaddr_storage_t *addr1,
    const sockaddr_storage_t *addr2) {

	if (NULL == addr1 || NULL == addr2)
		return (0);
	if (addr1 == addr2)
		return (1);
	if (addr1->ss_family != addr2->ss_family)
		return (0);
	switch (addr1->ss_family) {
	case AF_UNIX:
		if (0 == strncmp(((const sockaddr_un_t*)addr1)->sun_path,
		    ((const sockaddr_un_t*)addr2)->sun_path,
		    sizeof(((const sockaddr_un_t*)addr1)->sun_path)))
			return (1);
		break;
	case AF_INET:
		if (((const sockaddr_in_t*)addr1)->sin_port ==
		    ((const sockaddr_in_t*)addr2)->sin_port &&
		    ((const sockaddr_in_t*)addr1)->sin_addr.s_addr ==
		    ((const sockaddr_in_t*)addr2)->sin_addr.s_addr)
			return (1);
		break;
	case AF_INET6:
		if (((const sockaddr_in6_t*)addr1)->sin6_port ==
		    ((const sockaddr_in6_t*)addr2)->sin6_port &&
		    0 == memcmp(
		    &((const sockaddr_in6_t*)addr1)->sin6_addr,
		    &((const sockaddr_in6_t*)addr2)->sin6_addr,
		    sizeof(in6_addr_t)))
			return (1);
		break;
	}

	return (0);
}

/* Compares two sockaddr_storage struct, ONLY address fields. */
int
sa_addr_is_eq(const sockaddr_storage_t *addr1,
    const sockaddr_storage_t *addr2) {

	if (NULL == addr1 || NULL == addr2)
		return (0);
	if (addr1 == addr2)
		return (1);
	if (addr1->ss_family != addr2->ss_family)
		return (0);
	switch (addr1->ss_family) {
	case AF_UNIX:
		if (0 == strncmp(((const sockaddr_un_t*)addr1)->sun_path,
		    ((const sockaddr_un_t*)addr2)->sun_path,
		    sizeof(((const sockaddr_un_t*)addr1)->sun_path)))
			return (1);
		break;
	case AF_INET:
		if (0 == memcmp(
		    &((const sockaddr_in_t*)addr1)->sin_addr,
		    &((const sockaddr_in_t*)addr2)->sin_addr,
		    sizeof(in__addr_t)))
			return (1);
		break;
	case AF_INET6:
		if (0 == memcmp(
		    &((const sockaddr_in6_t*)addr1)->sin6_addr,
		    &((const sockaddr_in6_t*)addr2)->sin6_addr,
		    sizeof(in6_addr_t)))
			return (1);
		break;
	}

	return (0);
}


/* Ex:
 * 127.0.0.1
 * [2001:4f8:fff6::28]
 * 2001:4f8:fff6::28
 */
int
sa_addr_from_str(sockaddr_storage_p addr,
    const char *buf, size_t buf_size) {
	size_t addr_size, i;
	char straddr[STR_ADDR_LEN];
	const char *ptm, *ptm_end;

	if (NULL == addr || NULL == buf || 0 == buf_size)
		return (EINVAL);

	ptm = buf;
	ptm_end = (buf + buf_size);
	/* Skip spaces, tabs and [ before address. */
	while (ptm < ptm_end && (' ' == (*ptm) || '\t' == (*ptm) || '[' == (*ptm))) {
		ptm ++;
	}
	/* Skip spaces, tabs and ] after address. */
	while (ptm < ptm_end && (' ' == (*(ptm_end - 1)) ||
	    '\t' == (*(ptm_end - 1)) ||
	    ']' == (*(ptm_end - 1)))) {
		ptm_end --;
	}

	addr_size = (size_t)(ptm_end - ptm);
	if (0 == addr_size ||
	    (sizeof(straddr) - 1) < addr_size)
		return (EINVAL);
	memcpy(straddr, ptm, addr_size);
	straddr[addr_size] = 0;

	/* AF_INET, AF_INET6 */
	for (i = 0; i < nitems(family_list); i ++) {
		sa_init(addr, family_list[i], NULL, 0);
		if (1 == inet_pton(family_list[i], straddr,
		    sa_addr_get(addr))) {
			sa_port_set(addr, 0);
			return (0);
		}
	}
	/* AF_UNIX */
	if ('/' == straddr[0] || '.' == straddr[0]) {
		sa_init(addr, AF_UNIX, straddr, 0);
		return (0);
	}
	/* Fail: unknown address. */
	return (EINVAL);
}

/* Ex:
 * 127.0.0.1:1234
 * [2001:4f8:fff6::28]:1234
 * 2001:4f8:fff6::28:1234 - wrong, but work.
 */
int
sa_addr_port_from_str(sockaddr_storage_p addr,
    const char *buf, size_t buf_size) {
	size_t addr_size, i;
	uint16_t port = 0;
	char straddr[STR_ADDR_LEN];
	const char *ptm, *ptm_end;

	if (NULL == addr || NULL == buf || 0 == buf_size)
		return (EINVAL);

	ptm = mem_rchr(buf, buf_size, ':'); /* Addr-port delimiter. */
	ptm_end = mem_rchr(buf, buf_size, ']'); /* IPv6 addr end. */
	if (NULL != ptm &&
	    ptm > buf &&
	    ':' != (*(ptm - 1))) { /* IPv6 or port. */
		if (ptm > ptm_end) { /* ptm = port (':' after ']') */
			if (NULL == ptm_end) {
				ptm_end = ptm;
			}
			ptm ++;
			port = str2u16(ptm, (size_t)(buf_size - (size_t)(ptm - buf)));
		}/* else - IPv6 and no port. */
	}
	if (NULL == ptm_end) {
		ptm_end = (buf + buf_size);
	}
	ptm = buf;
	/* Skip spaces, tabs and [ before address. */
	while (ptm < ptm_end && (' ' == (*ptm) || '\t' == (*ptm) || '[' == (*ptm))) {
		ptm ++;
	}
	/* Skip spaces, tabs and ] after address. */
	while (ptm < ptm_end && (' ' == (*(ptm_end - 1)) ||
	    '\t' == (*(ptm_end - 1)) ||
	    ']' == (*(ptm_end - 1)))) {
		ptm_end --;
	}

	addr_size = (size_t)(ptm_end - ptm);
	if (0 == addr_size ||
	    (sizeof(straddr) - 1) < addr_size)
		return (EINVAL);
	memcpy(straddr, ptm, addr_size);
	straddr[addr_size] = 0;

	/* AF_INET, AF_INET6 */
	for (i = 0; i < nitems(family_list); i ++) {
		sa_init(addr, family_list[i], NULL, 0);
		if (1 == inet_pton(family_list[i], straddr,
		    sa_addr_get(addr))) {
			sa_port_set(addr, port);
			return (0);
		}
	}
	/* AF_UNIX */
	if ('/' == straddr[0] || '.' == straddr[0]) {
		sa_init(addr, AF_UNIX, straddr, 0);
		return (0);
	}
	/* Fail: unknown address. */
	return (EINVAL);
}

int
sa_addr_to_str(const sockaddr_storage_t *addr, char *buf,
    size_t buf_size, size_t *buf_size_ret) {
	void *sin_addr;
	size_t size_ret = 0;

	if (NULL == addr || NULL == buf || 0 == buf_size)
		return (EINVAL);

	sin_addr = sa_addr_get(addr);
	if (NULL == sin_addr)
		return (EAFNOSUPPORT);

	switch (addr->ss_family) {
	case AF_UNIX:
		size_ret = strlcpy(buf, sin_addr, buf_size);
		break;
	case AF_INET:
	case AF_INET6:
		if (NULL == inet_ntop(addr->ss_family, sin_addr,
		    buf, (buf_size - 1)))
			return (errno);
		buf[(buf_size - 1)] = 0; /* Should be not nessesary. */
		size_ret = strnlen(buf, buf_size);
		break;
	default:
		return (EAFNOSUPPORT);
	}

	if (NULL != buf_size_ret) {
		(*buf_size_ret) = size_ret;
	}

	return (((buf_size > size_ret) ? 0 : ENOSPC));
}

int
sa_addr_port_to_str(const sockaddr_storage_t *addr, char *buf,
    size_t buf_size, size_t *buf_size_ret) {
	int error;
	uint16_t port;
	size_t size_ret = 0, port_srt_size = 0;

	if (NULL == addr || NULL == buf || 0 == buf_size)
		return (EINVAL);

	switch (addr->ss_family) {
	case AF_UNIX:
	case AF_INET:
		error = sa_addr_to_str(addr, buf, buf_size, &size_ret);
		if (0 != error)
			goto err_out;
		break;
	case AF_INET6:
		error = sa_addr_to_str(addr, (buf + 1), (buf_size - 2),
		    &size_ret);
		if (0 != error)
			goto err_out;
		buf[0] = '[';
		buf[size_ret + 0] = ']';
		buf[size_ret + 1] = 0x00;
		size_ret ++;
		break;
	default:
		return (EAFNOSUPPORT);
	}

	port = sa_port_get(addr);
	if (0 != port) {
		if (buf_size < (size_ret + 7)) {
			size_ret += 7; /* 5 digits + ':' + zero. */
			error = ENOSPC;
			goto err_out;
		}
		buf[size_ret++] = ':';
		error = u162str(port, (buf + size_ret),
		    (size_t)(buf_size - size_ret), &port_srt_size);
		if (0 != error)
			return (error);
		size_ret += port_srt_size;
	}

err_out:
	if (NULL != buf_size_ret) {
		(*buf_size_ret) = size_ret;
	}

	return (error);
}
