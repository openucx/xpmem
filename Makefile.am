ACLOCAL_AMFLAGS=-I m4

SUBDIRS = include \
          lib \
          test

if BUILD_KERNEL_MODULE
SUBDIRS += kernel
endif

pkgconfig_DATA = cray-xpmem.pc

sysconf_DATA = .version \
	       56-xpmem.rules

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
