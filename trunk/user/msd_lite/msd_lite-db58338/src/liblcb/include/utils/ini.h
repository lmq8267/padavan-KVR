/*-
 * Copyright (c) 2015 - 2020 Rozhuk Ivan <rozhuk.im@gmail.com>
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

/* Example:
[section]
name=value
an=av
bn=bv
*/


#ifndef __INI_H__
#define __INI_H__

#include <sys/types.h>
#include <inttypes.h>


typedef struct ini_s		*ini_p;

#define INI_OFFSET_INVALID	((size_t)~0)


int	ini_create(ini_p *ini_ret);
void	ini_destroy(const ini_p ini);

int	ini_buf_parse(const ini_p ini, const uint8_t *buf,
	    const size_t buf_size);

int	ini_buf_calc_size(const ini_p ini, size_t *file_size);
int	ini_buf_gen(const ini_p ini, uint8_t *buf, const size_t buf_size,
	    size_t *buf_size_ret);

int	ini_sect_enum(const ini_p ini, size_t *sect_off,
	    const uint8_t **sect_name, size_t *sect_name_size);
size_t	ini_sect_find(const ini_p ini, const uint8_t *sect_name,
	    const size_t sect_name_size);
size_t	ini_sect_findi(const ini_p ini, const uint8_t *sect_name,
	    const size_t sect_name_size);

int	ini_sect_val_enum(const ini_p ini, const size_t sect_off,
	    size_t *val_off,
	    const uint8_t **val_name, size_t *val_name_size,
	    const uint8_t **val, size_t *val_size);
size_t	ini_sect_val_find(const ini_p ini, const size_t sect_off,
	    const uint8_t *val_name, const size_t val_name_size);
size_t	ini_sect_val_findi(const ini_p ini, const size_t sect_off,
	    const uint8_t *val_name, const size_t val_name_size);

int	ini_val_get(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    const uint8_t **val, size_t *val_size);
int	ini_val_get_int(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    ssize_t *val);
int	ini_val_get_uint(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    size_t *val);

int	ini_vali_get(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    const uint8_t **val, size_t *val_size);
int	ini_vali_get_int(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    ssize_t *val);
int	ini_vali_get_uint(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    size_t *val);

int	ini_val_set(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    const uint8_t *val, size_t val_size);
int	ini_val_set_int(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    ssize_t val);
int	ini_val_set_uint(const ini_p ini,
	    const uint8_t *sect_name, const size_t sect_name_size,
	    const uint8_t *val_name, const size_t val_name_size,
	    size_t val);


#endif /* __INI_H__ */
