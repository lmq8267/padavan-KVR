/* source: xio-vsock.c */
/* Copyright Gerhard Rieger and contributors (see file CHANGES) */
/* Author: Stefano Garzarella <sgarzare@redhat.com */
/* Published under the GNU General Public License V.2, see file COPYING */

/* this file contains the source for opening addresses of VSOCK socket type */

#include "xiosysincludes.h"

#ifdef WITH_VSOCK
#include "xioopen.h"
#include "xio-listen.h"
#include "xio-socket.h"
#include "xio-vsock.h"

static int xioopen_vsock_connect(int argc, const char *argv[], struct opt *opts,
        int xioflags, xiofile_t *xxfd, unsigned groups, int abstract,
        int dummy2, int dummy3);
static int xioopen_vsock_listen(int argc, const char *argv[], struct opt *opts,
        int xioflags, xiofile_t *xxfd, unsigned groups, int abstract,
        int dummy2, int dummy3);

const struct addrdesc addr_vsock_connect = { "vsock-connect", 1 + XIO_RDWR,
    xioopen_vsock_connect,
    GROUP_FD|GROUP_SOCKET|GROUP_CHILD|GROUP_RETRY,
    0, 0, 0 HELP(":<cid>:<port>") };
#if WITH_LISTEN
const struct addrdesc addr_vsock_listen  = { "vsock-listen", 1 + XIO_RDWR,
    xioopen_vsock_listen,
    GROUP_FD|GROUP_SOCKET|GROUP_LISTEN|GROUP_CHILD|GROUP_RETRY,
    0, 0, 0 HELP(":<port>") };
#endif /* WITH_LISTEN */

static int vsock_addr_init(struct sockaddr_vm *sa, const char *cid_str,
        const char *port_str) {
   int ret;

   memset(sa, 0, sizeof(*sa));

   sa->svm_family = AF_VSOCK;
   ret = sockaddr_vm_parse(sa, cid_str, port_str);
   if (ret < 0)
      return STAT_NORETRY;

   return STAT_OK;
}

static int vsock_init(struct opt *opts, struct single *xfd) {

   xfd->howtoend = END_SHUTDOWN;

   if (applyopts_single(xfd, opts, PH_INIT) < 0)
      return STAT_NORETRY;

   applyopts(-1, opts, PH_INIT);
   applyopts(-1, opts, PH_EARLY);

   xfd->dtype = XIODATA_STREAM;

   return STAT_OK;
}

static int xioopen_vsock_connect(int argc, const char *argv[], struct opt *opts,
        int xioflags, xiofile_t *xxfd, unsigned groups,
        int abstract, int dummy2, int dummy3) {
   /* we expect the form :cid:port */
   struct single *xfd = &xxfd->stream;
   struct sockaddr_vm sa, sa_local;
   socklen_t sa_len = sizeof(sa);
   bool needbind = false;
   int socktype = SOCK_STREAM;
   int pf = PF_VSOCK;
   int protocol = 0;
   int ret;

   if (argc != 3) {
      Error2("%s: wrong number of parameters (%d instead of 2)",
	     argv[0], argc-1);
      return STAT_NORETRY;
   }

   ret = vsock_addr_init(&sa, argv[1], argv[2]);
   if (ret) {
      return ret;
   }

   ret = vsock_init(opts, xfd);
   if (ret) {
      return ret;
   }

   ret = retropt_bind(opts, pf, socktype, protocol,
                      (struct sockaddr *)&sa_local, &sa_len, 3, 0, 0);
   if (ret == STAT_NORETRY)
      return ret;
   if (ret == STAT_OK)
      needbind = true;

   ret = xioopen_connect(xfd, needbind ? (union sockaddr_union *)&sa_local : NULL,
                         sa_len, (struct sockaddr *)&sa, sizeof(sa),
                         opts, pf, socktype, protocol, false);
   if (ret)
      return ret;

   ret = _xio_openlate(xfd, opts);
   if (ret < 0)
       return ret;

   return STAT_OK;
}

#if WITH_LISTEN
static int xioopen_vsock_listen(int argc, const char *argv[], struct opt *opts,
        int xioflags, xiofile_t *xxfd, unsigned groups, int abstract,
        int dummy2, int dummy3) {
   /* we expect the form :port */
   struct single *xfd = &xxfd->stream;
   struct sockaddr_vm sa, sa_bind;
   socklen_t sa_len = sizeof(sa_bind);
   struct opt *opts0;
   int socktype = SOCK_STREAM;
   int pf = PF_VSOCK;
   int protocol = 0;
   int ret;

   if (argc != 2) {
      Error2("%s: wrong number of parameters (%d instead of 1)",
	     argv[0], argc-1);
      return STAT_NORETRY;
   }

   ret = vsock_addr_init(&sa, NULL, argv[1]);
   if (ret) {
      return ret;
   }

   ret = vsock_init(opts, xfd);
   if (ret) {
      return ret;
   }

   opts0 = copyopts(opts, GROUP_ALL);

   ret = retropt_bind(opts, pf, socktype, protocol, (struct sockaddr *)&sa_bind,
                      &sa_len, 1, 0, 0);
   if (ret == STAT_NORETRY)
       return ret;
   if (ret == STAT_OK)
       sa.svm_cid = sa_bind.svm_cid;

   /* this may fork() */
   return xioopen_listen(xfd, xioflags, (struct sockaddr *)&sa, sizeof(sa),
                         opts, opts0, pf, socktype, protocol);
}

#endif /* WITH_LISTEN */
#endif /* WITH_VSOCK */
