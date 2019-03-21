#!/bin/bash

DOCKERHUB_REPO_NAME=solomonlinux
IMAGE_LIST_FILE=kubeadm_components.txt

set -e

# 作用: 安装依赖的软件包
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

# 作用: github仓库初始化
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

# 作用: github仓库提交
git_commit(){
	local COMMIT_FILES_COUNT=$(git status -s | wc -l)
	local TODAY=$(date "+%F %T")
	if [ $COMMIT_FILES_COUNT -gt 0 ]; then
		git add -A
		git commit -m "Synchronizing completion at $TODAY"
		git push -u origin develop
	fi
}

# 参数: $1为用户输入的镜像(检查本地有没有),如k8s.gcr.io/kube-proxy:v1.12.2
# 作用: 为了检查用户输入的镜像转换为我本地的镜像,如k8s.gcr.io/kube-proxy:v1.12.2转换为solomonlinux/gcr.io.kube-proxy:v1.12.2
image_tag_convert(){
	local SRC_IMAGE=$1
	local DEST_IMAGE="${DOCKERHUB_REPO_NAME}/$(echo ${SRC_IMAGE} | tr '/' '.')"
	echo $DEST_IMAGE
}

# 用于检查我自己的仓库是否存在镜像
# $1为镜像名称,如nginx,$2为镜像标签,如v1-test
# 返回值为0表示镜像存在,为1表示镜像不存在
# $1: image_name; $2: image_tag_name

# 参数: $1为我本地镜像仓库的镜像名称,如solomonlinux/nginx:v1-test的nginx
# 参数: $2为我本地镜像仓库镜像的标签,如solomonlinux/nginx:v1-test的v1-test

image_tag_check(){
        local RESULT=$(curl -s https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO_NAME}/$1/tags/$2/ | jq -r .name)
	if [ "$RESULT" == "null" ]; then
		#echo failure
		return 1
	else
		#echo ok
		return 0
	fi
}

sync_image(){
	while read IMGTAG; do
		local SRC_IMAGE=$IMGTAG
		local DEST_IMAGE=$(image_tag_convert $SRC_IMAGE)
		local IMAGE=$(echo $DEST_IMAGE | cut -d/ -f2 | cut -d: -f1)
		local TAG=$(echo $DEST_IMAGE | cut -d: -f2)
		
		#if [[ $(image_tag_check $IMAGE $TAG) == "failure" ]]; then
		if [[ $(image_tag_check $IMAGE $TAG) -eq 1 ]]; then
			docker pull $SRC_IMAGE &> /dev/null
			docker tag $SRC_IMAGE $DEST_IMAGE &> /dev/null
			docker push $DEST_IMAGE &> /dev/null
			[ $? -eq 0 ] && echo "${SRC_IMAGE}已同步完成"
		else
			echo "${SRC_IMAGE}镜像已存在,不需要再次同步"
		fi	
	done < <( cat $IMAGE_LIST_FILE )
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
