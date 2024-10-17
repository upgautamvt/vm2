# This explains information about launching vm<X>; Replace \<x> with 1, 2, etc.

## Prerequisites

* Download VM script downloads, renames, and then resizes.
* Cloudinit scripts sets the rosa/rosalab user account.

* For launch-vm<X>.bash

```cmake
qemu-system-x86_64  \
-enable-kvm \
-smp 8 \
-cpu host \
-m 16G \
-nographic \
-device virtio-net-pci,netdev=net0 \
-netdev user,id=net0,hostfwd=tcp::2222-:22 \
-drive if=virtio,format=qcow2,file=../images/noble-server-cloudimg-amd64-vm<X>.img \
-drive if=virtio,media=cdrom,file=../seeds/vm<X>-seed.iso \
-device vfio-pci,host=0000:<your_vfio_pcie_id>
```


## Steps
* Download .img file: `images/download-img-vm<X>.sh`
* Prepare cloud init: `scripts/make-cloudinit-vm<X>.bash`
* Launch VM: `sudo scripts/.launch-vm<X>.bash`

**Note**: If you don't have sudo access then you need first launch a
privileged docker container and then do `make docker-enter` and there
do above three steps.


## From within the VM,

```cmake
sudo apt install -y git build-essential gcc g++ fakeroot libncurses5-dev libssl-dev ccache dwarves libelf-dev \
cmake automake mold libdw-dev libdwarf-dev bpfcc-tools libbpfcc-dev libbpfcc linux-headers-generic \
libtinfo-dev terminator libstdc++-11-dev libstdc++-12-dev libstdc++-13-dev libstdc++-14-dev bc \
xterm trace-cmd tcpdump flex bison rsync python3-venv ltrace sysdig kmod xdp-tools net-tools \
openssh-client openssh-server strace bpftrace tmux gdb xterm attr busybox curl vim htop openssl \
genisoimage pciutils clang llvm libvirt-daemon-system libvirt-clients qemu-kvm \
libbpf-dev linux-tools-common libbpfcc-dev libbpfcc binutils-dev dwarves libcap-dev"
```

```cmake
git clone ggit@github.com:rosalab/bpfabsorb.git
cd bpfabsorb/linux # linux root directory

# do these 4 lines; otherwise make fails
scripts/config --disable SYSTEM_TRUSTED_KEYS
scripts/config --disable SYSTEM_REVOCATION_KEYS
scripts/config --set-str CONFIG_SYSTEM_TRUSTED_KEYS ""
scripts/config --set-str CONFIG_SYSTEM_REVOCATION_KEYS ""

#copy .config from running kernel (where you are right now)



fakeroot make -j`nproc` # compiles linux
echo $? # make sure nothing wrong
make headers_install

cd tools/lib/bpf
make 

cd tools/bpf/bpftool
make

# go back to linux root directory
sudo ln -s /usr/include/x86_64-linux-gnu/asm /usr/include/asm

sudo make modules_install
suo make install
reboot
```

# If you are using rosa network testbed
The idea is VM1 in one server and VM2 in another server.

Two hardcoded things:
* VFIO device id (for Uddhav 01:00.2) (for Egore 01:00.3)
* You also need  your public ssh key in make-cloudinit script file
  such as, ssh_authorized_keys:- <your public ssh key>
* -netdev user,id=net0,hostfwd=tcp::<unique port>-:22 \ (unique port for uddhav 2222, and Egor 22222)



This whole VM should be run inside a privileged container. Since we don't have sudo
access here, so we must use docker.

Steps to follow
1) make docker
2) make enter-docker (you enter inside docker. docker has volume mounted your vm1 directory)
3) go to images directory, run download-img-vm<X>.sh script
4) go to scripts directory, and run make-cloudinit-vm<X>.bash script
5) Then from scripts directory, execute launch-vm<X>.bash
6) provide rosa/rosalab login
7) lspci and ip a check bus number (e..g, from 01:04.3, 04 part is bus number, so choose ens<bus_number> interface)
8) Using netplan, assign static IP and 9000 MTU for SR-IOV VFIO nic inside VM


**Note**: don't use same ip that is used by host.


# To install Mellanox driver in host machine (this is your root machine, which hosts vm<X> and qemu vm)

```cmake
upgautam@deimos:~/Downloads/bpfabsorb/vm1/scripts$ sudo cat /etc/netplan/01-netcfg.yaml
network:
version: 2
renderer: networkd
ethernets:
enp1s0f0np0:
dhcp4: no
addresses:
- 192.168.101.1/24
mtu: 9000
version: 2

```

```cmake
wget https://www.mellanox.com/downloads/ofed/MLNX_EN-24.04-0.7.0.0/mlnx-en-24.04-0.7.0.0-ubuntu24.04-x86_64.tgz
tar xaf mlnx-en-24.04-0.7.0.0-ubuntu24.04-x86_64.tgz
cd mlnx-en-24.04-0.7.0.0-ubuntu24.04-x86_64 && sudo ./install
sudo /etc/init.d/mlnx-en.d restart

```

```cmake
sudo su
mstconfig -d <domain:bus.device> query
mstconfig -d <domain:bus.device> set NUM_OF_VFS=2
reboot
```

```cmake
cat /sys/class/net/<your mellanox physical NIC that is connected with another Mellanox NIC>/device/sriov_numvfs
sudo su
echo 1 > /sys/class/net/<your mellanox physical NIC that is connected with another Mellanox NIC>/device/sriov_numvfs
lspci -nn | grep Mellanox
modprobe vfio-pci
echo "<vender id, device i>" | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id
echo "0000:<domain:bus.device>" | sudo tee /sys/bus/pci/devices/0000:<domain:bus.device>/driver/unbind
echo "0000:<domain:bus.device>" | sudo tee /sys/bus/pci/drivers/vfio-pci/bind

lspci -nnk -d <vender id, device i>

```

Next step is the launch vm<X> and use your VFIO from withing vm<X>.