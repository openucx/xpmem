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
    yum install -y -q centos-release-scl
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
    mainline install-minor
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
