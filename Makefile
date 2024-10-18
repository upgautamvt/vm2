BASE_PROJ ?= $(shell pwd)
SSH_PORT ?= "52222"
DOCKER_PORT ?= "11234"
GDB_PORT ?= "1234"
DOCKER := testvm2
.ALWAYS:

docker: .ALWAYS
	make -C docker/docker-linux-builder docker

enter-docker:
	docker run --privileged --rm \
	--device=/dev/vfio:/dev/vfio \
	--device=/dev/kvm:/dev/kvm --device=/dev/net/tun:/dev/net/tun \
    --network host \
	-v ${BASE_PROJ}:/testvm2 \
	-p 127.0.0.1:${SSH_PORT}:52222 \
	-p 127.0.0.1:${DOCKER_PORT}:1234 \
	-p 127.0.0.1:${GDB_PORT}:1234 \
	-it ${DOCKER}:latest /bin/bash
