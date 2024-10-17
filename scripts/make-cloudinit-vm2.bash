#!/bin/bash

# Variables
HOSTNAME="sriov-vm2"
USERNAME="rosa"
PASSWORD="rosalab"
PACKAGES="curl vim htop make cmake"  # Add your predefined packages here
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

