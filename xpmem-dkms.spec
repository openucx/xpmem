%{?!_dkmsdir: %define _dkmsdir /var/lib/dkms}

%define module xpmem
%define version 2.7.3

Summary: XPMEM: Cross-partition memory dkms package
Name: %{module}
Version: %{version}
Release: dkms
BuildArch: noarch
License: GPLv2
Group: System Environment/Kernel
Requires: dkms >= 1.95 gcc bash sed flex bison

%description
XPMEM is a Linux kernel module that enables a process to map the
memory of another process into its virtual address space. Source code
can be obtained by cloning the Git repository, original Mercurial
repository or by downloading a tarball from the link above.

%prep
sudo /usr/sbin/dkms mktarball -m %module -v %version --archive `basename %{module}-%{version}.dkms.tar.gz`
cp -af %{_dkmsdir}/%{module}/%{version}/tarball/`basename %{module}-%{version}.dkms.tar.gz` %{module}-%{version}.dkms.tar.gz

%install
[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_datarootdir}/%{module}
install -m 644 %{module}-%{version}.dkms.tar.gz $RPM_BUILD_ROOT/%{_datarootdir}/%{module}

%clean
#[ "$RPM_BUILD_ROOT" != "/" ] && rm -rf $RPM_BUILD_ROOT

%post
/usr/sbin/dkms ldtarball %{_datarootdir}/%{module}/%{module}-%{version}.dkms.tar.gz
/usr/sbin/dkms build -m %{module} -v %{version} --force
/usr/sbin/dkms install -m %{module} -v %{version}
exit 0

%preun
echo -e "Uninstalling %{module} module (version %{version}):"
/usr/sbin/dkms remove -m %{module} -v %{version} --all --rpm_safe_upgrade
exit 0

%files
%defattr(-,root,root)
/%{_datarootdir}/%{module}/%{module}-%{version}.dkms.tar.gz

%changelog
* %(date "+%a %b %d %Y") %{version}-%{release}
- Built from DKMS
