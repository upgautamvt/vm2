#!/bin/bash

# Variables
HOSTNAME="sriov-vm2"
USERNAME="rosa"
PASSWORD="rosalab"

PACKAGES="\
    git build-essential gcc g++ fakeroot libncurses5-dev libssl-dev ccache dwarves libelf-dev \
    cmake automake mold libdw-dev libdwarf-dev bpfcc-tools libbpfcc-dev libbpfcc linux-headers-generic \
    libtinfo-dev terminator libstdc++-11-dev libstdc++-12-dev libstdc++-13-dev libstdc++-14-dev bc fping \
    xterm trace-cmd tcpdump flex bison rsync python3-venv ltrace sysdig kmod xdp-tools net-tools ip \
    openssh-client openssh-server strace bpftrace tmux gdb xterm attr busybox curl vim htop openssl \
    genisoimage pciutils clang llvm libvirt-daemon-system libvirt-clients qemu-kvm \
    libbpf-dev bpftool linux-tools-$(uname -r) libbpfcc-dev libbpfcc"


CLOUD_INIT_DIR="cloud-init-data"
ISO_NAME="../seeds/vm2-seed.iso"

# Create directory for cloud-init files
mkdir -p $CLOUD_INIT_DIR
mkdir -p ../seeds

# Create the meta-data file
cat <<EOF > $CLOUD_INIT_DIR/meta-data
instance-id: iid-local02
local-hostname: $HOSTNAME
EOF

# Create the user-data file
cat <<EOF > $CLOUD_INIT_DIR/user-data
#cloud-config
users:
  - default
  - name: $USERNAME
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    lock_passwd: false
    passwd: $(echo $PASSWORD | openssl passwd -6 -stdin)
    ssh_pwauth: true
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPZLS2jLMOxPzEVr8XyXPYSV9QDsgihmZ4lnBYY01j2Z upgautam@vt.edu

# Update the system and install predefined packages
package_update: true
package_upgrade: true
packages:
  - $PACKAGES

# Enable SSH password authentication
ssh_pwauth: true

# Run a command after the system starts
runcmd:
  - [ sudo, apt, -y, autoremove ]
  - [ echo, "Provisioning complete!" ]
EOF

# Generate the seed ISO using genisoimage
genisoimage -input-charset utf-8 -output $ISO_NAME -volid cidata -joliet -rock $CLOUD_INIT_DIR/meta-data $CLOUD_INIT_DIR/user-data

# Cleanup
rm -r $CLOUD_INIT_DIR

echo "Cloud-Init seed ISO created: $ISO_NAME"

