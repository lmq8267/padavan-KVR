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


#ifndef __NET_UTILS_H__
#define __NET_UTILS_H__

#include <sys/param.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <inttypes.h>


int	str_net_to_ss(const char *buf, size_t buf_size, struct sockaddr_storage *addr,
	    uint16_t *preflen_ret);
void	net_addr_truncate_preflen(struct sockaddr_storage *net_addr, uint16_t preflen);
void	net_addr_truncate_mask(sa_family_t family, uint32_t *net, uint32_t *mask);
int	is_addr_in_net(sa_family_t family, const uint32_t *net, const uint32_t *mask,
	    const uint32_t *addr);

int	inet_len2mask(size_t len, struct in_addr *mask);
int	inet_mask2len(const struct in_addr *mask);

int	inet6_len2mask(size_t len, struct in6_addr *mask);
int	inet6_mask2len(const struct in6_addr *mask);

int	get_if_addr_by_name(const char *if_name, size_t if_name_size, sa_family_t family,
	    struct sockaddr_storage *addr);
int	get_if_addr_by_idx(uint32_t if_index, sa_family_t family,
	    struct sockaddr_storage *addr);
int	is_host_addr(const struct sockaddr_storage *addr);
int	is_host_addr_ex(const struct sockaddr_storage *addr, void **data);
void	is_host_addr_ex_free(void *data);

size_t	iovec_calc_size(struct iovec *iov, size_t iov_cnt);
void	iovec_set_offset(struct iovec *iov, size_t iov_cnt, size_t iov_off);


#endif /* __NET_UTILS_H__ */
