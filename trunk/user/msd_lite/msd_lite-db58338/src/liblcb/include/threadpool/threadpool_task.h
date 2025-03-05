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

 
#ifndef __THREAD_POOL_TASK_H__
#define __THREAD_POOL_TASK_H__


#include <sys/param.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <inttypes.h>

#include "utils/io_buf.h"
#include "net/socket.h"
#include "net/socket_options.h"
#include "threadpool/threadpool.h"
#include "threadpool/threadpool_msg_sys.h"



typedef struct tp_task_s *tp_task_p;
/* tp_task flags: */
#define TP_TASK_F_CLOSE_ON_DESTROY	(((uint32_t)1) << 0) /* Call close(ident) in tp_task_destroy(). */
#define TP_TASK_F_CB_AFTER_EVERY_READ	(((uint32_t)1) << 1) /* Call cb_func after each read/recv. 
					* Allways set for TP_TASK_TYPE_SOCK_DGRAM with
					* TP_TASK_F_CB_TYPE_DEFAULT
					*/


/* Replace 'io_buf_p' for connect_ex(). */
typedef struct tp_task_connect_params_s {
	uint64_t	time_limit;	/* Time limit for all retries / max connect time. 0 - no limit. ms from system up time (MONOTONIC). */
	uint64_t	retry_delay;	/* Wait before retry / time before try connect to next addr. ms. */
	uint64_t	max_tries;	/* Num tries to connect. 0 - no limit, also set TP_TASK_CONNECT_F_ROUND_ROBIN. */
	uint32_t	flags;		/* Flags. */
	int		protocol;	/* Socket proto. 0 - os auto = IPPROTO_TCP in most cases. */
	size_t		addrs_count;	/* Addresses count. */
	struct sockaddr_storage *addrs;	/* Addresses connect to. */
} tp_task_conn_prms_t, *tp_task_conn_prms_p;

#define TP_TASK_CONNECT_F_INITIAL_DELAY	(((uint32_t)1) << 0) /* Delay before first try. retry_delay must be set to non zero! */
#define TP_TASK_CONNECT_F_ROUND_ROBIN	(((uint32_t)1) << 1) /* while (max_tries --) { connect(addrs[0]...addrs[addrs_count]); sleep(retry_delay) }. */



/* Replace 'io_buf_p' for send_file(). */
/* TODO: write 
 * - tp_task_sendfile_handler();
 * - tp_task_create_sendfile();
 * - tp_task_sendfile_cb().
 */
typedef struct tp_task_sendfile_s { /* send_file */
	/*uintptr_t	fd; - send data from tp_task.ident */
	/*off_t		offset; - tp_task.offset */
	uintptr_t	s; /* Socket to send data. */
	size_t		nbytes; /* Number of bytes to send. */
#ifdef BSD /* BSD specific code. */
	struct sf_hdtr	hdtr; /* XXX: use writev/sendmsg in linux? */
	off_t		sbytes;
	int		flags;
#endif /* BSD specific code. */
} tp_task_sf_t, *tp_task_sf_p;


/* Internal tp_cb tp.data.cb funtions handlers: */

void	tp_task_rw_handler(tp_event_p ev, tp_udata_p tp_udata);
/* read() / write() from/to buf. */
/* cb func type: tp_task_cb */

void	tp_task_sr_handler(tp_event_p ev, tp_udata_p tp_udata);
/* send() / recv() from/to buf. */
/* cb func type: tp_task_cb */

void	tp_task_notify_handler(tp_event_p ev, tp_udata_p tp_udata);
/* Only notify cb function about IO ready for descriptor. */
/* cb func type: tp_task_notify_cb */

void	tp_task_pkt_rcvr_handler(tp_event_p ev, tp_udata_p tp_udata);
/* recvfrom() to buf. */
/* cb func type: tp_task_pkt_rcvr_cb */

void	tp_task_accept_handler(tp_event_p ev, tp_udata_p tp_udata);
/* Notify cb function on new connection received, pass new socket and perr addr. */
/* cb func type: tp_task_accept_cb */

void	tp_task_connect_handler(tp_event_p ev, tp_udata_p tp_udata);
/* Call tp_task_stop() and notify cb function then descriptor ready to write. */
/* cb func type: tp_task_connect_cb */

void	tp_task_connect_ex_handler(tp_event_p ev, tp_udata_p tp_udata);
/* Call tp_task_stop() and notify cb function then descriptor ready to write. */
/* cb func type: tp_task_connect_ex_cb */


/* Call back functions return codes: */
#define TP_TASK_CB_ERROR	-1 /* error, call done func with error code */
#define TP_TASK_CB_NONE		0 /* Do nothink / All done, call done func, error = 0. */
#define TP_TASK_CB_EOF		1 /* end of file / conn close / half closed: other side call shutdown(, SHUT_WR) */
#define TP_TASK_CB_CONTINUE	2 /* recv/read / send/write - reshedule task
				* eg call tp_task_enable().
				* should not retun if TP_F_ONESHOT event_flags is set
				*/
/* Return TP_TASK_CB_CONTINUE to continue recv/rechedule io. 
 * All other return codes stop callback untill tp_task_enable(1) is called
 * if TP_F_DISPATCH flag was set.
 * TP_F_DISPATCH = auto disable task before callback. ie manual mode.
 * If event flag TP_F_DISPATCH not set in tp_task_start(event_flags) then you must
 * call tp_task_stop() / tp_task_enable(0) / tp_task_ident_close() / tp_task_destroy()
 * before return code other than TP_TASK_CB_CONTINUE.
 */


#define TP_TASK_IOF_F_SYS	(((uint32_t)1) << 0) /* System return EOF. */
#define TP_TASK_IOF_F_BUF	(((uint32_t)1) << 1) /* All data in task buf transfered. Only for read/recv. */

/* Call back function types. */
typedef int (*tp_task_cb)(tp_task_p tptask, int error, io_buf_p buf,
    uint32_t eof, size_t transfered_size, void *udata);
/* Transfer data to/from buf and then call back. */

typedef int (*tp_task_pkt_rcvr_cb)(tp_task_p tptask, int error,
    struct sockaddr_storage *addr, io_buf_p buf, size_t transfered_size,
    void *udata);
/* Designed for receive datagramms. If TP_TASK_F_CB_AFTER_EVERY_READ not set
 * then packets data will store in singe buffer, and thet call cb function
 * with peer addr from last received packet. */

typedef int (*tp_task_notify_cb)(tp_task_p tptask, int error,
    uint32_t eof, size_t data2transfer_size, void *udata);
/* Notify call back function: ident ready for data transfer. */

typedef int (*tp_task_accept_cb)(tp_task_p tptask, int error,
    uintptr_t skt_new, struct sockaddr_storage *addr, void *udata);
/* Callback then new connection received. */

typedef int (*tp_task_connect_cb)(tp_task_p tptask, int error, void *udata);
/* Callback then connection to remonte host established.
 * Handler call tp_task_stop() before tp_task_connect_cb call.
 * Use in case you need connect and receive data.
 * For connect and send use tp_task_sr_handler() + tp_task_cb() for write. */
/* TP_TASK_CB_CONTINUE return code - ignored. */

typedef int (*tp_task_connect_ex_cb)(tp_task_p tptask, int error,
    tp_task_conn_prms_p conn_prms, size_t addr_index, void *udata);
/* Callback then connection established or error happen (if TP_TASK_F_CB_AFTER_EVERY_READ set). */
/* TP_TASK_CB_CONTINUE return code - ignored if error = 0 or error = -1. */



/* Create io task and set some data. */
int	tp_task_create(tpt_p tpt, uintptr_t ident,
	    tp_cb tp_cb_func, uint32_t flags, void *udata,
	    tp_task_p *tptask_ret);
/* tpt - Thread pool thread pointer
 * ident - socket/file descriptor
 * tp_cb_func - tp_task_XXX_handler(...) - internal io task handler function
 * flags - io task flags: TP_TASK_F_*
 * arg - associated user data, passed to cb_func()
 * tptask_ret - pointer to return created tptask.
 */
/* tp_task_create() + tp_task_start() */
int	tp_task_create_start(tpt_p tpt, uintptr_t ident,
	    tp_cb tp_cb_func, uint32_t flags, uint16_t event,
	    uint16_t event_flags, uint64_t timeout, off_t offset,
	    io_buf_p buf, tp_task_cb cb_func, void *udata,
	    tp_task_p *tptask_ret);
/* Call tp_task_stop(); optional: close(ident). */
void	tp_task_destroy(tp_task_p tptask);


/* Set some vars in tp_task_s and shedule io for 'ident'. */
int	tp_task_start_ex(int shedule_first_io, tp_task_p tptask,
	    uint16_t event, uint16_t event_flags, uint64_t timeout,
	    off_t offset, io_buf_p buf, tp_task_cb cb_func);
int	tp_task_start(tp_task_p tptask, uint16_t event,
	    uint16_t event_flags, uint64_t timeout, off_t offset,
	    io_buf_p buf, tp_task_cb cb_func);
/*
 * sfio - shedule first io, set 0 if you want do first recv/send/read/write without
 *  sheduling via kqueue/epoll.
 *  Need to receive data after accept() + accept_filter callback: we know that data
 *  allready received, but not shure that all data/full request.
 * tptask - point to io task.
 * event - TP_EV_*.
 * event_flags - TP_F_*, see tpt_ev_add()
 * timeout - time out for io in ms (1 second = 1000 ms).
 * buf - pointer to io_buf for read/write
 *  buf->offset + buf->transfer_size <= buf->size
 *  If buf is null then tp_task_cb() called every time.
 * cb_func - call back function: tp_task_cb, tp_task_XXX_cb, see 'Call back function types'.
 */

int	tp_task_restart(tp_task_p tptask);
/* Same as tp_task_start(), but without any params, can be used after tp_task_stop(). */

/* Remove shedule io for 'ident'. */
void	tp_task_stop(tp_task_p tptask);

/* Enable/disable io for 'ident'. */
int	tp_task_enable(tp_task_p tptask, int enable);


/* Set/get some vars in tp_task_s. */
/* Call tp_task_stop() before set!!! */
tpt_p	tp_task_tpt_get(tp_task_p tptask);
void	tp_task_tpt_set(tp_task_p tptask, tpt_p tpt);

uintptr_t tp_task_ident_get(tp_task_p tptask);
void	tp_task_ident_set(tp_task_p tptask, uintptr_t ident);
/* Call tp_task_stop() before! */

void	tp_task_ident_close(tp_task_p tptask);
/* tp_task_stop(); close(ident); ident = -1 */

tp_cb tp_task_tp_cb_func_get(tp_task_p tptask);
void	tp_task_tp_cb_func_set(tp_task_p tptask, tp_cb cb_func);
/* Set tp_task_XXX_handler(...) - internal io task handler function. */

tp_task_cb tp_task_cb_func_get(tp_task_p tptask);
void	tp_task_cb_func_set(tp_task_p tptask, tp_task_cb cb_func);

void	*tp_task_udata_get(tp_task_p tptask);
void	tp_task_udata_set(tp_task_p tptask, void *udata);

/* Task flag TP_TASK_F_* manipulation. */
void	tp_task_flags_set(tp_task_p tptask, uint32_t flags);
uint32_t tp_task_flags_add(tp_task_p tptask, uint32_t flags);
uint32_t tp_task_flags_del(tp_task_p tptask, uint32_t flags);
uint32_t tp_task_flags_get(tp_task_p tptask);

off_t	tp_task_offset_get(tp_task_p tptask);
void	tp_task_offset_set(tp_task_p tptask, off_t offset);

/* No affect on task in wait event state, apply on start/continue after callback. */
uint64_t tp_task_timeout_get(tp_task_p tptask);
void	tp_task_timeout_set(tp_task_p tptask, uint64_t timeout);

io_buf_p tp_task_buf_get(tp_task_p tptask);
void	tp_task_buf_set(tp_task_p tptask, io_buf_p buf);


// Generic (default build-in) check functions for recv and send
// will receive until connection open and some free space in buf
int	tp_task_cb_check(io_buf_p buf, uint32_t eof, size_t transfered_size);


/* Creates notifier for read/write ready. */
int	tp_task_notify_create(tpt_p tpt, uintptr_t ident,
	    uint32_t flags, uint16_t event, uint64_t timeout,
	    tp_task_notify_cb cb_func, void *udata,
	    tp_task_p *tptask_ret);
/* Creates packet receiver. */
int	tp_task_pkt_rcvr_create(tpt_p tpt, uintptr_t ident,
	    uint32_t flags, uint64_t timeout, io_buf_p buf,
	    tp_task_pkt_rcvr_cb cb_func, void *udata,
	    tp_task_p *tptask_ret);
/* Valid flags: TP_TASK_F_CB_AFTER_EVERY_READ */
/* Call tp_task_destroy() then no needed. */


int	tp_task_accept_create(tpt_p tpt, uintptr_t ident,
	    uint32_t flags, uint64_t timeout,
	    tp_task_accept_cb cb_func, void *udata,
	    tp_task_p *tptask_ret);
/* Valid flags: TP_TASK_F_CLOSE_ON_DESTROY */

int	tp_task_bind_accept_create(tpt_p tpt,
	    const sockaddr_storage_t *addr, int type, int protocol, skt_opts_p skt_opts,
	    uint32_t flags, uint64_t timeout,
	    tp_task_accept_cb cb_func, void *udata,
	    tp_task_p *tptask_ret);
/* Valid flags: TP_TASK_F_CLOSE_ON_DESTROY */

int	tp_task_bind_accept_multi_create(tp_p tp,
	    const sockaddr_storage_t *addr, int type, int protocol, skt_opts_p skt_opts,
	    uint32_t flags, uint64_t timeout,
	    tp_task_accept_cb cb_func, void *udata,
	    size_t *tptasks_count_ret, tp_task_p **tptasks_ret);
/* Creates and bind() + listen() sockets, one per thread if SO_F_REUSEPORT
 * is set in skt_opts and OS support SO_REUSEPORT to load balance
 * incomming traffic (linux and BSD with SO_REUSEPORT_LB).
 * listen() call only if type == SOCK_STREAM.
 * If SO_F_REUSEPORT not set or not supported then only one socket will
 * be created, task will be assosiated with thread returned by
 * tp_thread_get_rr().
 * Returns pointer to array of tp_task_p and array size (elems count).
 */

int	tp_task_connect_create(tpt_p tpt, uintptr_t ident,
	    uint32_t flags, uint64_t timeout, tp_task_connect_cb cb_func,
	    void *udata, tp_task_p *tptask_ret);

int	tp_task_connect_send_create(tpt_p tpt, uintptr_t ident,
	    uint32_t flags, uint64_t timeout, io_buf_p buf,
	    tp_task_cb cb_func, void *udata, tp_task_p *tptask_ret);
/* timeout - for connect, then for send (write) data. */

int	tp_task_connect_ex_create(tpt_p tpt, uint32_t flags,
	    uint64_t timeout, tp_task_conn_prms_p conn_prms,
	    tp_task_connect_ex_cb cb_func, void *udata,
	    tp_task_p *tptask_ret);
/* Connect to first addr, if timeout/error then wait retry_delay
 * and try connect to second addr.
 * TP_TASK_F_CB_AFTER_EVERY_READ - report about fails.
 * Function return control before cb_func called.
 * If time_limit is set then timeout must be != 0 and lower than time_limit.
 */
/* timeout - for connect try.
 * conn_prms - keep until cb_func called or tptask not stop/
 * conn_prms->time_limit - time limit for all retries / max connect time. 0 - no limit.
 * conn_prms->retry_delay - time before try connect to next addr.
 * conn_prms->max_tries - num tries connect to addrs[0]...addrs[addrs_count]
 * 
 * Pseudo code:
 * for (i = 0; i < max_tries; i ++) {
 * 	for (j = 0; j < addrs_count; j ++) {
 * 		if (ok == connect(SOCK_STREAM, conn_prms->protocol, addrs[j], timeout))
 * 			return (OK);
 * 	}
 * 	if (time_limit < retry_delay)
 * 		return (FAIL);
 * 	time_limit -= retry_delay;
 * 	sleep(retry_delay);
 * }
 */


#endif /* __THREAD_POOL_TASK_H__ */
