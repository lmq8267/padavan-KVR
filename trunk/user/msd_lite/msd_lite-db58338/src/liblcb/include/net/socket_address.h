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


#ifndef __NET_SOCKET_ADDRESS_H__
#define __NET_SOCKET_ADDRESS_H__

#include <sys/param.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <inttypes.h>

/* OLD: (56) = 46(INET6_ADDRSTRLEN) + 2('[]') + 1(':') + 5(port num) + zero */
#define STR_ADDR_LEN		(((size_t)sizeof(((struct sockaddr_un*)0)->sun_path)) + 4)

typedef struct in_addr		in__addr_t, *in_addr_p;
typedef struct in6_addr		in6_addr_t, *in6_addr_p;
typedef struct sockaddr		sockaddr_t, *sockaddr_p;
typedef struct sockaddr_un	sockaddr_un_t, *sockaddr_un_p;
typedef struct sockaddr_in	sockaddr_in_t, *sockaddr_in_p;
typedef struct sockaddr_in6	sockaddr_in6_t, *sockaddr_in6_p;
typedef struct sockaddr_storage	sockaddr_storage_t, *sockaddr_storage_p;


void	sa_copy(const void *src, void *dst);
int	sa_init(sockaddr_storage_p addr, const sa_family_t family,
	    const void *sin_addr, const uint16_t port);
sa_family_t sa_family(const sockaddr_storage_t *addr);
socklen_t sa_size(const sockaddr_storage_t *addr);
uint16_t sa_port_get(const sockaddr_storage_t *addr);
int	sa_port_set(sockaddr_storage_p addr, const uint16_t port);
void 	*sa_addr_get(const sockaddr_storage_t *addr);
int	sa_addr_set(sockaddr_storage_p addr, const void *sin_addr);
int	sa_addr_is_specified(const sockaddr_storage_t *addr);
int	sa_addr_is_loopback(const sockaddr_storage_t *addr);
int	sa_addr_is_multicast(const sockaddr_storage_t *addr);
int	sa_addr_is_broadcast(const sockaddr_storage_t *addr);
int	sa_addr_port_is_eq(const sockaddr_storage_t *addr1,
	    const sockaddr_storage_t *addr2);
int	sa_addr_is_eq(const sockaddr_storage_t *addr1,
	    const sockaddr_storage_t *addr2);

int	sa_addr_from_str(sockaddr_storage_p addr,
	    const char *buf, size_t buf_size);
int	sa_addr_port_from_str(sockaddr_storage_p addr,
	    const char *buf, size_t buf_size);
int	sa_addr_to_str(const sockaddr_storage_t *addr,
	    char *buf, size_t buf_size, size_t *buf_size_ret);
int	sa_addr_port_to_str(const sockaddr_storage_t *addr,
	     char *buf, size_t buf_size, size_t *buf_size_ret);


#endif /* __NET_SOCKET_ADDRESS_H__ */
