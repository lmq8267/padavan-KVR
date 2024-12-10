#
# Makefile for the kernel security code
#

obj-y			+= keys/
subdir-y	+= selinux
subdir-y		+= smack
subdir-y        += tomoyo
subdir-y	+= apparmor
subdir-y		+= yama

# always enable default capabilities
obj-y					+= commoncap.o
obj-$(CONFIG_MMU)			+= min_addr.o

# Object file lists
obj-$(CONFIG_SECURITY)			+= security.o capability.o
obj-$(CONFIG_SECURITYFS)		+= inode.o
# Must precede capability.o in order to stack properly.
obj-$(CONFIG_SECURITY_SELINUX)		+= selinux/built-in.o
obj-$(CONFIG_SECURITY_SMACK)		+= smack/built-in.o
obj-$(CONFIG_AUDIT)			+= lsm_audit.o
obj-$(CONFIG_SECURITY_TOMOYO)		+= tomoyo/built-in.o
obj-$(CONFIG_SECURITY_APPARMOR)		+= apparmor/built-in.o
obj-$(CONFIG_SECURITY_YAMA)		+= yama/built-in.o
obj-$(CONFIG_CGROUP_DEVICE)		+= device_cgroup.o

# Object integrity file lists
subdir-y		+= integrity
obj-y			+= integrity/built-in.o
