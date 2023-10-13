#!/bin/bash

# script to run after LustreOSSInstall.sh which reboots host

function installRPMs {
    rm -rf ~/Downloads
    rsync -av -e ssh lwastor01:Downloads ~/    
    if [[ ! -e ~/Downloads/lustre/libmount-devel-2.32.1-42.el8.x86_64.rpm ]]; then
	echo "Error. libmount-devel not found in ~/Downloads/lustre"
	exit
    fi
    sudo rpm -ivh --nodeps ~/Downloads/lustre/libmount-devel-2.32.1-42.el8.x86_64.rpm
    sudo rpm -ivh --nodeps ~/Downloads/lustre/libyaml-devel-0.1.7-5.el8.x86_64.rpm
}

function installPkgs {
   sudo yum --nogpgcheck --enablerepo=lustre-server install -y \
       lustre-zfs-dkms \
       lustre-osd-zfs-mount \
       lustre \
       zfs
}

function installLnet {
    sudo modprobe -r lnet
    sudo ifup ens3f0
    sleep 2
    net="10.41"
    iface=`ifconfig | grep -B1 $net | grep mtu | awk '{print $1}' | awk -F ':' '{print $1}'`
    echo "options lnet networks=\"tcp0($iface)\"" > /tmp/lnet.conf
    sudo mv /tmp/lnet.conf /etc/modprobe.d/
    sudo modprobe lnet
    sudo lctl network up
    sudo lctl list_nids | grep $net
    if [[ $? -ne 0 ]]; then
	echo "ERROR. LNET not setup on 40G interface"
	exit
    fi
}

function fixAndReinstallLuster {
    sudo yum remove -y lustre-zfs-dkms
    sudo rpm -ivh --nodeps ~/Downloads/lustre/libmount-devel-2.32.1-42.el8.x86_64.rpm
    sudo rpm -ivh --nodeps ~/Downloads/lustre/libyaml-devel-0.1.7-5.el8.x86_64.rpm
    sudo yum install -y lustre-zfs-dkms lustre
    
    #sudo dkms build --force zfs/2.1.13
    #sudo dkms install --force zfs/2.1.13
    sudo sed -i s/REMAKE_INITRD/\#REMAKE_INITRD/ /var/lib/dkms/lustre-zfs/2.15.3/source/dkms.conf    
    sudo dkms build --force lustre-zfs/2.15.3
    sudo dkms install --force lustre-zfs/2.15.3
}

function installMod {
    sudo dkms status
    sudo modprobe -v zfs
    sudo modprobe -v lustre
}

function makefs {

    hn=`hostname -s`
    p0=$hn
    p1=${hn}a
    p2=${hn}b
    # extract host number from hostname. hostname must be of the form
    # lwastorXY. ib should then equal Y
    ib=`echo $hn | cut -c 9`
    i=$(( $ib*3 - 3 ))
    if [[ -e /tmp/ldev.conf ]]; then
       sudo rm -f /tmp/ldev.conf
    fi
    for p in $p0 $p1 $p2; do
	sudo zpool list $p > /dev/null 2>&1
	sudo mkdir -p /mnt/lustre/$p
      if [[ $? -ne 0 ]]; then
	  echo "pool $p does not exist, Importing..."
	  sudo zpool import
	  sudo zpool import $p
      fi
      echo "making lustre fs on $p/ost..."
      sudo mkfs.lustre --reformat --ost --backfstype=zfs --fsname=lstore --mgsnode=10.41.0.86 --index=$i $p/ost
      ostname=`printf 'lstore-OST%4.4x\n' $i`
      echo "$hn - $ostname zfs:$p/ost" >> /tmp/ldev.conf
      sudo mount -t lustre $p/ost /mnt/lustre/$p
      i=$(( $i + 1 ))
    done
    sudo cp /tmp/ldev.conf /etc/
    cp /tmp/ldev.conf /home/ubuntu/
    rm /tmp/ldev.conf
    #sudo systemctl restart lustre
    sudo systemctl enable lustre
}

installRPMs
installPkgs
fixAndReinstallLuster
installMod
installLnet
makefs

