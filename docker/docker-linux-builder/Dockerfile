FROM ubuntu:22.04 AS linux-builder

RUN apt-get update && apt-get install -y \
    openssl \
    genisoimage \
    qemu \
    wget curl \
    pciutils \
    libvirt-daemon-system \
    libvirt-clients \
    qemu-kvm \
    gcc-multilib \
    build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /testvm2

CMD ["/bin/bash"]
