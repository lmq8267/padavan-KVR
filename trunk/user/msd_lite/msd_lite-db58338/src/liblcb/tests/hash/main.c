/*-
 * Copyright (c) 2016-2024 Rozhuk Ivan <rozhuk.im@gmail.com>
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
#include <inttypes.h>
#include <stdio.h> /* snprintf, fprintf */


#undef __SSE2__

#define MD5_SELF_TEST 1
#define SHA1_SELF_TEST 1
#define SHA2_SELF_TEST 1
#define GOST3411_2012_SELF_TEST 1

#include "crypto/hash/md5.h"
#include "crypto/hash/sha1.h"
#include "crypto/hash/sha2.h"
#include "crypto/hash/gost3411-2012.h"


#define LOG_INFO_FMT(fmt, args...)					\
	    fprintf(stdout, fmt"\n", ##args)


int
main(int argc, char *argv[]) {
	int error;

	error = md5_self_test();
	if (0 != error) {
		LOG_INFO_FMT("md5_self_test(): err: %i", error);
		return (error);
	}

	error = sha1_self_test();
	if (0 != error) {
		LOG_INFO_FMT("sha1_self_test(): err: %i", error);
		return (error);
	}

	error = sha2_self_test();
	if (0 != error) {
		LOG_INFO_FMT("sha2_self_test(): err: %i", error);
		return (error);
	}

	error = gost3411_2012_self_test();
	if (0 != error) {
		LOG_INFO_FMT("gost3411_2012_self_test(): err: %i", error);
		return (error);
	}

	return (0);
}
