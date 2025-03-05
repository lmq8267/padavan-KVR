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
#ifdef __linux__ 
#	include <sys/socket.h>
#endif
#include <sys/types.h>
#include <sys/uio.h> /* readv, preadv, writev, pwritev */
#include <inttypes.h>
#include <unistd.h> /* close, write, sysconf */
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <errno.h>

#include "utils/macro.h"
#include "al/os.h"
#include "net/socket.h"
#include "threadpool/threadpool_task.h"


typedef struct tp_task_s {
	tp_udata_t	tp_data; /*  */
	tp_udata_t	tp_timer; /* Per task timer: ident=pointer to tp_task_t. */
	uint16_t	event;	/* Need for cancel io on timeout. */
	uint16_t	event_flags; /* Need for work with timer. */
	uint32_t	flags;	/* read/write / send/recv / recvfrom/sendto */
	uint64_t	timeout;/* IO timeout, 0 = disable. */
	off_t		offset;	/* Read/write offset for tp_task_rw_handler() / try_no for connect_ex(). */
	io_buf_p	buf;	/* Buffer to read/write / send/recv / tp_task_conn_prms_p for connect_ex(). */
	size_t		tot_transfered_size; /* Total transfered size between calls of cb func / addrs_cur for connect_ex(). */
	uint64_t	start_time; /* Task start time. Used in connect_ex for time_limit work. ms from system up time (MONOTONIC).*/
	tp_task_cb	cb_func;/* Called after check return TP_TASK_DONE. */
	void		*udata;	/* Passed as arg to check and done funcs. */
	tpt_p		tpt;	/* Need for free and enable function */
} tp_task_t;


static void	tp_task_handler(int type, tp_event_p ev,
		    tp_udata_p tp_udata, int *cb_code_ret);
#define TP_TASK_H_TYPE_RW	1
#define TP_TASK_H_TYPE_SR	2

static int	tp_task_connect_ex_start(tp_task_p tptask, int do_connect);


int
tp_task_create(tpt_p tpt, uintptr_t ident, tp_cb tp_cb_func,
    uint32_t flags, void *udata, tp_task_p *tptask_ret) {
	tp_task_p tptask;

	if (NULL == tpt || NULL == tp_cb_func || NULL == tptask_ret)
		return (EINVAL);
	tptask = calloc(1, sizeof(tp_task_t));
	if (NULL == tptask)
		return (ENOMEM);
	tptask->tp_data.cb_func = tp_cb_func;
	tptask->tp_data.ident = ident;
	tptask->tp_timer.cb_func = tp_cb_func;
	tptask->tp_timer.ident = (uintptr_t)tptask;
	//tptask->event = event;
	//tptask->event_flags = event_flags;
	tptask->flags = flags;
	//tptask->timeout = timeout;
	//tptask->buf = buf;
	//tptask->tot_transfered_size = 0;
	//tptask->cb_func = cb_func;
	tptask->udata = udata;
	tptask->tpt = tpt;

	(*tptask_ret) = tptask;

	return (0);
}

int
tp_task_create_start(tpt_p tpt, uintptr_t ident, tp_cb tp_cb_func,
    uint32_t flags, uint16_t event, uint16_t event_flags,
    uint64_t timeout, off_t offset, io_buf_p buf, tp_task_cb cb_func,
    void *udata, tp_task_p *tptask_ret) {
	tp_task_p tptask;
	int error;

	if (NULL == tptask_ret)
		return (EINVAL);
	error = tp_task_create(tpt, ident, tp_cb_func, flags, udata,
	    &tptask);
	if (0 != error)
		return (error);
	error = tp_task_start(tptask, event, event_flags, timeout,
	    offset, buf, cb_func);
	if (0 != error) {
		tp_task_destroy(tptask);
		tptask = NULL;
	}
	(*tptask_ret) = tptask;
	return (error);
}

void
tp_task_destroy(tp_task_p tptask) {

	if (NULL == tptask)
		return;
	tp_task_stop(tptask);
	if ((uintptr_t)-1 != tptask->tp_data.ident &&
	    0 != (TP_TASK_F_CLOSE_ON_DESTROY & tptask->flags)) {
		close((int)tptask->tp_data.ident);
	}
	free(tptask);
}


tpt_p
tp_task_tpt_get(tp_task_p tptask) {
	
	if (NULL == tptask)
		return (NULL);
	return (tptask->tpt);
}

void
tp_task_tpt_set(tp_task_p tptask, tpt_p tpt) {
	
	if (NULL == tptask && NULL != tpt)
		return;
	tptask->tpt = tpt;
}


uintptr_t
tp_task_ident_get(tp_task_p tptask) {

	if (NULL == tptask)
		return ((uintptr_t)-1);
	return (tptask->tp_data.ident);
}

void
tp_task_ident_set(tp_task_p tptask, uintptr_t ident) {

	if (NULL == tptask)
		return;
	tptask->tp_data.ident = ident;
}

void
tp_task_ident_close(tp_task_p tptask) {

	if (NULL == tptask)
		return;
	tp_task_stop(tptask);
	if ((uintptr_t)-1 != tptask->tp_data.ident) {
		close((int)tptask->tp_data.ident);
		tptask->tp_data.ident = (uintptr_t)-1;
	}
}


tp_cb
tp_task_tp_cb_func_get(tp_task_p tptask) {

	if (NULL == tptask)
		return (NULL);
	return (tptask->tp_data.cb_func);
}

void
tp_task_tp_cb_func_set(tp_task_p tptask, tp_cb cb_func) {

	if (NULL == tptask || NULL == cb_func)
		return;
	tptask->tp_data.cb_func = cb_func;
	tptask->tp_timer.cb_func = cb_func;
}


tp_task_cb
tp_task_cb_func_get(tp_task_p tptask) {

	if (NULL == tptask)
		return (NULL);
	return (tptask->cb_func);
}

void
tp_task_cb_func_set(tp_task_p tptask, tp_task_cb cb_func) {

	if (NULL == tptask || NULL == cb_func)
		return;
	tptask->cb_func = cb_func;
}


void *
tp_task_udata_get(tp_task_p tptask) {

	if (NULL == tptask)
		return (NULL);
	return (tptask->udata);
}

void
tp_task_udata_set(tp_task_p tptask, void *udata) {

	if (NULL == tptask)
		return;
	tptask->udata = udata;
}


void
tp_task_flags_set(tp_task_p tptask, uint32_t flags) {

	if (NULL == tptask)
		return;
	tptask->flags = flags;
}

uint32_t
tp_task_flags_add(tp_task_p tptask, uint32_t flags) {

	if (NULL == tptask)
		return (0);
	tptask->flags |= flags;
	return (tptask->flags);
}

uint32_t
tp_task_flags_del(tp_task_p tptask, uint32_t flags) {

	if (NULL == tptask)
		return (0);
	tptask->flags &= ~flags;
	return (tptask->flags);
}

uint32_t
tp_task_flags_get(tp_task_p tptask) {

	if (NULL == tptask)
		return (0);
	return (tptask->flags);
}


off_t
tp_task_offset_get(tp_task_p tptask) {

	if (NULL == tptask)
		return (0);
	return (tptask->offset);
}

void
tp_task_offset_set(tp_task_p tptask, off_t offset) {

	if (NULL == tptask)
		return;
	tptask->offset = offset;
}


uint64_t
tp_task_timeout_get(tp_task_p tptask) {

	if (NULL == tptask)
		return (0);
	return (tptask->timeout);
}

void
tp_task_timeout_set(tp_task_p tptask, uint64_t timeout) {

	if (NULL == tptask)
		return;
	tptask->timeout = timeout;
}


io_buf_p
tp_task_buf_get(tp_task_p tptask) {

	if (NULL == tptask)
		return (NULL);
	return (tptask->buf);
}

void
tp_task_buf_set(tp_task_p tptask, io_buf_p buf) {

	if (NULL == tptask)
		return;
	tptask->buf = buf;
}

int
tp_task_start_ex(int shedule_first_io, tp_task_p tptask, uint16_t event,
    uint16_t event_flags, uint64_t timeout, off_t offset, io_buf_p buf,
    tp_task_cb cb_func) {
	int type, cb_ret;
	tp_event_t ev;

	if (NULL == tptask || NULL == cb_func)
		return (EINVAL);
	//tptask->tp_data.cb_func = tp_task_handler;
	//tptask->tp_data.ident = ident;
	tptask->event = event;
	tptask->event_flags = event_flags;
	//tptask->flags = flags;
	tptask->timeout = timeout;
	tptask->offset = offset;
	tptask->buf = buf;
	tptask->tot_transfered_size = 0;
	tptask->cb_func = cb_func;
	//tptask->udata = udata;
	//tptask->tpt = tpt;
	if (0 != shedule_first_io ||
	    NULL == buf) /* buf may point not to io_buf_p.  */
		goto shedule_io;
	if (tp_task_sr_handler == tptask->tp_data.cb_func) {
		type = TP_TASK_H_TYPE_SR;
	} else if (tp_task_rw_handler == tptask->tp_data.cb_func) {
		type = TP_TASK_H_TYPE_RW;
	} else { /* Notify handler does not support skip first IO. */
		goto shedule_io;
	}
	/* Now we shure that buf point to io_buf_p, do additional checks. */
	if (0 == IO_BUF_TR_SIZE_GET(buf))
		goto shedule_io;
	/* Validate buf. */
	if ((buf->offset + IO_BUF_TR_SIZE_GET(buf)) > buf->size)
		return (EINVAL);
	ev.event = event;
	ev.flags = 0;
	ev.fflags = 0;
	ev.data = (uint64_t)IO_BUF_TR_SIZE_GET(buf);

	tp_task_handler(type, &ev, &tptask->tp_data, &cb_ret);
	if (TP_TASK_CB_CONTINUE != cb_ret)
		return (0);
shedule_io:
	/* Handler func may change task! */
	return (tp_task_restart(tptask));
}

int
tp_task_start(tp_task_p tptask, uint16_t event, uint16_t event_flags,
    uint64_t timeout, off_t offset, io_buf_p buf, tp_task_cb cb_func) {

	return (tp_task_start_ex(1, tptask, event, event_flags, timeout,
	    offset, buf, cb_func));
}

int
tp_task_restart(tp_task_p tptask) {
	int error;

	if (NULL == tptask || NULL == tptask->cb_func)
		return (EINVAL);
	if (0 != tptask->timeout) { /* Set io timeout timer */
		error = tpt_ev_add_args(tptask->tpt, TP_EV_TIMER,
		    TP_F_DISPATCH, TP_FF_T_MSEC, tptask->timeout,
		    &tptask->tp_timer);
		if (0 != error)
			return (error);
	}
	error = tpt_ev_add_args2(tptask->tpt, tptask->event,
	    tptask->event_flags, &tptask->tp_data);
	if (0 != error)	{ /* Error, remove timer. */
		debugd_break();
		tpt_ev_del_args1(TP_EV_TIMER, &tptask->tp_data);
	}
	return (error);
}

void
tp_task_stop(tp_task_p tptask) {

	if (NULL == tptask)
		return;
	tpt_ev_del_args1(tptask->event, &tptask->tp_data);
	if (0 != tptask->timeout) {
		tpt_ev_del_args1(TP_EV_TIMER, &tptask->tp_timer);
	}
}


int
tp_task_enable(tp_task_p tptask, int enable) {
	int error;

	if (NULL == tptask)
		return (EINVAL);
	if (0 != tptask->timeout) {
		error = tpt_ev_enable_args(enable, TP_EV_TIMER,
		    TP_F_DISPATCH, TP_FF_T_MSEC, tptask->timeout,
		    &tptask->tp_timer);
		if (0 != error)
			return (error);
	}
	error = tpt_ev_enable_args1(enable, tptask->event, &tptask->tp_data);
	if (0 != error) {
		debugd_break();
		tpt_ev_enable_args1(0, TP_EV_TIMER, &tptask->tp_data);
	}
	return (error);
}


static inline int
tp_task_handler_pre_int(tp_event_p ev, tp_udata_p tp_udata,
    tp_task_p *tptask, uint32_t *eof, size_t *data2transfer_size) {

	(*eof) = ((0 != (TP_F_EOF & ev->flags)) ? TP_TASK_IOF_F_SYS : 0);
	/* Disable other events. */
	if (TP_EV_TIMER == ev->event) { /* Timeout! Disable io operation. */
		(*tptask) = (tp_task_p)tp_udata->ident;
		if (0 != (TP_F_ONESHOT & (*tptask)->event_flags)) {
			tp_task_stop((*tptask));
		} else {
			tpt_ev_enable_args1(0, (*tptask)->event,
			    &(*tptask)->tp_data);
		}
		(*data2transfer_size) = 0;
		return (ETIMEDOUT);
	}
	(*tptask) = (tp_task_p)tp_udata;
	if (0 != (*tptask)->timeout) { /* Disable/remove timer. */
		if (0 != (TP_F_ONESHOT & (*tptask)->event_flags)) {
			tpt_ev_del_args1(TP_EV_TIMER, &(*tptask)->tp_timer);
		} else {
			tpt_ev_enable_args1(0, TP_EV_TIMER,
			    &(*tptask)->tp_timer);
		}
	}
	(*data2transfer_size) = (size_t)ev->data;
	if (0 != (TP_F_ERROR & ev->flags)) /* Some error. */
		return (((int)ev->fflags));
	return (0);
}

static inline void
tp_task_handler_post_int(tp_event_p ev, tp_task_p tptask, int cb_ret) {

	if (TP_TASK_CB_CONTINUE != cb_ret)
		return;
	/* tp_task_enable() */
	if (0 != tptask->timeout) {
		tpt_ev_q_enable_args(1, TP_EV_TIMER, TP_F_DISPATCH,
		    TP_FF_T_MSEC, tptask->timeout, &tptask->tp_timer);
	}
	if (0 != (tptask->event_flags & TP_F_DISPATCH) ||
	    TP_EV_TIMER == ev->event) {
		tpt_ev_q_enable_args1(1, tptask->event, &tptask->tp_data);
	}
}


static void
tp_task_handler(int type, tp_event_p ev, tp_udata_p tp_udata,
    int *cb_code_ret) {
	tp_task_p tptask;
	uintptr_t ident;
	ssize_t ios;
	size_t data2transfer_size, transfered_size = 0;
	int error, cb_ret;
	uint32_t eof;

	debugd_break_if(NULL == ev);
	debugd_break_if(NULL == tp_udata);

	if (NULL != cb_code_ret) { /* Direct IO call. Skip many checks. */
		error = 0;
		eof = 0;
		tptask = (tp_task_p)tp_udata;
		data2transfer_size = (size_t)ev->data;
	} else {
		error = tp_task_handler_pre_int(ev, tp_udata, &tptask,
		    &eof, &data2transfer_size);
		/* Ignory error if we can transfer data. */
		if (0 == data2transfer_size ||
		    NULL == tptask->buf ||
		    0 == IO_BUF_TR_SIZE_GET(tptask->buf))
			goto call_cb; /* transfered_size = 0 */
		/* Transfer as much as we can. */
		data2transfer_size = MIN(data2transfer_size,
		    IO_BUF_TR_SIZE_GET(tptask->buf));
	}
	/* IO operations. */
	ident = tptask->tp_data.ident;
	switch (ev->event) {
	case TP_EV_READ:
		/* Do IO: read / recv / recvfrom. */
		while (transfered_size < data2transfer_size) { /* transfer loop. */
			if (TP_TASK_H_TYPE_RW == type) {
				ios = pread((int)ident,
				    IO_BUF_OFFSET_GET(tptask->buf),
				    IO_BUF_TR_SIZE_GET(tptask->buf),
				    tptask->offset);
			} else { /* TP_TASK_H_TYPE_SR */
				ios = recv((int)ident,
				    IO_BUF_OFFSET_GET(tptask->buf),
				    IO_BUF_TR_SIZE_GET(tptask->buf),
				    MSG_DONTWAIT);
			}
			SYSLOGD_EX(LOG_DEBUG, "ev->data = %zu, ios = %zu, "
			    "transfered_size = %zu, eof = %i, err = %i",
			    ev->data, ios, transfered_size, eof, errno);
			if (-1 == ios) /* Error. */
				goto err_out;
			if (0 == ios) { /* All data read. */
				/* Set EOF ONLY if no data read and it is direct call
				 * from tp_task_start_ex() or other int func, 
				 * - not from thread pool.
				 * Thread pool set EOF by self and dont need help.
				 */
				 /* Set EOF allways: eof may happen after thread pool
				  * call this callback and before pread/recv done. */
				if (/*NULL != cb_code_ret &&*/
				    0 != IO_BUF_TR_SIZE_GET(tptask->buf)) {
					eof |= TP_TASK_IOF_F_BUF;
				}
				goto call_cb;
			}
			transfered_size += (size_t)ios;
			tptask->offset += (size_t)ios;
			IO_BUF_USED_INC(tptask->buf, (size_t)ios);
			IO_BUF_OFFSET_INC(tptask->buf, (size_t)ios);
			IO_BUF_TR_SIZE_DEC(tptask->buf, (size_t)ios);
			if (0 == IO_BUF_TR_SIZE_GET(tptask->buf) || /* All data read. */
			    0 != (TP_TASK_F_CB_AFTER_EVERY_READ & tptask->flags))
				goto call_cb;
		} /* end while() */
		/* Continue read/recv. */
		/* Linux: never get here: data2transfer_size = UINT64_MAX, so
		 * we go to err_out with errno = EAGAIN */
		tptask->tot_transfered_size += transfered_size; /* Save transfered_size. */
		cb_ret = TP_TASK_CB_CONTINUE;
		goto call_cb_handle;
	case TP_EV_WRITE:
		/* Do IO: pwrite / send. */
		while (transfered_size < data2transfer_size) { /* transfer loop. */
			if (TP_TASK_H_TYPE_RW == type) {
				ios = pwrite((int)ident,
				    IO_BUF_OFFSET_GET(tptask->buf),
				    IO_BUF_TR_SIZE_GET(tptask->buf),
				    tptask->offset);
			} else { /* TP_TASK_H_TYPE_SR */
				ios = send((int)ident,
				    IO_BUF_OFFSET_GET(tptask->buf),
				    IO_BUF_TR_SIZE_GET(tptask->buf),
				    (MSG_DONTWAIT | MSG_NOSIGNAL));
			}
			if (-1 == ios) /* Error. */
				goto err_out;
			if (0 == ios) /* All data written. */
				goto call_cb;
			transfered_size += (size_t)ios;
			tptask->offset += (size_t)ios;
			IO_BUF_OFFSET_INC(tptask->buf, (size_t)ios);
			IO_BUF_TR_SIZE_DEC(tptask->buf, (size_t)ios);
			if (0 == IO_BUF_TR_SIZE_GET(tptask->buf)) /* All data written. */
				goto call_cb;
		} /* end while() */
		/* Continue write/send at next event. */
		/* Linux: never get here: data2transfer_size = UINT64_MAX, so
		 * we go to err_out with errno = EAGAIN */
		tptask->tot_transfered_size += transfered_size; /* Save transfered_size. */
		cb_ret = TP_TASK_CB_CONTINUE;
		goto call_cb_handle;
	default: /* Unknown filter. */
		debugd_break();
		error = ENOSYS;
		goto call_cb;
	}

err_out: /* Error. */
	error = errno;
	if (0 == error) {
		error = EINVAL;
	}
	error = SKT_ERR_FILTER(error);
	if (0 == error) {
		tptask->tot_transfered_size += transfered_size; /* Save transfered_size. */
		cb_ret = TP_TASK_CB_CONTINUE;
		goto call_cb_handle;
	}

call_cb:
	transfered_size += tptask->tot_transfered_size;
	tptask->tot_transfered_size = 0;
	cb_ret = tptask->cb_func(tptask, error, tptask->buf, eof,
	    transfered_size, tptask->udata);

call_cb_handle:
	if (NULL != cb_code_ret) { /* Extrenal handle cb code. */
		(*cb_code_ret) = cb_ret;
		return;
	}
	tp_task_handler_post_int(ev, tptask, cb_ret);
}

void
tp_task_rw_handler(tp_event_p ev, tp_udata_p tp_udata) {

	tp_task_handler(TP_TASK_H_TYPE_RW, ev, tp_udata, NULL);
}

void
tp_task_sr_handler(tp_event_p ev, tp_udata_p tp_udata) {

	tp_task_handler(TP_TASK_H_TYPE_SR, ev, tp_udata, NULL);
}

void
tp_task_notify_handler(tp_event_p ev, tp_udata_p tp_udata) {
	tp_task_p tptask;
	size_t data2transfer_size;
	int error, cb_ret;
	uint32_t eof;

	debugd_break_if(NULL == ev);
	debugd_break_if(NULL == tp_udata);

	error = tp_task_handler_pre_int(ev, tp_udata, &tptask, &eof,
	    &data2transfer_size);
	cb_ret = ((tp_task_notify_cb)tptask->cb_func)(tptask, error,
	    eof, data2transfer_size, tptask->udata);
	tp_task_handler_post_int(ev, tptask, cb_ret);
}

void
tp_task_pkt_rcvr_handler(tp_event_p ev, tp_udata_p tp_udata) {
	tp_task_p tptask;
	uintptr_t ident;
	ssize_t ios;
	size_t data2transfer_size, transfered_size = 0;
	int error, cb_ret;
	uint32_t eof;
	socklen_t addrlen;
	struct sockaddr_storage ssaddr;

	debugd_break_if(NULL == ev);
	debugd_break_if(NULL == tp_udata);

	error = tp_task_handler_pre_int(ev, tp_udata, &tptask, &eof,
	    &data2transfer_size);
	if (TP_EV_WRITE == ev->event) {
		debugd_break();
		error = EINVAL;
	}
	if (0 != error) { /* Report about error. */
call_cb:
		cb_ret = ((tp_task_pkt_rcvr_cb)tptask->cb_func)(tptask,
		    error, NULL, tptask->buf, 0, tptask->udata);
		if (TP_TASK_CB_CONTINUE != cb_ret)
			return;
		if (0 == data2transfer_size)
			goto call_cb_handle;
		/* Try to receive data. */
	}

	cb_ret = TP_TASK_CB_CONTINUE;
	ident = tptask->tp_data.ident;
	while (transfered_size < data2transfer_size) { /* recv loop. */
		addrlen = sizeof(ssaddr);
		ios = recvfrom((int)ident, IO_BUF_OFFSET_GET(tptask->buf),
		    IO_BUF_TR_SIZE_GET(tptask->buf), MSG_DONTWAIT,
		    (struct sockaddr*)&ssaddr, &addrlen);
		if (-1 == ios) { /* Error. */
			error = errno;
			if (0 == error) {
				error = EINVAL;
			}
			error = SKT_ERR_FILTER(error);
			if (0 == error) { /* No more data. */
				cb_ret = TP_TASK_CB_CONTINUE;
				goto call_cb_handle;
			}
			goto call_cb; /* Report about error. */
		}
		if (0 == ios)
			break;
		transfered_size += (size_t)ios;
		IO_BUF_USED_INC(tptask->buf, ios);
		IO_BUF_OFFSET_INC(tptask->buf, ios);
		IO_BUF_TR_SIZE_DEC(tptask->buf, ios);

		cb_ret = ((tp_task_pkt_rcvr_cb)tptask->cb_func)(tptask,
		    /*error*/ 0, &ssaddr, tptask->buf, (size_t)ios,
		    tptask->udata);
		if (TP_TASK_CB_CONTINUE != cb_ret)
			return;
	} /* end recv while */

call_cb_handle:
	tp_task_handler_post_int(ev, tptask, cb_ret);
}

void
tp_task_accept_handler(tp_event_p ev, tp_udata_p tp_udata) {
	tp_task_p tptask;
	uintptr_t skt;
	int error, cb_ret;
	uint32_t eof = 0;
	size_t i, data2transfer_size;
	socklen_t addrlen;
	struct sockaddr_storage ssaddr;

	debugd_break_if(NULL == ev);
	debugd_break_if(NULL == tp_udata);

	error = tp_task_handler_pre_int(ev, tp_udata, &tptask, &eof,
	    &data2transfer_size);
	if (TP_EV_WRITE == ev->event) {
		debugd_break();
		error = EINVAL;
	}
	if (0 != error) { /* Report about error. */
call_cb:
		cb_ret = ((tp_task_accept_cb)tptask->cb_func)(tptask,
		    error, (uintptr_t)-1, NULL, tptask->udata);
		goto call_cb_handle;
	}

	cb_ret = TP_TASK_CB_CONTINUE;
	for (i = 0; i < data2transfer_size; i ++) { /* Accept all connections! */
		addrlen = sizeof(ssaddr);
		error = skt_accept(tptask->tp_data.ident,
		    &ssaddr, &addrlen, SO_F_NONBLOCK, &skt);
		if (0 != error) { /* Error. */
			error = SKT_ERR_FILTER(error);
			if (0 == error) { /* No more new connections. */
				cb_ret = TP_TASK_CB_CONTINUE;
				goto call_cb_handle;
			}
			goto call_cb; /* Report about error. */
		}
		cb_ret = ((tp_task_accept_cb)tptask->cb_func)(tptask,
		    /*error*/ 0, skt, &ssaddr, tptask->udata);
		if (TP_TASK_CB_CONTINUE != cb_ret)
			return;
	}

call_cb_handle:
	tp_task_handler_post_int(ev, tptask, cb_ret);
}

void
tp_task_connect_handler(tp_event_p ev, tp_udata_p tp_udata) {
	tp_task_p tptask;
	int error;

	debugd_break_if(NULL == ev);
	debugd_break_if(NULL == tp_udata);

	if (TP_EV_TIMER == ev->event) { /* Timeout! */
		tptask = (tp_task_p)tp_udata->ident;
		error = ETIMEDOUT;
	} else {
		debugd_break_if(TP_EV_WRITE != ev->event);
		tptask = (tp_task_p)tp_udata;
		error = ((TP_F_ERROR & ev->flags) ? ((int)ev->fflags) : 0); /* Some error? */
	}
	tp_task_stop(tptask); /* Call it on write and timeout. */
	((tp_task_connect_cb)tptask->cb_func)(tptask, error, tptask->udata);
}


int
tp_task_cb_check(io_buf_p buf, uint32_t eof, size_t transfered_size) {

	/* All data transfered! */
	if (NULL != buf &&
	    0 == IO_BUF_TR_SIZE_GET(buf))
		return (TP_TASK_CB_NONE);
	/* Connection closed / end of file. */
	if (0 != eof)
		return (TP_TASK_CB_EOF);
	/* Error may contain error code, or not, let done func handle this. */
	if ((size_t)-1 == transfered_size)
		return (TP_TASK_CB_ERROR);
	/* No free spase in recv buf / EOF */
	if (0 == transfered_size)
		return (TP_TASK_CB_ERROR);

	/* Handle data:
	 * here we can check received data, and decide receive more or process
	 * received in done func but this is generic receiver untill buf full or
	 * connection closed, so continue receive.
	 */
	/* Need transfer more data. */
	return (TP_TASK_CB_CONTINUE);
}


int
tp_task_notify_create(tpt_p tpt, uintptr_t ident, uint32_t flags,
    uint16_t event, uint64_t timeout, tp_task_notify_cb cb_func,
    void *udata, tp_task_p *tptask_ret) {
	int error;

	flags &= TP_TASK_F_CLOSE_ON_DESTROY; /* Filter out flags. */
	error = tp_task_create_start(tpt, ident, tp_task_notify_handler,
	    flags, event, 0/*TP_F_DISPATCH*/, timeout, 0, NULL,
	    (tp_task_cb)cb_func, udata, tptask_ret);
	return (error);
}

int
tp_task_pkt_rcvr_create(tpt_p tpt, uintptr_t ident, uint32_t flags,
    uint64_t timeout, io_buf_p buf, tp_task_pkt_rcvr_cb cb_func,
    void *udata, tp_task_p *tptask_ret) {
	int error;

	flags &= TP_TASK_F_CLOSE_ON_DESTROY; /* Filter out flags. */
	flags |= TP_TASK_F_CB_AFTER_EVERY_READ; /* Add flags. */
	error = tp_task_create_start(tpt, ident, tp_task_pkt_rcvr_handler,
	    flags, TP_EV_READ, 0/*TP_F_DISPATCH*/, timeout, 0, buf,
	    (tp_task_cb)cb_func, udata, tptask_ret);
	return (error);
}

int
tp_task_accept_create(tpt_p tpt, uintptr_t ident, uint32_t flags,
    uint64_t timeout, tp_task_accept_cb cb_func, void *udata,
    tp_task_p *tptask_ret) {
	int error;

	flags &= TP_TASK_F_CLOSE_ON_DESTROY; /* Filter out flags. */
	error = tp_task_create_start(tpt, ident, tp_task_accept_handler,
	    flags, TP_EV_READ, 0, timeout, 0, NULL,
	    (tp_task_cb)cb_func, udata, tptask_ret);
	return (error);
}

int
tp_task_bind_accept_create(tpt_p tpt,
    const sockaddr_storage_t *addr, int type, int protocol, skt_opts_p skt_opts,
    uint32_t flags, uint64_t timeout, tp_task_accept_cb cb_func, void *udata,
    tp_task_p *tptask_ret) {
	int error;
	uint32_t err_mask;
	uintptr_t skt = (uintptr_t)-1;

	if (NULL == tpt || NULL == addr || NULL == skt_opts || NULL == tptask_ret)
		return (EINVAL);

	error = skt_bind(addr, type, protocol,
	    (SO_F_NONBLOCK | SKT_OPTS_GET_FLAGS_VALS(skt_opts, SKT_BIND_FLAG_MASK)),
	    &skt);
	if (0 != error)
		goto err_out;
	if (SOCK_STREAM == type) {
		error = skt_listen(skt, skt_opts->backlog);
		if (0 != error)
			goto err_out;
	}
	/* Tune socket. */
	error = skt_opts_apply_ex(skt, SO_F_TCP_LISTEN_AF_MASK,
	    skt_opts, addr->ss_family, &err_mask);
	if (0 != error) { /* Non fatal error. */
		skt_opts->bit_vals &= ~(err_mask & SO_F_ACC_FILTER);
	}
	error = tp_task_accept_create(tpt, skt, flags, timeout,
	    cb_func, udata, tptask_ret);
	if (0 == error)
		return (0);

err_out: /* Error. */
	close((int)skt);
	(*tptask_ret) = NULL;

	return (error);
}

int
tp_task_bind_accept_multi_create(tp_p tp,
    const sockaddr_storage_t *addr, int type, int protocol, skt_opts_p skt_opts,
    uint32_t flags, uint64_t timeout, tp_task_accept_cb cb_func, void *udata,
    size_t *tptasks_count_ret, tp_task_p **tptasks_ret) {
	int error;
	size_t i, max_threads = 1, tptasks_cnt = 0;
	tp_task_p *tptasks;
	tpt_p tpt;

	if (NULL == tp || NULL == addr || NULL == skt_opts ||
	    NULL == tptasks_count_ret || NULL == tptasks_ret)
		return (EINVAL);

#if defined(__linux__) || defined(SO_REUSEPORT_LB)
	/* Can balance incomming connections. */
	if (SKT_OPTS_IS_FLAG_ACTIVE(skt_opts, SO_F_REUSEPORT)) {
		/* Listen socket per thread. */
		max_threads = tp_thread_count_max_get(tp);
	}
#endif

	tptasks = calloc(max_threads, sizeof(tp_task_p));
	if (NULL == tptasks)
		return (ENOMEM);

	/* Create listen sockets per thread or on one on rand thread. */
	for (i = 0; i < max_threads; i ++) {
#if defined(__linux__) || defined(SO_REUSEPORT_LB)
		/* Can balance incomming connections. */
		if (SKT_OPTS_IS_FLAG_ACTIVE(skt_opts, SO_F_REUSEPORT)) {
			tpt = tp_thread_get(tp, i);
		} else
#endif
		{
			tpt = tp_thread_get_rr(tp);
		}
		error = tp_task_bind_accept_create(tpt,
		    addr, type, protocol, skt_opts,
		    flags, timeout, cb_func, udata, &tptasks[tptasks_cnt]);
		if (0 != error)
			goto err_out;
		tptasks_cnt ++;
	}

	(*tptasks_count_ret) = tptasks_cnt;
	(*tptasks_ret) = tptasks;

	return (0);

err_out: /* Error. */
	for (i = 0; i < tptasks_cnt; i ++) {
		if (0 == (TP_TASK_F_CLOSE_ON_DESTROY & flags)) {
			tp_task_ident_close(tptasks[i]);
		}
		tp_task_destroy(tptasks[i]);
	}
	free(tptasks);
	(*tptasks_count_ret) = 0;
	(*tptasks_ret) = NULL;

	return (error);
}


int
tp_task_connect_create(tpt_p tpt, uintptr_t ident, uint32_t flags,
    uint64_t timeout, tp_task_connect_cb cb_func, void *udata,
    tp_task_p *tptask_ret) {
	int error;

	flags &= TP_TASK_F_CLOSE_ON_DESTROY; /* Filter out flags. */
	error = tp_task_create_start(tpt, ident, tp_task_connect_handler,
	    flags, TP_EV_WRITE, TP_F_ONESHOT, timeout, 0, NULL,
	    (tp_task_cb)cb_func, udata, tptask_ret);
	return (error);
}

int
tp_task_connect_send_create(tpt_p tpt, uintptr_t ident,
    uint32_t flags, uint64_t timeout, io_buf_p buf, tp_task_cb cb_func,
    void *udata, tp_task_p *tptask_ret) {
	int error;

	flags &= TP_TASK_F_CLOSE_ON_DESTROY; /* Filter out flags. */
	error = tp_task_create_start(tpt, ident, tp_task_sr_handler,
	    flags, TP_EV_WRITE, 0, timeout, 0, buf, cb_func, udata,
	    tptask_ret);
	return (error);
}


void
tp_task_connect_ex_handler(tp_event_p ev, tp_udata_p tp_udata) {
	int error, cb_ret;
	tp_task_p tptask;

	debugd_break_if(NULL == ev);
	debugd_break_if(NULL == tp_udata);

	if (TP_EV_TIMER == ev->event) { /* Timeout / retry delay! */
		tptask = (tp_task_p)tp_udata->ident;
		if ((uintptr_t)-1 == tptask->tp_data.ident) { /* Retry delay. */
			/* XXX tp_task_stop()? */
			error = 0;
			goto connect_ex_start;
		}
		error = ETIMEDOUT; /* Timeout */
	} else {
		debugd_break_if(TP_EV_WRITE != ev->event);
		tptask = (tp_task_p)tp_udata;
		error = ((TP_F_ERROR & ev->flags) ? ((int)ev->fflags) : 0); /* Some error? */
	}
	tp_task_stop(tptask);

	if (0 == error) { /* Connected: last report. */
		((tp_task_connect_ex_cb)tptask->cb_func)(tptask, error,
		    (tp_task_conn_prms_p)tptask->buf,
		    tptask->tot_transfered_size, tptask->udata);
		return; /* Done with this task. */
	}
	/* Error, retry. */
	close((int)tptask->tp_data.ident);
	tptask->tp_data.ident = (uintptr_t)-1;
	for (;;) {
		/* Report about fail to connect. */
		if (-1 == error || /* Can not continue, always report! */
		    0 != (TP_TASK_F_CB_AFTER_EVERY_READ & tptask->flags)) {
			cb_ret = ((tp_task_connect_ex_cb)tptask->cb_func)(tptask,
			    error, (tp_task_conn_prms_p)tptask->buf,
			    tptask->tot_transfered_size, tptask->udata);
			if (-1 == error ||
			    TP_TASK_CB_CONTINUE != cb_ret)
				return; /* Can not continue... */
		}
		if (0 == ((tp_task_conn_prms_p)tptask->buf)->max_tries || /* Force: TP_TASK_CONNECT_F_ROUND_ROBIN */
		    0 != (((tp_task_conn_prms_p)tptask->buf)->flags & TP_TASK_CONNECT_F_ROUND_ROBIN)) {
			tptask->tot_transfered_size ++; /* Move to next addr. */
		} else {
			tptask->offset ++; /* One more try connect to addr. */
		}
connect_ex_start:
		error = tp_task_connect_ex_start(tptask, (0 == error));
		if (0 == error)
			return; /* Connect retry sheduled. */
		/* Fail / no more time/retries, report to cb. */
	}
}

static int
tp_task_connect_ex_start(tp_task_p tptask, int do_connect) {
	int error;
	uint64_t time_limit_ms = 0, time_run_ms;
	struct timespec	time_now;
	tp_task_conn_prms_p conn_prms;

	if (NULL == tptask)
		return (EINVAL);
	conn_prms = (tp_task_conn_prms_p)tptask->buf;
	if (0 != do_connect)
		goto try_connect;
	/* Check connect time limit / do initial delay. */
	if (0 == tptask->offset &&
	    0 == tptask->tot_transfered_size) { /* First connect attempt. */
		if (0 != (conn_prms->flags & TP_TASK_CONNECT_F_INITIAL_DELAY) &&
		    0 != conn_prms->retry_delay)
			goto shedule_delay_timer;
	} else {
		if (0 != conn_prms->time_limit) { /* time limit checks. */
			clock_gettime(CLOCK_MONOTONIC_FAST, &time_now);
			time_run_ms = (TIMESPEC_TO_MS(&time_now) -
			    tptask->start_time); /* Task run time. */
			time_limit_ms = conn_prms->time_limit;
			if (time_limit_ms <= time_run_ms)
				return (-1); /* No more tries. */
			time_limit_ms -= time_run_ms; /* Time to end task. */
		}

		/* Check addr index and retry limit. */
		if (0 == conn_prms->max_tries || /* Force: TP_TASK_CONNECT_F_ROUND_ROBIN */
		    0 != (conn_prms->flags & TP_TASK_CONNECT_F_ROUND_ROBIN)) {
			if (tptask->tot_transfered_size >= conn_prms->addrs_count) {
				tptask->tot_transfered_size = 0;
				tptask->offset ++;
				if (0 != conn_prms->max_tries &&
				    (uint64_t)tptask->offset >= conn_prms->max_tries)
					return (-1); /* No more rounds/tries. */
				/* Delay between rounds. */
				if (0 != conn_prms->retry_delay)
					goto shedule_delay_timer;
			}
		} else {
			if ((uint64_t)tptask->offset >= conn_prms->max_tries) {
				tptask->tot_transfered_size ++;
				tptask->offset = 0;
				if (tptask->tot_transfered_size >= conn_prms->addrs_count)
					return (-1); /* No more tries. */
			}
			/* Delay before next connect attempt. */
			if (0 != conn_prms->retry_delay)
				goto shedule_delay_timer;
		}
	}

try_connect:
	/* Create socket, try to connect, start IO task with created socket. */
	error = skt_connect(&conn_prms->addrs[tptask->tot_transfered_size],
	    SOCK_STREAM, conn_prms->protocol,
	    SO_F_NONBLOCK, &tptask->tp_data.ident);
	if (0 != error) /* Cant create socket. */
		return (error);
	error = tp_task_start(tptask, TP_EV_WRITE,
	    TP_F_ONESHOT, tptask->timeout, tptask->offset,
	    tptask->buf, tptask->cb_func);
	if (0 != error) {
		close((int)tptask->tp_data.ident);
		tptask->tp_data.ident = (uintptr_t)-1;
	}
	return (error);

shedule_delay_timer:
	/* Shedule delay timer. */
	if (0 != time_limit_ms &&
	    conn_prms->retry_delay >= time_limit_ms)
		return (-1); /* No more tries. */
	error = tpt_ev_add_args(tptask->tpt, TP_EV_TIMER,
	    TP_F_DISPATCH, TP_FF_T_MSEC, conn_prms->retry_delay,
	    &tptask->tp_timer);
	return (error);
}

int
tp_task_connect_ex_create(tpt_p tpt, uint32_t flags,
    uint64_t timeout, tp_task_conn_prms_p conn_prms,
    tp_task_connect_ex_cb cb_func, void *udata, tp_task_p *tptask_ret) {
	int error;
	tp_task_p tptask;
	struct timespec	time_now;

	if (NULL == conn_prms || NULL == tptask_ret)
		return (EINVAL);
	if (0 != (conn_prms->flags & TP_TASK_CONNECT_F_INITIAL_DELAY) &&
	    0 == conn_prms->retry_delay)
		return (EINVAL);
	if (0 != conn_prms->time_limit) {
		if (0 == timeout ||
		    timeout >= conn_prms->time_limit)
			return (EINVAL);
		if (conn_prms->retry_delay >= conn_prms->time_limit)
			return (EINVAL);
	}
	flags &= (TP_TASK_F_CLOSE_ON_DESTROY | TP_TASK_F_CB_AFTER_EVERY_READ); /* Filter out flags. */
	error = tp_task_create(tpt, (uintptr_t)-1,
	    tp_task_connect_ex_handler, flags, udata, &tptask);
	if (0 != error)
		return (error);
	/* Set internal task values. */
	tptask->timeout = timeout;
	//tptask->offset = 0; /* try_no */
	tptask->buf = (io_buf_p)conn_prms;
	//tptask->tot_transfered_size = 0; /* addrs_cur */
	tptask->cb_func = (tp_task_cb)cb_func;
	if (0 != conn_prms->time_limit) {
		clock_gettime(CLOCK_MONOTONIC_FAST, &time_now);
		tptask->start_time = TIMESPEC_TO_MS(&time_now);
	}

	/* Try to shedule IO for connect. */
	for (;;) {
		error = tp_task_connect_ex_start(tptask, 0);
		if (0 == error ||
		    -1 == error)
			break; /* OK / Error - can not continue. */
		if (0 == conn_prms->max_tries || /* Force: TP_TASK_CONNECT_F_ROUND_ROBIN */
		    0 != (conn_prms->flags & TP_TASK_CONNECT_F_ROUND_ROBIN)) {
			tptask->tot_transfered_size ++; /* Move to next addr. */
		} else {
			tptask->offset ++; /* One more try connect to addr. */
		}
	}
	if (0 != error) {
		tp_task_destroy(tptask);
		tptask = NULL;
	}
	(*tptask_ret) = tptask;
	return (error);
}
