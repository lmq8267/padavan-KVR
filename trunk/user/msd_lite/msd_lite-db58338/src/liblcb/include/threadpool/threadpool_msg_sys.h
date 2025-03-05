/*-
 * Copyright (c) 2011-2024 Rozhuk Ivan <rozhuk.im@gmail.com>
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

 
#ifndef __THREAD_POOL_MESSAGE_SYSTEM_H__
#define __THREAD_POOL_MESSAGE_SYSTEM_H__


#include <sys/param.h>
#include <sys/types.h>
#include <inttypes.h>
#include <time.h>

#include "threadpool.h"


typedef struct thread_pool_thread_msg_queue_s	*tpt_msg_queue_p;	/* Thread pool thread message queue. */
typedef struct thread_pool_thread_msg_async_operation_s	*tpt_msg_async_op_p;

typedef void (*tpt_msg_cb)(tpt_p tpt, void *udata);
typedef void (*tpt_msg_done_cb)(tpt_p tpt, size_t send_msg_cnt,
    size_t error_cnt, void *udata);
typedef void (*tpt_msg_async_op_cb)(tpt_p tpt, void **udata);


tpt_msg_queue_p tpt_msg_queue_create(tpt_p tpt, const uint32_t flags);
#define TP_MSG_Q_F_CLOEXEC	(((uint32_t)1) <<  0) /* Pass O_CLOEXEC to pipe2(). */

void		tpt_msg_queue_destroy(tpt_msg_queue_p msg_queue);


/* Thread messages. Unicast and Broadcast. */
/* Only threads from pool can receive messages. */
int	tpt_msg_send(tpt_p dst, tpt_p src, uint32_t flags, tpt_msg_cb msg_cb,
	    void *udata);
/* tpt_msg_send() return:
 * 0 = no errors, message sended
 * EINVAL - on invalid arg
 * EHOSTDOWN - dst thread not running and TP_MSG_F_FORCE flag not set
 * other err codes from kevent() on BSD and write() on linux
 */
int	tpt_msg_bsend_ex(tp_p tp, tpt_p src, uint32_t flags, tpt_msg_cb msg_cb,
	    void *udata, size_t *send_msg_cnt, size_t *error_cnt);
#define tpt_msg_bsend(__tp, __src, __flags, __msg_cb, __udata)		\
	    tpt_msg_bsend_ex((__tp), (__src), (__flags), (__msg_cb), (__udata), NULL, NULL)
/* tpt_msg_bsend_ex() return:
 * 0 = no errors, at least 1 message sended
 * EINVAL - on invalid arg
 * ESPIPE - no messages sended, all send operations fail
 * + errors count, + send_msg_cnt
 */
int	tpt_msg_cbsend(tp_p tp, tpt_p src, uint32_t flags, tpt_msg_cb msg_cb,
	    void *udata, tpt_msg_done_cb done_cb);
/* tpt_msg_cbsend() return:
 * error code if none messages sended,
 * 0 if at least one message sended + sended messages and errors count on done cb. */
/* Unicast + broadcast messages flags. */
#define TP_MSG_F_SELF_DIRECT	(((uint32_t)1) <<  0) /* Directly call cb func for calling thread. */
#define TP_MSG_F_FORCE		(((uint32_t)1) <<  1) /* If thread mark as not running - directly call cb func.
					   * WARNING! if thread not running - tpt will be ignored. */
#define TP_MSG_F_FAIL_DIRECT	(((uint32_t)1) <<  2) /* Directly call cb func if fail to send. */
#define TP_MSG_F__ALL__		(TP_MSG_F_SELF_DIRECT | TP_MSG_F_FORCE | TP_MSG_F_FAIL_DIRECT)
/* Broadcast flags. */
#define TP_BMSG_F_SELF_SKIP	(((uint32_t)1) <<  8) /* Do not send mesg to caller thread. */
#define TP_BMSG_F_SYNC		(((uint32_t)1) <<  9) /* Wait before all thread process message before return.
						       * WARNING! This deadlock, frizes possible. */
#define TP_BMSG_F_SYNC_USLEEP	(((uint32_t)1) << 10) /* Wait before all thread process message before return. */
#define TP_BMSG_F__ALL__	(TP_BMSG_F_SELF_SKIP | TP_BMSG_F_SYNC | TP_BMSG_F_SYNC_USLEEP)
/* Broadcast with result cb. */
#define TP_CBMSG_F_SELF_SKIP	TP_BMSG_F_SELF_SKIP
#define TP_CBMSG_F_ONE_BY_ONE	(((uint32_t)1) << 16) /* Send message to next thread after current thread process message. */
#define TP_CBMSG__ALL__		(TP_CBMSG_F_SELF_SKIP | TP_CBMSG_F_ONE_BY_ONE)


/* Functions set for async callback with some additional params. */
/* It designed to be used in tpt_msg_done_cb or any other one time call back
 * function, like tp_task_connect_cb, tp_task_connect_ex_cb, etc...
 * On init (call tpt_msg_async_op_alloc()) set destination thread and
 * call back function that will be called by destination thread after
 * tpt_msg_async_op_cb_free() called. */
#define TP_MSG_AOP_UDATA_CNT	((size_t)6)
/* Typical names */
#define TP_MSG_AOP_ARG0		((size_t)0)
#define TP_MSG_AOP_ARG1		((size_t)1)
#define TP_MSG_AOP_ARG2		((size_t)2)
#define TP_MSG_AOP_ARG3		((size_t)3)
#define TP_MSG_AOP_ARG4		((size_t)4)
#define TP_MSG_AOP_ARG_ERR	(TP_MSG_AOP_UDATA_CNT - 1)

tpt_msg_async_op_p tpt_msg_async_op_alloc(tpt_p dst, tpt_msg_async_op_cb op_cb);
void	tpt_msg_async_op_cb_free(tpt_msg_async_op_p aop, tpt_p src);

void **	tpt_msg_async_op_udata(tpt_msg_async_op_p aop);
void *	tpt_msg_async_op_udata_get(tpt_msg_async_op_p aop, size_t index);
void	tpt_msg_async_op_udata_set(tpt_msg_async_op_p aop, size_t index, void *udata);

size_t *tpt_msg_async_op_udata_sz(tpt_msg_async_op_p aop);
size_t	tpt_msg_async_op_udata_sz_get(tpt_msg_async_op_p aop, size_t index);
void	tpt_msg_async_op_udata_sz_set(tpt_msg_async_op_p aop, size_t index, size_t udata);

ssize_t *tpt_msg_async_op_udata_ssz(tpt_msg_async_op_p aop);
ssize_t	tpt_msg_async_op_udata_ssz_get(tpt_msg_async_op_p aop, size_t index);
void	tpt_msg_async_op_udata_ssz_set(tpt_msg_async_op_p aop, size_t index, ssize_t udata);


#endif /* __THREAD_POOL_MESSAGE_SYSTEM_H__ */
