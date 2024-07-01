##
## additional m4 macros
##
## (C) 1999 Christoph Bartelmus (lirc@bartelmus.de)
## (C) 2016-2018 Nathan Hjelm
##


dnl check for kernel source

AC_DEFUN([AC_PATH_KERNEL_SOURCE_SEARCH],
[
  kerneldir=missing
  kernelext=ko
  no_kernel=yes

  if test `uname` != "Linux"; then
    kerneldir="not running Linux"
  else
    vers="$(uname -r)"
    for dir in ${ac_kerneldir} \
        /lib/modules/${vers}/build \
        /usr/src/kernel-source-* \
        /usr/src/linux-source-${vers} \
        /usr/src/linux /lib/modules/${vers}/source
    do
      if test -e $dir/Module.symvers ; then
        kerneldir=`dirname $dir/Makefile`/ || continue
        no_kernel=no
        break
      fi;
    done
  fi

  if test x${no_kernel} = xyes; then
      AC_MSG_ERROR([could not find kernel sources])
  fi
  ac_cv_have_kernel="no_kernel=${no_kernel} \
                kerneldir=\"${kerneldir}\" \
                kernelext=\"ko\""
]
)

AC_DEFUN([AC_PATH_KERNEL_SOURCE],
[
  AC_CHECK_PROG(ac_pkss_mktemp,mktemp,yes,no)
  AC_PROVIDE([AC_PATH_KERNEL_SOURCE])

  AC_ARG_ENABLE([kernel-module],[Enable building the kernel module (default: enabled)],[build_kernel_module=$enableval],
		[build_kernel_module=1])
  AS_IF([test $build_kernel_module = 1],[

  AC_MSG_CHECKING([for Linux kernel sources])
  kernelvers=$(uname -r)

  AC_ARG_WITH(kerneldir,
    [  --with-kerneldir=DIR    kernel sources in DIR],

    ac_kerneldir=${withval}

    if test -n "$ac_kerneldir" ; then
	if test ! ${ac_kerneldir#/lib/modules} = ${ac_kerneldir} ; then
	    kernelvers=$(basename $(dirname ${ac_kerneldir}))
	elif test ! ${ac_kerneldir#*linux-headers-} = ${ac_kerneldir} ; then
	    # special case to deal with the way the travis script does headers
	    kernelvers=${ac_kerneldir#*linux-headers-}
	else
	    kernelvers=$(make -s kernelrelease -C ${ac_kerneldir} M=dummy 2>/dev/null)
	fi
    fi

    AC_PATH_KERNEL_SOURCE_SEARCH,

    ac_kerneldir=""
    AC_CACHE_VAL(ac_cv_have_kernel,AC_PATH_KERNEL_SOURCE_SEARCH)
  )

  AC_ARG_WITH(kernelvers, [--with-kernelvers=VERSION   kernel release name], kernelvers=${with_kernelvers})

  eval "$ac_cv_have_kernel"

  AC_SUBST(kerneldir)
  AC_SUBST(kernelext)
  AC_SUBST(kernelvers)
  AC_MSG_RESULT(${kerneldir})

  AC_MSG_CHECKING([kernel release])
  AC_MSG_RESULT([${kernelvers}])
  ])
  AM_CONDITIONAL([BUILD_KERNEL_MODULE], [test $build_kernel_module = 1])
]
)

AC_DEFUN([AC_KERNEL_CHECKS],
[
  srcarch=$(uname -m | sed -e s/i.86/x86/ \
                           -e s/x86_64/x86/ \
                           -e s/ppc.*/powerpc/ \
                           -e s/powerpc64/powerpc/ \
                           -e s/aarch64.*/arm64/ \
                           -e s/sparc32.*/sparc/ \
                           -e s/sparc64.*/sparc/ \
                           -e s/s390x/s390/)
  save_CFLAGS="$CFLAGS"
  save_CPPFLAGS="$CPPFLAGS"
  CFLAGS=
  CPPFLAGS="-include $kerneldir/include/linux/kconfig.h \
            -include $kerneldir/include/linux/compiler.h \
            -D__KERNEL__ \
            -DKBUILD_MODNAME=\"xpmem_configure\" \
            -I$kerneldir/include \
            -I$kerneldir/include/uapi \
            -I$kerneldir/arch/$srcarch/include \
            -I$kerneldir/arch/$srcarch/include/uapi \
            -I$kerneldir/arch/$srcarch/include/generated \
            -I$kerneldir/arch/$srcarch/include/generated/uapi \
            $CPPFLAGS"

  AC_CHECK_MEMBERS([struct task_struct.cpus_mask], [], [],
                   [[#include <linux/sched.h>]])

  AC_CHECK_DECL(pde_data, [], [
    AC_DEFINE([HAVE_NO_PDE_DATA_FUNC], 1, [Have pde_data()])
    AC_CHECK_DECL(PDE_DATA, [
      AC_DEFINE([HAVE_PDE_DATA_MACRO], 1, [Have PDE_DATA()])
    ], [], [[#include <linux/proc_fs.h>]])
  ], [[#include <linux/proc_fs.h>]])

  AC_CHECK_DECL(pmd_leaf, [
    AC_DEFINE([HAVE_PMD_LEAF_MACRO], 1, [Have pmd_leaf()])],
    [], [[#include <linux/mm.h>]])
  AC_CHECK_DECL(pud_leaf, [
    AC_DEFINE([HAVE_PUD_LEAF_MACRO], 1, [Have pud_leaf()])],
    [], [[#include <linux/mm.h>]])
  AC_CHECK_DECL(pte_offset_map, [
    AC_DEFINE([HAVE_PTE_OFFSET_MAP_MACRO], 1, [Have pte_offset_map()])],
    [], [[#include <linux/mm.h>]])

  AC_CHECK_DECLS([vma_iter_init], [], [], [[#include <linux/mm_types.h>]])

  AC_MSG_CHECKING(latest apply_to_page_range support)
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[
      #include <linux/mm.h>
      extern pte_fn_t callback;
    ]], [[
      int a = callback(NULL, 1, NULL);
    ]])], [
    AC_DEFINE([HAVE_LATEST_APPLY_TO_PAGE_RANGE], 1, [Have latest page iterator])
  ], [])

  AC_CHECK_DECLS([vm_flags_set], [], [], [[#include <linux/mm.h>]])

  AC_SUBST(KFLAGS, [$KFLAGS])
  CPPFLAGS="$save_CPPFLAGS"
  CFLAGS="$save_CFLAGS"
]
)
