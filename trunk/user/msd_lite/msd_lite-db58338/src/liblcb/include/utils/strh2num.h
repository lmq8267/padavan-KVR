/*-
 * Copyright (c) 2005-2023 Rozhuk Ivan <rozhuk.im@gmail.com>
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


#ifndef __STRH2NUM_H__
#define __STRH2NUM_H__

#include <sys/types.h>
#include <inttypes.h>


#define STRH2NUM_SIGN(_str, _len, _sign)				\
	for (size_t _i = 0; _i < (_len); _i ++) {			\
		uint8_t _cval = ((const uint8_t*)(_str))[_i];		\
		if ('-' == _cval) {					\
			(_sign) = -1;					\
		} else if ('+' == _cval) {				\
			(_sign) = 1;					\
		} else {						\
			break;						\
		}							\
	}

#define STRH2NUM(_str, _len, _type, _res)				\
	for (size_t _i = 0; _i < (_len); _i ++) {			\
		uint8_t _cval = ((const uint8_t*)(_str))[_i];		\
		if ('0' <= _cval && '9' >= _cval) {			\
			_cval -= '0';					\
		} else if ('a' <= _cval && 'f' >= _cval) {		\
			_cval -= ('a' - 10);				\
		} else if ('A' <= _cval && 'F' >= _cval) {		\
			_cval -= ('A' - 10);				\
		} else {						\
			continue;					\
		}							\
		(_res) = (_type)(((_type)((_res) << 4)) | _cval);	\
	}

#define STRH2UNUM(_str, _len, _type) do {				\
		_type _res = 0;						\
		if (NULL == (_str) || 0 == (_len))			\
			return (0);					\
		STRH2NUM((_str), (_len), _type, _res);			\
		return (_res);						\
} while (0)

#define STRH2SNUM(_str, _len, _type)	do {				\
		_type _res = 0, _sign = 1;				\
		if (NULL == (_str) || 0 == (_len))			\
			return (0);					\
		STRH2NUM_SIGN((_str), (_len), _sign);			\
		STRH2NUM((_str), (_len), _type, _res);			\
		_res *= _sign;						\
		return (_res);						\
} while (0)


static inline size_t
strh2usize(const char *str, const size_t str_len) {

	STRH2UNUM(str, str_len, size_t);
}

static inline size_t
ustrh2usize(const uint8_t *str, const size_t str_len) {

	STRH2UNUM(str, str_len, size_t);
}

static inline uint8_t
strh2u8(const char *str, const size_t str_len) {

	STRH2UNUM(str, str_len, uint8_t);
}

static inline uint8_t
ustrh2u8(const uint8_t *str, const size_t str_len) {

	STRH2UNUM(str, str_len, uint8_t);
}

static inline uint16_t
strh2u16(const char *str, const size_t str_len) {

	STRH2UNUM(str, str_len, uint16_t);
}

static inline uint16_t
ustrh2u16(const uint8_t *str, const size_t str_len) {

	STRH2UNUM(str, str_len, uint16_t);
}

static inline uint32_t
strh2u32(const char *str, const size_t str_len) {

	STRH2UNUM(str, str_len, uint32_t);
}

static inline uint32_t
ustrh2u32(const uint8_t *str, const size_t str_len) {

	STRH2UNUM(str, str_len, uint32_t);
}

static inline uint64_t
strh2u64(const char *str, const size_t str_len) {

	STRH2UNUM(str, str_len, uint64_t);
}

static inline uint64_t
ustrh2u64(const uint8_t *str, const size_t str_len) {

	STRH2UNUM(str, str_len, uint64_t);
}


/* Signed. */

static inline ssize_t
strh2ssize(const char *str, const size_t str_len) {

	STRH2SNUM(str, str_len, ssize_t);
}

static inline ssize_t
ustrh2ssize(const uint8_t *str, const size_t str_len) {

	STRH2SNUM(str, str_len, ssize_t);
}

static inline int8_t
strh2s8(const char *str, const size_t str_len) {

	STRH2SNUM(str, str_len, int8_t);
}

static inline int8_t
ustrh2s8(const uint8_t *str, const size_t str_len) {

	STRH2SNUM(str, str_len, int8_t);
}

static inline int16_t
strh2s16(const char *str, const size_t str_len) {

	STRH2SNUM(str, str_len, int16_t);
}

static inline int16_t
ustrh2s16(const uint8_t *str, const size_t str_len) {

	STRH2SNUM(str, str_len, int16_t);
}

static inline int32_t
strh2s32(const char *str, const size_t str_len) {

	STRH2SNUM(str, str_len, int32_t);
}

static inline int32_t
ustrh2s32(const uint8_t *str, const size_t str_len) {

	STRH2SNUM(str, str_len, int32_t);
}

static inline int64_t
strh2s64(const char *str, const size_t str_len) {

	STRH2SNUM(str, str_len, int64_t);
}

static inline int64_t
ustrh2s64(const uint8_t *str, const size_t str_len) {

	STRH2SNUM(str, str_len, int64_t);
}


#endif /* __STRH2NUM_H__ */
