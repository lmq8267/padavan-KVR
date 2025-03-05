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


#include <sys/param.h>
#include <sys/types.h>
#include <sys/fcntl.h> /* open, fcntl */
#include <inttypes.h>
#include <stdlib.h> /* malloc, exit */
#include <unistd.h> /* close, write, sysconf */
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <errno.h>
#include <sched.h>

#include "utils/macro.h"
#include "utils/mem_utils.h"
#include "al/os.h"
#include "threadpool/threadpool.h"
#include "threadpool/threadpool_msg_sys.h"



typedef struct thread_pool_thread_msg_queue_s { /* thread pool thread info */
	tp_udata_t	udata;
	int		fd[2]; /* Queue specific. */
} tpt_msg_queue_t;


typedef struct tpt_msg_pkt_s { /* thread message packet data. */
	size_t		magic;
	tpt_msg_cb	msg_cb;
	void		*udata;
	size_t		chk_sum;
} tpt_msg_pkt_t, *tpt_msg_pkt_p;

#define TPT_MSG_PKT_MAGIC	0xffddaa00
#define TPT_MSG_COUNT_TO_READ	1024 /* Read messages count at one read() call. */

#define TPT_MSG_PKT_CHK_SUM_SET(__msg_pkt)				\
    (__msg_pkt)->chk_sum = (((size_t)(__msg_pkt)->msg_cb) ^ ((size_t)(__msg_pkt)->udata))
#define TPT_MSG_PKT_IS_VALID(__msg_pkt)					\
    (TPT_MSG_PKT_MAGIC == (__msg_pkt)->magic &&				\
     (((size_t)(__msg_pkt)->msg_cb) ^ ((size_t)(__msg_pkt)->udata)) == (__msg_pkt)->chk_sum)


typedef struct tpt_msg_data_s { /* thread message sync data. */
	tpt_msg_cb	msg_cb;
	void		*udata;
	MTX_S		lock;	/* For count exclusive access. */
	volatile size_t	active_thr_count;
	size_t		cur_thr_idx; /*  */
	uint32_t	flags;
	volatile size_t	send_msg_cnt;
	volatile size_t	error_cnt;
	tpt_p		tpt;	/* Caller context, for done_cb. */
	tpt_msg_done_cb done_cb;
} tpt_msg_data_t, *tpt_msg_data_p;


typedef struct thread_pool_thread_msg_async_operation_s {
	tpt_p		tpt;	/* Caller context, for op_cb. */
	tpt_msg_async_op_cb op_cb;
	void		*udata[TP_MSG_AOP_UDATA_CNT];
} tpt_msg_async_op_t;


size_t	tpt_msg_broadcast_send__int(tp_p tp, tpt_p src,
	    tpt_msg_data_p msg_data, uint32_t flags, tpt_msg_cb msg_cb,
	    void *udata, volatile size_t *send_msg_cnt,
	    volatile size_t *error_cnt);
int	tpt_msg_one_by_one_send_next__int(tp_p tp, tpt_p src,
	    tpt_msg_data_p msg_data);



static void
tpt_msg_recv_and_process(tp_event_p ev, tp_udata_p tp_udata) {
	ssize_t rd;
	size_t magic = TPT_MSG_PKT_MAGIC, i, cnt, readed;
	tpt_msg_pkt_t msg[TPT_MSG_COUNT_TO_READ], tmsg;
	uint8_t *ptm, *pend;

	debugd_break_if(NULL == ev);
	debugd_break_if(TP_EV_READ != ev->event);
	debugd_break_if(NULL == tp_udata);
	debugd_break_if((uintptr_t)((tpt_msg_queue_p)tp_udata)->fd[0] != tp_udata->ident);

	for (;;) {
		rd = read((int)tp_udata->ident, &msg, sizeof(msg));
		if (((ssize_t)sizeof(tpt_msg_pkt_t)) > rd)
			return; /* -1, 0, < sizeof(tpt_msg_pkt_t) */
		readed = (size_t)rd;
		cnt = (readed / sizeof(tpt_msg_pkt_t));
		for (i = 0; i < cnt; i ++) { /* Process loop. */
			if (0 == TPT_MSG_PKT_IS_VALID(&msg[i])) { /* Try recover. */
				SYSLOGD_EX(LOG_WARNING, "tpt_msg_pkt_t damaged!!!");
				debugd_break();
				ptm = ((uint8_t*)&msg[i]);
				pend = (((uint8_t*)&msg) + readed);
				for (;;) {
					ptm = mem_find_ptr(ptm, &msg, readed,
					    &magic, sizeof(size_t));
					if (NULL == ptm)
						return; /* No more messages. */
					i = (size_t)(pend - ptm); /* Unprocessed messages size. */
					if (sizeof(tpt_msg_pkt_t) > i)
						return; /* Founded to small, no more messages. */
					memcpy(&tmsg, ptm, sizeof(tpt_msg_pkt_t)); /* Avoid allign missmatch. */
					if (0 == TPT_MSG_PKT_IS_VALID(&tmsg)) { /* Bad msg, try find next. */
						ptm += sizeof(size_t);
						continue;
					}
					/* Looks OK, fix and restart. */
					readed = i;
					cnt = (readed / sizeof(tpt_msg_pkt_t));
					i = 0;
					memmove(&msg, ptm, readed);
					break;
				}
			}
			if (NULL == msg[i].msg_cb)
				continue;
			msg[i].msg_cb(tp_udata->tpt, msg[i].udata);
		}
		if (sizeof(msg) > readed) /* All data read. */
			return; /* OK. */
	}
}


static void
tpt_msg_cb_done_proxy_cb(tpt_p tpt, void *udata) {
	tpt_msg_data_p msg_data;

	debugd_break_if(NULL == tpt);
	debugd_break_if(NULL == udata);

	msg_data = udata;
	msg_data->done_cb(tpt, msg_data->send_msg_cnt,
	    msg_data->error_cnt, msg_data->udata);
	if (0 == (TP_CBMSG_F_ONE_BY_ONE & msg_data->flags)) {
		MTX_DESTROY(&msg_data->lock);
	}
	free(msg_data);
}

static inline size_t
tpt_msg_active_thr_count_dec(tpt_msg_data_p msg_data, tpt_p src,
    size_t dec) {
	size_t tm;

	/* Additional data handling. */
	MTX_LOCK(&msg_data->lock);
	msg_data->active_thr_count -= dec;
	tm = msg_data->active_thr_count;
	MTX_UNLOCK(&msg_data->lock);

	if (0 != tm ||
	    NULL == msg_data->done_cb)
		return (tm); /* There is other alive threads. */
	/* This was last thread, so we need do call back done handler. */
	tpt_msg_send(msg_data->tpt, src,
	    (TP_MSG_F_FAIL_DIRECT | TP_MSG_F_SELF_DIRECT),
	    tpt_msg_cb_done_proxy_cb, msg_data);
	return (tm);
}

static void
tpt_msg_sync_proxy_cb(tpt_p tpt, void *udata) {
	tpt_msg_data_p msg_data;

	debugd_break_if(NULL == tpt);
	debugd_break_if(NULL == udata);

	msg_data = udata;
	msg_data->msg_cb(tpt, msg_data->udata);
	tpt_msg_active_thr_count_dec(msg_data, tpt, 1);
}

static void
tpt_msg_one_by_one_proxy_cb(tpt_p tpt, void *udata) {
	tpt_msg_data_p msg_data;

	debugd_break_if(NULL == tpt);
	debugd_break_if(NULL == udata);

	msg_data = udata;
	msg_data->msg_cb(tpt, msg_data->udata);
	/* Send to next thread. */
	msg_data->cur_thr_idx ++;
	if (0 == tpt_msg_one_by_one_send_next__int(tpt_get_tp(tpt), tpt, msg_data))
		return;
	/* All except caller thread done / error. */
	if (0 == ((TP_BMSG_F_SELF_SKIP | TP_MSG_F_SELF_DIRECT) & msg_data->flags) &&
	    msg_data->tpt != tpt) { /* Try shedule caller thread. */
		msg_data->cur_thr_idx = tp_thread_count_max_get(tpt_get_tp(tpt));
		msg_data->send_msg_cnt ++;
		if (0 == tpt_msg_send(msg_data->tpt, tpt,
		    msg_data->flags, tpt_msg_one_by_one_proxy_cb,
		    msg_data))
			return;
		/* Error on send. Allso here EHOSTDOWN from not running threads. */
		msg_data->send_msg_cnt --;
		msg_data->error_cnt ++;
	}
	/* Error / Done. */
	tpt_msg_send(msg_data->tpt, tpt,
	    (TP_MSG_F_FAIL_DIRECT | TP_MSG_F_SELF_DIRECT),
	    tpt_msg_cb_done_proxy_cb, msg_data);
}



tpt_msg_queue_p
tpt_msg_queue_create(tpt_p tpt, const uint32_t flags) { /* Init threads message exchange. */
	int error;
	tpt_msg_queue_p msg_queue;

	msg_queue = calloc(1, sizeof(tpt_msg_queue_t));
	if (NULL == msg_queue)
		return (NULL);
	if (-1 == pipe2(msg_queue->fd,
	    (O_NONBLOCK | (0 != (TP_MSG_Q_F_CLOEXEC & flags) ? O_CLOEXEC : 0)))) {
		/* Can not use tpt_msg_queue_destroy() here: fd not initialized. */
		free(msg_queue);
		return (NULL);
	}
	msg_queue->udata.cb_func = tpt_msg_recv_and_process;
	msg_queue->udata.ident = (uintptr_t)msg_queue->fd[0];
	error = tpt_ev_add_args2(tpt, TP_EV_READ, 0, &msg_queue->udata);
	if (0 != error) {
		errno = error;
		tpt_msg_queue_destroy(msg_queue);
		return (NULL);
	}
	return (msg_queue);
}

void
tpt_msg_queue_destroy(tpt_msg_queue_p msg_queue) {

	if (NULL == msg_queue)
		return;
	close(msg_queue->fd[0]);
	close(msg_queue->fd[1]);
	free(msg_queue);
}


int
tpt_msg_send(tpt_p dst, tpt_p src, uint32_t flags,
    tpt_msg_cb msg_cb, void *udata) {
	tpt_msg_pkt_t msg;
	tpt_msg_queue_p msg_queue;

	if (NULL == dst || NULL == msg_cb)
		return (EINVAL);
	msg_queue = tpt_get_msg_queue(dst);
	if (NULL == msg_queue)
		return (EINVAL);
	if (0 != (TP_MSG_F_SELF_DIRECT & flags)) {
		if (NULL == src) {
			src = tp_thread_get_current();
		}
		if (src == dst) { /* Self. */
			msg_cb(dst, udata);
			return (0);
		}
	}
	if (0 == tpt_is_running(dst)) {
		if (0 == (TP_MSG_F_FORCE & flags))
			return (EHOSTDOWN);
		msg_cb(dst, udata);
		return (0);
	}

	msg.magic = TPT_MSG_PKT_MAGIC;
	msg.msg_cb = msg_cb;
	msg.udata = udata;
	TPT_MSG_PKT_CHK_SUM_SET(&msg);
	if (sizeof(msg) == write(msg_queue->fd[1], &msg, sizeof(msg)))
		return (0);
	/* Error. */
	debugd_break();
	if (0 != (TP_MSG_F_FAIL_DIRECT & flags)) {
		msg_cb(dst, udata);
		return (0);
	}
	return (errno);
}


size_t
tpt_msg_broadcast_send__int(tp_p tp, tpt_p src,
    tpt_msg_data_p msg_data, uint32_t flags,
    tpt_msg_cb msg_cb, void *udata,
    volatile size_t *send_msg_cnt, volatile size_t *error_cnt) {
	size_t i, threads_max, err_cnt = 0;
	tpt_p tpt;

	if (NULL != msg_data &&
	    NULL != src &&
	    0 != (TP_BMSG_F_SELF_SKIP & flags)) {
		msg_data->active_thr_count --;
	}
	(*send_msg_cnt) = 0;
	(*error_cnt) = 0;
	threads_max = tp_thread_count_max_get(tp);
	for (i = 0; i < threads_max; i ++) { /* Send message loop. */
		tpt = tp_thread_get(tp, i);
		if (tpt == src && /* Self. */
		    0 != (TP_BMSG_F_SELF_SKIP & flags)) {
			/* No need to "active_thr_count --" here:
			 * SELF_SKIP allready done,
			 * msg_cb = tpt_msg_sync_proxy_cb and handle count for
			 * tpt_msg_bsend_ex(TP_BMSG_F_SYNC) and
			 * tpt_msg_cbsend() w/o TP_CBMSG_F_ONE_BY_ONE. */
			continue;
		}
		(*send_msg_cnt) ++;
		if (0 == tpt_msg_send(tpt, src, flags, msg_cb, udata))
			continue;
		/* Error on send. Allso here EHOSTDOWN from not running threads. */
		(*send_msg_cnt) --;
		(*error_cnt) ++;
		err_cnt ++;
	}
	/* Do not forget for "unlock" and free + done cb:
	 * if err_cnt = 0 then msg_data may not exist!
	 * if (0 != err_cnt && NULL != msg_data)
	 *	tpt_msg_active_thr_count_dec(msg_data, tpt, err_cnt);
	 */
	return (err_cnt);
}

int
tpt_msg_bsend_ex(tp_p tp, tpt_p src, uint32_t flags,
    tpt_msg_cb msg_cb, void *udata,
    size_t *send_msg_cnt, size_t *error_cnt) {
	int error = 0;
	volatile size_t tm_cnt;
	size_t threads_max;
	tpt_msg_data_p msg_data = NULL;
	tpt_msg_data_t msg_data_s;
	struct timespec rqts;

	msg_data_s.send_msg_cnt = 0;
	msg_data_s.error_cnt = 0;
	threads_max = tp_thread_count_max_get(tp);
	if (NULL == tp || NULL == msg_cb) {
		error = EINVAL;
		goto err_out;
	}
	if (NULL == src) {
		src = tp_thread_get_current();
	}
	/* 1 thread specific. */
	if (1 == threads_max &&
	    NULL != src) { /* Only if thread send broadcast to self. */
		if (0 != (TP_BMSG_F_SELF_SKIP & flags))
			goto err_out; /* Nothink to do. */
		if (0 == (TP_BMSG_F_SYNC & flags)) {
			error = tpt_msg_send(tp_thread_get(tp, 0), src, flags, msg_cb, udata);
			if (0 == error) {
				msg_data_s.send_msg_cnt ++;
			}
		} else { /* Cant async call from self. */
			msg_cb(src, udata);
		}
		goto err_out; /* Sended / error on send. */
	}
	/* Multithread. */
	if (0 != (TP_BMSG_F_SYNC & flags)) {
		/* Setup proxy cb. */
		msg_data = &msg_data_s;
		msg_data->msg_cb = msg_cb;
		msg_data->udata = udata;
		MTX_INIT(&msg_data->lock);
		msg_data->active_thr_count = threads_max;
		msg_data->cur_thr_idx = 0;
		msg_data->flags = flags;
		//msg_data->send_msg_cnt = 0;
		//msg_data->error_cnt = 0;
		msg_data->tpt = NULL;
		msg_data->done_cb = NULL;
		msg_cb = tpt_msg_sync_proxy_cb;
		udata = msg_data;
	}

	tm_cnt = tpt_msg_broadcast_send__int(tp, src, msg_data,
	    flags, msg_cb, udata, &msg_data_s.send_msg_cnt,
	    &msg_data_s.error_cnt);

	if (NULL != msg_data) { /* TP_BMSG_F_SYNC: Wait for all. */
		/* Update active threads count and store to tm_cnt. */
		rqts.tv_sec = 0;
		rqts.tv_nsec = 10000000; /* 1 sec = 1000000000 nanoseconds */
		tm_cnt = tpt_msg_active_thr_count_dec(msg_data, src, tm_cnt);
		while (0 != tm_cnt) {
			if (0 == (TP_BMSG_F_SYNC_USLEEP & flags)) {
				sched_yield();
			} else {
				nanosleep(&rqts, NULL); /* Ignore early wakeup and errors. */
			}
			MTX_LOCK(&msg_data->lock);
			tm_cnt = msg_data->active_thr_count;
			MTX_UNLOCK(&msg_data->lock);
		}
		MTX_DESTROY(&msg_data->lock);
	}
	if (0 == msg_data_s.send_msg_cnt) {
		error = ESPIPE;
	}
err_out:
	if (NULL != send_msg_cnt) {
		(*send_msg_cnt) = msg_data_s.send_msg_cnt;
	}
	if (NULL != error_cnt) {
		(*error_cnt) = msg_data_s.error_cnt;
	}
	return (error);
}


int
tpt_msg_one_by_one_send_next__int(tp_p tp, tpt_p src,
    tpt_msg_data_p msg_data) {
	tpt_p tpt;
	size_t threads_max;

	threads_max = tp_thread_count_max_get(tp);
	if (msg_data->cur_thr_idx >= threads_max)
		return (EINVAL);
	for (; msg_data->cur_thr_idx < threads_max; msg_data->cur_thr_idx ++) {
		tpt = tp_thread_get(tp, msg_data->cur_thr_idx);
		if (tpt == msg_data->tpt) /* Self. */
			continue;
		msg_data->send_msg_cnt ++;
		if (0 == tpt_msg_send(tpt, src, msg_data->flags,
		    tpt_msg_one_by_one_proxy_cb, msg_data))
			return (0);
		/* Error on send. Also here EHOSTDOWN from not running threads. */
		msg_data->send_msg_cnt --;
		msg_data->error_cnt ++;
	}
	return (ESPIPE);
}

int
tpt_msg_cbsend(tp_p tp, tpt_p src, uint32_t flags,
    tpt_msg_cb msg_cb, void *udata, tpt_msg_done_cb done_cb) {
	size_t tm_cnt, send_msg_cnt, threads_max;
	tpt_msg_data_p msg_data;

	if (NULL == tp || NULL == msg_cb || NULL == done_cb ||
	    0 != ((TP_BMSG_F_SYNC | TP_BMSG_F_SYNC_USLEEP) & flags))
		return (EINVAL);
	if (NULL == src) {
		src = tp_thread_get_current();
	}
	if (NULL == src) /* Cant do final callback. */
		return (EINVAL);
	threads_max = tp_thread_count_max_get(tp);
	/* 1 thread specific. */
	if (1 == threads_max &&
	    NULL != src) { /* Only if thread send broadcast to self. */
		if (0 != (TP_BMSG_F_SELF_SKIP & flags)) {
			done_cb(src, 0, 0, udata); /* Nothink to do. */
		} else { /* Cant async call from self. */
			msg_cb(src, udata);
			done_cb(src, 1, 0, udata);
		}
		return (0); /* Sended / error on send. */
	}
	msg_data = calloc(1, sizeof(tpt_msg_data_t));
	if (NULL == msg_data)
		return (ENOMEM);
	msg_data->msg_cb = msg_cb;
	msg_data->udata = udata;
	msg_data->active_thr_count = threads_max;
	msg_data->flags = flags;
	msg_data->tpt = src;
	msg_data->done_cb = done_cb;

	if (0 != (TP_CBMSG_F_ONE_BY_ONE & flags)) {
		if (TP_MSG_F_SELF_DIRECT == ((TP_BMSG_F_SELF_SKIP | TP_MSG_F_SELF_DIRECT) & flags)) {
			msg_data->send_msg_cnt ++;
			msg_cb(src, udata);
		}
		if (0 == tpt_msg_one_by_one_send_next__int(tp, src, msg_data))
			return (0); /* OK, sheduled. */
		if (TP_MSG_F_SELF_DIRECT == ((TP_BMSG_F_SELF_SKIP | TP_MSG_F_SELF_DIRECT) & flags)) {
			done_cb(src, msg_data->send_msg_cnt,
			    msg_data->error_cnt, udata);
			return (0);
		}
		return (ESPIPE);
	}
	/* Like SYNC but with cb. */
	MTX_INIT(&msg_data->lock);

	tm_cnt = tpt_msg_broadcast_send__int(tp, src, msg_data, flags,
	    tpt_msg_sync_proxy_cb, msg_data, &msg_data->send_msg_cnt,
	    &msg_data->error_cnt);
	if (0 == tm_cnt)
		return (0); /* OK, sheduled. */
	/* Errors. Update active threads count and store to tm_cnt. */
	send_msg_cnt = msg_data->send_msg_cnt; /* Remember before release. */
	tm_cnt = tpt_msg_active_thr_count_dec(msg_data, src, tm_cnt);
	if (0 == send_msg_cnt)
		return (ESPIPE);
	return (0);
}


tpt_msg_async_op_p
tpt_msg_async_op_alloc(tpt_p dst, tpt_msg_async_op_cb op_cb) {
	tpt_msg_async_op_p aop;

	if (NULL == op_cb)
		return (NULL);
	aop = calloc(1, sizeof(tpt_msg_async_op_t));
	if (NULL == aop)
		return (NULL);
	if (NULL == dst) {
		dst = tp_thread_get_current();
	}
	aop->tpt = dst;
	aop->op_cb = op_cb;

	return (aop);
}

static void
tpt_msg_async_op_cb_free_cb(tpt_p tpt, void *udata) {
	tpt_msg_async_op_p aop = udata;

	debugd_break_if(tpt != aop->tpt);

	aop->op_cb(aop->tpt, aop->udata);
	free(aop);
}
void
tpt_msg_async_op_cb_free(tpt_msg_async_op_p aop, tpt_p src) {

	if (NULL == aop)
		return;
	tpt_msg_send(aop->tpt, src,
	    (TP_MSG_F_SELF_DIRECT | TP_MSG_F_FORCE | TP_MSG_F_FAIL_DIRECT),
	    tpt_msg_async_op_cb_free_cb, aop);
}


void **
tpt_msg_async_op_udata(tpt_msg_async_op_p aop) {

	if (NULL == aop)
		return (NULL);
	return (aop->udata);
}
void *
tpt_msg_async_op_udata_get(tpt_msg_async_op_p aop, size_t index) {

	if (NULL == aop || TP_MSG_AOP_UDATA_CNT <= index)
		return (NULL);
	return (aop->udata[index]);
}
void
tpt_msg_async_op_udata_set(tpt_msg_async_op_p aop, size_t index, void *udata) {

	if (NULL == aop || TP_MSG_AOP_UDATA_CNT <= index)
		return;
	aop->udata[index] = udata;
}


size_t *
tpt_msg_async_op_udata_sz(tpt_msg_async_op_p aop) {

	if (NULL == aop)
		return (NULL);
	return ((size_t*)aop->udata);
}
size_t
tpt_msg_async_op_udata_sz_get(tpt_msg_async_op_p aop, size_t index) {

	if (NULL == aop || TP_MSG_AOP_UDATA_CNT <= index)
		return (0);
	return ((size_t)aop->udata[index]);
}
void
tpt_msg_async_op_udata_sz_set(tpt_msg_async_op_p aop, size_t index, size_t udata) {

	if (NULL == aop || TP_MSG_AOP_UDATA_CNT <= index)
		return;
	aop->udata[index] = (void*)udata;
}


ssize_t *
tpt_msg_async_op_udata_ssz(tpt_msg_async_op_p aop) {

	if (NULL == aop)
		return (NULL);
	return ((ssize_t*)aop->udata);
}
ssize_t
tpt_msg_async_op_udata_ssz_get(tpt_msg_async_op_p aop, size_t index) {

	if (NULL == aop || TP_MSG_AOP_UDATA_CNT <= index)
		return (0);
	return ((ssize_t)aop->udata[index]);
}
void
tpt_msg_async_op_udata_ssz_set(tpt_msg_async_op_p aop, size_t index, ssize_t udata) {

	if (NULL == aop || TP_MSG_AOP_UDATA_CNT <= index)
		return;
	aop->udata[index] = (void*)udata;
}
