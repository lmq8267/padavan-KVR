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
#include <sys/stat.h> /* chmod, fchmod, umask */
#include <sys/uio.h> /* readv, preadv, writev, pwritev */
#include <inttypes.h>
#include <errno.h>
#include <pwd.h>
#include <grp.h>
#include <fcntl.h> /* open, fcntl */
#include <stdio.h>  /* snprintf, fprintf */
#include <string.h> /* memcpy, memmove, memset, strnlen, strerror... */
#include <unistd.h> /* close, write, sysconf */
#include <stdlib.h> /* malloc, exit */
#include <signal.h>
#include <poll.h>
#include <syslog.h>

#include "utils/macro.h"
#include "al/os.h"
#include "utils/mem_utils.h"
#include "utils/sys.h"


void
signal_install(sig_t func) {

	signal(SIGINT, func);
	signal(SIGTERM, func);
	//signal(SIGKILL, func);
	signal(SIGHUP, func);
	signal(SIGUSR1, func);
	signal(SIGUSR2, func);
	signal(SIGPIPE, SIG_IGN);
}

void
make_daemon(void) {
	int error, nullfd;
	char err_descr[256], *err_source = NULL;

	switch (fork()) {
	case -1:
		err_source = "fork()";
err_out:
		error = errno;
		strerror_r(error, err_descr, sizeof(err_descr));
		fprintf(stderr, "make_daemon: %s failed: %i %s\n",
		    err_source, error, err_descr);
		exit(error);
		/* return; */
	case 0: /* Child. */
		break;
	default: /* Parent. */
		exit(0);
	}

	/* Child... */
	setsid();
	setpgid(getpid(), 0);
	chdir("/");

	/* Close stdin, stdout, stderr. */
	nullfd = open("/dev/null", O_RDWR);
	if (-1 == nullfd) {
		err_source = "open(\"/dev/null\")";
		goto err_out;
	}
	dup2(nullfd, STDIN_FILENO);
	dup2(nullfd, STDOUT_FILENO);
	dup2(nullfd, STDERR_FILENO);
	if (STDERR_FILENO < nullfd) {
		close(nullfd);
	}
}


/* WARNING!
 * While use with openlog(..., LOG_PERROR, ...) call
 * std_syslog_redirector(LOG_MASK(LOG_ERR)) to avoid infinite messages loop.
 * 
 * close(STDOUT_FILENO) + close(STDERR_FILENO) - will trigger cleanup
 * and thread exit.
 * 
 * If printf(...)/fprintf(stdout, ...) not logged than check:
 * 1. \n at end of string is present.
 * 2. fflush(stdout) may be required to avoid caching.
 */
static void *
std_syslog_redirector_proc(void *data) {
	sigset_t sig_set;
	int fildes[2];
	const int prio_skip_mask = (int)(size_t)data;
	const int target_fd[2] = { STDOUT_FILENO, STDERR_FILENO };
	const int syslog_prio[2] = { LOG_INFO, LOG_ERR };
	struct pollfd fds[2];
	uint8_t buf[2][4096], *cur_pos, *le;
	size_t i, fds_cnt = nitems(fds), buf_pos[2] = { 0, 0 };
	ssize_t ios;

	syslog(LOG_DEBUG, "STD syslog redirector starting...");

	/* Set thread name for better debugging. */
	pthread_self_name_set("STD syslog redirector");
	/* Block PIPE signal. */
	sigemptyset(&sig_set);
	sigaddset(&sig_set, SIGPIPE);
	if (0 != pthread_sigmask(SIG_BLOCK, &sig_set, NULL)) {
		SYSLOG_ERR(LOG_WARNING, errno,
		    "std_syslog_redirector: can't block the SIGPIPE signal.");
	}
	/* Create pipes and make them as stdout and stderr. */
	memset(&fds, 0x00, sizeof(fds));
	for (i = 0; i < nitems(fds); i ++) {
		if (0 != (prio_skip_mask & LOG_MASK(syslog_prio[i]))) {
			fds[i].fd = -1;
			fds_cnt --;
			continue;
		}
		if (-1 == pipe2(fildes, (O_CLOEXEC | O_NONBLOCK))) {
			SYSLOG_ERR(LOG_ERR, errno,
			    "std_syslog_redirector: pipe2() fail, exiting.");
			return (NULL);
		}
		fds[i].fd = fildes[0]; /* Read side descriptor. */
		fds[i].events = (POLLIN | POLLERR | POLLHUP);
		/* Replace target std descriptor with pipe~s write side descriptor. */
		dup2(fildes[1], target_fd[i]);
		close(fildes[1]);
	}

	/* Read and syslog() loop. */
	for (; 0 != fds_cnt;) {
		/* Wait for new data in STDOUT_FILENO, STDERR_FILENO. */
		if (0 >= poll(fds, nitems(fds), -1)) {
			for (i = 0; i < nitems(fds); i ++) { /* Cleanup descriptors. */
				close(fds[i].fd);
			}
			SYSLOG_ERR(LOG_ERR, errno,
			    "std_syslog_redirector: poll() fail, exiting.");
			break;
		}
		for (i = 0; i < nitems(fds); i ++) {
			if (-1 == fds[i].fd ||
			    0 == fds[i].revents)
				continue;
			fds[i].revents = 0;
			ios = read(fds[i].fd, &buf[i][buf_pos[i]],
			    (sizeof(buf[0]) - buf_pos[i]));
			if (0 >= ios) { /* Error or EOF. */
				close(fds[i].fd);
				fds[i].fd = -1;
				fds_cnt --;
				continue;
			}
			buf_pos[i] += (size_t)ios;
			/* Lines to syslog(). */
			for (cur_pos = buf[i];;) {
				le = mem_chr_ptr(cur_pos, buf[i], buf_pos[i], '\n');
				if (NULL == le)
					break;
				syslog(syslog_prio[i], "%.*s",
				    (int)(le - cur_pos), cur_pos);
				cur_pos = (le + 1);
			}
			/* Tail handle. */
			ios = (cur_pos - buf[i]); /* Processed data size. */
			if (buf_pos[i] <= (size_t)ios) { /* All data sysloged. */
				buf_pos[i] = 0;
				continue;
			}
			if (0 == ios &&
			    sizeof(buf[0]) == buf_pos[i]) { /* Log line > buf size, flush. */
				syslog(syslog_prio[i], "%.*s...",
				    (int)buf_pos[i], cur_pos);
				buf_pos[i] = 0;
				continue;
			}
			/* Shift buf. */
			memmove(buf[i], cur_pos, (buf_pos[i] - (size_t)ios));
			buf_pos[i] -= (size_t)ios;
		}
	}

	syslog(LOG_DEBUG, "STD syslog redirector exit.");

	return (NULL);
}
int
std_syslog_redirector(const int prio_skip_mask) {
	pthread_t pt_id;

	if (0 != (prio_skip_mask & ~(LOG_MASK(LOG_INFO) | LOG_MASK(LOG_ERR))))
		return (EINVAL); /* Some unsupported bits set. */
	if ((LOG_MASK(LOG_INFO) | LOG_MASK(LOG_ERR)) ==
	    (prio_skip_mask & (LOG_MASK(LOG_INFO) | LOG_MASK(LOG_ERR))))
		return (EINVAL); /* Nothink to do. */
	return (pthread_create_eagain(&pt_id, NULL,
	    std_syslog_redirector_proc, (void*)(size_t)prio_skip_mask));
}


int
write_pid(const char *file_name) {
	int rc, fd;
	char data[16];
	ssize_t ios;

	if (NULL == file_name)
		return (EINVAL);

	rc = snprintf(data, sizeof(data), "%d", getpid());
	if (0 > rc || sizeof(data) <= (size_t)rc)
		return (EFAULT);
	fd = open(file_name, (O_WRONLY | O_CREAT | O_TRUNC), 0644);
	if (-1 == fd)
		return (errno);
	ios = write(fd, data, (size_t)rc);
	if ((size_t)ios != (size_t)rc) {
		close(fd);
		unlink(file_name);
		return (errno);
	}
	fchmod(fd, (S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH));
	close(fd);

	return (0);
}

int
set_user_and_group(uid_t pw_uid, gid_t pw_gid) {
	int error;
	struct passwd *pwd, pwd_buf;
	char buffer[4096], err_descr[256];

	if (0 == pw_uid || 0 == pw_gid)
		return (EINVAL);

	error = getpwuid_r(pw_uid, &pwd_buf, buffer, sizeof(buffer), &pwd);
	if (0 != error) {
		strerror_r(error, err_descr, sizeof(err_descr));
		fprintf(stderr, "set_user_and_group: getpwuid_r() error %i: %s\n",
		    error, err_descr);
		return (error);
	}

	if (0 != setgid(pw_gid)) {
		error = errno;
		strerror_r(error, err_descr, sizeof(err_descr));
		fprintf(stderr, "set_user_and_group: setgid() error %i: %s\n",
		    error, err_descr);
		return (error);
	}
	if (0 != initgroups(pwd->pw_name, pw_gid)) {
		error = errno;
		strerror_r(error, err_descr, sizeof(err_descr));
		fprintf(stderr, "set_user_and_group: initgroups() error %i: %s\n",
		    error, err_descr);
		return (error);
	}
	if (0 != setgroups(1, &pwd->pw_gid)) {
		error = errno;
		strerror_r(error, err_descr, sizeof(err_descr));
		fprintf(stderr, "set_user_and_group: setgroups() error %i: %s\n",
		    error, err_descr);
		return (error);
	}
	if (0 != setuid(pw_uid)) {
		error = errno;
		strerror_r(error, err_descr, sizeof(err_descr));
		fprintf(stderr, "set_user_and_group: setuid() error %i: %s\n",
		    error, err_descr);
		return (error);
	}

	return (0);
}

int
user_home_dir_get(char *buf, size_t buf_size, size_t *buf_size_ret) {
	const char *homedir;
	char tmbuf[4096];
	size_t homedir_size;
	struct passwd pwd, *pwdres;

	homedir = getenv("HOME");
	if (NULL == homedir) {
		if (0 == getpwuid_r(getuid(), &pwd, tmbuf, sizeof(tmbuf), &pwdres)) {
			homedir = pwd.pw_dir;
		}
	}
	if (NULL == homedir)
		return (errno);
	homedir_size = strlen(homedir);
	if (NULL != buf_size_ret) {
		(*buf_size_ret) = homedir_size;
	}
	if (NULL == buf && buf_size < homedir_size)
		return (-1);
	memcpy(buf, homedir, homedir_size);

	return (0);
}

int
read_file(const char *file_name, size_t file_name_size, off_t offset,
    size_t size, size_t max_size, uint8_t **buf, size_t *buf_size) {
	int fd, error;
	ssize_t rd;
	char filename[1024];
	struct stat sb;

	if (NULL == file_name || sizeof(filename) <= file_name_size ||
	    NULL == buf || NULL == buf_size)
		return (EINVAL);
	if (0 == file_name_size) {
		file_name_size = strnlen(file_name, (sizeof(filename) - 1));
	}
	memcpy(filename, file_name, file_name_size);
	filename[file_name_size] = 0;

	/* Open file. */
	fd = open(filename, O_RDONLY);
	if (-1 == fd)
		return (errno);
	/* Get file size. */
	if (0 != fstat(fd, &sb)) {
		error = errno;
		goto err_out;
	}
	/* Check size and offset. */
	if (0 != size) {
		if ((offset + (off_t)size) > sb.st_size) {
			error = EINVAL;
			goto err_out;
		}
	} else {
		/* Check overflow. */
		if (offset >= sb.st_size) {
			error = EINVAL;
			goto err_out;
		}
		size = (size_t)(sb.st_size - offset);
		if (0 != max_size && max_size < size) {
			(*buf_size) = size;
			error = EFBIG;
			goto err_out;
		}
	}
	/* Allocate buf for file content. */
	(*buf_size) = size;
	(*buf) = malloc((size + sizeof(void*)));
	if (NULL == (*buf)) {
		error = ENOMEM;
		goto err_out;
	}
	/* Read file content. */
	rd = pread(fd, (*buf), size, offset);
	close(fd);
	if (-1 == rd) {
		error = errno;
		free((*buf));
		(*buf) = NULL;
		return (error);
	}
	(*buf)[size] = 0;

	return (0);

err_out:
	close(fd);

	return (error);
}

int
read_file_buf(const char *file_name, size_t file_name_size, uint8_t *buf,
    size_t buf_size, size_t *buf_size_ret) {
	int fd;
	size_t rd;
	char filename[1024];

	if (NULL == file_name || sizeof(filename) <= file_name_size ||
	    NULL == buf || 0 == buf_size)
		return (EINVAL);

	if (0 == file_name_size) {
		file_name_size = strnlen(file_name, (sizeof(filename) - 1));
	}
	memcpy(filename, file_name, file_name_size);
	filename[file_name_size] = 0;
	/* Open file. */
	fd = open(filename, O_RDONLY);
	if (-1 == fd)
		return (errno);
	/* Read file content. */
	rd = (size_t)read(fd, buf, buf_size);
	close(fd);
	if ((size_t)-1 == rd)
		return (errno);
	if (buf_size > rd) { /* Zeroize end. */
		buf[rd] = 0;
	}
	if (NULL != buf_size_ret) {
		(*buf_size_ret) = rd;
	}

	return (0);
}

int
file_size_get(const char *file_name, size_t file_name_size, off_t *file_size) {
	struct stat sb;
	char filename[1024];

	if (NULL == file_name || sizeof(filename) <= file_name_size ||
	    NULL == file_size)
		return (EINVAL);
	if (0 == file_name_size) {
		file_name_size = strnlen(file_name, (sizeof(filename) - 1));
	}
	memcpy(filename, file_name, file_name_size);
	filename[file_name_size] = 0;
	if (0 != stat(filename, &sb))
		return (errno);
	(*file_size) = sb.st_size;

	return (0);
}

int
get_cpu_count(void) {
	int ret;

	ret = (int)sysconf(_SC_NPROCESSORS_ONLN);
	if (-1 == ret) {
		ret = 1;
	}

	return (ret);
}

time_t
gettime_monotonic(void) {
	struct timespec ts;

	if (0 != clock_gettime(CLOCK_MONOTONIC_FAST, &ts))
		return (0);
	return (ts.tv_sec);
}

/* Set file/socket CLOEXEC mode. */
int
fd_set_cloexec(const uintptr_t fd, const int cloexec) {
	int cf, tf; /* File descriptor flags. */

	if ((uintptr_t)-1 == fd)
		return (EINVAL);
	/* This part can be simplificated to only call:
	 * fcntl(fd, F_SETFD, ((0 != cloexec) ? FD_CLOEXEC : 0))
	 * if build system some how check that only FD_CLOEXEC defined for
	 * F_SETFD. */
	cf = fcntl((int)fd, F_GETFD); /* Read current flags. */
	if (-1 == cf)
		return (errno);
	tf = ((0 != cloexec) ? (cf | FD_CLOEXEC) : (cf & ~FD_CLOEXEC));
	if (cf == tf)
		return (0); /* Allready set. */
	if (-1 == fcntl((int)fd, F_SETFD, tf)) /* Update flags. */
		return (errno);
	return (0);
}

/* Set file/socket to non blocking mode. */
int
fd_set_nonblocking(const uintptr_t fd, const int nonblock) {
	int cf, tf; /* File status flags. */

	if ((uintptr_t)-1 == fd)
		return (EINVAL);
	cf = fcntl((int)fd, F_GETFL); /* Read current flags. */
	if (-1 == cf)
		return (errno);
	tf = ((0 != nonblock) ? (cf | O_NONBLOCK) : (cf & ~O_NONBLOCK));
	if (cf == tf)
		return (0); /* Allready set. */
	if (-1 == fcntl((int)fd, F_SETFL, tf)) /* Update flags. */
		return (errno);
	return (0);
}
