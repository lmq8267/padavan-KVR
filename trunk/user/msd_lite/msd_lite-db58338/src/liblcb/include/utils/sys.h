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


#ifndef __SYS_H__
#define __SYS_H__

#include <sys/types.h>
#include <inttypes.h>
#include <pwd.h>
#include <grp.h>
#include <signal.h>


void	signal_install(sig_t func);
void	make_daemon(void);
int	std_syslog_redirector(const int prio_skip_mask);
int	write_pid(const char *file_name);
int	set_user_and_group(uid_t pw_uid, gid_t pw_gid);
int	user_home_dir_get(char *buf, size_t buf_size, size_t *buf_size_ret);

int	read_file(const char *file_name, size_t file_name_size,
	    off_t offset, size_t size, size_t max_size,
	    uint8_t **buf, size_t *buf_size);
int	read_file_buf(const char *file_name, size_t file_name_size,
	    uint8_t *buf, size_t buf_size, size_t *buf_size_ret);
int	file_size_get(const char *file_name, size_t file_name_size,
	    off_t *file_size);

int	get_cpu_count(void);
time_t	gettime_monotonic(void);
int	fd_set_cloexec(const uintptr_t fd, const int cloexec);
int	fd_set_nonblocking(const uintptr_t fd, const int nonblock);


#endif /* __SYS_H__ */
