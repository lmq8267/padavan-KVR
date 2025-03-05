/*-
 * Copyright (c) 2011 - 2022 Rozhuk Ivan <rozhuk.im@gmail.com>
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


#ifndef __HOST_ADDRESS_H__
#define __HOST_ADDRESS_H__

#include <sys/param.h>
#include <sys/types.h>
#include <inttypes.h>
#include <netdb.h>
#include <errno.h>
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <stdlib.h> /* malloc, exit */

#include "utils/macro.h"
#include "utils/mem_utils.h"
#include "utils/num2str.h"
#include "utils/str2num.h"
#include "net/socket_address.h"


#define HOST_ADDR_PREALLOC	8


typedef struct host_addr_s {
	sockaddr_storage_p addrs;	/* proto:addr:port */
	uint8_t		*name;		/* Hostname. */
	size_t		name_size;	/* Host name size. */
	uint16_t	port;		/* Port. */
	size_t		allocated;	/* Num of available sockaddr_storage_t. */
	size_t		count;		/* Num of used sockaddr_storage_t. */
} host_addr_t, *host_addr_p;


static inline host_addr_p
host_addr_alloc(const uint8_t *name, size_t name_size, uint16_t def_port) {
	host_addr_p haddr;
	uint8_t *ptm_end;

	if (NULL == name || 0 == name_size)
		return (NULL);

	ptm_end = mem_rchr(name, name_size, ':');
	if (NULL != ptm_end) { /* Port after hostname. */
		ptm_end ++;
		def_port = ustr2u16(ptm_end,
		    (size_t)((name + name_size) - ptm_end));
		name_size = (size_t)(ptm_end - name - 1);
	}

	haddr = calloc(1, (sizeof(host_addr_t) + name_size + sizeof(void*)));
	if (NULL == haddr)
		return (haddr);
	haddr->name = (uint8_t*)(haddr + 1);
	memcpy(haddr->name, name, name_size);
	haddr->name_size = name_size;
	haddr->name[name_size] = 0;
	haddr->port = def_port;

	return (haddr);
}

static inline host_addr_p
host_addr_clone(host_addr_p src) {
	host_addr_p haddr;

	if (NULL == src)
		return (NULL);

	haddr = calloc(src->allocated, sizeof(sockaddr_storage_t));
	if (NULL == haddr)
		return (haddr);
	haddr->addrs = calloc(1, (sizeof(host_addr_t) + src->name_size + sizeof(void*)));
	if (NULL == haddr->addrs) {
		free(haddr);
		return (NULL);
	}
	memcpy(haddr->addrs, src->addrs,
	    (sizeof(sockaddr_storage_t) * src->count));
	haddr->name = (uint8_t*)(haddr + 1);
	memcpy(haddr->name, src->name, src->name_size);
	haddr->name_size = src->name_size;
	haddr->name[src->name_size] = 0;
	haddr->port = src->port;
	haddr->allocated = src->allocated;
	haddr->count = src->count;

	return (haddr);
}

static inline void
host_addr_free(host_addr_p haddr) {

	if (NULL == haddr)
		return;

	if (NULL != haddr->addrs) {
		free(haddr->addrs);
	}
	free(haddr);
}

static inline int
host_addr_is_host_soaddr(host_addr_p haddr, const sockaddr_storage_p addr) {
	size_t i;

	if (NULL == haddr || NULL == addr)
		return (0);

	for (i = 0; i < haddr->count; i ++) {
		if (0 != sa_addr_port_is_eq(&haddr->addrs[i], addr))
			return (1);
	}

	return (0);
}

static inline int
host_addr_is_host_addr(host_addr_p haddr, const sockaddr_storage_p addr) {
	size_t i;

	if (NULL == haddr || NULL == addr)
		return (0);

	for (i = 0; i < haddr->count; i ++) {
		if (0 != sa_addr_is_eq(&haddr->addrs[i], addr))
			return (1);
	}

	return (0);
}

/*
 * Add ip address to host
 */
static inline int
host_addr_add_addr(host_addr_p haddr, const sockaddr_storage_p addr) {
	int error;

	if (NULL == haddr)
		return (EINVAL);

	/* Is we need to add? */
	if (0 != host_addr_is_host_soaddr(haddr, addr))
		return (0);

	/* Need more space? */
	error = realloc_items((void**)&haddr->addrs,
	    sizeof(sockaddr_storage_t), &haddr->allocated,
	    HOST_ADDR_PREALLOC, haddr->count);
	if (0 != error)
		return (error);

	sa_copy(addr, &haddr->addrs[haddr->count]);
	if (0 == sa_port_get(&haddr->addrs[haddr->count])) {
		sa_port_set(&haddr->addrs[haddr->count], haddr->port);
	}
	haddr->count ++;

	return (0);
}

/*
 * Very simple resolver
 * work slow, block thread, has no cache
 */
static inline int
host_addr_resolv(host_addr_p haddr) {
	int error;
	struct addrinfo hints, *res, *res0;
	char servname[8];

	if (NULL == haddr)
		return (EINVAL);

	memset(&hints, 0x00, sizeof(hints));
	hints.ai_family = PF_UNSPEC;
	hints.ai_flags = AI_NUMERICSERV;
	u162str(haddr->port, servname, sizeof(servname), NULL); /* Should not fail. */
	error = getaddrinfo((char*)haddr->name, servname, &hints, &res0);
	if (0 != error)  /* NOTREACHED */
		return (error);
	
	for (res = res0; NULL != res; res = res->ai_next) {
		if (AF_INET != res->ai_family && AF_INET6 != res->ai_family)
			continue;
		host_addr_add_addr(haddr, res->ai_addr);
	}
	freeaddrinfo(res0);

	return (0);
}


#endif /* __HOST_ADDRESS_H__ */
