/* source: xio-fs.c */
/* Copyright Gerhard Rieger and contributors (see file CHANGES) */
/* Published under the GNU General Public License V.2, see file COPYING */

/* this file contains the source for handling Linux fs options
   they can also be set with chattr(1) and viewed with lsattr(1) */

#include "xiosysincludes.h"
#include "xioopen.h"

#include "xio-fs.h"


#if WITH_FS

/****** FD options ******/

#if defined(EXT2_IOC_GETFLAGS) && !defined(FS_IOC_GETFLAGS)
#  define FS_IOC_GETFLAGS EXT2_IOC_GETFLAGS
#endif
#if defined(EXT2_IOC_SETFLAGS) && !defined(FS_IOC_SETFLAGS)
#  define FS_IOC_SETFLAGS EXT2_IOC_SETFLAGS
#endif

#if defined(EXT2_SECRM_FL) && !defined(FS_SECRM_FL)
#  define FS_SECRM_FL EXT2_SECRM_FL
#endif
#ifdef FS_SECRM_FL
/* secure deletion, chattr 's' */
const struct optdesc opt_fs_secrm        = { "fs-secrm",        "secrm",        OPT_FS_SECRM,        GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_SECRM_FL };
#endif

#if defined(EXT2_UNRM_FL) && !defined(FS_UNRM_FL)
#  define FS_UNRM_FL EXT2_UNRM_FL
#endif
#ifdef FS_UNRM_FL
/* undelete, chattr 'u' */
const struct optdesc opt_fs_unrm         = { "fs-unrm",         "unrm",         OPT_FS_UNRM,         GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_UNRM_FL };
#endif /* FS_UNRM_FL */

#if defined(EXT2_COMPR_FL) && !defined(FS_COMPR_FL)
#  define FS_COMPR_FL EXT2_COMPR_FL
#endif
#ifdef FS_COMPR_FL
/* compress file, chattr 'c' */
const struct optdesc opt_fs_compr        = { "fs-compr",        "compr",        OPT_FS_COMPR,        GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_COMPR_FL };
#endif /* FS_COMPR_FL */

#if defined(EXT2_SYNC_FL) && !defined(FS_SYNC_FL)
#  define FS_SYNC_FL EXT2_SYNC_FL
#endif
#ifdef FS_SYNC_FL
/* synchronous update, chattr 'S' */
const struct optdesc opt_fs_sync         = { "fs-sync",         "sync",         OPT_FS_SYNC,         GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_SYNC_FL };
#endif /* FS_SYNC_FL */

#if defined(EXT2_IMMUTABLE_FL) && !defined(FS_IMMUTABLE_FL)
#  define FS_IMMUTABLE_FL EXT2_IMMUTABLE_FL
#endif
#ifdef FS_IMMUTABLE_FL
/* immutable file, chattr 'i' */
const struct optdesc opt_fs_immutable    = { "fs-immutable",    "immutable",    OPT_FS_IMMUTABLE,    GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_IMMUTABLE_FL };
#endif /* FS_IMMUTABLE_FL */

#if defined(EXT2_APPEND_FL) && !defined(FS_APPEND_FL)
#  define FS_APPEND_FL EXT2_APPEND_FL
#endif
#ifdef FS_APPEND_FL
/* writes to file may only append, chattr 'a' */
const struct optdesc opt_fs_append       = { "fs-append",       "append",       OPT_FS_APPEND,       GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_APPEND_FL };
#endif /* FS_APPEND_FL */

#if defined(EXT2_NODUMP_FL) && !defined(FS_NODUMP_FL)
#  define FS_NODUMP_FL EXT2_NODUMP_FL
#endif
#ifdef FS_NODUMP_FL
/* do not dump file, chattr 'd' */
const struct optdesc opt_fs_nodump       = { "fs-nodump",       "nodump",       OPT_FS_NODUMP,       GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_NODUMP_FL };
#endif /* FS_NODUMP_FL */

#if defined(EXT2_NOATIME_FL) && !defined(FS_NOATIME_FL)
#  define FS_NOATIME_FL EXT2_NOATIME_FL
#endif
#ifdef FS_NOATIME_FL
/* do not update atime, chattr 'A' */
const struct optdesc opt_fs_noatime      = { "fs-noatime",      "noatime",      OPT_FS_NOATIME,      GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_NOATIME_FL };
#endif /* FS_NOATIME_FL */

/* FS_DIRTY_FL ??? */
/* FS_COMPRBLK_FL one ore more compress clusters */
/* FS_NOCOMPR_FL access raw compressed data */
/* FS_ECOMPR_FL compression error */
/* FS_BTREE_FL btree format dir */
/* FS_INDEX_FL hash indexed directory */
/* FS_IMAGIC ??? */

#if defined(EXT2_JOURNAL_DATA_FL) && !defined(FS_JOURNAL_DATA_FL)
#  define FS_JOURNAL_DATA_FL EXT2_JOURNAL_DATA_FL
#endif
#ifdef FS_JOURNAL_DATA_FL
/* file data should be journaled, chattr 'j' */
const struct optdesc opt_fs_journal_data = { "fs-journal-data", "journal-data", OPT_FS_JOURNAL_DATA, GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_JOURNAL_DATA_FL };
#endif /* FS_JOURNAL_DATA_FL */

#if defined(EXT2_NOTAIL_FL) && !defined(FS_NOTAIL_FL)
#  define FS_NOTAIL_FL EXT2_NOTAIL_FL
#endif
#ifdef FS_NOTAIL_FL
/* file tail should not be merged, chattr 't' */
const struct optdesc opt_fs_notail       = { "fs-notail",       "notail",       OPT_FS_NOTAIL,       GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_NOTAIL_FL };
#endif /* FS_NOTAIL_FL */

#if defined(EXT2_DIRSYNC_FL) && !defined(FS_DIRSYNC_FL)
#  define FS_DIRSYNC_FL EXT2_DIRSYNC_FL
#endif
#ifdef FS_DIRSYNC_FL
/* synchronous directory modifications, chattr 'D' */
const struct optdesc opt_fs_dirsync      = { "fs-dirsync",      "dirsync",      OPT_FS_DIRSYNC,      GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_DIRSYNC_FL };
#endif /* FS_DIRSYNC_FL */

#if defined(EXT2_TOPDIR_FL) && !defined(FS_TOPDIR_FL)
#  define FS_TOPDIR_FL EXT2_TOPDIR_FL
#endif
#ifdef FS_TOPDIR_FL
/* top of directory hierarchies, chattr 'T' */
const struct optdesc opt_fs_topdir       = { "fs-topdir",       "topdir",       OPT_FS_TOPDIR,       GROUP_REG, PH_FD, TYPE_BOOL, OFUNC_IOCTL_MASK_LONG, FS_IOC_GETFLAGS, FS_IOC_SETFLAGS, FS_TOPDIR_FL };
#endif /* FS_TOPDIR_FL */

/* EXTENTS inode uses extents */


#endif /* WITH_FS */


