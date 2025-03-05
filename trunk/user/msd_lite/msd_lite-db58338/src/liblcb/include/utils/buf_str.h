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


#ifndef __BUF_STR_H__
#define __BUF_STR_H__

#include <sys/types.h>
#include <inttypes.h>


size_t	calc_sptab_count(const char *buf, size_t buf_size);
size_t	calc_sptab_count_r(const char *buf, size_t buf_size);
size_t	calc_non_sptab_count(const char *buf, size_t buf_size);
size_t	calc_non_sptab_count_r(const char *buf, size_t buf_size);

size_t	buf2args(char *buf, size_t buf_size, size_t max_args, char **args,
	    size_t *args_sizes);

int	buf_get_next_line(const uint8_t *buf, size_t buf_size,
	    const uint8_t *line, size_t line_size,
	    const uint8_t **next_line, size_t *next_line_size);

size_t	fmt_as_uptime(time_t *ut, char *buf, size_t buf_size);


uint8_t	data_xor8(const void *buf, size_t size);
void	memxorbuf(void *dst, size_t dsize, const void *src, size_t ssize);

int	cvt_hex2bin(const uint8_t *hex, size_t hex_size, int auto_out_size,
	    uint8_t *bin, size_t bin_size, size_t *bin_size_ret);
int	cvt_bin2hex(const uint8_t *bin, size_t bin_size, int auto_hex_size,
	    uint8_t *hex, size_t hex_size, size_t *hex_size_ret);

int	yn_set_flag32(const uint8_t *buf, size_t buf_size, uint32_t flag_bit,
	    uint32_t *flags);


#endif /* __BUF_STR_H__ */
