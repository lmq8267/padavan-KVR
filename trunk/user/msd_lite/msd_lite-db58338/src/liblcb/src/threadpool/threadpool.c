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

#ifdef BSD /* BSD specific code. */
#	include <sys/event.h>
#	ifndef DARWIN
#		include <pthread_np.h>
		typedef cpuset_t cpu_set_t;
#	endif
#endif /* BSD specific code. */

#ifdef __linux__ /* Linux specific code. */
#	include <sys/epoll.h>
#	include <sys/timerfd.h>
#	include <sys/ioctl.h>
#	include <sys/socket.h>
#endif /* Linux specific code. */

#include <sys/queue.h>
#include <sys/fcntl.h> /* open, fcntl */
#include <inttypes.h>
#include <stdlib.h> /* malloc, exit */
#include <stdio.h>  /* snprintf, fprintf */
#include <unistd.h> /* close, write, sysconf */
#include <string.h> /* memcpy, memmove, memset, strerror... */
#include <strings.h> /* explicit_bzero */
#include <errno.h>
#include <signal.h>
#include <pthread.h>
#include <time.h>
#include <syslog.h>

#include "utils/macro.h"
#include "al/os.h"
#include "threadpool/threadpool.h"
#include "threadpool/threadpool_msg_sys.h"

#ifdef THREAD_POOL_SETTINGS_XML
#	include "utils/buf_str.h"
#	include "utils/xml.h"
#endif
#ifdef THREAD_POOL_SETTINGS_INI
#	include "utils/buf_str.h"
#	include "utils/ini.h"
#endif


/* Initialize Thread Local Storage. */
static pthread_key_t tp_tls_key_tpt;
static int tp_tls_key_tpt_error = EAGAIN;
static tp_p g_tp = NULL;


/* Operation. */
#define TP_CTL_ADD		0
#define TP_CTL_DEL		1
#define TP_CTL_ENABLE		2
#define TP_CTL_DISABLE		3
#define TP_CTL_LAST		TP_CTL_DISABLE


#ifdef BSD /* BSD specific code. */

#define TPT_ITEM_EV_COUNT	64

static const u_short tp_op_to_flags_kq_map[] = {
	(EV_ADD | EV_ENABLE),	/* 0: TP_CTL_ADD */
	EV_DELETE,		/* 1: TP_CTL_DEL */
	EV_ENABLE,		/* 2: TP_CTL_ENABLE */
	EV_DISABLE,		/* 3: TP_CTL_DISABLE */
	0
};

static const short tp_event_to_kq_map[] = {
	EVFILT_READ,		/* 0: TP_EV_READ */
	EVFILT_WRITE,		/* 1: TP_EV_WRITE */
	EVFILT_TIMER,		/* 2: TP_EV_TIMER */
	0
};

#endif /* BSD specific code. */


#ifdef __linux__ /* Linux specific code. */
//#define TP_LINUX_MULTIPLE_EVENTS

#define EPOLL_INOUT		(EPOLLIN | EPOLLOUT)
#define EPOLL_OUT		(EPOLLOUT)
#define EPOLL_IN		(EPOLLIN | EPOLLRDHUP | EPOLLPRI)
#define EPOLL_HUP		(EPOLLHUP | EPOLLRDHUP)

static const uint32_t tp_event_to_ep_map[] = {
	EPOLL_IN,		/* 0: TP_EV_READ */
	EPOLL_OUT,		/* 1: TP_EV_WRITE */
	0,			/* 2: TP_EV_TIMER */
	0
};

/* Single event. */
#define U64_BITS_MASK(__bits)		((((uint64_t)1) << (__bits)) - 1)
#define U64_BITS_GET(__u64, __off, __len)				\
    (((__u64) >> (__off)) & U64_BITS_MASK(__len))
#define U64_BITS_SET(__u64, __off, __len, __data)			\
    (__u64) = (((__u64) & ~(U64_BITS_MASK(__len) << (__off))) |		\
	(((__data) & U64_BITS_MASK(__len)) << (__off)))

#define TPDATA_TFD_GET(__u64)		(int)U64_BITS_GET(__u64, 0, 32)
#define TPDATA_TFD_SET(__u64, __tfd)	U64_BITS_SET(__u64, 0, 32, ((uint32_t)(__tfd)))
#define TPDATA_EVENT_GET(__u64)		U64_BITS_GET(__u64, 32, 3)
#define TPDATA_EVENT_SET(__u64, __ev)	U64_BITS_SET(__u64, 32, 3, __ev)
#define TPDATA_FLAGS_GET(__u64, __ev)	U64_BITS_GET(__u64, (35 + (3 * (__ev))), 3)
#define TPDATA_FLAGS_SET(__u64, __ev, __fl)				\
    U64_BITS_SET(__u64, (35 + (3 * (__ev))), 3, __fl)
#define TPDATA_EV_FL_SET(__u64, __ev, __fl) {				\
    TPDATA_EVENT_SET(__u64, __ev);					\
    TPDATA_FLAGS_SET(__u64, __ev, __fl);				\
}
#define TPDATA_F_DISABLED		(((uint64_t)1) << 63) /* Make sure that disabled event never call cb func. */

#endif /* Linux specific code. */




typedef struct thread_pool_thread_s { /* thread pool thread info */
	volatile size_t state;		/* State: TP_THREAD_STATE_*. */
	volatile size_t tick_cnt;	/* For detecting hangs thread. */
	uintptr_t	io_fd;		/* IO handle: kqueue (per thread). */
#ifdef BSD /* BSD specific code. */
	int		ev_nchanges;	/* Passed to kevent. */
	struct kevent	ev_changelist[TPT_ITEM_EV_COUNT]; /* Passed to kevent. */
#endif /* BSD specific code. */
	pthread_t	pt_id;		/* Thread id. */
	int		cpu_id;		/* CPU num or -1 if no bindings. */
	size_t		thread_num;	/* num in array, short internal thread id. */
	void		*msg_queue;	/* Queue specific. */
#ifdef __linux__ /* Linux specific code. */
	tp_udata_t	pvt_udata;	/* Pool virtual thread support. */
#endif	/* Linux specific code. */
	tp_p		tp;		/*  */
} tp_thread_t;

#define TP_THREAD_STATE_STOP		0
#define TP_THREAD_STATE_STOPING		1
#define TP_THREAD_STATE_STARTING	2
#define TP_THREAD_STATE_RUNNING		3


typedef struct thread_pool_s { /* thread pool */
	tpt_p		pvt;		/* Pool virtual thread. */
	volatile size_t	rr_idx;
	volatile size_t	shutdown;
	uint32_t	flags;
	char		name[TP_NAME_SIZE];
	size_t		cpu_count;
	uintptr_t	fd_count;
	size_t		threads_max;
	volatile size_t	threads_cnt;	/* Worker threads count. */
	tp_thread_t	threads[];	/* Worker threads. */
} tp_t;


static int	tpt_ev_post(int op, tp_event_p ev, tp_udata_p tp_udata);
static int	tpt_data_event_init(tpt_p tpt);
static void	tpt_data_event_destroy(tpt_p tpt);
static void	tpt_loop(tpt_p tpt);

int		tpt_data_init(tp_p tp, int cpu_id, size_t thread_num,
		    tpt_p tpt);
void		tpt_data_uninit(tpt_p tpt);

static void	*tp_thread_proc(void *data);

void		tpt_cached_time_update_cb(tp_event_p ev, tp_udata_p tp_udata);


/*
 * FreeBSD specific code.
 */
#ifdef BSD /* BSD specific code. */

/* Translate thread pool flags <-> kqueue flags. */
static inline u_short
tp_flags_to_kq(uint16_t flags) {
	u_short ret = 0;

	if (0 == flags)
		return (0);
	if (0 != (TP_F_ONESHOT & flags)) {
		ret |= EV_ONESHOT;
	}
	if (0 != (TP_F_DISPATCH & flags)) {
		ret |= EV_DISPATCH;
	}
#ifdef TP_F_EDGE
	if (0 != (TP_F_EDGE & flags)) {
		ret |= EV_CLEAR;
	}
#endif
	return (ret);
}

static inline u_int
tp_fflags_to_kq(uint16_t event, uint32_t fflags) {
	u_int ret = 0;

	switch (event) {
	case TP_EV_READ:
	case TP_EV_WRITE:
		if (0 != (TP_FF_RW_LOWAT & fflags)) {
			ret |= NOTE_LOWAT;
		}
		break;
	case TP_EV_TIMER:
		if (0 != (TP_FF_T_ABSTIME & fflags)) {
			ret |= NOTE_ABSTIME;
		}
		switch ((TP_FF_T_TM_MASK & fflags)) {
		case TP_FF_T_SEC:
			ret |= NOTE_SECONDS;
			break;
		case TP_FF_T_MSEC:
			ret |= NOTE_MSECONDS;
			break;
		case TP_FF_T_USEC:
			ret |= NOTE_USECONDS;
			break;
		case TP_FF_T_NSEC:
			ret |= NOTE_NSECONDS;
			break;
		}
		break;
	}

	return (ret);
}

static int
tpt_data_event_init(tpt_p tpt) {
	struct kevent kev;

	tpt->io_fd = (uintptr_t)kqueuex(
	    (0 != (TP_S_F_CLOEXEC & tpt->tp->flags) ? KQUEUE_CLOEXEC : 0));
	if ((uintptr_t)-1 == tpt->io_fd)
		return (errno);
	/* Init threads message exchange. */
	tpt->msg_queue = tpt_msg_queue_create(tpt,
	    (0 != (TP_S_F_CLOEXEC & tpt->tp->flags) ? TP_MSG_Q_F_CLOEXEC : 0));
	if (NULL == tpt->msg_queue)
		return (errno);
	if (NULL != tpt->tp->pvt &&
	    tpt != tpt->tp->pvt) {
		/* Add pool virtual thread to normal thread. */
		EV_SET(&kev, tpt->tp->pvt->io_fd,
		    EVFILT_READ, (EV_ADD | EV_ENABLE | EV_CLEAR),
		    0, 0, NULL);
		if (-1 == kevent((int)tpt->io_fd, &kev, 1, NULL, 0, NULL))
			return (errno);
		if (0 != (EV_ERROR & kev.flags))
			return ((int)kev.data);
	}
	return (0);
}

static void
tpt_data_event_destroy(tpt_p tpt) {

	tpt_msg_queue_destroy(tpt->msg_queue);
}

static int
tpt_ev_post(int op, tp_event_p ev, tp_udata_p tp_udata) {
	struct kevent kev;

	if (TP_CTL_LAST < op ||
	    NULL == ev ||
	    NULL == tp_udata)
		return (EINVAL);

	EV_SET(&kev,
	    tp_udata->ident,
	    tp_event_to_kq_map[ev->event],
	    (tp_op_to_flags_kq_map[op] | tp_flags_to_kq(ev->flags)),
	    tp_fflags_to_kq(ev->event, ev->fflags),
	    ev->data,
	    (void*)tp_udata);

	switch (ev->event) {
	case TP_EV_READ:
	case TP_EV_WRITE:
		if (0 != (NOTE_LOWAT & kev.fflags) &&
		    0 == kev.data) { /* LOWAT can not be 0. */
			kev.data = 1;
		}
		break;
	case TP_EV_TIMER: /* Timer: force update. */
		if (0 != ((EV_ADD | EV_ENABLE) & kev.flags)) {
			kev.flags |= (EV_ADD | EV_ENABLE);
		}
		break;
	}

	if (-1 == kevent((int)tp_udata->tpt->io_fd, &kev, 1, NULL, 0, NULL))
		return (errno);
	if (0 != (EV_ERROR & kev.flags))
		return ((int)kev.data);
	return (0);
}

#if 0 /* XXX may be in future... */
int
tpt_ev_q_add(tpt_p tpt, uint16_t event, uint16_t flags,
    tp_udata_p tp_udata) {
	/*tpt_p tpt;

	if (NULL == tpt)
		return (EINVAL);
	if (TPT_ITEM_EV_COUNT <= tpt->ev_nchanges)
		return (-1);

	EV_SET(&tpt->ev_changelist[tpt->ev_nchanges], ident, filter,
	    flags, fflags, data, tp_udata);
	tpt->ev_nchanges ++;

	return (0);*/
	return (tpt_ev_add(tpt, event, flags, tp_udata));
}

int
tpt_ev_q_del(uint16_t event, tp_udata_p tp_udata) {
	/*int i, ev_nchanges, ret;
	tpt_p tpt;

	if (NULL == tpt || (uintptr_t)-1 == ident)
		return (EINVAL);

	ret = 0;
	ev_nchanges = tpt->ev_nchanges;
	for (i = 0; i < ev_nchanges; i ++) {
		if (tpt->ev_changelist[i].ident != ident ||
		    tpt->ev_changelist[i].filter != filter)
			continue;

		ret ++;
		ev_nchanges --;
		if (i < ev_nchanges) {
			memmove(&tpt->ev_changelist[i], 
			    &tpt->ev_changelist[(i + 1)], 
			    (sizeof(struct kevent) * (ev_nchanges - i))); // move items, except last
		}
		memset(&tpt->ev_changelist[(ev_nchanges + 1)], 0x00,
		    sizeof(struct kevent));// zeroize last
	}
	tpt->ev_nchanges = ev_nchanges;

	return (ret);*/
	return (tpt_ev_del_args1(event, tp_udata));
}

int
tpt_ev_q_enable(int enable, uint16_t event, tp_udata_p tp_udata) {

	return (tpt_ev_enable_args1(enable, event, tp_udata));
}

int
tpt_ev_q_enable_ex(int enable, uint16_t event, uint16_t flags,
    uint32_t fflags, intptr_t data, tp_udata_p tp_udata) {

	return (tpt_ev_enable_args(enable, event, flags, fflags, data, tp_udata));
}

int
tpt_ev_q_flush(tpt_p tpt) {

	if (NULL == tpt)
		return (EINVAL);
	if (0 == tpt->ev_nchanges)
		return (0);
	if (-1 == kevent(tpt->io_fd, tpt->ev_changelist,
	    tpt->ev_nchanges, NULL, 0, NULL))
		return (errno);
	return (0);
}
#endif /* XXX may be in future... */

static void
tpt_loop(tpt_p tpt) {
	tpt_p pvt;
	int cnt;
	struct kevent kev;
	tp_event_t ev;
	tp_udata_p tp_udata;
	struct timespec ke_timeout;

	pvt = tpt->tp->pvt;
	tpt->ev_nchanges = 0;
	memset(&ke_timeout, 0x00, sizeof(ke_timeout));

	/* Main loop. */
	while (TP_THREAD_STATE_RUNNING == tpt->state) {
		tpt->tick_cnt ++; /* Tic-toc. */
		cnt = kevent((int)tpt->io_fd, tpt->ev_changelist, 
		    tpt->ev_nchanges, &kev, 1, NULL /* Infinite wait. */);
		if (0 != tpt->ev_nchanges) {
			memset(tpt->ev_changelist, 0x00,
			    (sizeof(struct kevent) * (size_t)tpt->ev_nchanges));
			tpt->ev_nchanges = 0;
		}
		if (0 == cnt) { /* Timeout. */
			SYSLOG_EX(LOG_DEBUG, "kevent: cnt = 0");
			continue;
		}
		if (0 > cnt) { /* Error / Exit. */
			if (EINTR == errno)
				continue; /* Non fatal error. */
			SYSLOG_ERR(LOG_ERR, errno, "kevent()");
			break;
		}
		if (pvt->io_fd == kev.ident) { /* Pool virtual thread. */
			//memcpy(&tpt->ev_changelist[tpt->ev_nchanges], &kev,
			//    sizeof(kev));
			EV_SET(&tpt->ev_changelist[tpt->ev_nchanges],
			    kev.ident, EVFILT_READ, EV_CLEAR, 0, 0, NULL);
			tpt->ev_nchanges ++;

			cnt = kevent((int)pvt->io_fd, NULL, 0, &kev, 1, &ke_timeout);
			if (1 != cnt) /* Timeout or error. */
				continue;
		}
		if (NULL == kev.udata) {
			syslog(LOG_DEBUG, "kevent with invalid user data, ident = %zu.", kev.ident);
			debugd_break();
			continue;
		}
		tp_udata = (tp_udata_p)kev.udata;
		if (tp_udata->ident != kev.ident) {
			syslog(LOG_DEBUG, "kevent with invalid ident, kq_ident = %zu, thr_ident = %zu.",
			    kev.ident, tp_udata->ident);
			debugd_break();
			continue;
		}
		if (tp_udata->tpt != tpt &&
		    tp_udata->tpt != pvt) {
			syslog(LOG_DEBUG, "kevent with invalid tpt, tpt = %zu, thr_tpt = %zu.",
			    (size_t)tpt, (size_t)tp_udata->tpt);
			debugd_break();
			//continue;
		}
		if (NULL == tp_udata->cb_func) {
			syslog(LOG_DEBUG, "kevent with invalid user cb_func, ident = %zu.", kev.ident);
			debugd_break();
			continue;
		}
		/* Translate kq event to thread poll event. */
		switch (kev.filter) {
		case EVFILT_READ:
			ev.event = TP_EV_READ;
			break;
		case EVFILT_WRITE:
			ev.event = TP_EV_WRITE;
			break;
		case EVFILT_TIMER:
			ev.event = TP_EV_TIMER;
			break;
		default:
			syslog(LOG_DEBUG, "kevent with invalid filter = %i, ident = %zu.",
			    kev.filter, kev.ident);
			debugd_break();
			continue;
		}
		ev.flags = 0;
		if (0 != (EV_EOF & kev.flags)) {
			ev.flags |= TP_F_EOF;
			if (0 != kev.fflags) { /* For socket: closed, and error present. */
				ev.flags |= TP_F_ERROR;
			}
		}
		ev.fflags = (uint32_t)kev.fflags;
		ev.data = (uint64_t)kev.data;

		tp_udata->cb_func(&ev, tp_udata);
	} /* End Main loop. */
	return;
}
#endif /* BSD specific code. */


#ifdef __linux__ /* Linux specific code. */
#define TP_EV_OTHER(event)						\
    (TP_EV_READ == (event) ? TP_EV_WRITE : TP_EV_READ)

/* Translate thread pool flags <-> epoll flags. */
static inline uint32_t
tp_flags_to_ep(const int op, const uint16_t flags) {
	uint32_t ret = 0;

	if (0 == flags)
		return (0);
	if (0 != ((TP_F_ONESHOT | TP_F_DISPATCH) & flags)) {
		ret |= EPOLLONESHOT;
	}
#ifdef TP_F_EDGE
	if (0 != (TP_F_EDGE & flags)) {
		ret |= EPOLLET;
	}
#endif
#ifdef TP_F_EXCLUSIVE
	if (0 != (TP_F_EXCLUSIVE & flags) &&
	    TP_CTL_ADD == op) {
		ret |= EPOLLEXCLUSIVE;
	}
#endif
	return (ret);
}

static int
tpt_data_event_init(tpt_p tpt) {
	int error;
	tp_event_t ev;

	tpt->io_fd = epoll_create1(
	    (0 != (TP_S_F_CLOEXEC & tpt->tp->flags) ? EPOLL_CLOEXEC : 0));
	if ((uintptr_t)-1 == tpt->io_fd)
		return (errno);
	/* Init threads message exchange. */
	tpt->msg_queue = tpt_msg_queue_create(tpt,
	    (0 != (TP_S_F_CLOEXEC & tpt->tp->flags) ? TP_MSG_Q_F_CLOEXEC : 0));
	if (NULL == tpt->msg_queue)
		return (errno);
	if (NULL != tpt->tp->pvt &&
	    tpt != tpt->tp->pvt) {
		/* Add pool virtual thread to normal thread. */
		memset(&ev, 0x00, sizeof(tp_event_t));
		ev.event = TP_EV_READ;
		/* ev.flags = TP_F_EXCLUSIVE; Should be here, but it is not
		 * implemented on BSD and does not work with epoll() fd on linux. */
		tpt->pvt_udata.cb_func = NULL;
		tpt->pvt_udata.ident = tpt->tp->pvt->io_fd;
		tpt->pvt_udata.tpt = tpt;
		error = tpt_ev_post(TP_CTL_ADD, &ev, &tpt->pvt_udata);
		if (0 != error)
			return (error);
	}
	return (0);
}

static void
tpt_data_event_destroy(tpt_p tpt) {

	tpt_msg_queue_destroy(tpt->msg_queue);
}

static inline int
epoll_ctl_ex(int epfd, int op, int fd, struct epoll_event *event) {
	int error;

	switch (op) {
	case EPOLL_CTL_ADD: /* Try to add event to epoll. */
		if (0 == epoll_ctl(epfd, EPOLL_CTL_ADD, fd, event))
			return (0);
		error = errno;
		if (EEXIST != error)
			return (error);
		if (0 == epoll_ctl(epfd, EPOLL_CTL_MOD, fd, event))
			return (0);
		break;
	case EPOLL_CTL_MOD: /* Try to modify existing. */
		if (0 == epoll_ctl(epfd, EPOLL_CTL_MOD, fd, event))
			return (0);
		error = errno;
		if (ENOENT != error)
			return (error);
		if (0 == epoll_ctl(epfd, EPOLL_CTL_ADD, fd, event))
			return (0);
		break;
	case EPOLL_CTL_DEL:
		if (0 == epoll_ctl(epfd, EPOLL_CTL_DEL, fd, event))
			return (0);
		break;
	default:
		return (EINVAL);
	}
	return (errno);
}

static int
tpt_ev_post(int op, tp_event_p ev, tp_udata_p tp_udata) {
	int error = 0, tfd, clockid = CLOCK_MONOTONIC, tmr_flags = 0, op_guess;
	uint32_t lowat;
	struct itimerspec new_tmr;
	struct epoll_event epev;

	if (TP_CTL_LAST < op ||
	    NULL == ev ||
	    NULL == tp_udata)
		return (EINVAL);

	epev.events = (EPOLLHUP | EPOLLERR);
	epev.data.ptr = (void*)tp_udata;

	if (TP_EV_TIMER == ev->event) { /* Special handle for timer. */
		tfd = TPDATA_TFD_GET(tp_udata->tpdata);
		if (TP_CTL_DEL == op) { /* Delete timer. */
			if (0 == tfd)
				return (ENOENT);
			error = 0;
err_out_timer:
			close(tfd); /* No need to epoll_ctl(EPOLL_CTL_DEL). */
			tp_udata->tpdata = 0;
			return (error);
		}
		if (TP_CTL_DISABLE == op) {
			if (0 == tfd)
				return (ENOENT);
			tp_udata->tpdata |= TPDATA_F_DISABLED;
			memset(&new_tmr, 0x00, sizeof(new_tmr));
			if (-1 == timerfd_settime(tfd, 0, &new_tmr, NULL)) {
				error = errno;
				goto err_out_timer;
			}
			return (0);
		}

		/* TP_CTL_ADD, TP_CTL_ENABLE */
		if (0 != (TP_FF_T_ABSTIME & ev->fflags)) {
			clockid = CLOCK_REALTIME;
			tmr_flags = TFD_TIMER_ABSTIME;
		}

		if (0 == tfd) { /* Create timer, if needed. */
			tfd = timerfd_create(clockid, TFD_NONBLOCK);
			if (-1 == tfd) {
				tp_udata->tpdata = 0;
				return (errno);
			}
			TPDATA_TFD_SET(tp_udata->tpdata, tfd);
			TPDATA_EV_FL_SET(tp_udata->tpdata, ev->event, ev->flags); /* Remember original event and flags. */
			/* Adding to epoll. */
			epev.events |= EPOLLIN; /* Not set EPOLLONESHOT, control timer. */
			if (0 != epoll_ctl((int)tp_udata->tpt->io_fd,
			    EPOLL_CTL_ADD, tfd, &epev)) {
				error = errno;
				goto err_out_timer;
			}
		}

		tp_udata->tpdata &= ~TPDATA_F_DISABLED;
		switch ((TP_FF_T_TM_MASK & ev->fflags)) {
		case TP_FF_T_SEC:
			new_tmr.it_value.tv_sec = (time_t)ev->data;
			new_tmr.it_value.tv_nsec = 0;
			break;
		case TP_FF_T_MSEC:
			new_tmr.it_value.tv_sec = (ev->data / 1000ul);
			new_tmr.it_value.tv_nsec = ((ev->data % 1000ul) * 1000000ul);
			break;
		case TP_FF_T_USEC:
			new_tmr.it_value.tv_sec = (ev->data / 1000000ul);
			new_tmr.it_value.tv_nsec = ((ev->data % 1000000ul) * 1000000000000ul);
			break;
		case TP_FF_T_NSEC:
			new_tmr.it_value.tv_sec = (ev->data / 1000000000ul);
			new_tmr.it_value.tv_nsec = (ev->data % 1000000000ul);
			break;
		}
		if (0 != ((TP_F_ONESHOT | TP_F_DISPATCH) & ev->flags)) { /* Onetime. */
			memset(&new_tmr.it_interval, 0x00, sizeof(struct timespec));
		} else { /* Periodic. */
			new_tmr.it_interval = new_tmr.it_value; /* memcpy(). */
		}
		if (-1 == timerfd_settime(tfd, tmr_flags, &new_tmr, NULL)) {
			error = errno;
			goto err_out_timer;
		}
		return (0);
	}

	/* Read/Write events. */
	/* Single event. */
	if (TP_CTL_DEL == op) {
		tp_udata->tpdata = 0;
		if (0 == epoll_ctl((int)tp_udata->tpt->io_fd,
		    EPOLL_CTL_DEL, (int)tp_udata->ident, &epev))
			return (0);
		return (errno);
	}

	op_guess = ((0 == tp_udata->tpdata) ? EPOLL_CTL_ADD : EPOLL_CTL_MOD);
	TPDATA_TFD_SET(tp_udata->tpdata, 0);
	TPDATA_EV_FL_SET(tp_udata->tpdata, ev->event, ev->flags); /* Remember original event and flags. */
	if (TP_CTL_DISABLE == op) { /* Disable event. */
		tp_udata->tpdata |= TPDATA_F_DISABLED;
		epev.events |= EPOLLET; /* Mark as level trig, to only once report HUP/ERR. */
	} else {
		tp_udata->tpdata &= ~TPDATA_F_DISABLED;
		epev.events |= tp_event_to_ep_map[ev->event];
		epev.events |= tp_flags_to_ep(op, ev->flags);
	}

	/* fflags. */
	switch (ev->event) {
	case TP_EV_READ:
		if (0 != (TP_FF_RW_LOWAT & ev->fflags)) {
			lowat = ((0 == ev->data) ? 1 : ev->data); /* LOWAT can not be 0. */
			setsockopt((int)tp_udata->ident, SOL_SOCKET, SO_RCVLOWAT,
			    &lowat, sizeof(uint32_t));
		}
		break;
	case TP_EV_WRITE:
#if 0		/* Linux allways fail on set SO_SNDLOWAT. May be in future. */
		if (0 != (TP_FF_RW_LOWAT & ev->fflags)) {
			lowat = ((0 == ev->data) ? 1 : ev->data); /* LOWAT can not be 0. */
			setsockopt((int)tp_udata->ident, SOL_SOCKET, SO_SNDLOWAT,
			    &lowat, sizeof(uint32_t))
		}
#endif
		break;
	}

	error = epoll_ctl_ex((int)tp_udata->tpt->io_fd,
	    op_guess, (int)tp_udata->ident, &epev);
	if (0 != error) {
		tp_udata->tpdata = 0;
	}
	return (error);
}

static void
tpt_loop(tpt_p tpt) {
	tpt_p pvt;
	tp_p tp;
	int cnt, itm, tfd;
	uint16_t tpev_flags;
	struct epoll_event epev;
	tp_event_t ev;
	tp_udata_p tp_udata;
	socklen_t optlen;

	tp = tpt->tp;
	pvt = tp->pvt;
	/* Main loop. */
	while (TP_THREAD_STATE_RUNNING == tpt->state) {
		tpt->tick_cnt ++; /* Tic-toc. */
		cnt = epoll_wait((int)tpt->io_fd, &epev, 1, -1 /* infinite wait. */);
		if (0 == cnt) /* Timeout. */
			continue;
		if (-1 == cnt) { /* Error / Exit. */
			if (EINTR == errno)
				continue; /* Non fatal error. */
			SYSLOG_ERR(LOG_ERR, errno, "epoll_wait().");
			debugd_break();
			break;
		}
		/* Single event. */
		if (NULL == epev.data.ptr) {
			syslog(LOG_DEBUG, "epoll event with invalid user data, epev.data.ptr = NULL");
			debugd_break();
			continue;
		}
		tp_udata = (tp_udata_p)epev.data.ptr;
		if (NULL == tp_udata->cb_func) {
			if (pvt->io_fd == tp_udata->ident) { /* Pool virtual thread. */
				cnt = epoll_wait((int)pvt->io_fd, &epev, 1, 0);
				if (1 != cnt ||
				    NULL == epev.data.ptr) /* Timeout or error. */
					continue;
				tp_udata = (tp_udata_p)epev.data.ptr;
			}
			if (NULL == tp_udata->cb_func) {
				syslog(LOG_DEBUG, "epoll event with invalid "
				    "user cb_func, epev.data.u64 = %"PRIu64,
				    epev.data.u64);
				debugd_break();
				continue;
			}
		}
		if (0 != (TPDATA_F_DISABLED & tp_udata->tpdata))
			continue; /* Do not process disabled events. */
		/* Translate ep event to thread poll event. */
		ev.event = TPDATA_EVENT_GET(tp_udata->tpdata);
		tpev_flags = TPDATA_FLAGS_GET(tp_udata->tpdata, ev.event);
		ev.flags = 0;
		ev.fflags = 0;
		if (0 != (TP_F_DISPATCH & tpev_flags)) { /* Mark as disabled. */
			tp_udata->tpdata |= TPDATA_F_DISABLED;
		}
		if (TP_EV_TIMER == ev.event) { /* Timer. */
			tfd = TPDATA_TFD_GET(tp_udata->tpdata);
			itm = read(tfd, &ev.data, sizeof(uint64_t));
			if (0 != (TP_F_ONESHOT & tpev_flags)) { /* Onetime. */
				close(tfd); /* No need to epoll_ctl(EPOLL_CTL_DEL). */
				tp_udata->tpdata = 0;
			}
			tp_udata->cb_func(&ev, tp_udata);
			continue;
		}
		/* Read/write. */
		ev.data = UINT64_MAX; /* Transfer as many as you can. */
		//ioctl((int)tp_udata->ident, FIONREAD, &ev.data);
		if (0 != (EPOLL_HUP & epev.events)) {
			ev.flags |= TP_F_EOF;
		}
		if (0 != (EPOLLERR & epev.events)) { /* Try to get error code. */
			ev.flags |= TP_F_ERROR;
			ev.fflags = errno;
			optlen = sizeof(int);
			if (0 == getsockopt((int)tp_udata->ident,
			    SOL_SOCKET, SO_ERROR, &itm, &optlen)) {
				ev.fflags = itm;
			}
			if (0 == ev.fflags) {
				ev.fflags = EINVAL;
			}
		}
		if (0 != (TP_F_ONESHOT & tpev_flags)) { /* Onetime. */
			epoll_ctl((int)tpt->io_fd, EPOLL_CTL_DEL,
			    (int)tp_udata->ident, &epev);
			tp_udata->tpdata = 0;
		}

		tp_udata->cb_func(&ev, tp_udata);
	} /* End Main loop. */
	return;
}
#endif /* Linux specific code. */





/*
 * Shared code.
 */
int
tp_signal_handler_add_tp(tp_p tp) {
	
	/* XXX: need modify to handle multiple threads pools. */
	g_tp = tp;
	
	return (0);
}

void
tp_signal_handler(int sig) {

	switch (sig) {
	case SIGINT:
	case SIGTERM:
	case SIGKILL:
		tp_shutdown(g_tp);
		g_tp = NULL;
		break;
	case SIGHUP:
	case SIGUSR1:
	case SIGUSR2:
		break;
	}
}


void
tp_settings_def(tp_settings_p s_ret) {

	if (NULL == s_ret)
		return;
	/* Init. */
	memset(s_ret, 0x00, sizeof(tp_settings_t));

	/* Default settings. */
	s_ret->flags = TP_S_DEF_FLAGS;
	s_ret->threads_max = TP_S_DEF_THREADS_MAX;
	strlcpy(s_ret->name, "TP", sizeof(s_ret->name));
}

#ifdef THREAD_POOL_SETTINGS_XML
int
tp_settings_load_xml(const uint8_t *buf, size_t buf_size, tp_settings_p s) {
	const uint8_t *data;
	size_t data_size;

	if (NULL == buf || 0 == buf_size || NULL == s)
		return (EINVAL);
	/* Read from config. */
	/* Flags. */
	if (0 == xml_get_val_args(buf, buf_size, NULL, NULL, NULL,
	    &data, &data_size,
	    (const uint8_t*)"fBindToCPU", NULL)) {
		yn_set_flag32(data, data_size, TP_S_F_BIND2CPU, &s->flags);
	}

	/* Other. */
	xml_get_val_size_t_args(buf, buf_size, NULL, &s->threads_max,
	    (const uint8_t*)"threadsCountMax", NULL);

	return (0);
}
#endif
#ifdef THREAD_POOL_SETTINGS_INI
int
tp_settings_load_ini(const ini_p ini, const uint8_t *sect_name,
    const size_t sect_name_size, tp_settings_p s) {
	const uint8_t *data;
	size_t data_size;

	if (NULL == ini || NULL == sect_name || 0 == sect_name_size || NULL == s)
		return (EINVAL);
	/* Read from config. */
	/* Flags. */
	if (0 == ini_vali_get(ini, sect_name, sect_name_size,
	    (const uint8_t*)"fBindToCPU", 0, &data, &data_size)) {
		yn_set_flag32(data, data_size, TP_S_F_BIND2CPU, &s->flags);
	}

	/* Other. */
	ini_vali_get_uint(ini, sect_name, sect_name_size,
	    (const uint8_t*)"threadsCountMax", 0, &s->threads_max);

	return (0);
}
#endif


int
tp_init(void) {

	if (0 != tp_tls_key_tpt_error) { /* Try to reinit TLS. */
		tp_tls_key_tpt_error = pthread_key_create(&tp_tls_key_tpt, NULL);
	}
	return (tp_tls_key_tpt_error);
}

int
tp_create(tp_settings_p s, tp_p *ptp) {
	int error, cur_cpu;
	uintptr_t fd_max_count;
	size_t i, cpu_count;
	tp_p tp;
	tp_settings_t s_def;

	error = tp_init();
	if (0 != error) {
		SYSLOG_ERR(LOG_CRIT, error, "tp_init().");
		return (error);
	}

	if (NULL == ptp)
		return (EINVAL);
	if (NULL == s) {
		tp_settings_def(&s_def);
	} else {
		memcpy(&s_def, s, sizeof(s_def));
	}
	s = &s_def;

	cpu_count = (size_t)sysconf(_SC_NPROCESSORS_CONF);
	if ((size_t)-1 == cpu_count) {
		cpu_count = 1; /* At least 1 processor available. */
	}
	if (0 == s->threads_max) {
		s->threads_max = cpu_count;
	}
	tp = (tp_p)calloc(1, (sizeof(tp_t) + ((s->threads_max + 1) * sizeof(tp_thread_t))));
	if (NULL == tp)
		return (ENOMEM);
	fd_max_count = (uintptr_t)getdtablesize();
	tp->flags = s->flags;
	memcpy(tp->name, s->name, TP_NAME_SIZE);
	tp->cpu_count = cpu_count;
	tp->threads_max = s->threads_max;
	tp->fd_count = fd_max_count;
	tp->pvt = &tp->threads[s->threads_max];
	error = tpt_data_init(tp, -1, (size_t)~0, &tp->threads[s->threads_max]);
	if (0 != error) {
		SYSLOG_ERR(LOG_CRIT, error, "tpt_data_init() - pvt.");
		goto err_out;
	}
	for (i = 0, cur_cpu = 0; i < s->threads_max; i ++, cur_cpu ++) {
		if (0 != (TP_S_F_BIND2CPU & s->flags)) {
			if ((size_t)cur_cpu >= cpu_count) {
				cur_cpu = 0;
			}
		} else {
			cur_cpu = -1;
		}
		error = tpt_data_init(tp, cur_cpu, i, &tp->threads[i]);
		if (0 != error) {
			SYSLOG_ERR(LOG_CRIT, error, "tpt_data_init() - threads.");
			goto err_out;
		}
	}

	(*ptp) = tp;
	return (0);

err_out:
	tp_destroy(tp);
	return (error);
}

static void
tpt_msg_shutdown_cb(tpt_p tpt, void *udata __unused) {

	tpt->state = TP_THREAD_STATE_STOPING;
}
void
tp_shutdown(tp_p tp) {

	if (NULL == tp)
		return;
	if (0 != tp->shutdown)
		return;
	tp->shutdown ++;
	/* Shutdown threads. */
	for (size_t i = 0; i < tp->threads_max; i ++) {
		if (0 == tpt_is_running(&tp->threads[i]))
			continue;
		tpt_msg_send(&tp->threads[i], NULL, 0,
		    tpt_msg_shutdown_cb, NULL);
	}
}

int
tp_shutdown_wait(tp_p tp) {
	int error;
	size_t err_cnt = 0;
	/* 1 sec = 1000000000 nanoseconds. */
	struct timespec rqts = { .tv_sec = 0, .tv_nsec = 100000000 };

	if (NULL == tp)
		return (EINVAL);
	if (0 == tp->shutdown)
		return (EBUSY);
	if (0 != tp_thread_is_tp_thr(tp, NULL))
		return (EDEADLK);

	for (size_t i = 0; i < tp->threads_max; i ++) {
		if (TP_THREAD_STATE_STOP == tp->threads[i].state)
			continue;
		error = pthread_join(tp->threads[i].pt_id, NULL);
		switch (error) {
		case 0: /* No error. */
			break;
		case EDEADLK: /* Should not happen, checked by tp_thread_is_tp_thr(). */
			return (error);
		case EOPNOTSUPP: /* Probably other thread also call this right now. */
			/* FreeBSD specific. */
		default:
			tp->threads[i].state = TP_THREAD_STATE_STOP;
			err_cnt ++;
			break;
		}
	}
	/* Fallback code, normally not used. */
	while (0 != err_cnt && 0 != tp_thread_count_get(tp)) {
		nanosleep(&rqts, NULL); /* Ignore early wakeup and errors. */
	}

	return (0);
}

int
tp_destroy(tp_p tp) {
	int error;

	if (NULL == tp)
		return (EINVAL);
	if (0 != tp_thread_is_tp_thr(tp, NULL))
		return (EDEADLK);
	/* Make sure that shutdown called. */
	tp_shutdown(tp);
	/* Wait all threads before free mem. */
	error = tp_shutdown_wait(tp);
	if (0 != error)
		return (error);
	/* Free resources. */
	tpt_data_uninit(tp->pvt);
	for (size_t i = 0; i < tp->threads_max; i ++) {
		tpt_data_uninit(&tp->threads[i]);
	}
	free(tp);

	return (0);
}


int
tp_threads_create(tp_p tp, int skip_first) {
	tpt_p tpt;

	if (NULL == tp)
		return (EINVAL);
	if (0 != tp->shutdown)
		return (EBUSY);

	for (size_t i = ((0 != skip_first) ? 1 : 0); i < tp->threads_max; i ++) {
		tpt = &tp->threads[i];
		if (NULL == tpt->tp)
			continue;
		tpt->state = TP_THREAD_STATE_STARTING;
		if (0 == pthread_create_eagain(&tpt->pt_id, NULL,
		    tp_thread_proc, tpt)) {
		} else {
			tpt->state = TP_THREAD_STATE_STOP;
		}
	}
	return (0);
}

int
tp_thread_attach_first(tp_p tp) {
	tpt_p tpt;

	if (NULL == tp)
		return (EINVAL);
	if (0 != tp->shutdown)
		return (EBUSY);

	tpt = &tp->threads[0];
	if (TP_THREAD_STATE_STOP != tpt->state)
		return (ESPIPE);

	tpt->state = TP_THREAD_STATE_STARTING;
	tpt->pt_id = pthread_self();

	tp_thread_proc(tpt);

	return (0);
}

int
tp_thread_dettach(tpt_p tpt) {

	if (NULL == tpt)
		return (EINVAL);
	tpt->state = TP_THREAD_STATE_STOP;
	return (0);
}

static void *
tp_thread_proc(void *data) {
	tpt_p tpt = data;
	sigset_t sig_set;
	char thr_name[(TP_NAME_SIZE + 16)];

	if (NULL == tpt) {
		SYSLOGD_ERR(LOG_DEBUG, EINVAL, "Invalid data.");
		return (NULL);
	}

	tpt->tp->threads_cnt ++;
	tpt->state = TP_THREAD_STATE_RUNNING;

	snprintf(thr_name, sizeof(thr_name), "%s: %zu",
	    tpt->tp->name, tpt->thread_num);
	pthread_self_name_set(thr_name);
	pthread_setspecific(tp_tls_key_tpt, (const void*)tpt);
	syslog(LOG_INFO, "%s thread started...", thr_name);

	sigemptyset(&sig_set);
	sigaddset(&sig_set, SIGPIPE);
	if (0 != pthread_sigmask(SIG_BLOCK, &sig_set, NULL)) {
		SYSLOG_ERR(LOG_WARNING, errno,
		    "%s: Can't block the SIGPIPE signal for thread %zu.",
		    tpt->tp->name, tpt->thread_num);
	}

#ifndef DARWIN
	if (-1 != tpt->cpu_id) {
		cpu_set_t cs;
		/* Bind this thread to a single cpu core. */
		CPU_ZERO(&cs);
		CPU_SET(tpt->cpu_id, &cs);
		if (0 == pthread_setaffinity_np(pthread_self(),
		    sizeof(cpu_set_t), &cs)) {
			syslog(LOG_INFO, "%s: bind thread %zu to CPU %i.",
			    tpt->tp->name, tpt->thread_num, tpt->cpu_id);
		} else {
			SYSLOG_ERR(LOG_WARNING, errno,
			    "%s: can't Bind thread %zu to CPU %i.",
			    tpt->tp->name, tpt->thread_num, tpt->cpu_id);
		}
	}
#endif

	tpt_loop(tpt);

	syslog(LOG_INFO, "%s thread exited...", thr_name);
	pthread_setspecific(tp_tls_key_tpt, NULL);
	pthread_self_name_set(NULL);
	memset(&tpt->pt_id, 0x00, sizeof(pthread_t));
	tpt->state = TP_THREAD_STATE_STOP; /* Reset state on exit. */
	tpt->tp->threads_cnt --;

	return (NULL);
}



size_t
tp_thread_count_max_get(tp_p tp) {

	if (NULL == tp)
		return (0);
	return (tp->threads_max);
}

size_t
tp_thread_count_get(tp_p tp) {
	size_t i, cnt;

	if (NULL == tp)
		return (0);
	for (i = 0, cnt = 0; i < tp->threads_max; i ++) {
		if (0 == tpt_is_running(&tp->threads[i]))
			continue;
		cnt ++;
	}
	return (cnt);
}


tpt_p
tp_thread_get_current(void) {
	/* TLS magic. */
	return ((tpt_p)pthread_getspecific(tp_tls_key_tpt));
}

int
tp_thread_is_tp_thr(tp_p tp, tpt_p tpt) {

	if (NULL == tp)
		return (0);
	if (NULL == tpt) {
		tpt = tp_thread_get_current();
	}
	return ((NULL != tpt && tpt->tp == tp));
}

tpt_p
tp_thread_get(tp_p tp, size_t thread_num) {

	if (NULL == tp)
		return (NULL);
	if (tp->threads_max <= thread_num) {
		thread_num = (tp->threads_max - 1);
	}
	return (&tp->threads[thread_num]);
}

tpt_p
tp_thread_get_rr(tp_p tp) {

	if (NULL == tp)
		return (NULL);
	tp->rr_idx ++;
	if (tp->threads_max <= tp->rr_idx) {
		tp->rr_idx = 0;
	}
	return (&tp->threads[tp->rr_idx]);
}

/* Return io_fd that handled by all threads. */
tpt_p
tp_thread_get_pvt(tp_p tp) {

	if (NULL == tp)
		return (NULL);
	return (tp->pvt /* tp->threads[0] */);
}

int
tp_thread_get_cpu_id(tpt_p tpt) {

	if (NULL == tpt)
		return (-1);
	return (tpt->cpu_id);
}

size_t
tp_thread_get_num(tpt_p tpt) {

	if (NULL == tpt)
		return ((size_t)-1);
	return (tpt->thread_num);
}



tp_p
tpt_get_tp(tpt_p tpt) {

	if (NULL == tpt)
		return (NULL);
	return (tpt->tp);
}

int
tpt_is_running(tpt_p tpt) {

	if (NULL == tpt)
		return (0);
	return ((TP_THREAD_STATE_RUNNING == tpt->state ||
	    TP_THREAD_STATE_STARTING == tpt->state));
}

void *
tpt_get_msg_queue(tpt_p tpt) {

	if (NULL == tpt)
		return (NULL);
	return (tpt->msg_queue);
}


int
tpt_data_init(tp_p tp, int cpu_id, size_t thread_num, tpt_p tpt) {
	int error;

	if (NULL == tp || NULL == tpt)
		return (EINVAL);
	memset(tpt, 0x00, sizeof(tp_thread_t));
	tpt->tp = tp;
	tpt->cpu_id = cpu_id;
	tpt->thread_num = thread_num;
	error = tpt_data_event_init(tpt);
	if (0 != error) {
		tpt_data_uninit(tpt);
		return (error);
	}
	return (0);
}

void
tpt_data_uninit(tpt_p tpt) {

	if (NULL == tpt || NULL == tpt->tp)
		return;
	tpt_data_event_destroy(tpt);
	close((int)tpt->io_fd);
	explicit_bzero(tpt, sizeof(tp_thread_t));
}


static int
tpt_ev_validate(int op, tp_event_p ev, tp_udata_p tp_udata) {

	/* Args. */
	if (TP_CTL_LAST < op ||
	    NULL == ev ||
	    NULL == tp_udata)
		return (EINVAL);
	/* flags. */
	if (0 != (~(TP_F_S_MASK) & ev->flags) ||
	    (TP_F_ONESHOT | TP_F_DISPATCH) == ((TP_F_ONESHOT | TP_F_DISPATCH) & ev->flags))
		return (EINVAL); /* Invalid flags: some unknown bits is set. */
	/* tp_udata */
	if (NULL == tp_udata->cb_func ||
	    (uintptr_t)-1 == tp_udata->ident ||
	    NULL == tp_udata->tpt)
		return (EINVAL);
	/* Extended checks. */
	switch (ev->event) {
	case TP_EV_READ:
	case TP_EV_WRITE:
		if (tp_udata->tpt->tp->fd_count <= tp_udata->ident)
			return (EBADF); /* Bad FD. */
		if (0 != (~(TP_FF_RW_MASK) & ev->fflags))
			return (EINVAL); /* Invalid fflags: some unknown bits is set. */
		break;
	case TP_EV_TIMER:
#if defined(TP_F_EDGE) && 0 /* XXX: check this. */
		if (0 != (TP_F_EDGE & ev->flags))
			return (EINVAL); /* Invalid flags. */
#endif
		if (0 != (~(TP_FF_T_MASK) & ev->fflags))
			return (EINVAL); /* Invalid fflags: some unknown bits is set. */
		break;
	default:
		return (EINVAL); /* Bad event. */
	}

	return (0);
}

static int
tpt_ev_post_validate(int op, tp_event_p ev, tp_udata_p tp_udata) {
	int error;

	error = tpt_ev_validate(op, ev, tp_udata);
	if (0 != error)
		return (error);
	return (tpt_ev_post(op, ev, tp_udata));
}

static int
tpt_ev_post_validate_args(int op, uint16_t event,
    uint16_t flags, uint32_t fflags, uint64_t data, tp_udata_p tp_udata) {
	tp_event_t ev;

	ev.event = event;
	ev.flags = flags;
	ev.fflags = fflags;
	ev.data = data;

	return (tpt_ev_post_validate(op, &ev, tp_udata));
}

int
tpt_ev_add(tpt_p tpt, tp_event_p ev, tp_udata_p tp_udata) {

	if (NULL == tp_udata)
		return (EINVAL);
	tp_udata->tpt = tpt;

	return (tpt_ev_post_validate(TP_CTL_ADD, ev, tp_udata));
}

int
tpt_ev_add_args(tpt_p tpt, uint16_t event, uint16_t flags,
    uint32_t fflags, uint64_t data, tp_udata_p tp_udata) {

	if (NULL == tp_udata)
		return (EINVAL);
	tp_udata->tpt = tpt;

	return (tpt_ev_post_validate_args(TP_CTL_ADD, event, flags,
	    fflags, data, tp_udata));
}

int
tpt_ev_add_args2(tpt_p tpt, uint16_t event, uint16_t flags,
    tp_udata_p tp_udata) {

	if (NULL == tp_udata)
		return (EINVAL);
	tp_udata->tpt = tpt;

	return (tpt_ev_post_validate_args(TP_CTL_ADD, event, flags,
	    0, 0, tp_udata));
}

int
tpt_ev_del(tp_event_p ev, tp_udata_p tp_udata) {

	return (tpt_ev_post_validate(TP_CTL_DEL, ev, tp_udata));
}

int
tpt_ev_del_args1(uint16_t event, tp_udata_p tp_udata) {

	return (tpt_ev_post_validate_args(TP_CTL_DEL, event, 0, 0, 0,
	    tp_udata));
}

int
tpt_ev_enable(int enable, tp_event_p ev, tp_udata_p tp_udata) {

	return (tpt_ev_post_validate(
	    ((0 != enable) ? TP_CTL_ENABLE : TP_CTL_DISABLE),
	    ev, tp_udata));
}

int
tpt_ev_enable_args(int enable, uint16_t event, uint16_t flags,
    uint32_t fflags, uint64_t data, tp_udata_p tp_udata) {

	return (tpt_ev_post_validate_args(
	    ((0 != enable) ? TP_CTL_ENABLE : TP_CTL_DISABLE),
	    event, flags, fflags, data, tp_udata));
}

int
tpt_ev_enable_args1(int enable, uint16_t event, tp_udata_p tp_udata) {

	return (tpt_ev_post_validate_args(
	    ((0 != enable) ? TP_CTL_ENABLE : TP_CTL_DISABLE),
	    event, 0, 0, 0, tp_udata));
}
