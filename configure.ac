#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.

AC_PREREQ([2.63])
AC_INIT([xpmem], [2.7], [http://github.com/openucx/xpmem/issues])
AM_INIT_AUTOMAKE([-Wall -Werror foreign subdir-objects])
AC_CONFIG_SRCDIR([include/xpmem.h])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_HEADERS([config.h])
AM_SILENT_RULES

# Checks for programs.
AC_PROG_CC
AC_PROG_CXX
AC_PROG_INSTALL
AM_PROG_AR
LT_INIT
AC_PROG_LN_S

# Checks for typedefs, structures, and compiler characteristics.
AC_C_CONST
AC_TYPE_UID_T
AC_C_INLINE
AC_TYPE_OFF_T
AC_TYPE_PID_T
AC_TYPE_SIZE_T
AC_C_VOLATILE

# Check C++ 14 support
save_CXXFLAGS="$CXXFLAGS"
CXXFLAGS="-Werror -std=c++14"
AC_LANG_PUSH([C++])
AC_MSG_CHECKING([C++14 support])
AC_COMPILE_IFELSE([AC_LANG_PROGRAM([int x = 0b101010;])],
                  [have_cxx14=yes], [have_cxx14=no])
AC_MSG_RESULT([$have_cxx14])
AC_LANG_POP
CXXFLAGS="$save_CXXFLAGS"

# Checks for library functions.
AC_PROG_GCC_TRADITIONAL
AC_FUNC_MMAP
AC_CHECK_FUNCS([getpagesize memset])

AC_ARG_WITH([module-prefix],
            [AS_HELP_STRING([--with-module-prefix],
                            [Prefix for kernel module installation])],
            [],
            [with_module_prefix=$prefix])

# Check for gtest being requested
AC_ARG_ENABLE([gtest],
  [AS_HELP_STRING([--enable-gtest],
                  [Enable tests using the Google C++ Testing Framework.
                  (Default is disabled.)])],
  [enable_gtest=$enableval],
  [enable_gtest=no])

AC_MSG_CHECKING([for using Google C++ Testing Framework])
AC_MSG_RESULT([$enable_gtest])
# Check gtest can only build with C++14 support
AS_IF([test "x$enable_gtest" = "xyes" && test "x$have_cxx14" != "xyes"],
      [AC_MSG_ERROR([gtest enabled without C++14 compiler support])])
AM_CONDITIONAL([HAVE_GTEST], [test "x$enable_gtest" = "xyes"])

AC_SUBST([moduleprefix], [${with_module_prefix%%/}])
AC_SUBST([initdir], [${sysconfdir}/init.d])
AC_SUBST([ldsoconfdir], [/etc/ld.so.conf.d])
AC_SUBST([pkgconfigdir], [${libdir}/pkgconfig])

AC_KERNEL_CHECKS

AC_CONFIG_FILES([Makefile
                 cray-xpmem.pc
                 module
                 include/Makefile
                 kernel/Kbuild
                 kernel/Makefile
                 kernel/xpmem
                 lib/Makefile
                 test/Makefile
                 test/share/Makefile
                 test/gtest/Makefile
                 test/gtest/common/googletest/Makefile])

AC_CONFIG_LINKS([kernel/xpmem_attach.c:kernel/xpmem_attach.c
                 kernel/xpmem_get.c:kernel/xpmem_get.c
                 kernel/xpmem_main.c:kernel/xpmem_main.c
                 kernel/xpmem_make.c:kernel/xpmem_make.c
                 kernel/xpmem_misc.c:kernel/xpmem_misc.c
                 kernel/xpmem_mmu_notifier.c:kernel/xpmem_mmu_notifier.c
                 kernel/xpmem_pfn.c:kernel/xpmem_pfn.c
                 kernel/xpmem_private.h:kernel/xpmem_private.h
                 test/share/run.sh:test/share/run.sh])
AC_OUTPUT
