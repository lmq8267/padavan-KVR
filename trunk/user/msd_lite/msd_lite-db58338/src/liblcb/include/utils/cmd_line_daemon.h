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


#ifndef __COMMAND_LINE_DAEMON_H__
#define __COMMAND_LINE_DAEMON_H__

#include <sys/param.h>
#include <sys/types.h>
#include <inttypes.h>
#include <pwd.h>
#include <grp.h>


typedef struct cmd_line_data_s {
	char	*cfg_file_name;
	char	*pid_file_name;
	uid_t	pw_uid;		/* user uid */
	gid_t	pw_gid;		/* user gid */
	int	daemon;
	int	log_level;	/* LOG_DEBUG - LOG_EMERG. */
	int	verbose;
	char	*file_name;
} cmd_line_data_t, *cmd_line_data_p;


int	cmd_line_parse(int argc, char **argv, cmd_line_data_p data);
void	cmd_line_usage(const char *prog_name, const char *version,
	    const char *author_email, const char *url);


#endif /* __COMMAND_LINE_DAEMON_H__ */
