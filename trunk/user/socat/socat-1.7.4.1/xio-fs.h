/* source: xio-fs.h */
/* Copyright Gerhard Rieger and contributors (see file CHANGES) */
/* Published under the GNU General Public License V.2, see file COPYING */

#ifndef __xio_fs_h_included
#define __xio_fs_h_included 1

#if defined(EXT2_SECRM_FL) && !defined(FS_SECRM_FL)
#  define FS_SECRM_FL EXT2_SECRM_FL
#endif
#if defined(EXT2_UNRM_FL) && !defined(FS_UNRM_FL)
#  define FS_UNRM_FL EXT2_UNRM_FL
#endif
#if defined(EXT2_COMPR_FL) && !defined(FS_COMPR_FL)
#  define FS_COMPR_FL EXT2_COMPR_FL
#endif
#if defined(EXT2_SYNC_FL) && !defined(FS_SYNC_FL)
#  define FS_SYNC_FL EXT2_SYNC_FL
#endif
#if defined(EXT2_IMMUTABLE_FL) && !defined(FS_IMMUTABLE_FL)
#  define FS_IMMUTABLE_FL EXT2_IMMUTABLE_FL
#endif
#if defined(EXT2_APPEND_FL) && !defined(FS_APPEND_FL)
#  define FS_APPEND_FL EXT2_APPEND_FL
#endif
#if defined(EXT2_NODUMP_FL) && !defined(FS_NODUMP_FL)
#  define FS_NODUMP_FL EXT2_NODUMP_FL
#endif
#if defined(EXT2_NOATIME_FL) && !defined(FS_NOATIME_FL)
#  define FS_NOATIME_FL EXT2_NOATIME_FL
#endif
#if defined(EXT2_JOURNAL_DATA_FL) && !defined(FS_JOURNAL_DATA_FL)
#  define FS_JOURNAL_DATA_FL EXT2_JOURNAL_DATA_FL
#endif
#if defined(EXT2_NOTAIL_FL) && !defined(FS_NOTAIL_FL)
#  define FS_NOTAIL_FL EXT2_NOTAIL_FL
#endif
#if defined(EXT2_DIRSYNC_FL) && !defined(FS_DIRSYNC_FL)
#  define FS_DIRSYNC_FL EXT2_DIRSYNC_FL
#endif
#if defined(EXT2_TOPDIR_FL) && !defined(FS_TOPDIR_FL)
#  define FS_TOPDIR_FL EXT2_TOPDIR_FL
#endif

extern const struct optdesc opt_fs_secrm;
extern const struct optdesc opt_fs_unrm;
extern const struct optdesc opt_fs_compr;
extern const struct optdesc opt_fs_sync;
extern const struct optdesc opt_fs_immutable;
extern const struct optdesc opt_fs_append;
extern const struct optdesc opt_fs_nodump;
extern const struct optdesc opt_fs_noatime;
extern const struct optdesc opt_fs_journal_data;
extern const struct optdesc opt_fs_notail;
extern const struct optdesc opt_fs_dirsync;
extern const struct optdesc opt_fs_topdir;

#endif /* !defined(__xio_fs_h_included) */
