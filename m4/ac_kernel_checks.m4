##
## additional m4 macros
##
## (C) 1999 Christoph Bartelmus (lirc@bartelmus.de)
## (C) 2016-2018 Nathan Hjelm
##


dnl check for kernel source

AC_DEFUN([AC_PATH_KERNEL_SOURCE_SEARCH],
[
  kerneldir=
  kernelinc=
  kernelext="ko"

  for dir in "${ac_kerneldir}" "${ac_kernelinc}" \
      /lib/modules/${kernelvers}/build \
      /lib/modules/${kernelvers}/source \
      /usr/src/linux-source-${kernelvers} \
      /usr/src/kernels/${kernelvers} \
      /usr/src/kernel-source-* \
      /usr/src/linux
  do
    if test -z "$dir"; then
      continue
    fi
    if test -z "$kerneldir" && test -e "$dir"/Module.symvers ; then
      kerneldir="$dir"/
    fi
    if test -z "$kernelinc" && test -e "$dir"/include/linux/mm.h; then
      kernelinc="$dir"/
    fi
  done

  if test -z "$kerneldir"; then
      AC_MSG_ERROR([could not find kernel sources])
  fi
  if test -z "$kernelinc"; then
      AC_MSG_ERROR([could not find kernel includes to use for configuration])
  fi
]
)

AC_DEFUN([AC_KERNEL_CHECKS],
[
  AC_CHECK_PROG(ac_pkss_mktemp,mktemp,yes,no)
  AC_PROVIDE([AC_KERNEL_CHECKS])

  AC_ARG_ENABLE([kernel-module],
    [AS_HELP_STRING([--disable-kernel-module],
                    [Disable building the kernel module (default is enabled)],)],
    [build_kernel_module=$enableval],
    [build_kernel_module=1])
  AS_IF([test $build_kernel_module = 1],[

  AC_MSG_CHECKING([for Linux kernel sources])
  AC_ARG_WITH(kernelvers, [  --with-kernelvers=VERS  kernel release name], kernelvers=${with_kernelvers})
  AC_ARG_WITH(kernelinc,  [  --with-kernelinc=INC    kernel directory containing ./include/linux],
              ac_kernelinc=${withval})

  AC_ARG_WITH(kerneldir,
    [  --with-kerneldir=DIR    kernel sources in DIR],

    ac_kerneldir=${withval}

    if test -n "$ac_kerneldir" && test x"$kernelvers" = x;  then
        if test ! ${ac_kerneldir#/lib/modules} = ${ac_kerneldir} ; then
            kernelvers=$(basename $(dirname ${ac_kerneldir}))
        else
            kernelvers=$(make -s kernelversion -C ${ac_kerneldir} 2>/dev/null)
        fi
    fi
    ,
    ac_kerneldir=""
  )

  kernelvers="${kernelvers:-$(uname -r)}"
  AC_PATH_KERNEL_SOURCE_SEARCH

  AC_SUBST(kerneldir)
  AC_SUBST(kernelext)
  AC_SUBST(kernelvers)
  AC_MSG_RESULT(${kerneldir})

  AC_MSG_CHECKING([for kernel checks include path])
  AC_MSG_RESULT([${kernelinc}])

  AC_MSG_CHECKING([kernel release])
  AC_MSG_RESULT([${kernelvers}])

  AC_KERNEL_CHECK_SUPPORT
  ])
  AM_CONDITIONAL([BUILD_KERNEL_MODULE], [test $build_kernel_module = 1])
]
)

AC_DEFUN([AC_GUP_CHECK], [
  AC_COMPILE_IFELSE([AC_LANG_PROGRAM([[#include <linux/mm.h>]], [[
	$1
  ]])], [
    AS_IF([test x"$gup_version" != xno], [AC_MSG_ERROR([get_user_pages_remote has multiple matches])])
    gup_version=$2
    AC_DEFINE([$3], 1, [Have get_user_pages_remote() kernel >= $gup_version])
  ])
])

AC_DEFUN([AC_KERNEL_CHECK_GUP],
[
  AC_MSG_CHECKING(get_user_pages_remote version)
  gup_version=no
  AC_GUP_CHECK([
	long get_user_pages_remote(struct mm_struct *mm,
				   unsigned long start, unsigned long nr_pages,
				   unsigned int gup_flags, struct page **pages,
				   int *locked);],
	[6.5], [HAVE_GUP_6_5])
  AC_GUP_CHECK([
	long get_user_pages_remote(struct mm_struct *mm,
				    unsigned long start, unsigned long nr_pages,
				    unsigned int gup_flags, struct page **pages,
				    struct vm_area_struct **vmas, int *locked);],
	[5.9], [HAVE_GUP_5_9])
  AC_GUP_CHECK([
	long get_user_pages_remote(struct task_struct *tsk, struct mm_struct *mm,
				    unsigned long start, unsigned long nr_pages,
				    unsigned int gup_flags, struct page **pages,
				    struct vm_area_struct **vmas, int *locked);],
	[4.10], [HAVE_GUP_4_10])
  AC_GUP_CHECK([
	long get_user_pages_remote(struct task_struct *tsk, struct mm_struct *mm,
				    unsigned long start, unsigned long nr_pages,
				    unsigned int gup_flags, struct page **pages,
				    struct vm_area_struct **vmas);],
	[4.9], [HAVE_GUP_4_9])
  AC_GUP_CHECK([
	long get_user_pages_remote(struct task_struct *tsk, struct mm_struct *mm,
				    unsigned long start, unsigned long nr_pages,
				    int write, int force, struct page **pages,
				    struct vm_area_struct **vmas);],
	[4.8], [HAVE_GUP_4_8])

  AS_IF([test "$gup_version" = no && test "${kernelvers%%.*}" -ge 5],
        [AC_MSG_ERROR([could not find get_user_pages_remote function for kernel >=5.x.x])])

  AC_MSG_RESULT(${gup_version//_/.})
]
)

AC_DEFUN([AC_KERNEL_CHECK_SUPPORT],
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
  CFLAGS="${KERNEL_CHECKS_CFLAGS:--g -O2}"
  CPPFLAGS="-include $kernelinc/include/linux/kconfig.h \
            -include $kernelinc/include/linux/compiler.h \
            -D__KERNEL__ \
            -DKBUILD_MODNAME=\"xpmem_configure\" \
            -I$kernelinc/include \
            -I$kernelinc/include/uapi \
            -I$kernelinc/arch/$srcarch/include \
            -I$kernelinc/arch/$srcarch/include/uapi \
            -I$kernelinc/arch/$srcarch/include/generated \
            -I$kernelinc/arch/$srcarch/include/generated/uapi \
            $CPPFLAGS"

  AC_CHECK_DECL([kmalloc], [], [
    AC_MSG_ERROR([cannot run kernel module configuration checks])], [[
    #include <linux/slab.h>
    #include <linux/mm.h>
    #include <linux/sched.h>
    #include <linux/mm_types.h>
    #include <linux/proc_fs.h>]])

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
    AC_MSG_RESULT(yes)
  ], [AC_MSG_RESULT(no)])

  AC_CHECK_DECLS([vm_flags_set], [], [], [[#include <linux/mm.h>]])
  AC_KERNEL_CHECK_GUP

  AC_SUBST(KFLAGS, [$KFLAGS])
  CPPFLAGS="$save_CPPFLAGS"
  CFLAGS="$save_CFLAGS"
]
)
