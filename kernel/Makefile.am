AM_CPPFLAGS = -I@top_srcdir@/include

moduledir = @moduleprefix@/lib/modules/@kernelvers@/kernel/xpmem
KERNEL_PATH=@kerneldir@
init_SCRIPTS = xpmem
MODULE=xpmem.ko

module_sources = \
    xpmem_attach.c \
    xpmem_get.c \
    xpmem_main.c \
    xpmem_make.c \
    xpmem_misc.c \
    xpmem_mmu_notifier.c \
    xpmem_pfn.c \
    xpmem_private.h

EXTRA_DIST = ${module_sources}

module_DATA = $(MODULE)

$(MODULE): ${module_sources}
	$(MAKE) -C $(KERNEL_PATH) M=$(abs_builddir)

modules_install: $(MODULE)
	$(MAKE) -C $(KERNEL_PATH) M=$(abs_builddir) modules_install

clean-local:
	$(MAKE) -C $(KERNEL_PATH) M=$(abs_builddir) clean
	rm -rf test_mods xpmem_kernel.h

.PHONY: $(MODULE)
