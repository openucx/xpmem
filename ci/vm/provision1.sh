#!/bin/bash
set -Exeuo pipefail

OS=$1
KERNEL=$2

install_packages() {
  if [[ $OS == *"ubuntu"* ]]; then
    apt-get update &&
      DEBIAN_FRONTEND=noninteractive apt-get install -yq \
        automake \
        dkms \
        git \
        libtool &&
      apt-get clean && rm -rf /var/lib/apt/lists/*
  elif [[ $OS == *"centos"* ]]; then
    # Update all repos to use vault.centos.org
    for repo in /etc/yum.repos.d/*.repo; do
      sed -i 's|^mirrorlist=|#mirrorlist=|g' "$repo"
      sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' "$repo"
    done
    # Update repo config to vault.centos.org
    sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo
    sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

    # Install centos-release-scl and update its repo config
    yum install -y -q centos-release-scl
    sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo /etc/yum.repos.d/CentOS-SCLo-scl.repo
    sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo /etc/yum.repos.d/CentOS-SCLo-scl.repo

    yum install -y -q \
      automake \
      devtoolset-8-gcc \
      devtoolset-8-gcc-c++ \
      elfutils-libelf-devel \
      git \
      libtool \
      make &&
      yum clean all
  fi
}

install_mainline_kernel() {
    uname -r
    add-apt-repository ppa:cappelikan/ppa    
    apt-get update &&
      DEBIAN_FRONTEND=noninteractive apt-get install -yq mainline
    mainline install 6.3.13
    echo $?
}


err_report() {
  echo "Exited with ERROR in line $1"
}
trap 'err_report $LINENO' ERR

install_packages
if [[ $KERNEL == "mainline" ]]; then
  install_mainline_kernel
fi
