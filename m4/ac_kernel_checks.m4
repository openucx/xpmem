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

AC_DEFUN([AC_KERNEL_CHECK_SUPPORT],
[
  __xpmem_silent_opt=''
  # Will print its own messages:
  if test "$silent" = "yes"; then
    __xpmem_silent_opt="-q"
  fi
  # FIXME: what about out-of-tree build?
  env KSRC=$kerneldir XPMEM_VERSION="$PACKAGE_VERSION" kernel/config_kernel $__xpmem_silent_opt
  if test $? -ne 0; then
    AC_MSG_ERROR([Failed to configure kernel. Missing kernel headers (-devel) or broken build system])
  fi
  unset __xpmem_silent_opt
])
