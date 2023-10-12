#!/bin/bash

# lustre oss install

function disableFirewall {
    echo "Stopping and disable fiewalld"
    sudo systemctl stop firewalld
    sudo systemctl disable firewalld
#    sudo iptables -F
}

function installLustreRepo {
    rn="/etc/yum.repos.d/lustre.repo"
    if [[ -e $rn ]]; then
	echo "Removing and reinstalling $rn"
	sudo rm -f $rn
    fi
    cat >/tmp/lustre.repo <<__EOF
[lustre-server]
name=lustre-server
baseurl=https://downloads.whamcloud.com/public/lustre/latest-release/el8.8/server
# exclude=*debuginfo*
gpgcheck=0

enabled=1
[lustre-client]
name=lustre-client
baseurl=https://downloads.whamcloud.com/public/lustre/latest-release/el8.8/client
# exclude=*debuginfo*
gpgcheck=0

enabled=1
[e2fsprogs-wc]
name=e2fsprogs-wc
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/latest/el8
# exclude=*debuginfo*
gpgcheck=0
enabled=1    
__EOF
    sudo mv /tmp/lustre.repo $rn
}

function installPkgs {
    sudo yum install -y emacs-nox
    sudo yum install -y asciidoc audit-libs-devel automake bc \
	 binutils-devel bison elfutils-devel \
	 elfutils-libelf-devel expect flex gcc gcc-c++ git \
	 glib2 glib2-devel hmaccalc keyutils-libs-devel krb5-devel ksh \
	 libattr-devel libblkid-devel libselinux-devel libtool \
	 libuuid-devel lsscsi make ncurses-devel \
	 net-snmp-devel net-tools newt-devel numactl-devel \
	 parted patchutils pciutils-devel perl-ExtUtils-Embed \
	 pesign redhat-rpm-config rpm-build systemd-devel \
	 tcl tcl-devel tk tk-devel wget xmlto yum-utils zlib-devel
    sudo yum install -y epel-release
}

function installZFS {
    sudo yum install -y http://download.zfsonlinux.org/epel/zfs-release.el8_8.noarch.rpm
}


#    Note: The RPM package name changes with each release of Red Hat Enterprise Linux (RHEL). At the time of writing, the current release of RHEL is 7.4.
#    Install the kernel packages that match the latest supported version for the Lustre release:
function installKernel {
    #VER="3.10.0-693.2.2.el7"
    VER="4.18.0-477.21.1.el8_8.x86_64"
    sudo yum install -y \
	kernel-$VER \
	kernel-devel-$VER \
	kernel-headers-$VER \
	kernel-tools-$VER \
	kernel-tools-libs-$VER
}
#    Refer to the Lustre ChangeLog for the list of supported kernels.
#    Generate a persistent hostid on the machine, if one does not already exist. This is needed to help protect ZFS zpools against simultaneous imports on multiple servers. For example:

function genHostID {
    hid=`[ -f /etc/hostid ] && od -An -tx /etc/hostid|sed 's/ //g'`
    [ "$hid" = `hostid` ] || sudo genhostid
}

function rebootNode {
    echo "Rebooting node"
    sudo reboot
}

disableFirewall
installLustreRepo
installPkgs
## ZFS Already installed
## installZFS
installKernel
genHostID
rebootNode

