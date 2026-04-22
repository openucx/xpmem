ACLOCAL_AMFLAGS=-I m4

SUBDIRS = include \
          lib \
          test

if BUILD_KERNEL_MODULE
SUBDIRS += kernel
endif

pkgconfig_DATA = cray-xpmem.pc

udevrules_DATA = 56-xpmem.rules
udevrulesdir = /lib/udev/rules.d

EXTRA_DIST = \
	56-xpmem.rules \
	$(pkgconfig_DATA) \
	xpmem.spec \
	xpmem-kmod.spec \
	xpmem-dkms.spec \
	dkms.conf \
	debian

.version:
	echo "#%Module" > $@
	echo "set ModulesVersion \"@MODULE_VERSION@\"" >> $@

dist: dist-bzip2
