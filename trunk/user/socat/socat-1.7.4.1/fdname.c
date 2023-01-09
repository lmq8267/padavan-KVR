/* source: fdname.c */
/* Copyright Gerhard Rieger and contributors (see file CHANGES) */
/* Published under the GNU General Public License V.2, see file COPYING */

/* the subroutine sockname prints the basic info about the address of a socket
   NOTE: it works on UNIX (kernel) file descriptors, not on libc files! */

#include "config.h"
#include "xioconfig.h"	/* what features are enabled */

#include "sysincludes.h"

#include "mytypes.h"
#include "compat.h"
#include "error.h"
#include "sycls.h"
#include "sysutils.h"

#include "filan.h"


struct sockopt {
   int so;
   char *name;
};


int statname(const char *file, int fd, int filetype, FILE *outfile, char style);
int cdevname(int fd, FILE *outfile);
int sockname(int fd, FILE *outfile, char style);
int unixame(int fd, FILE *outfile);
int tcpname(int fd, FILE *outfile);


int fdname(const char *file, int fd, FILE *outfile, const char *numform,
	   char style) {
   struct stat buf = {0};
   int filetype;
   Debug1("checking file descriptor %u", fd);
   if (fd >= 0) {
      if (Fstat(fd, &buf) < 0) {
	 if (errno == EBADF) {
	    Debug2("fstat(%d): %s", fd, strerror(errno));
	    return -1;
	 } else {
	    Error2("fstat(%d): %s", fd, strerror(errno));
	 }
      }
      filetype = (buf.st_mode&S_IFMT)>>12;
      if (numform != NULL) {
	 fprintf(outfile, numform, fd);
      }
      return statname(file, fd, filetype, outfile, style);
   } else {
      if (Stat(file, &buf) < 0) {
	 Error2("stat(\"%s\"): %s", file, strerror(errno));
      }
      filetype = (buf.st_mode&S_IFMT)>>12;
      return statname(file, -1, filetype, outfile, style);
   }
}

#if HAVE_PROC_DIR_FD
static int procgetfdname(int fd, char *filepath, size_t pathsize) {
   static pid_t pid = -1;
   char procpath[PATH_MAX];
   int len;

   /* even if configure has shown that we have /proc, we must check if it
      exists at runtime, because we might be in a chroot environment */
#if HAVE_STAT64
   {
      struct stat64 buf;
      if (Stat64("/proc", &buf) < 0) {
	 return -1;
      }
      if (!S_ISDIR(buf.st_mode)) {
	 return -1;
      }
   }
#else /* !HAVE_STAT64 */
   {
      struct stat buf;
      if (Stat("/proc", &buf) < 0) {
	 return -1;
      }
      if (!S_ISDIR(buf.st_mode)) {
	 return -1;
      }
   }
#endif /* !HAVE_STAT64 */
       
   if (pid < 0)  pid = Getpid();
   snprintf(procpath, sizeof(procpath), "/proc/"F_pid"/fd/%d", pid, fd);
   if ((len = Readlink(procpath, filepath, pathsize-1)) < 0) {
      Error4("readlink(\"%s\", %p, "F_Zu"): %s",
	     procpath, filepath, pathsize, strerror(errno));
      return -1;
   }
   filepath[len] = '\0';
   return 0;
}
#endif /* HAVE_PROC_DIR_FD */
   
int statname(const char *file, int fd, int filetype, FILE *outfile,
	     char style) {
   char filepath[PATH_MAX];

   filepath[0] = '\0';
#if HAVE_PROC_DIR_FD
   if (fd >= 0) {
      procgetfdname(fd, filepath, sizeof(filepath));
      if (filepath[0] == '/') {
	 file = filepath;
      }
   }
#endif /*  HAVE_PROC_DIR_FD */
   /* now see for type specific infos */
   switch (filetype) {
   case (S_IFIFO>>12):	/* 1, FIFO */
      fputs("pipe", outfile);
      if (file) fprintf(outfile, " %s", file);
      break;
   case (S_IFCHR>>12):	/* 2, character device */
      if (cdevname(fd, outfile) == 0) {
	 if (file) fprintf(outfile, " %s", file);
      }
      break;
   case (S_IFDIR>>12):	/* 4, directory */
      fputs("dir", outfile);
      if (file) fprintf(outfile, " %s", file);
      break;
   case (S_IFBLK>>12):	/* 6, block device */
      fputs("blkdev", outfile);
      if (file) fprintf(outfile, " %s", file);
      break;
   case (S_IFREG>>12):	/* 8, regular file */
      fputs("file", outfile);
      if (file) fprintf(outfile, " %s", file);
      break;
   case (S_IFLNK>>12):	/* 10, symbolic link */
      fputs("link", outfile);
      if (file) fprintf(outfile, " %s", file);
      break;
   case (S_IFSOCK>>12): /* 12, socket */
#if _WITH_SOCKET
      if (fd >= 0) {
	 sockname(fd, outfile, style);
      } else if (file) {
	 fprintf(outfile, "socket %s", file);
      } else {
	 fputs("socket", outfile);
      }
#else
      Error("SOCKET support not compiled in");
      return -1;
#endif /* !_WITH_SOCKET */
      break;
   }
   /* ioctl() */
   fputc('\n', outfile);

   return 0;
}


/* character device analysis */
/* return -1 on error, 0 if no name was found, or 1 if it printed ttyname */
int cdevname(int fd, FILE *outfile) {
   int ret;

   if ((ret = Isatty(fd)) < 0) {
      Error2("isatty(%d): %s", fd, strerror(errno));
      return -1;
   }
   if (ret > 0) {
      char *name;

      fputs("tty", outfile);
      if ((name = Ttyname(fd)) != NULL) {
	 fputc(' ', outfile);
	 fputs(name, outfile);
	 return 1;
      }
   } else {
      fputs("chrdev", outfile);
   }
   return 0;
}

int sockettype(int socktype, char *typename, size_t typenamemax) {
   switch (socktype) {
   case SOCK_STREAM:    strncpy(typename,  "stream",    typenamemax); break;
   case SOCK_DGRAM:     strncpy(typename,  "dgram",     typenamemax); break;
   case SOCK_SEQPACKET: strncpy(typename,  "seqpacket", typenamemax); break;
   case SOCK_RAW:       strncpy(typename,  "raw",       typenamemax); break;
   case SOCK_RDM:       strncpy(typename,  "rdm",       typenamemax); break;
#ifdef SOCK_PACKET
   case SOCK_PACKET:    strncpy(typename,  "packet",    typenamemax); break;
#endif
   default:             snprintf(typename, typenamemax, "socktype%u", socktype); break;
   }
   return 0;
}

#if _WITH_SOCKET
int sockname(int fd, FILE *outfile, char style) {
#define FDNAME_OPTLEN 256
#define FDNAME_NAMELEN 256
   socklen_t optlen;
#if HAVE_GETPROTOBYNUMBER || HAVE_GETPROTOBYNUMBER_R
   struct protoent protoent, *protoentp;
#endif
#define PROTONAMEMAX 1024 
   char protoname[PROTONAMEMAX];
#if defined(SO_PROTOCOL) || defined(SO_PROTOTYPE)
   int proto;
#endif
   int opttype;
#ifdef SO_ACCEPTCONN
   int optacceptconn;
#endif
   int result /*0, i*/;
   char socknamebuff[FDNAME_NAMELEN];
   char peernamebuff[FDNAME_NAMELEN];
   /* in Linux these optcodes are 'enum', but on AIX they are bits! */
   union sockaddr_union sockname, peername;	/* the longest I know of */
   socklen_t socknamelen, peernamelen;
#     define TYPENAMEMAX 16
      char typename[TYPENAMEMAX];
#if 0 && defined(SIOCGIFNAME)
   /*Linux struct ifreq ifc = {{{ 0 }}};*/
   struct ifreq ifc = {{ 0 }};
#endif
   int rc;

#if defined(SO_PROTOCOL) || defined(SO_PROTOTYPE)
   optlen = sizeof(proto);
#ifdef SO_PROTOCOL
   Getsockopt(fd, SOL_SOCKET, SO_PROTOCOL,   &proto,         &optlen);
#elif defined(SO_PROTOTYPE)
   Getsockopt(fd, SOL_SOCKET, SO_PROTOTYPE,  &proto,         &optlen);
#endif
#endif /* defined(SO_PROTOCOL) || defined(SO_PROTOTYPE) */

   optlen = sizeof(opttype);
   Getsockopt(fd, SOL_SOCKET, SO_TYPE,       &opttype,       &optlen);
   sockettype(opttype, typename, sizeof(typename));

   optlen = sizeof(optacceptconn);
#ifdef SO_ACCEPTCONN
   Getsockopt(fd, SOL_SOCKET, SO_ACCEPTCONN, &optacceptconn, &optlen);
#endif

#if defined(SO_PROTOCOL) || defined(SO_PROTOTYPE)
#if HAVE_GETPROTOBYNUMBER_R
   rc = getprotobynumber_r(proto, &protoent, protoname, sizeof(protoname), &protoentp);
   if (protoentp == NULL) {
      Warn2("sockname(): getprotobynumber_r(proto=%d, ...): %s",
	    proto, strerror(rc));
   }
   strncpy(protoname, protoentp->p_name, sizeof(protoname));
#elif HAVE_GETPROTOBYNUMBER
   protoentp = getprotobynumber(proto);
   strncpy(protoname, protoentp->p_name, sizeof(protoname));
#else
   switch (proto) {
   case IPPROTO_TCP:  strcpy(protoname, "tcp"); break; 
   case IPPROTO_UDP:  strcpy(protoname, "udp"); break; 
   case IPPROTO_SCTP: strcpy(protoname, "sctp"); break;
   default: sprintf(protoname, "proto%d", proto); break;
   }
#endif
#else
   if (opttype == SOCK_STREAM) {
      strcpy(protoname, "tcp");
   } else if (opttype == SOCK_DGRAM) {
      strcpy(protoname, "udp");
   } else {
      strcpy(protoname, "socket");
   }
#endif /* defined(SO_PROTOCOL) || defined(SO_PROTOTYPE) */
   socknamelen = sizeof(sockname);
   result = Getsockname(fd, &sockname.soa, &socknamelen);
   if (result < 0) {
      Error2("getsockname(%d): %s", fd, strerror(errno));
      return -1;
   }

   peernamelen = sizeof(peername);
   result = Getpeername(fd, (struct sockaddr *)&peername, &peernamelen);
   if (result < 0) {
      Warn2("getpeername(%d): %s", fd, strerror(errno));
   }

   switch (sockname.soa.sa_family) {
#if WITH_UNIX
   case AF_UNIX:
     switch (style) {
     case 's':
      fprintf(outfile, "unix%s%s %s",
	      opttype==SOCK_DGRAM?"datagram":"",
#ifdef SO_ACCEPTCONN
	      optacceptconn?"(listening)":
#endif
	      "",
	      sockaddr_unix_info(&sockname.un, socknamelen,
				 socknamebuff, sizeof(socknamebuff)));
      break;
     case 'S':
	//sockettype(opttype, typename, TYPENAMEMAX);
	fprintf(outfile, "unix %s-%s %s %s",
		sockaddr_unix_info(&sockname.un, socknamelen,
				   socknamebuff, sizeof(socknamebuff)),
		sockaddr_unix_info(&peername.un, peernamelen,
				   peernamebuff, sizeof(peernamebuff)),
		typename,
#ifdef SO_ACCEPTCONN
		optacceptconn?"(listening)":
#endif
		"");
	break;
     }
     break;
#endif /* WITH_UNIX */
#if WITH_IP4
   case AF_INET:
     switch (style) {
     case 's':
      switch (opttype) {
#if WITH_TCP
      case SOCK_STREAM:
	 fprintf(outfile, "%s%s %s %s",
		 protoname,
#ifdef SO_ACCEPTCONN
		 optacceptconn?"(listening)":
#endif
		 "",
		 sockaddr_inet4_info(&sockname.ip4,
				     socknamebuff, sizeof(socknamebuff)),
		 sockaddr_inet4_info(&peername.ip4,
				     peernamebuff, sizeof(peernamebuff)));
	 break;
#endif
#if WITH_UDP
      case SOCK_DGRAM:
	 fprintf(outfile, "%s%s %s %s",
		 protoname,
#ifdef SO_ACCEPTCONN
		 optacceptconn?"(listening)":
#endif
		 "",
		 sockaddr_inet4_info(&sockname.ip4,
				     socknamebuff, sizeof(socknamebuff)),
		 sockaddr_inet4_info(&peername.ip4,
				     peernamebuff, sizeof(peernamebuff)));
	 break;
#endif
      default:
	 fprintf(outfile, "ip %s",
		 sockaddr_inet4_info(&sockname.ip4,
				     socknamebuff, sizeof(socknamebuff)));
	 break;
      }
      break;
     case 'S':
	fprintf(outfile, "%s %s-%s (%s) %s",
		protoname,
		 sockaddr_inet4_info(&sockname.ip4,
				     socknamebuff, sizeof(socknamebuff)),
		 sockaddr_inet4_info(&peername.ip4,
				     peernamebuff, sizeof(peernamebuff)),
		typename,
#ifdef SO_ACCEPTCONN
		 optacceptconn?"(listening)":
#endif
		"");
	break;
     }
     break;
#endif /* WITH_IP4 */

#if WITH_IP6
   case AF_INET6:
     switch (style) {
     case 's':
      switch (opttype) {
#if WITH_TCP
      case SOCK_STREAM:
	 fprintf(outfile, "%s6%s %s %s",
		 protoname,
#ifdef SO_ACCEPTCONN
		 optacceptconn?"(listening)":
#endif
		 "",
		 sockaddr_inet6_info(&sockname.ip6,
				     socknamebuff, sizeof(socknamebuff)),
		 sockaddr_inet6_info(&peername.ip6,
				     peernamebuff, sizeof(peernamebuff)));
	 break;
#endif
#if WITH_UDP
      case SOCK_DGRAM:
	 fprintf(outfile, "%s6%s %s %s",
		 protoname,
#ifdef SO_ACCEPTCONN
		 optacceptconn?"(listening)":
#endif
		 "",
		 sockaddr_inet6_info(&sockname.ip6,
				     socknamebuff, sizeof(socknamebuff)),
		 sockaddr_inet6_info(&peername.ip6,
				     peernamebuff, sizeof(peernamebuff)));
	 break;
#endif
      default:
	 fprintf(outfile, "ip6 %s",
		 sockaddr_inet6_info(&sockname.ip6,
				     socknamebuff, sizeof(socknamebuff)));
	 break;
      }
      break;
     case 'S':
	fprintf(outfile, "%s6 %s-%s (%s) %s",
		protoname,
		 sockaddr_inet6_info(&sockname.ip6,
				     socknamebuff, sizeof(socknamebuff)),
		 sockaddr_inet6_info(&peername.ip6,
				     peernamebuff, sizeof(peernamebuff)),
		typename,
#ifdef SO_ACCEPTCONN
		 optacceptconn?"(listening)":
#endif
		"");
	break;
     }
     break;
#endif /* WITH_IP6 */

   default:
      fprintf(outfile, "socket(family/domain=%d)", sockname.soa.sa_family);
   }

#if HAVE_GETPROTOENT
   if (ipproto >= 0) {
      endprotoent();
   }
#endif
   return result;
#undef FDNAME_OPTLEN
#undef FDNAME_NAMELEN
}
#endif /* _WITH_SOCKET */




