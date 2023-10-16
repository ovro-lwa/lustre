As of kernel version

```export VER=4.18.0-477.21.1.el8_8```

make sure I have the right kernel headers etc.

```
dnf install kernel-$VER kernel-devel-$VER kernel-headers-$VER kernel-tools-$VER kernel-tools-libs-$VER kernel-tools-libs-devel-$VER
```

```
dnf install kernel-abi-stablelists-4.18.0-477.21.1.el8_8
```

Repo config

```
[yuping@lwacalim00 ~]$ cat /etc/yum.repos.d/lustre.repo 
[lustre-client]
name=lustre-client
baseurl=https://downloads.whamcloud.com/public/lustre/latest-release/el8.8/client
gpgcheck=0
enable=0
```
Install
```
sudo dnf --enablerepo=lustre-client install lustre-client-dkms lustre-client
```

LNet

```
[yuping@lwacalim00 ~]$ cat /etc/modprobe.d/lnet.conf 
options lnet networks="tcp0(enp161s0f0)"
```
