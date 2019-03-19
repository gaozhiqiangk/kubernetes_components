#!/bin/bash

VERSION=v1.12.2
MASTER_COMPONENTS='k8s.gcr.io/kube-proxy:v1.12.2
k8s.gcr.io/kube-apiserver:v1.12.2
k8s.gcr.io/kube-controller-manager:v1.12.2
k8s.gcr.io/kube-scheduler:v1.12.2
k8s.gcr.io/etcd:3.2.24
k8s.gcr.io/coredns:1.2.2
quay.io/coreos/flannel:v0.10.0-amd64
k8s.gcr.io/pause:3.1'
NODE_COMPONENTS='k8s.gcr.io/kube-proxy:v1.12.2
quay.io/coreos/flannel:v0.10.0-amd64
k8s.gcr.io/pause:3.1'

git_init(){
	git config --global user.name "gaozhiqiang"
	git config --golbal user.email "1211348968@qq.com"
	git remote remove origin
	git remote add origin git@github.com:solomonlinux/kubernetes_components.git
	if git branch -a | grep 'origin/develop' &> /dev/null; then
		git checkout develop
		git pull origin develop
		git branch --set-upstream-to=origin/develop develop
	else
		git checkout -b develop
		git pull origin develop
	fi
}

git_commit(){
	local COMMIT_FILES_COUNT=$(git status -s | wc -l)
	local TODAY=$(date +%F %T)
	if [ $COMMIT_FILES_COUNT -gt 0 ]; then
		git add -A
		git commit -m "Synchronizing completion at $TODAY"
		git push -u origin develop
	fi
}

pull_images(){
	echo
	for IMAGE in $MASTER_COMPONENTS; do
		docker pull $IMAGE
	done
	docker save -o kubernetes-${VERSION}-master-components.tar.gz $MASTER_COMPONENTS
	docker save -o kubernetes-${VERSION}-node-components.tar.gz $NODE_COMPONENTS
	mv kubernetes-${VERSION}-master-components.tar.gz images/
	mv kubernetes-${VERSION}-node-components.tar.gz images/
}

main(){
	git_init
	pull_images
	git_commit
}

main
