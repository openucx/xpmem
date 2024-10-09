#!/usr/bin/env sh

set -eEx

clean_autogen() {
    git clean -xdf
    git reset --hard
    export CFLAGS='-Werror -Wall'
    ./autogen.sh
}

clean_configure() {
    clean_autogen
    export KFLAGS='-Werror'
    ./configure --with-kerneldir="$1"
}

clean_userspace_configure() {
    clean_autogen
    ./configure --disable-kernel-module "$@"
}

centos_kernel_versions() {
    rpm -qa 'kernel-devel*' --qf "%{version}-%{release}.%{arch}\n"
}

centos_kernel_version() {
    centos_kernel_versions | head -n 1
}

debian_kernel_version() {
    dpkg -l | grep 'linux-headers-.*-generic' | awk '{print $2}' | head -n 1
}

dkms_workaround() {
    # Workaround DKMS issue:
    # - https://github.com/dell/dkms/commit/468025752343dbc8609704bf0915f52b9c5c50f2
    sudo sed -i  -e 's@if \[\[ ! $temp_dir_name/dkms_main_tree \]\]@if \[\[ ! -d $temp_dir_name/dkms_main_tree \]\]@g' /usr/sbin/dkms || true
}

dkms_xpmem_version() {
    dkms status -m xpmem | sed -n -e 's@xpmem[,/ ]\+\([^:,]\+\).*@\1@p'
}
