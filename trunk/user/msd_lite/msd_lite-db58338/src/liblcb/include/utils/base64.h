/*-
 * Copyright (c) 2003-2024 Rozhuk Ivan <rozhuk.im@gmail.com>
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
 */


#ifndef __BASE64_H__
#define __BASE64_H__

#include <sys/param.h>
#include <sys/types.h>
#include <inttypes.h>

#ifndef nitems /* SIZEOF() */
#	define nitems(__val)	(sizeof(__val) / sizeof(__val[0]))
#endif

/*
 *      BASE64 coding:
 *      214             46              138
 *      11010100        00101110        10001010
 *            !             !             !
 *      ---------->>> convert 3 8bit to 4 6bit
 *      110101  000010  111010  001010
 *      53      2       58      10
 *      this numbers is offset in array coding below...
 */

static const uint8_t *base64_tbl_coding = (const uint8_t*)
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const uint8_t base64_tbl_decoding[256] = {
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
	52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
	64,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
	15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
	64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
	41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
	64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64
};


static inline int
base64_encode(const uint8_t *src, const size_t src_size,
    uint8_t *dst, size_t dst_size, size_t *enc_size_ret) {
	size_t enc_size, src_m3_size;
	register const uint8_t *rpos, *src_m3_max;
	register uint8_t *wpos;
	
	if (0 == src_size) {
		if (NULL != enc_size_ret) {
			(*enc_size_ret) = 0;
		}
		return (0);
	}
	if (NULL == src)
		return (EINVAL);
	/* Dst buf size calculation. */
	enc_size = (src_size / 3);
	src_m3_size = (enc_size * 3);
	if (src_m3_size != src_size) { /* Is multiple of 3? */
		enc_size ++;
	}
	enc_size *= 4;
	if (NULL != enc_size_ret) {
		(*enc_size_ret) = enc_size;
	}
	if (dst_size < enc_size) /* Is dst buf too small? */
		return (ENOBUFS);
	if (NULL == dst)
		return (EINVAL);
	wpos = dst;
	rpos = src;
	/* Main loop: encode 3 -> 4. */
	for (src_m3_max = (src + src_m3_size); rpos < src_m3_max; rpos += 3) {
		(*wpos ++) = base64_tbl_coding[rpos[0] >> 2]; /* c1. */
		(*wpos ++) = base64_tbl_coding[((rpos[0] << 4) & 0x30) | ((rpos[1] >> 4) & 0x0f)]; /* c2. */
		(*wpos ++) = base64_tbl_coding[((rpos[1] << 2) & 0x3c) | ((rpos[2] >> 6) & 0x03)]; /* c3. */
		(*wpos ++) = base64_tbl_coding[rpos[2] & 0x3f]; /* c4. */
	}
	/* Tail special encoding. */
	if (src_size != src_m3_size) { /* If src_size was not a multiple of 3: 1-2 bytes tail special coding. */
		(*wpos ++) = base64_tbl_coding[rpos[0] >> 2]; /* c1. */
		if (1 == (src_size - src_m3_size)) { /* 1 byte tail. */
			(*wpos ++) = base64_tbl_coding[((rpos[0] << 4) & 0x30)]; /* c2. */
			(*wpos ++) = '='; /* c3: tail padding. */
		} else { /* 2 bytes tail. */
			(*wpos ++) = base64_tbl_coding[((rpos[0] << 4) & 0x30) | ((rpos[1] >> 4) & 0x0f)]; /* c2. */
			(*wpos ++) = base64_tbl_coding[((rpos[1] << 2) & 0x3c)]; /* c3. */
		}
		(*wpos ++) = '='; /* c4: tail padding. */
	}
	(*wpos) = 0;
#if 0
	if ((wpos - dst) != enc_size) { /* Must be euqual! */
		(*enc_size_ret) = (wpos - dst);
	}
#endif

	return (0);
}


static inline int
base64_decode(const uint8_t *src, const size_t src_size,
    uint8_t *dst, size_t dst_size, size_t *dcd_size_ret) {
	size_t src_size_real, dcd_size, src_m4_size;
	register const uint8_t *rpos, *src_m4_max;
	register uint8_t *wpos;

	if (0 == src_size) {
zero_out:
		if (NULL != dcd_size_ret) {
			(*dcd_size_ret) = 0;
		}
		return (0);
	}
	if (NULL == src)
		return (EINVAL);
	/* Remove tail padding. */
	for (src_size_real = src_size; 0 < src_size_real; src_size_real --) {
		if ('=' != src[(src_size_real - 1)])
			break;
	}
	if (0 == src_size_real)
		goto zero_out;
	if (2 > src_size_real) /* Check again: at least 2 byte needed for decoder. */
		return (EINVAL);
	/* Dst buf size calculation. */
	dcd_size = (src_size_real / 4);
	src_m4_size = (dcd_size * 4);
	if (src_m4_size != src_size_real) { /* Is multiple of 4? */
		dcd_size ++;
	}
	dcd_size *= 3;
	if (dst_size < dcd_size) { /* Is dst buf too small? */
		if (NULL != dcd_size_ret) {
			(*dcd_size_ret) = dcd_size;
		}
		return (ENOBUFS);
	}
	if (NULL == dst)
		return (EINVAL);
	wpos = dst;
	rpos = src;
	/* Main loop: decode 4 -> 3. */
	for (src_m4_max = (src + src_m4_size); rpos < src_m4_max; rpos += 4) {
		(*wpos ++) = (base64_tbl_decoding[rpos[0]] << 2 | base64_tbl_decoding[rpos[1]] >> 4);
		(*wpos ++) = (base64_tbl_decoding[rpos[1]] << 4 | base64_tbl_decoding[rpos[2]] >> 2);
		(*wpos ++) = (base64_tbl_decoding[rpos[2]] << 6 | base64_tbl_decoding[rpos[3]]);
	}
	/* Tail special decoding. */
	switch ((src_size_real - src_m4_size)) {
	case 2:
		(*wpos ++) = (base64_tbl_decoding[rpos[0]] << 2 | base64_tbl_decoding[rpos[1]] >> 4);
		break;
	case 3:
		(*wpos ++) = (base64_tbl_decoding[rpos[0]] << 2 | base64_tbl_decoding[rpos[1]] >> 4);
		(*wpos ++) = (base64_tbl_decoding[rpos[1]] << 4 | base64_tbl_decoding[rpos[2]] >> 2);
		break;
	}
	(*wpos) = 0;
	if (NULL != dcd_size_ret) { /* Real decoded size can be smaller than calculated. */
		(*dcd_size_ret) = (wpos - dst);
	}

	return (0);
}

/* Copy only Base64 encoded symbols. */
static inline int
base64_en_copy(const uint8_t *src, uint8_t *dst,
    const size_t buf_size, size_t *new_size) {
	register const uint8_t *rpos, *src_max;
	register uint8_t *wpos, tmb;

	if (0 == buf_size) {
		if (NULL != new_size) {
			(*new_size) = 0;
		}
		return (0);
	}
	if (NULL == src || NULL == dst)
		return (EINVAL);
	wpos = dst;
	rpos = src;
	for (src_max = (src + buf_size); rpos < src_max; rpos ++) {
		tmb = (*rpos);
		if (64 == base64_tbl_decoding[tmb])
			continue;
		(*wpos ++) = tmb;
	}
	if (NULL != new_size) {
		(*new_size) = (wpos - dst);
	}

	return (0);
}


static inline int
base64_decode_fmt(const uint8_t *src, const size_t src_size,
    uint8_t *dst, size_t dst_size, size_t *dcd_size_ret) {
	int error;
	size_t src_size_real;

	if (src_size > dst_size)
		return (ENOBUFS);
	error = base64_en_copy(src, dst, src_size, &src_size_real);
	if (0 != error)
		return (error);

	return (base64_decode(dst, src_size_real, dst, dst_size, dcd_size_ret));
}


#ifdef BASE64_SELF_TEST

typedef struct base64_test_vectors_s {
	const char 	*decoded;
	size_t		decoded_size;
	const char 	*encoded;
	size_t		encoded_size;
} base64_tv_t, *base64_tv_p;


static base64_tv_t base64_tst[] = {
	{
		/*.decoded =*/		"",
		/*.decoded_size =*/	0,
		/*.encoded =*/		"",
		/*.encoded_size =*/	0,
	}, {
		/*.decoded =*/		"",
		/*.decoded_size =*/	0,
		/*.encoded =*/		"====",
		/*.encoded_size =*/	4,
	}, {
		/*.decoded =*/		"",
		/*.decoded_size =*/	0,
		/*.encoded =*/		"===",
		/*.encoded_size =*/	3,
	}, {
		/*.decoded =*/		"",
		/*.decoded_size =*/	0,
		/*.encoded =*/		"==",
		/*.encoded_size =*/	2,
	}, {
		/*.decoded =*/		"",
		/*.decoded_size =*/	0,
		/*.encoded =*/		"=",
		/*.encoded_size =*/	1,
	}, {
		/*.decoded =*/		"1",
		/*.decoded_size =*/	1,
		/*.encoded =*/		"MQ==",
		/*.encoded_size =*/	4,
	}, {
		/*.decoded =*/		"12",
		/*.decoded_size =*/	2,
		/*.encoded =*/		"MTI=",
		/*.encoded_size =*/	4,
	}, {
		/*.decoded =*/		"123",
		/*.decoded_size =*/	3,
		/*.encoded =*/		"MTIz",
		/*.encoded_size =*/	4,
	}, {
		/*.decoded =*/		"1234",
		/*.decoded_size =*/	4,
		/*.encoded =*/		"MTIzNA==",
		/*.encoded_size =*/	8,
	}, {
		/*.decoded =*/		"12345",
		/*.decoded_size =*/	5,
		/*.encoded =*/		"MTIzNDU=",
		/*.encoded_size =*/	8,
	}, {
		/*.decoded =*/		"123456",
		/*.decoded_size =*/	6,
		/*.encoded =*/		"MTIzNDU2",
		/*.encoded_size =*/	8,
	}, {
		/*.decoded =*/		"1234567",
		/*.decoded_size =*/	7,
		/*.encoded =*/		"MTIzNDU2Nw==",
		/*.encoded_size =*/	12,
	}, {
		/*.decoded =*/		"12345678",
		/*.decoded_size =*/	8,
		/*.encoded =*/		"MTIzNDU2Nzg=",
		/*.encoded_size =*/	12,
	}, {
		/*.decoded =*/		"123456789",
		/*.decoded_size =*/	9,
		/*.encoded =*/		"MTIzNDU2Nzg5",
		/*.encoded_size =*/	12,
	}, { /* https://www.rfc-editor.org/rfc/rfc4648 */
		/*.decoded =*/		"f",
		/*.decoded_size =*/	1,
		/*.encoded =*/		"Zg==",
		/*.encoded_size =*/	4,
	}, { /* https://www.rfc-editor.org/rfc/rfc4648 */
		/*.decoded =*/		"fo",
		/*.decoded_size =*/	2,
		/*.encoded =*/		"Zm8=",
		/*.encoded_size =*/	4,
	}, { /* https://www.rfc-editor.org/rfc/rfc4648 */
		/*.decoded =*/		"foo",
		/*.decoded_size =*/	3,
		/*.encoded =*/		"Zm9v",
		/*.encoded_size =*/	4,
	}, { /* https://www.rfc-editor.org/rfc/rfc4648 */
		/*.decoded =*/		"foob",
		/*.decoded_size =*/	4,
		/*.encoded =*/		"Zm9vYg==",
		/*.encoded_size =*/	8,
	}, { /* https://www.rfc-editor.org/rfc/rfc4648 */
		/*.decoded =*/		"fooba",
		/*.decoded_size =*/	5,
		/*.encoded =*/		"Zm9vYmE=",
		/*.encoded_size =*/	8,
	}, { /* https://www.rfc-editor.org/rfc/rfc4648 */
		/*.decoded =*/		"foobar",
		/*.decoded_size =*/	6,
		/*.encoded =*/		"Zm9vYmFy",
		/*.encoded_size =*/	8,
	}, { /* https://commons.apache.org/proper/commons-codec/xref-test/org/apache/commons/codec/binary/Base64Test.html */
		/*.decoded =*/		"The quick brown fox jumped over the lazy dogs.",
		/*.decoded_size =*/	46,
		/*.encoded =*/		"VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wZWQgb3ZlciB0aGUgbGF6eSBkb2dzLg==",
		/*.encoded_size =*/	64,
	}, { /* https://commons.apache.org/proper/commons-codec/xref-test/org/apache/commons/codec/binary/Base64Test.html */
		/*.decoded =*/		"It was the best of times, it was the worst of times.",
		/*.decoded_size =*/	52,
		/*.encoded =*/		"SXQgd2FzIHRoZSBiZXN0IG9mIHRpbWVzLCBpdCB3YXMgdGhlIHdvcnN0IG9mIHRpbWVzLg==",
		/*.encoded_size =*/	72,
	}, { /* https://commons.apache.org/proper/commons-codec/xref-test/org/apache/commons/codec/binary/Base64Test.html */
		/*.decoded =*/		"{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 }",
		/*.decoded_size =*/	32,
		/*.encoded =*/		"eyAwLCAxLCAyLCAzLCA0LCA1LCA2LCA3LCA4LCA5IH0=",
		/*.encoded_size =*/	44,
	}, { /* https://commons.apache.org/proper/commons-codec/xref-test/org/apache/commons/codec/binary/Base64Test.html */
		/*.decoded =*/		"xyzzy!",
		/*.decoded_size =*/	6,
		/*.encoded =*/		"eHl6enkh",
		/*.encoded_size =*/	8,
	}, { /* https://commons.apache.org/proper/commons-codec/xref-test/org/apache/commons/codec/binary/Base64Test.html */
		/*.decoded =*/		"Hello World",
		/*.decoded_size =*/	11,
		/*.encoded =*/		"SGVsbG8gV29ybGQ=",
		/*.encoded_size =*/	16,
	}
};

static base64_tv_t base64_tst_dec[] = {
	{ /* https://commons.apache.org/proper/commons-codec/xref-test/org/apache/commons/codec/binary/Base64Test.html */
		/*.decoded =*/		"The quick brown fox jumped over the lazy dogs.",
		/*.decoded_size =*/	46,
		/*.encoded =*/		"VGhlIH@$#$@%F1aWN@#@#@@rIGJyb3duIGZve\n\r\t%#%#%#%CBqd##$#$W1wZWQgb3ZlciB0aGUgbGF6eSBkb2dzLg==",
		/*.encoded_size =*/	91,
	}
};


/* 0 - OK, non zero - error */
static inline int
base64_self_test(void) {
	int error;
	size_t i, buf_size;
	uint8_t buf[4096];

	/* Test 1 - encode. */
	for (i = 0; i < nitems(base64_tst); i ++) {
		error = base64_encode((const uint8_t*)base64_tst[i].decoded,
		    base64_tst[i].decoded_size,
		    buf, sizeof(buf), &buf_size);
		if (0 != error)
			return (error);
		if (0 == base64_tst[i].decoded_size)
			continue;
		if (base64_tst[i].encoded_size != buf_size ||
		    0 != memcmp(buf, base64_tst[i].encoded, buf_size))
			return (-1);
	}

	/* Test 2 - decode. */
	for (i = 0; i < nitems(base64_tst); i ++) {
		error = base64_decode((const uint8_t*)base64_tst[i].encoded,
		    base64_tst[i].encoded_size,
		    buf, sizeof(buf), &buf_size);
		if (0 != error)
			return (error);
		if (base64_tst[i].decoded_size != buf_size ||
		    0 != memcmp(buf, base64_tst[i].decoded, buf_size))
			return (-1);
	}

	/* Test 3 - decode with possible extra chars. */
	for (i = 0; i < nitems(base64_tst); i ++) {
		error = base64_decode_fmt((const uint8_t*)base64_tst[i].encoded,
		    base64_tst[i].encoded_size,
		    buf, sizeof(buf), &buf_size);
		if (0 != error)
			return (error);
		if (base64_tst[i].decoded_size != buf_size ||
		    0 != memcmp(buf, base64_tst[i].decoded, buf_size))
			return (-1);
	}

	/* Test 4 - decode with extra chars. */
	for (i = 0; i < nitems(base64_tst_dec); i ++) {
		error = base64_decode_fmt((const uint8_t*)base64_tst_dec[i].encoded,
		    base64_tst_dec[i].encoded_size,
		    buf, sizeof(buf), &buf_size);
		if (0 != error)
			return (error);
		if (base64_tst_dec[i].decoded_size != buf_size ||
		    0 != memcmp(buf, base64_tst_dec[i].decoded, buf_size))
			return (-1);
	}

	return (0);
}
#endif


#endif /* __BASE64_H__ */
