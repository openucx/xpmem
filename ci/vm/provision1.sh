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
    # Update repo config to vault links
    sudo sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-*.repo
    sudo sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo

    # Install centos-release-scl and update its repo config
    sudo yum install -y -q centos-release-scl scl-utils
    sudo rm -f /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
    sudo sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-SCLo*.repo
    sudo sed -i \
      's|# baseurl=http://mirror.centos.org/centos/7/sclo/\$basearch/sclo/|\baseurl=http://vault.centos.org/centos/7/sclo/x86_64/rh/|' \
      /etc/yum.repos.d/CentOS-SCLo-scl.repo

    sudo yum install -y  \
      automake \
      devtoolset-8-gcc \
      devtoolset-8-gcc-c++ \
      elfutils-libelf-devel \
      git \
      libtool \
      make &&
      sudo yum clean all

  elif [[ $OS == *"rhel"* ]]; then
    # Copy the repo file
    sudo cp /vagrant/rhel-web.repo /etc/yum.repos.d/
    # Set yum OS version
    sudo bash -c '. /etc/os-release && echo "${VERSION_ID}" > /etc/yum/vars/os_version'

    sudo yum install -y git
    sudo yum clean all
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
