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
#include <inttypes.h>
#include <errno.h>
#include <pwd.h>
#include <grp.h>
#include <stdio.h>  /* snprintf, fprintf */
#include <string.h> /* memcpy, memmove, memset, strnlen, strerror... */
#include <stdlib.h> /* malloc, exit */
#include <syslog.h>

#include "utils/cmd_line_daemon.h"


int
cmd_line_parse(int argc, char **argv, cmd_line_data_p data) {
	int error, i;
	uint8_t *cur_ptr;
	char *num, *uid, *gid;
	struct passwd *pwd, pwd_buf;
	struct group *grp, grp_buf;
	char tmbuf[4096];

	if (NULL == data)
		return (1);
	memset(data, 0x00, sizeof(cmd_line_data_t));
	data->log_level = LOG_INFO;
	if (2 > argc)
		return (1);

	for (i = 1; i < argc; i ++) {
		cur_ptr = (uint8_t*)argv[i];
		if ('-' != cur_ptr[0]) {
			fprintf(stderr, "invalid option: \"%s\".\n", argv[i]);
			return (0);
		}
		cur_ptr ++;
		while (cur_ptr[0]) {
			switch (*cur_ptr++) {
			case '?':
			case 'h':
			case 'H':
				return (1);
			case 'd':
			case 'D':
				data->daemon = 1;
				break;
			case 'l':
			case 'L':
				if (cur_ptr[0]) {
					num = (char*)cur_ptr;
				} else if (argv[++ i]) {
					num = argv[i];
				} else {
					fprintf(stderr, "option \"-l\" requires number.\n");
					return (1);
				}
				if (NULL == num)
					break;
				data->log_level = atoi(num);
				if (data->log_level < LOG_EMERG &&
				    data->log_level > LOG_DEBUG) {
					fprintf(stderr, "option \"-l\" requires number in range: %i - %i.\n",
						LOG_EMERG, LOG_DEBUG);
					return (1);
				}
				break;
			case 'c':
			case 'C':
				if (cur_ptr[0]) {
					data->cfg_file_name = (char*)cur_ptr;
				} else if (argv[++ i]) {
					data->cfg_file_name = argv[i];
				} else {
					fprintf(stderr, "option \"-c\" requires config file name.\n");
					return (1);
				}
				break;
			case 'f':
			case 'F':
				if (cur_ptr[0]) {
					data->file_name = (char*)cur_ptr;
				} else if (argv[++ i]) {
					data->file_name = argv[i];
				} else {
					fprintf(stderr, "option \"-f\" requires file name.\n");
					return (1);
				}
				break;
			case 'p':
			case 'P':
				if (cur_ptr[0]) {
					data->pid_file_name = (char*)cur_ptr;
				} else if (argv[++ i]) {
					data->pid_file_name = argv[i];
				} else {
					fprintf(stderr, "option \"-p\" requires pid file name.\n");
					return (1);
				}
				break;
			case 'u':
			case 'U':
				if (cur_ptr[0]) {
					uid = (char*)cur_ptr;
				} else if (argv[++ i]) {
					uid = argv[i];
				} else {
					fprintf(stderr, "option \"-u\" requires UID.\n");
					return (1);
				}
				if (NULL == uid)
					break;
				error = getpwnam_r(uid, &pwd_buf, tmbuf, sizeof(tmbuf), &pwd);
				if (0 == error) {
					data->pw_uid = pwd->pw_uid;
				} else {
					strerror_r(error, tmbuf, sizeof(tmbuf));
					fprintf(stderr, "option \"-u\" requires UID, UID %s not found: %i - %s.\n",
					    uid, error, tmbuf);
					return (1);
				}
				break;
			case 'g':
			case 'G':
				if (cur_ptr[0]) {
					gid = (char*)cur_ptr;
				} else if (argv[++ i]) {
					gid = argv[i];
				} else {
					fprintf(stderr, "option \"-g\" requires GID.\n");
					return (1);
				}
				if (NULL == gid)
					break;
				error = getgrnam_r(gid, &grp_buf, tmbuf, sizeof(tmbuf), &grp);
				if (0 == error) {
					data->pw_gid = grp->gr_gid;
				} else {
					strerror_r(error, tmbuf, sizeof(tmbuf));
					fprintf(stderr, "option \"-g\" requires GID, GID %s not found: %i - %s.\n",
					    gid, error, tmbuf);
					return (1);
				}
				break;
			case 'v':
			case 'V':
				data->verbose = 1;
				break;
			default:
				fprintf(stderr, "unknown option: \"%c\".\n", cur_ptr[-1]);
				return (1);
			} /* switch (*cur_ptr++) */
		} /* while (*cur_ptr) */
	} /* for(i) */

	return (0);
}

void
cmd_line_usage(const char *prog_name, const char *version,
    const char *author_email, const char *url) {

	fprintf(stderr, "%s %s -- (c) %s\n", prog_name, version, author_email);
	fprintf(stderr, "   Website: %s\n", url);
#ifdef DEBUG
	fprintf(stderr, "   Build: "__DATE__" "__TIME__", DEBUG\n");
#else
	fprintf(stderr, "   Build: "__DATE__" "__TIME__", Release\n");
#endif
	fprintf(stderr,
		"usage: [-d] [-l num] [-v] [-c file]\n"
		"       [-p PID file] [-u uid|usr -g gid|grp]\n"
		" -h           usage (this screen)\n"
		" -d           become daemon\n"
		" -l num       log level from LOG_EMERG=%i to LOG_DEBUG=%i\n",
		LOG_EMERG, LOG_DEBUG);
	fprintf(stderr,
		" -c file      config file\n"
		" -p PID file  file name to store PID\n"
		" -u uid|user  change uid\n"
		" -g gid|group change gid\n"
		" -v           verbose\n");
}
