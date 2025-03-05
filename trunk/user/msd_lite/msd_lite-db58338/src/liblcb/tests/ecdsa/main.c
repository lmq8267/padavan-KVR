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
#include <sys/time.h> /* For getrusage. */
#include <inttypes.h>
#include <stdlib.h> /* malloc, exit */
#include <stdio.h> /* snprintf, fprintf */
#include <unistd.h> /* close, write, sysconf */
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <errno.h>


#define BN_DIGIT_BIT_CNT 	64
#define BN_BIT_LEN		1408
#define BN_CC_MULL_DIV		1
#define BN_NO_POINTERS_CHK	1
#define BN_MOD_REDUCE_ALGO	BN_MOD_REDUCE_ALGO_BASIC
#define BN_SELF_TEST		1
#define EC_USE_PROJECTIVE	1
#define EC_PROJ_REPEAT_DOUBLE	1
#define EC_PROJ_ADD_MIX		1
#define EC_PF_FXP_MULT_ALGO	EC_PF_FXP_MULT_ALGO_COMB_2T
#define EC_PF_FXP_MULT_WIN_BITS	9
#define EC_PF_UNKPT_MULT_ALGO	EC_PF_UNKPT_MULT_ALGO_COMB_1T
#define EC_PF_UNKPT_MULT_WIN_BITS 2
#define EC_PF_TWIN_MULT_ALGO	EC_PF_TWIN_MULT_ALGO_INTER //EC_PF_TWIN_MULT_ALGO_JOINT //EC_PF_TWIN_MULT_ALGO_FXP_UNKPT
#define EC_DISABLE_PUB_KEY_CHK	1
#define EC_SELF_TEST		1

#include "crypto/dsa/ecdsa.h"


#define LOG_INFO_FMT(fmt, args...)					\
	    fprintf(stdout, fmt"\n", ##args)


int
main(int argc, char *argv[]) {
	int error;

	error = bn_self_test();
	if (0 != error) {
		LOG_INFO_FMT("bn_self_test(): err: %i", error);
		return (error);
	}

	error = ec_self_test();
	if (0 != error) {
		LOG_INFO_FMT("ec_self_test(): err: %i", error);
		return (error);
	}

	return (0);
}
