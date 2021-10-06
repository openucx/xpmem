#define buildforkernels newest
#define buildforkernels current
#define buildforkernels akmod

%{!?kernel_release: %define kernel_release %(uname -r | sed -e 's/\.[^.]*$//g')}
%{!?version: %define version 2.6.5}
%global debug_package %{nil}

Summary: XPMEM: Cross-partition memory
Name: xpmem-kmod-%{kernel_release}
Version: %{version}
Release: 0
License: GPLv2
Group: System Environment/Kernel
Packager: Nathan Hjelm
Source: xpmem-0.2.tar.bz2
BuildRoot: %{_tmppath}/%{name}-%{version}-build
Requires: kernel >= %{kernel_release}
Requires(post): %{_sbindir}/weak-modules
Requires(postun): %{_sbindir}/weak-modules
Provides: xpmem-kmod

BuildRequires: kernel-devel = %{kernel_release}

%description
XPMEM is a Linux kernel module that enables a process to map the
memory of another process into its virtual address space. Source code
can be obtained by cloning the Git repository, original Mercurial
repository or by downloading a tarball from the link above.

%prep
%setup -n xpmem-0.2
echo "override xpmem * weak-updates/xpmem" > kmod-xpmem.conf

%build
./configure --prefix=/opt/xpmem --with-kerneldir=/usr/src/kernels/%{kernel_release}.%{_arch}
%{__make} -C kernel

%install
%{__install} -D -m 0644 56-xpmem.rules %{buildroot}%{_sysconfdir}/udev/rules.d/56-xpmem.rules
%{__install} -D -m 0644 kmod-xpmem.conf %{buildroot}%{_sysconfdir}/depmod.d/kmod-xpmem.conf
%{__install} -D -m 0644 kernel/xpmem.ko %{buildroot}/lib/modules/%{kernel_release}.%{_arch}/extra/xpmem.ko

%post
echo /lib/modules/%{kernel_release}.%{_arch}/extra/xpmem.ko | %{_sbindir}/weak-modules --add-modules --no-initramfs
depmod -a

%postun
echo /lib/modules/%{kernel_release}.%{_arch}/extra/xpmem.ko | %{_sbindir}/weak-modules --remove-modules

%files
%defattr(-, root, root)
/lib/modules

%config(noreplace)
/etc/depmod.d/kmod-xpmem.conf
/etc/udev/rules.d/56-xpmem.rules
