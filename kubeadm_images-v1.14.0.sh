#!/bin/bash

VERSION=v1.13.4
MASTER_COMPONENTS='k8s.gcr.io/kube-apiserver:v1.14.0
k8s.gcr.io/kube-controller-manager:v1.14.0
k8s.gcr.io/kube-scheduler:v1.14.0
k8s.gcr.io/kube-proxy:v1.14.0
k8s.gcr.io/pause:3.1
k8s.gcr.io/etcd:3.3.10
k8s.gcr.io/coredns:1.3.1
quay.io/coreos/flannel:v0.11.0-amd64'
NODE_COMPONENTS='k8s.gcr.io/kube-proxy:v1.14.0
quay.io/coreos/flannel:v0.11.0-amd64
k8s.gcr.io/pause:3.1'

DOCKERHUB_REPO_NAME=solomonlinux

image_tag_convert(){
        local SRC_IMAGE=$1
        local DEST_IMAGE="${DOCKERHUB_REPO_NAME}/$(echo ${SRC_IMAGE} | tr '/' '.')"
        echo $DEST_IMAGE
}

pull_image(){
        local SRC_IMAGE=$1
        local DEST_IMAGE=$(image_tag_convert $SRC_IMAGE)

        docker pull $DEST_IMAGE &> /dev/null
        docker tag $DEST_IMAGE $SRC_IMAGE &> /dev/null
        docker rmi $DEST_IMAGE &> /dev/null
}

main(){
	for IMAGE in $MASTER_COMPONENTS; do
		pull_image $IMAGE
	done
	docker save -o kubernetes-${VERSION}-master-components.tar.gz $MASTER_COMPONENTS
	docker save -o kubernetes-${VERSION}-node-components.tar.gz $NODE_COMPONENTS
}

main
