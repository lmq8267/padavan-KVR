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

 
// see
// RFC 1321 - MD5 (code base!)
// RFC 3174 - SHA1
// RFC 4634, RFC 6234 - SHA1, SHA2
// RFC 2104 - HMAC
// https://github.com/randombit/botan

/*
 *  Description:
 *      This file implements the Secure Hashing Algorithm 1 as
 *      defined in FIPS PUB 180-1 published April 17, 1995.
 *
 *      The SHA-1, produces a 160-bit message digest for a given
 *      data stream.  It should take about 2**n steps to find a
 *      message with the same digest as a given message and
 *      2**(n/2) to find any two messages with the same digest, 
 *      when n is the digest size in bits.  Therefore, this
 *      algorithm can serve as a means of providing a
 *      "fingerprint" for a message.
 *
 *  Portability Issues:
 *      SHA-1 is defined in terms of 32-bit "words".  This code
 *      uses <stdint.h> (included via "sha1.h" to define 32 and 8
 *      bit unsigned integer types.  If your C compiler does not
 *      support 32 bit unsigned integers, this code is not
 *      appropriate.
 *
 *  Caveats:
 *      SHA-1 is designed to work with messages less than 2^64 bits
 *      long.  Although SHA-1 allows a message digest to be generated
 *      for messages of any number of bits less than 2^64, this
 *      implementation only works with messages with a length that is
 *      a multiple of the size of an 8-bit character.
 */

#ifndef __SHA1_H__INCLUDED__
#define __SHA1_H__INCLUDED__

#include <sys/param.h>
#include <sys/types.h>
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <inttypes.h>
#ifdef __SSE2__
#	include <cpuid.h>
#	include <xmmintrin.h> /* SSE */
#	include <emmintrin.h> /* SSE2 */
#	include <pmmintrin.h> /* SSE3 */
#	include <tmmintrin.h> /* SSSE3 */
#	include <smmintrin.h> /* SSE4.1 */
#	include <nmmintrin.h> /* SSE4.2 */
#	include <immintrin.h> /* AVX */
#endif

#ifndef bswap64
#	define bswap64		__builtin_bswap64
#endif

#ifndef nitems /* SIZEOF() */
#	define nitems(__val)	(sizeof(__val) / sizeof(__val[0]))
#endif

#if defined(__SHA__) && defined(__SSSE3__) && defined(__SSE4_1__)
#	include <shaintrin.h>
#	define SHA1_ENABLE_SIMD	1
#endif

#if defined(_MSC_VER) || defined(__INTEL_COMPILER)
#	define SHA1_ALIGN(__n)	__declspec(align(__n)) /* DECLSPEC_ALIGN() */
#else /* GCC/clang */
#	define SHA1_ALIGN(__n)	__attribute__ ((aligned(__n)))
#endif

static void *(*volatile sha1_memset_volatile)(void*, int, size_t) = memset;
#define sha1_bzero(__mem, __size)	sha1_memset_volatile((__mem), 0x00, (__size))


/* HASH constants. */
#define SHA1_HASH_SIZE		((size_t)20) /* 160 bit */
#define SHA1_HASH_STR_SIZE	(SHA1_HASH_SIZE * 2)
#define SHA1_MSG_BLK_SIZE	((size_t)64) /* 512 bit */
#define SHA1_MSG_BLK_SIZE_MASK	(SHA1_MSG_BLK_SIZE - 1)
#define SHA1_MSG_BLK_64CNT	(SHA1_MSG_BLK_SIZE / sizeof(uint64_t)) /* 16 */


/* Define the SHA1 circular left shift macro. */
#define SHA1_ROTL(__n, __word)	(((__word) << (__n)) | ((__word) >> (32 - (__n))))

#define SHA1_Ch(__x, __y, __z)	(((__x) & (__y)) | ((~(__x)) & (__z)))
#define SHA1_Maj(__x, __y, __z)	(((__x) & (__y)) | ((__x) & (__z)) | ((__y) & (__z)))
/* From RFC 4634. */
//#define SHA1_Ch(__x, __y, __z)	(((__x) & (__y)) ^ ((~(__x)) & (__z)))
//#define SHA1_Maj(__x, __y, __z)	(((__x) & (__y)) ^ ((__x) & (__z)) ^ ((__y) & (__z)))
/* The following definitions are equivalent and potentially faster. */
//#define SHA1_Ch(__x, __y, __z)	(((__x) & ((__y) ^ (__z))) ^ (__z))
//#define SHA1_Maj(__x, __y, __z)	(((__x) & ((__y) | (__z))) | ((__y) & (__z)))
#define SHA1_Parity(__x, __y, __z)	((__x) ^ (__y) ^ (__z))


/* This structure will hold context information for the SHA-1 hashing operation. */
typedef struct sha1_ctx_s {
	uint64_t count; /* Number of bits, modulo 2^64 (lsb first). */
	SHA1_ALIGN(32) uint32_t hash[(SHA1_HASH_SIZE / sizeof(uint32_t))]; /* State (ABCDE) / Message Digest. */
	SHA1_ALIGN(32) uint64_t buffer[SHA1_MSG_BLK_64CNT]; /* Input buffer: 512-bit message blocks. */
	SHA1_ALIGN(32) uint32_t W[80]; /* Temp buf for sha1_transform(). */
#ifdef __SSE2__
	int use_sse; /* SSE2+ transform. */
#endif
#ifdef SHA1_ENABLE_SIMD
	int use_simd; /* SHA SIMD tansform. */
#endif
} sha1_ctx_t, *sha1_ctx_p;

typedef struct hmac_sha1_ctx_s {
	sha1_ctx_t ctx;
	SHA1_ALIGN(32) uint64_t k_opad[SHA1_MSG_BLK_64CNT]; /* outer padding - key XORd with opad. */
} hmac_sha1_ctx_t, *hmac_sha1_ctx_p;



static inline void
sha1_memcpy_bswap(uint8_t *dst, const uint8_t *src, size_t size) {
	register size_t i;

#pragma unroll
	for (i = 0; i < size; i += 4) {
		dst[(i + 0)] = src[(i + 3)];
		dst[(i + 1)] = src[(i + 2)];
		dst[(i + 2)] = src[(i + 1)];
		dst[(i + 3)] = src[(i + 0)];
	}
}

/*
 *  sha1_init
 *
 *  Description:
 *      This function will initialize the sha1_ctx in preparation
 *      for computing a new SHA1 message digest.
 *
 *  Parameters:
 *      ctx: [in/out]
 *          The ctx to reset.
 */
static inline void
sha1_init(sha1_ctx_p ctx) {
#if defined(__SSE2__) || defined(SHA1_ENABLE_SIMD)
	uint32_t eax, ebx, ecx, edx;
#endif

	/* Initial Hash Values: magic initialization constants. */
	ctx->hash[0] = 0x67452301;
	ctx->hash[1] = 0xefcdab89;
	ctx->hash[2] = 0x98badcfe;
	ctx->hash[3] = 0x10325476;
	ctx->hash[4] = 0xc3d2e1f0;
	ctx->count = 0;

#ifdef __SSE2__
	__get_cpuid_count(1, 0, &eax, &ebx, &ecx, &edx);
	ctx->use_sse = 0;
#	ifdef __SSE4_1__
		ctx->use_sse |= (ecx & (((uint32_t)1) << 19));
#	elif defined(__SSSE3__)
		ctx->use_sse |= (ecx & (((uint32_t)1) <<  9));
#	elif defined(__SSE3__)
		ctx->use_sse |= (ecx & (((uint32_t)1) <<  0));
#	elif defined(__SSE2__)
		ctx->use_sse |= (edx & (((uint32_t)1) << 26));
#	endif
#endif
#ifdef SHA1_ENABLE_SIMD
	__get_cpuid_count(7, 0, &eax, &ebx, &ecx, &edx);
	ctx->use_simd = (ebx & (((uint32_t)1) << 29));
#endif
}

/*
 *  sha1_transform
 *
 *  Description:
 *      This function will process the next 512 bits of the message
 *      stored in the buffer array.
 *
 *  Parameters:
 *      None.
 *
 *  Comments:
 *      Many of the variable names in this code, especially the
 *      single character names, were used because those were the
 *      names used in the publication.
 */
static inline void
sha1_transform_generic(sha1_ctx_p ctx, const uint8_t *blocks, const uint8_t *blocks_max) {
	/* Constants defined in SHA-1. */
	const uint32_t K[] = { 0x5a827999, 0x6ed9eba1, 0x8f1bbcdc, 0xca62c1d6 };
	register size_t t; /* Loop counter. */
	register uint32_t temp; /* Temporary word value. */
	register uint32_t A, B, C, D, E; /* Word buffers. */
	uint32_t *W, *hash; /* Word sequence. */

	W = ctx->W;
	hash = ctx->hash;
	A = hash[0];
	B = hash[1];
	C = hash[2];
	D = hash[3];
	E = hash[4];

	for (; blocks < blocks_max; blocks += SHA1_MSG_BLK_SIZE) {
		/* Initialize the first 16 words in the array W */
		sha1_memcpy_bswap((uint8_t*)W, blocks, SHA1_MSG_BLK_SIZE);

#pragma unroll
		for (t = 16; t < 80; t ++) {
			W[t] = SHA1_ROTL(1, W[(t - 3)] ^ W[(t - 8)] ^ W[(t - 14)] ^ W[(t - 16)]);
		}

#pragma unroll
		for (t = 0; t < 20; t ++) {
			temp = SHA1_ROTL(5, A) + SHA1_Ch(B, C, D) + E + W[t] + K[0];
			E = D;
			D = C;
			C = SHA1_ROTL(30, B);
			B = A;
			A = temp;
		}

#pragma unroll
		for (t = 20; t < 40; t ++) {
			temp = SHA1_ROTL(5, A) + SHA1_Parity(B, C, D) + E + W[t] + K[1];
			E = D;
			D = C;
			C = SHA1_ROTL(30, B);
			B = A;
			A = temp;
		}

#pragma unroll
		for (t = 40; t < 60; t ++) {
			temp = SHA1_ROTL(5, A) + SHA1_Maj(B, C, D) + E + W[t] + K[2];
			E = D;
			D = C;
			C = SHA1_ROTL(30, B);
			B = A;
			A = temp;
		}

#pragma unroll
		for (t = 60; t < 80; t ++) {
			temp = SHA1_ROTL(5, A) + SHA1_Parity(B, C, D) + E + W[t] + K[3];
			E = D;
			D = C;
			C = SHA1_ROTL(30, B);
			B = A;
			A = temp;
		}

		A = (hash[0] += A);
		B = (hash[1] += B);
		C = (hash[2] += C);
		D = (hash[3] += D);
		E = (hash[4] += E);
	}
}


#ifdef __SSE2__

#define SHA1_SSE_LOADU(__ptr, __xmm0, __xmm1, __xmm2, __xmm3) do { 	\
	__xmm0 = _mm_loadu_si128(&((const __m128i*)(const void*)(__ptr))[0]); \
	__xmm1 = _mm_loadu_si128(&((const __m128i*)(const void*)(__ptr))[1]); \
	__xmm2 = _mm_loadu_si128(&((const __m128i*)(const void*)(__ptr))[2]); \
	__xmm3 = _mm_loadu_si128(&((const __m128i*)(const void*)(__ptr))[3]); \
} while (0)
#ifdef __SSE4_1__ /* SSE4.1 required. */
#define SHA1_SSE_STREAM_LOAD(__ptr, __xmm0, __xmm1, __xmm2, __xmm3) do { \
	__xmm0 = _mm_stream_load_si128(&((const __m128i*)(const void*)(__ptr))[0]); \
	__xmm1 = _mm_stream_load_si128(&((const __m128i*)(const void*)(__ptr))[1]); \
	__xmm2 = _mm_stream_load_si128(&((const __m128i*)(const void*)(__ptr))[2]); \
	__xmm3 = _mm_stream_load_si128(&((const __m128i*)(const void*)(__ptr))[3]); \
} while (0)
#endif


#ifdef __SSSE3__ /* SSSE3 required. */
#define _mm_bswap_epi32(__x) do {					\
	(__x) = _mm_shuffle_epi8((__x), _mm_set_epi8(			\
	    12, 13, 14, 15, 8,  9, 10, 11,				\
	    4,  5,  6,  7, 0,  1,  2,  3)); 				\
} while (0)
#else
#define _mm_bswap_epi32(__x) do {					\
	(__x) = _mm_shufflehi_epi16((__x), _MM_SHUFFLE(2, 3, 0, 1));	\
	(__x) = _mm_shufflelo_epi16((__x), _MM_SHUFFLE(2, 3, 0, 1));	\
	(__x) = _mm_or_si128(_mm_slli_epi16((__x), 8), _mm_srli_epi16((__x), 8)); \
} while (0)
#endif

/*
 * First 16 bytes just need byte swapping. Preparing just means
 * adding in the round constants.
 */
#define SHA1_PREP00_15(__p, __w, __k) do {				\
	_mm_bswap_epi32((__w));						\
	(__p) = _mm_add_epi32((__w), (__k));				\
} while (0)

#define SHA1_PREP(__prep, __xw0, __xw1, __xw2, __xw3, __k) do {		\
	__m128i r0, r1, r2, r3;						\
									\
	/* get high 64-bits of __xw0 into low 64-bits */		\
	r1 = _mm_shuffle_epi32((__xw0), _MM_SHUFFLE(1, 0, 3, 2));	\
	/* load high 64-bits of r1 */					\
	r1 = _mm_unpacklo_epi64(r1, (__xw1));				\
	/* load W[t-4] 16-byte aligned, and shift */			\
	r3 = _mm_srli_si128((__xw3), 4);				\
									\
	r0 = _mm_xor_si128(r1, (__xw0));				\
	r2 = _mm_xor_si128(r3, (__xw2));				\
	r0 = _mm_xor_si128(r2, r0);					\
	/* unrotated W[t]..W[t+2] in r0 ... still need W[t+3] */	\
									\
	r2 = _mm_slli_si128(r0, 12);					\
	r1 = _mm_cmplt_epi32(r0, _mm_setzero_si128());			\
	r0 = _mm_add_epi32(r0, r0); /* shift left by 1 */		\
	r0 = _mm_sub_epi32(r0, r1); /* r0 has W[t]..W[t+2] */		\
									\
	r3 = _mm_srli_epi32(r2, 30);					\
	r2 = _mm_slli_epi32(r2, 2);					\
									\
	r0 = _mm_xor_si128(r0, r3);					\
	r0 = _mm_xor_si128(r0, r2); /* r0 now has W[t+3] */		\
									\
	(__xw0) = r0;							\
	(__prep) = _mm_add_epi32(r0, (__k));				\
} while (0)

/* SHA-160 F Functions. */
#define SHA1_F1(__a, __b, __c, __d, __e, __msg) do {			\
	(__e) += (((__d) ^ ((__b) & ((__c) ^ (__d)))) + (__msg) + SHA1_ROTL(5, (__a))); \
	(__b)  = SHA1_ROTL(30, (__b));					\
} while (0)

#define SHA1_F2(__a, __b, __c, __d, __e, __msg) do {			\
	(__e) += (((__b) ^ (__c) ^ (__d)) + (__msg) + SHA1_ROTL(5, (__a))); \
	(__b)  = SHA1_ROTL(30, (__b));					\
} while (0)

#define SHA1_F3(__a, __b, __c, __d, __e, __msg) do {			\
	(__e) += ((((__b) & (__c)) | (((__b) | (__c)) & (__d))) + (__msg) + SHA1_ROTL(5, (__a))); \
	(__b)  = SHA1_ROTL(30, (__b));					\
} while (0)

#define SHA1_F4(__a, __b, __c, __d, __e, __msg) do {			\
	(__e) += (((__b) ^ (__c) ^ (__d)) + (__msg) + SHA1_ROTL(5, (__a))); \
	(__b)  = SHA1_ROTL(30, (__b));					\
} while (0)

/*
* SHA-160 Compression Function using SSE for message expansion
*/
static inline void
sha1_transform_sse(sha1_ctx_p ctx, const uint8_t *blocks, const uint8_t *blocks_max) {
	const __m128i K00_19 = _mm_set1_epi32((int32_t)0x5a827999);
	const __m128i K20_39 = _mm_set1_epi32((int32_t)0x6ed9eba1);
	const __m128i K40_59 = _mm_set1_epi32((int32_t)0x8f1bbcdc);
	const __m128i K60_79 = _mm_set1_epi32((int32_t)0xca62c1d6);
	__m128i W0, W1, W2, W3;
	__m128i P0, P1, P2, P3;
	register uint32_t A, B, C, D, E; /* Word buffers. */
	uint32_t *hash;
	union sha1_v4si_u {
		uint32_t u32[4];
		__m128i u128;
	};
	/* Using SSE4; slower on Core2 and Nehalem
	 * #define SHA1_GET_P_32(__P, __i) _mm_extract_epi32((__P), (__i))
	 * Much slower on all tested platforms
	 * #define SHA1_GET_P_32(__P, __i) _mm_cvtsi128_si32(_mm_srli_si128((__P), ((__i) * 4)))
	 */
	//#define SHA1_GET_P_32(__P, __i) ((union sha1_v4si_u)(__P)).u32[(__i)]
	#define SHA1_GET_P_32(__P, __i) (uint32_t)_mm_extract_epi32((__P), (__i))

	hash = ctx->hash;
	A = hash[0];
	B = hash[1];
	C = hash[2];
	D = hash[3];
	E = hash[4];

	for (; blocks < blocks_max; blocks += SHA1_MSG_BLK_SIZE) {
#ifdef __SSE4_1__ /* SSE4.1 required. */
		if (0 == (((size_t)blocks) & 15)) { /* 16 byte alligned. */
			SHA1_SSE_STREAM_LOAD(blocks, W0, W1, W2, W3);
		} else 
#endif
		{ /* Unaligned. */
			SHA1_SSE_LOADU(blocks, W0, W1, W2, W3);
			/* Shedule to load into cache. */
			if ((blocks + (SHA1_MSG_BLK_SIZE * 8)) < blocks_max) {
				_mm_prefetch((const char*)(blocks + (SHA1_MSG_BLK_SIZE * 8)), _MM_HINT_T0);
			}
		}

		SHA1_PREP00_15(P0, W0, K00_19);
		SHA1_PREP00_15(P1, W1, K00_19);
		SHA1_PREP00_15(P2, W2, K00_19);
		SHA1_PREP00_15(P3, W3, K00_19);

		SHA1_F1(A, B, C, D, E, SHA1_GET_P_32(P0, 0));
		SHA1_F1(E, A, B, C, D, SHA1_GET_P_32(P0, 1));
		SHA1_F1(D, E, A, B, C, SHA1_GET_P_32(P0, 2));
		SHA1_F1(C, D, E, A, B, SHA1_GET_P_32(P0, 3));
		SHA1_PREP(P0, W0, W1, W2, W3, K00_19);

		SHA1_F1(B, C, D, E, A, SHA1_GET_P_32(P1, 0));
		SHA1_F1(A, B, C, D, E, SHA1_GET_P_32(P1, 1));
		SHA1_F1(E, A, B, C, D, SHA1_GET_P_32(P1, 2));
		SHA1_F1(D, E, A, B, C, SHA1_GET_P_32(P1, 3));
		SHA1_PREP(P1, W1, W2, W3, W0, K20_39);

		SHA1_F1(C, D, E, A, B, SHA1_GET_P_32(P2, 0));
		SHA1_F1(B, C, D, E, A, SHA1_GET_P_32(P2, 1));
		SHA1_F1(A, B, C, D, E, SHA1_GET_P_32(P2, 2));
		SHA1_F1(E, A, B, C, D, SHA1_GET_P_32(P2, 3));
		SHA1_PREP(P2, W2, W3, W0, W1, K20_39);

		SHA1_F1(D, E, A, B, C, SHA1_GET_P_32(P3, 0));
		SHA1_F1(C, D, E, A, B, SHA1_GET_P_32(P3, 1));
		SHA1_F1(B, C, D, E, A, SHA1_GET_P_32(P3, 2));
		SHA1_F1(A, B, C, D, E, SHA1_GET_P_32(P3, 3));
		SHA1_PREP(P3, W3, W0, W1, W2, K20_39);

		SHA1_F1(E, A, B, C, D, SHA1_GET_P_32(P0, 0));
		SHA1_F1(D, E, A, B, C, SHA1_GET_P_32(P0, 1));
		SHA1_F1(C, D, E, A, B, SHA1_GET_P_32(P0, 2));
		SHA1_F1(B, C, D, E, A, SHA1_GET_P_32(P0, 3));
		SHA1_PREP(P0, W0, W1, W2, W3, K20_39);

		SHA1_F2(A, B, C, D, E, SHA1_GET_P_32(P1, 0));
		SHA1_F2(E, A, B, C, D, SHA1_GET_P_32(P1, 1));
		SHA1_F2(D, E, A, B, C, SHA1_GET_P_32(P1, 2));
		SHA1_F2(C, D, E, A, B, SHA1_GET_P_32(P1, 3));
		SHA1_PREP(P1, W1, W2, W3, W0, K20_39);

		SHA1_F2(B, C, D, E, A, SHA1_GET_P_32(P2, 0));
		SHA1_F2(A, B, C, D, E, SHA1_GET_P_32(P2, 1));
		SHA1_F2(E, A, B, C, D, SHA1_GET_P_32(P2, 2));
		SHA1_F2(D, E, A, B, C, SHA1_GET_P_32(P2, 3));
		SHA1_PREP(P2, W2, W3, W0, W1, K40_59);

		SHA1_F2(C, D, E, A, B, SHA1_GET_P_32(P3, 0));
		SHA1_F2(B, C, D, E, A, SHA1_GET_P_32(P3, 1));
		SHA1_F2(A, B, C, D, E, SHA1_GET_P_32(P3, 2));
		SHA1_F2(E, A, B, C, D, SHA1_GET_P_32(P3, 3));
		SHA1_PREP(P3, W3, W0, W1, W2, K40_59);

		SHA1_F2(D, E, A, B, C, SHA1_GET_P_32(P0, 0));
		SHA1_F2(C, D, E, A, B, SHA1_GET_P_32(P0, 1));
		SHA1_F2(B, C, D, E, A, SHA1_GET_P_32(P0, 2));
		SHA1_F2(A, B, C, D, E, SHA1_GET_P_32(P0, 3));
		SHA1_PREP(P0, W0, W1, W2, W3, K40_59);

		SHA1_F2(E, A, B, C, D, SHA1_GET_P_32(P1, 0));
		SHA1_F2(D, E, A, B, C, SHA1_GET_P_32(P1, 1));
		SHA1_F2(C, D, E, A, B, SHA1_GET_P_32(P1, 2));
		SHA1_F2(B, C, D, E, A, SHA1_GET_P_32(P1, 3));
		SHA1_PREP(P1, W1, W2, W3, W0, K40_59);

		SHA1_F3(A, B, C, D, E, SHA1_GET_P_32(P2, 0));
		SHA1_F3(E, A, B, C, D, SHA1_GET_P_32(P2, 1));
		SHA1_F3(D, E, A, B, C, SHA1_GET_P_32(P2, 2));
		SHA1_F3(C, D, E, A, B, SHA1_GET_P_32(P2, 3));
		SHA1_PREP(P2, W2, W3, W0, W1, K40_59);

		SHA1_F3(B, C, D, E, A, SHA1_GET_P_32(P3, 0));
		SHA1_F3(A, B, C, D, E, SHA1_GET_P_32(P3, 1));
		SHA1_F3(E, A, B, C, D, SHA1_GET_P_32(P3, 2));
		SHA1_F3(D, E, A, B, C, SHA1_GET_P_32(P3, 3));
		SHA1_PREP(P3, W3, W0, W1, W2, K60_79);

		SHA1_F3(C, D, E, A, B, SHA1_GET_P_32(P0, 0));
		SHA1_F3(B, C, D, E, A, SHA1_GET_P_32(P0, 1));
		SHA1_F3(A, B, C, D, E, SHA1_GET_P_32(P0, 2));
		SHA1_F3(E, A, B, C, D, SHA1_GET_P_32(P0, 3));
		SHA1_PREP(P0, W0, W1, W2, W3, K60_79);

		SHA1_F3(D, E, A, B, C, SHA1_GET_P_32(P1, 0));
		SHA1_F3(C, D, E, A, B, SHA1_GET_P_32(P1, 1));
		SHA1_F3(B, C, D, E, A, SHA1_GET_P_32(P1, 2));
		SHA1_F3(A, B, C, D, E, SHA1_GET_P_32(P1, 3));
		SHA1_PREP(P1, W1, W2, W3, W0, K60_79);

		SHA1_F3(E, A, B, C, D, SHA1_GET_P_32(P2, 0));
		SHA1_F3(D, E, A, B, C, SHA1_GET_P_32(P2, 1));
		SHA1_F3(C, D, E, A, B, SHA1_GET_P_32(P2, 2));
		SHA1_F3(B, C, D, E, A, SHA1_GET_P_32(P2, 3));
		SHA1_PREP(P2, W2, W3, W0, W1, K60_79);

		SHA1_F4(A, B, C, D, E, SHA1_GET_P_32(P3, 0));
		SHA1_F4(E, A, B, C, D, SHA1_GET_P_32(P3, 1));
		SHA1_F4(D, E, A, B, C, SHA1_GET_P_32(P3, 2));
		SHA1_F4(C, D, E, A, B, SHA1_GET_P_32(P3, 3));
		SHA1_PREP(P3, W3, W0, W1, W2, K60_79);

		SHA1_F4(B, C, D, E, A, SHA1_GET_P_32(P0, 0));
		SHA1_F4(A, B, C, D, E, SHA1_GET_P_32(P0, 1));
		SHA1_F4(E, A, B, C, D, SHA1_GET_P_32(P0, 2));
		SHA1_F4(D, E, A, B, C, SHA1_GET_P_32(P0, 3));

		SHA1_F4(C, D, E, A, B, SHA1_GET_P_32(P1, 0));
		SHA1_F4(B, C, D, E, A, SHA1_GET_P_32(P1, 1));
		SHA1_F4(A, B, C, D, E, SHA1_GET_P_32(P1, 2));
		SHA1_F4(E, A, B, C, D, SHA1_GET_P_32(P1, 3));

		SHA1_F4(D, E, A, B, C, SHA1_GET_P_32(P2, 0));
		SHA1_F4(C, D, E, A, B, SHA1_GET_P_32(P2, 1));
		SHA1_F4(B, C, D, E, A, SHA1_GET_P_32(P2, 2));
		SHA1_F4(A, B, C, D, E, SHA1_GET_P_32(P2, 3));

		SHA1_F4(E, A, B, C, D, SHA1_GET_P_32(P3, 0));
		SHA1_F4(D, E, A, B, C, SHA1_GET_P_32(P3, 1));
		SHA1_F4(C, D, E, A, B, SHA1_GET_P_32(P3, 2));
		SHA1_F4(B, C, D, E, A, SHA1_GET_P_32(P3, 3));

		A = (hash[0] += A);
		B = (hash[1] += B);
		C = (hash[2] += C);
		D = (hash[3] += D);
		E = (hash[4] += E);
	}
	/* Restore the Floating-point status on the CPU. */
	_mm_empty();
}
#endif

#ifdef SHA1_ENABLE_SIMD
static inline void
sha1_transform_simd(sha1_ctx_p ctx, const uint8_t *blocks, const uint8_t *blocks_max) {
	const __m128i MASK = _mm_set_epi64x(0x0001020304050607ull, 0x08090a0b0c0d0e0full);
	__m128i ABCD, ABCD_SAVE, E0, E0_SAVE, E1;
	__m128i MSG0, MSG1, MSG2, MSG3;

	/* Load initial values. */
	ABCD = _mm_shuffle_epi32(_mm_loadu_si128((const __m128i*)(const void*)ctx->hash), 0x1b);
	E0 = (__m128i)_mm_set_epi32((int32_t)ctx->hash[4], 0, 0, 0);

	for (; blocks < blocks_max; blocks += SHA1_MSG_BLK_SIZE) {
#ifdef __SSE4_1__ /* SSE4.1 required. */
		if (0 == (((size_t)blocks) & 15)) { /* 16 byte alligned. */
			SHA1_SSE_STREAM_LOAD(blocks, MSG0, MSG1, MSG2, MSG3);
		} else 
#endif
		{ /* Unaligned. */
			SHA1_SSE_LOADU(blocks, MSG0, MSG1, MSG2, MSG3);
			/* Shedule to load into cache. */
			if ((blocks + (SHA1_MSG_BLK_SIZE * 8)) < blocks_max) {
				_mm_prefetch((const char*)(blocks + (SHA1_MSG_BLK_SIZE * 8)), _MM_HINT_T0);
			}
		}

		/* Save current hash. */
		ABCD_SAVE = ABCD;
		E0_SAVE = E0;

		MSG0 = _mm_shuffle_epi8(MSG0, MASK);
		MSG1 = _mm_shuffle_epi8(MSG1, MASK);
		MSG2 = _mm_shuffle_epi8(MSG2, MASK);
		MSG3 = _mm_shuffle_epi8(MSG3, MASK);

		/* Rounds 0-3 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_add_epi32(E0, MSG0), 0);

		/* Rounds 4-7 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG1), 0);
		MSG0 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG0, MSG1), MSG2);

		/* Rounds 8-11 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG2), 0);
		MSG1 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG1, MSG2), MSG3);

		/* Rounds 12-15 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG3), 0);
		MSG0 = _mm_sha1msg2_epu32(MSG0, MSG3);
		MSG2 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG2, MSG3), MSG0);

		/* Rounds 16-19 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG0), 0);
		MSG1 = _mm_sha1msg2_epu32(MSG1, MSG0);
		MSG3 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG3, MSG0), MSG1);

		/* Rounds 20-23 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG1), 1);
		MSG2 = _mm_sha1msg2_epu32(MSG2, MSG1);
		MSG0 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG0, MSG1), MSG2);

		/* Rounds 24-27 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG2), 1);
		MSG3 = _mm_sha1msg2_epu32(MSG3, MSG2);
		MSG1 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG1, MSG2), MSG3);

		/* Rounds 28-31 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG3), 1);
		MSG0 = _mm_sha1msg2_epu32(MSG0, MSG3);
		MSG2 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG2, MSG3), MSG0);

		/* Rounds 32-35 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG0), 1);
		MSG1 = _mm_sha1msg2_epu32(MSG1, MSG0);
		MSG3 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG3, MSG0), MSG1);

		/* Rounds 36-39 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG1), 1);
		MSG2 = _mm_sha1msg2_epu32(MSG2, MSG1);
		MSG0 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG0, MSG1), MSG2);

		/* Rounds 40-43 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG2), 2);
		MSG3 = _mm_sha1msg2_epu32(MSG3, MSG2);
		MSG1 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG1, MSG2), MSG3);

		/* Rounds 44-47 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG3), 2);
		MSG0 = _mm_sha1msg2_epu32(MSG0, MSG3);
		MSG2 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG2, MSG3), MSG0);

		/* Rounds 48-51 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG0), 2);
		MSG1 = _mm_sha1msg2_epu32(MSG1, MSG0);
		MSG3 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG3, MSG0), MSG1);

		/* Rounds 52-55 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG1), 2);
		MSG2 = _mm_sha1msg2_epu32(MSG2, MSG1);
		MSG0 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG0, MSG1), MSG2);

		/* Rounds 56-59 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG2), 2);
		MSG3 = _mm_sha1msg2_epu32(MSG3, MSG2);
		MSG1 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG1, MSG2), MSG3);

		/* Rounds 60-63 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG3), 3);
		MSG0 = _mm_sha1msg2_epu32(MSG0, MSG3);
		MSG2 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG2, MSG3), MSG0);

		/* Rounds 64-67 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG0), 3);
		MSG1 = _mm_sha1msg2_epu32(MSG1, MSG0);
		MSG3 = _mm_xor_si128(_mm_sha1msg1_epu32(MSG3, MSG0), MSG1);

		/* Rounds 68-71 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG1), 3);
		MSG2 = _mm_sha1msg2_epu32(MSG2, MSG1);

		/* Rounds 72-75 */
		E1 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E0, MSG2), 3);
		MSG3 = _mm_sha1msg2_epu32(MSG3, MSG2);

		/* Rounds 76-79 */
		E0 = ABCD;
		ABCD = (__m128i)_mm_sha1rnds4_epu32(ABCD, _mm_sha1nexte_epu32(E1, MSG3), 3);

		/* Add values back to state */
		E0 = _mm_sha1nexte_epu32(E0, E0_SAVE);
		ABCD = _mm_add_epi32(ABCD, ABCD_SAVE);
	}

	/* Save state. */
	ABCD = _mm_shuffle_epi32(ABCD, 0x1b);
	_mm_storeu_si128((__m128i*)(void*)ctx->hash, ABCD);
	ctx->hash[4] = (uint32_t)_mm_extract_epi32(E0, 3);

	/* Restore the Floating-point status on the CPU. */
	_mm_empty();
}
#endif

static inline void
sha1_transform(sha1_ctx_p ctx, const uint8_t *blocks, const uint8_t *blocks_max) {

#ifdef SHA1_ENABLE_SIMD
	if (0 != ctx->use_simd) {
		sha1_transform_simd(ctx, blocks, blocks_max);
		return;
	}
#endif
#ifdef __SSE2__
	if (0 != ctx->use_sse) {
		sha1_transform_sse(ctx, blocks, blocks_max);
		return;
	}
#endif
	sha1_transform_generic(ctx, blocks, blocks_max);
}


/*
 *  sha1_update
 *
 *  Description:
 *      This function accepts an array of octets as the next portion
 *      of the message.
 *
 *  Parameters:
 *      ctx: [in/out]
 *          The SHA ctx to update
 *      message_array: [in]
 *          An array of characters representing the next portion of
 *          the message.
 *      length: [in]
 *          The length of the message in message_array
 */
static inline void
sha1_update(sha1_ctx_p ctx, const uint8_t *data, size_t data_size) {
	size_t buffer_usage, part_size;

	if (0 == data_size)
		return;
	/* Compute number of bytes mod 64. */
	buffer_usage = (ctx->count & SHA1_MSG_BLK_SIZE_MASK);
	part_size = (SHA1_MSG_BLK_SIZE - buffer_usage);
	/* Update number of bits. */
	ctx->count += data_size;
	/* Transform as many times as possible. */
	if (part_size <= data_size) {
		if (0 != buffer_usage) { /* Add data to buffer and process it. */
			memcpy((((uint8_t*)ctx->buffer) + buffer_usage), data, part_size);
			buffer_usage = 0;
			data += part_size;
			data_size -= part_size;
			sha1_transform(ctx, (uint8_t*)ctx->buffer,
			    (((uint8_t*)ctx->buffer) + SHA1_MSG_BLK_SIZE));
		}
		if (SHA1_MSG_BLK_SIZE <= data_size) {
			sha1_transform(ctx, data,
			    (data + (data_size & ~SHA1_MSG_BLK_SIZE_MASK)));
			data += (data_size & ~SHA1_MSG_BLK_SIZE_MASK);
			data_size &= SHA1_MSG_BLK_SIZE_MASK;
		}
	}
	/* Buffer remaining data. */
	memcpy((((uint8_t*)ctx->buffer) + buffer_usage), data, data_size);
}

/*
 *  sha1_final
 *
 *  Description:
 *      According to the standard, the message must be padded to an even
 *      512 bits.  The first padding bit must be a '1'.  The last 64
 *      bits represent the length of the original message.  All bits in
 *      between should be 0.  This function will pad the message
 *      according to those rules by filling the buffer array
 *      accordingly.  It will also call the ProcessMessageBlock function
 *      provided appropriately.  When it returns, it can be assumed that
 *      the message digest has been computed.
 *      This function will return the 160-bit message digest into the
 *      digest array  provided by the caller.
 *      NOTE: The first octet of hash is stored in the 0th element, 
 *            the last octet of hash in the 19th element.
 *
 *  Parameters:
 *      ctx: [in/out]
 *          The ctx to use to calculate the SHA-1 hash.
 *      digest: [out]
 *          Where the digest is returned.
 */
static inline void
sha1_final(sha1_ctx_p ctx, uint8_t *digest) {
	size_t buffer_usage;

	/* Compute number of bytes mod 64. */
	buffer_usage = (ctx->count & SHA1_MSG_BLK_SIZE_MASK);
	((uint8_t*)ctx->buffer)[buffer_usage ++] = 0x80; /* Padding... */
	if ((SHA1_MSG_BLK_SIZE - 8) < buffer_usage) { /* Not enouth space for message length (8 bytes). */
		memset((((uint8_t*)ctx->buffer) + buffer_usage), 0x00,
		    (SHA1_MSG_BLK_SIZE - buffer_usage));
		sha1_transform(ctx, (uint8_t*)ctx->buffer,
		    (((uint8_t*)ctx->buffer) + SHA1_MSG_BLK_SIZE));
		buffer_usage = 0;
	}
	memset((((uint8_t*)ctx->buffer) + buffer_usage), 0x00,
	    ((SHA1_MSG_BLK_SIZE - 8) - buffer_usage));
	/* Store the message length as the last 8 octets. */
	ctx->buffer[(SHA1_MSG_BLK_64CNT - 1)] = bswap64((ctx->count << 3));
	sha1_transform(ctx, (uint8_t*)ctx->buffer,
	    (((uint8_t*)ctx->buffer) + SHA1_MSG_BLK_SIZE));
	/* Store state in digest. */
	sha1_memcpy_bswap(digest, (uint8_t*)ctx->hash, SHA1_HASH_SIZE);
	/* Zeroize sensitive information. */
	sha1_bzero(ctx, sizeof(sha1_ctx_t));
}


/* RFC 2104 */
/*
 * the HMAC_SHA1 transform looks like:
 *
 * SHA1(K XOR opad, SHA1(K XOR ipad, data))
 *
 * where K is an n byte 'key'
 * ipad is the byte 0x36 repeated 64 times
 * opad is the byte 0x5c repeated 64 times
 * and 'data' is the data being protected
 */
/*
 * data - pointer to data stream
 * data_size - length of data stream
 * key - pointer to authentication key
 * key_len - length of authentication key
 * digest - caller digest to be filled in
 */
static inline void
hmac_sha1_init(const uint8_t *key, size_t key_len, hmac_sha1_ctx_p hctx) {
	register size_t i;
	uint64_t k_ipad[SHA1_MSG_BLK_64CNT]; /* inner padding - key XORd with ipad. */

	/* Start out by storing key in pads. */
	/* If key is longer than block_size bytes reset it to key = SHA1(key). */
	sha1_init(&hctx->ctx); /* Init context for 1st pass / Get hash params. */
	if (SHA1_MSG_BLK_SIZE < key_len) {
		sha1_update(&hctx->ctx, key, key_len);
		key_len = SHA1_HASH_SIZE;
		sha1_final(&hctx->ctx, (uint8_t*)k_ipad);
		sha1_init(&hctx->ctx); /* Reinit context for 1st pass. */
	} else {
		memcpy(k_ipad, key, key_len);
	}
	memset((((uint8_t*)k_ipad) + key_len), 0x00, (SHA1_MSG_BLK_SIZE - key_len));
	memcpy(hctx->k_opad, k_ipad, sizeof(k_ipad));

	/* XOR key with ipad and opad values. */
#pragma unroll
	for (i = 0; i < SHA1_MSG_BLK_64CNT; i ++) {
		k_ipad[i] ^= 0x3636363636363636ull;
		hctx->k_opad[i] ^= 0x5c5c5c5c5c5c5c5cull;
	}
	/* Perform inner SHA1. */
	sha1_update(&hctx->ctx, (uint8_t*)k_ipad, sizeof(k_ipad)); /* Start with inner pad. */
	/* Zeroize sensitive information. */
	sha1_bzero(k_ipad, sizeof(k_ipad));
}

static inline void
hmac_sha1_update(hmac_sha1_ctx_p hctx, const uint8_t *data, size_t data_size) {

	sha1_update(&hctx->ctx, data, data_size); /* Then data of datagram. */
}

static inline void
hmac_sha1_final(hmac_sha1_ctx_p hctx, uint8_t *digest) {

	sha1_final(&hctx->ctx, digest); /* Finish up 1st pass. */
	/* Perform outer SHA1. */
	sha1_init(&hctx->ctx); /* Init context for 2nd pass. */
	sha1_update(&hctx->ctx, (uint8_t*)hctx->k_opad, SHA1_MSG_BLK_SIZE); /* Start with outer pad. */
	sha1_update(&hctx->ctx, digest, SHA1_HASH_SIZE); /* Then results of 1st hash. */
	sha1_final(&hctx->ctx, digest); /* Finish up 2nd pass. */
	/* Zeroize sensitive information. */
	sha1_bzero(hctx->k_opad, SHA1_MSG_BLK_SIZE);
}

static inline void
hmac_sha1(const uint8_t *key, size_t key_len, const uint8_t *data,
    size_t data_size, uint8_t *digest) {
	hmac_sha1_ctx_t hctx;

	hmac_sha1_init(key, key_len, &hctx);
	hmac_sha1_update(&hctx, data, data_size);
	hmac_sha1_final(&hctx, digest);
}


static inline void
sha1_cvt_hex(const uint8_t *bin, uint8_t *hex) {
	static const uint8_t *hex_tbl = (const uint8_t*)"0123456789abcdef";
	register const uint8_t *bin_max;
	register uint8_t byte;

#pragma unroll
	for (bin_max = (bin + SHA1_HASH_SIZE); bin < bin_max; bin ++) {
		byte = (*bin);
		(*hex ++) = hex_tbl[((byte >> 4) & 0x0f)];
		(*hex ++) = hex_tbl[(byte & 0x0f)];
	}
	(*hex) = 0;
}


/* Other staff. */
static inline void
sha1_cvt_str(const uint8_t *digest, char *digest_str) {

	sha1_cvt_hex(digest, (uint8_t*)digest_str);
}


static inline void
sha1_get_digest(const void *data, size_t data_size, uint8_t *digest) {
	sha1_ctx_t ctx;

	sha1_init(&ctx);
	sha1_update(&ctx, data, data_size);
	sha1_final(&ctx, digest);
}


static inline void
sha1_get_digest_str(const char *data, size_t data_size, char *digest_str) {
	sha1_ctx_t ctx;
	uint8_t digest[SHA1_HASH_SIZE];

	sha1_init(&ctx);
	sha1_update(&ctx, (const uint8_t*)data, data_size);
	sha1_final(&ctx, digest);

	sha1_cvt_str(digest, digest_str);
}


static inline void
sha1_hmac_get_digest(const void *key, size_t key_size,
    const void *data, size_t data_size, uint8_t *digest) {

	hmac_sha1(key, key_size, data, data_size, digest);
}


static inline void
sha1_hmac_get_digest_str(const char *key, size_t key_size,
    const char *data, size_t data_size, char *digest_str) {
	uint8_t digest[SHA1_HASH_SIZE];

	hmac_sha1((const uint8_t*)key, key_size,
	    (const uint8_t*)data, data_size, digest);
	sha1_cvt_str(digest, digest_str);
}


#ifdef SHA1_SELF_TEST
/* 0 - OK, non zero - error */
static inline int
sha1_self_test(void) {
	size_t i, j;
	sha1_ctx_t ctx;
	uint8_t digest[SHA1_HASH_SIZE];
	char digest_str[SHA1_HASH_STR_SIZE + 1]; /* Calculated digest. */
	const char *data[] = {
	    "",
	    "a",
	    "abc",
	    "message digest",
	    "abcdefghijklmnopqrstuvwxyz",
	    "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
	    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
	    "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
	    "01234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567012345670123456701234567",
	    "a",
	    "0123456701234567012345670123456701234567012345670123456701234567",
	    "012345670123456701234567012345670123456701234567012345",
	    "0123456701234567012345670123456701234567012345670123456",
	    "01234567012345670123456701234567012345670123456701234567",
	    "012345670123456701234567012345670123456701234567012345678",
	    "012345670123456701234567012345670123456701234567012345670123456"
	};
	const size_t data_size[] = {
	    0, 1, 3, 14, 26, 56, 62, 80, 128, 1, 64, 54, 55, 56, 57, 63
	};
	const size_t repeat_count[] = {
	    1, 1, 1, 1, 1, 1, 1, 1, 1, 1000000, 10, 1, 1, 1, 1, 1
	};
	const char *result_digest[] = {
	    "da39a3ee5e6b4b0d3255bfef95601890afd80709",
	    "86f7e437faa5a7fce15d1ddcb9eaeaea377667b8",
	    "a9993e364706816aba3e25717850c26c9cd0d89d",
	    "c12252ceda8be8994d5fa0290a47231c1d16aae3",
	    "32d10c7b8cf96570ca04ce37f2a19d84240d3a89",
	    "84983e441c3bd26ebaae4aa1f95129e5e54670f1",
	    "761c457bf73b14d27e9e9265c46f4b4dda11f940",
	    "50abf5706a150990a08b2c5ea40fa0e585554732",
	    "2249bd93900b5cb32bd4714a2be11e4c18450623",
	    "34aa973cd4c4daa4f61eeb2bdbad27316534016f",
	    "dea356a2cddd90c7a7ecedc5ebb563934f460452",
	    "09325e9054f88d7340deeb8785c6f8455ad13c78",
	    "adfc128b4a89c560e754c1659a6a90968b55490e",
	    "e8db7ebaebb692565d590a48b1dc506b6f130950",
	    "f8331b7f064d5886f371c47d8912c04439f4290a",
	    "f50965cd66d5793b37291ec7afe090406f2b6115"
	};
	const char *result_hdigest[] = {
	    "fbdb1d1b18aa6c08324b7d64b71fb76370690e1d",
	    "3902ed847ff28930b5f141abfa8b471681253673",
	    "5b333a389b4e9a2358ac5392bf2a64dc68e3c943",
	    "39729a5ace94cc349b79adffbd113a599ca59d47",
	    "d74df27e4293c4225813dd723007cfb8933bc70b",
	    "e977b6b86e9f1920f01be85e9cea1f5a15b89421",
	    "a70fe63deac3c18b9d36ba4ecd44bdaf07cf5548",
	    "3e9e3aeaa5c932036358071bfcc3755344e7e357",
	    "2993491f3989c24a1267a5a35c5de325e6ef5312",
	    "3902ed847ff28930b5f141abfa8b471681253673",
	    "96e41775f72e3b2c61dca03d5c767019bebcc335",
	    "4ba0fa8d31c37fcad8476eb4bdd64e62e843284f",
	    "84dccb278a7be4e7c4318849bf22fa42f44baccd",
	    "9698a0a5cda19c5f4266cd851f5a606dc7b85e91",
	    "bbf00e8e0ff7a4dcd1cff54080c516fab3692d6b",
	    "d5d9e4085429568f05a4ef8233f42722c4462d6c"
	};

	/* Hash test. */
	for (i = 0; i < nitems(data); i ++) {
		sha1_init(&ctx);
		for (j = 0; j < repeat_count[i]; j ++) {
			sha1_update(&ctx, (const uint8_t*)data[i], data_size[i]);
		}
		sha1_final(&ctx, digest);
		sha1_cvt_hex(digest, (uint8_t*)digest_str);
		if (0 != memcmp(digest_str, result_digest[i], SHA1_HASH_STR_SIZE))
			return (1);
	}
	/* HMAC test. */
	for (i = 0; i < nitems(data); i ++) {
		sha1_hmac_get_digest_str(data[i], data_size[i], data[i], data_size[i],
		    (char*)digest_str);
		if (0 != memcmp(digest_str, result_hdigest[i], SHA1_HASH_STR_SIZE))
			return (2);
	}

	return (0);
}
#endif


#endif /* __SHA1_H__INCLUDED__ */
