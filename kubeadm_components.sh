#!/bin/bash

DOCKERHUB_REPO_NAME=solomonlinux
IMAGE_LIST_FILE=kubeadm_components.txt

set -e

# 安装依赖的软件包
app_install(){
	if ! which jq &> /dev/null; then
		if ls /etc/ | grep 'redhat-release' &> /dev/null; then 
			yum -y install epel-release
			yum -y install jq
		else
			apt-get -y install jq
		fi
	fi
}

# github仓库初始化
git_init(){
	git config --global user.name "gaozhiqiang"
	git config --global user.email "1211348968@qq.com"
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

# github仓库提交
git_commit(){
	local COMMIT_FILES_COUNT=$(git status -s | wc -l)
	local TODAY=$(date "+%F %T")
	if [ $COMMIT_FILES_COUNT -gt 0 ]; then
		git add -A
		git commit -m "Synchronizing completion at $TODAY"
		git push -u origin develop
	fi
}

# 为了检查用户输入的镜像,如k8s.gcr.io/kube-proxy:v1.12.2转换为solomonlinux/gcr.io.kube-proxy:v1.12.2,用于检查我自己的仓库有没有
# $1为用户提供的镜像名称,如k8s.gcr.io/kube-proxy:v1.12.2
image_tag_convert(){
	local SRC_IMAGE=$1
	local DEST_IMAGE="${DOCKERHUB_REPO_NAME}/${SRC_IMAGE} | tr '/' '.'"
	echo $DEST_IMAGE
}

# 用于检查我自己的仓库是否存在镜像
# $1为镜像名称,如nginx,$2为镜像标签,如v1-test
# 返回值为0表示镜像存在,为1表示镜像不存在
# $1: image_name; $2: image_tag_name
image_tag_check(){
        local RESULT=$(curl -s https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO_NAME}/$1/tags/$2/ | jq -r .name)
	if [ "$RESULT" == "null" ]; then
		echo failure
	else
		echo ok
	fi
}

sync_image(){
	while read IMAGE TAG; do
		SRC_IMAGE=${IMAGE}:${TAG}
		DEST_IMAGE=$(image_tag_convert $SRC_IMAGE)
		if [ $(image_tag_check $IMAGE $TAGE) == "failure" ]; then
			docker pull $SRC_IMAGE &> /dev/null
			docker tag $SRC_IMAGE $DEST_IMAGE &> /dev/null
			docker push $DEST_IMAGE &> /dev/null
			[ $? -eq 0 ] && echo "${SRC_IMAGE}已同步完成"
		else
			echo "${SRC_IMAGE}镜像已存在,不需要再次同步"
		fi
	done < <( cat $IMAGE_LIST_FILE | tr "'" "\n" | grep -v "^$" | awk -F: '/:/{print $1,$2}' )
}

main(){
	app_install
	git_init
	sync_image
	git_commit
}

main


# 'xyz		xyz
# ab		ab
# cde		cde
# xyz'		xyz
# cat test | tr "'" "\n" | grep -v "^$" | sort | uniq
# ( cat $IMAGE_LIST_FILE | tr "'" "\n" | grep -v "^$" | awk -F: '/:/{print $1,$2}' )
