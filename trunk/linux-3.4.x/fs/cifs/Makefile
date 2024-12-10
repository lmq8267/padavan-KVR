#
# Makefile for Linux CIFS VFS client 
#
obj-y += cifs.o

cifs-y := cifsfs.o cifssmb.o cifs_debug.o connect.o dir.o file.o inode.o \
	  link.o misc.o netmisc.o smbencrypt.o transport.o asn1.o \
	  cifs_unicode.o nterr.o xattr.o cifsencrypt.o \
	  readdir.o ioctl.o sess.o export.o smb1ops.o winucase.o

cifs-y += cifsacl.o

cifs-y += cifs_spnego.o

cifs-y += dns_resolve.o cifs_dfs_ref.o

cifs-y += fscache.o cache.o

cifs-y += smb2ops.o smb2maperror.o smb2transport.o \
			    smb2misc.o smb2pdu.o smb2inode.o smb2file.o
