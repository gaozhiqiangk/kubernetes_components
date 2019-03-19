#!/bin/bash

DOCKERHUB_REPO_NAME=solomonlinux
#source kubeadm_pods.txt
IMAGE_LIST_FILE=kubeadm_pod.txt


# 安装依赖的软件包
app_install(){
	echo
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
	local DOMAIN=${SRC_IMAGE%%/*}
	if [ $DOMAIN == "k8s.gcr.io" ]; then
        	DEST_IMAGE=${DOCKERHUB}/`echo ${SRC_IMAGE#*.} | tr / .`
		echo $DEST_IMAGE
	elif [ $DOMAIN == 'gcr.io' ]; then
        	DEST_IMAGE=${DOCKERHUB}/`echo ${SRC_IMAGE} | tr / .`
		echo $DEST_IMAGE
	elif [ $DOMAIN == 'quay.io' ]; then
        	DEST_IMAGE=${DOCKERHUB}/`echo $SRC_IMAGE | tr / .`
		echo $DEST_IMAGE
	else
        	DEST_IMAGE=$SRC_IMAGE
		echo $DEST_IMAGE
	fi
}

# 用于检查我自己的仓库是否存在镜像
# $1为镜像名称,如nginx,$2为镜像标签,如v1-test
# 返回值为0表示镜像存在,为1表示镜像不存在
# $1: image_name; $2: image_tag_name
image_tag_check(){
        local RESULT=$(curl -s https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO_NAME}/$1/tags/$2/ | jq -r .name)
	if [ $RESULT == null ]; then
		return 1
	else
		return 0
	fi
}


# 检查我自己的仓库是否有镜像,有就算了,没有就拉取并改名上传至自己的仓库
# xxx为镜像列表
pull_image(){

	while read IMAGE TAG; do
		echo "$IMAGE ---- $TAG"
		local DEST_IMAGE=$(image_tag_convert ${IMAGE}:${TAG})
		image_tag_check ${IMAGE} ${TAG}
		if [ $? -ne 0 ]; then
			docker pull ${IMAGE}:${TAG}
			docker push ${DOCKERHUB_REPO_NAME}/${IMAGE#*/}:${TAG}
		fi
	done < <( cat $IMAGE_LIST_FILE | grep -v "^$" | awk -F: '/:/{print $1,$2}' )
}

main(){
	app_install
	git_init
	pull_image
	git_commit
}

# 我使用git lfs报错,而且它的容量为1G,因为我想通过脚本来实现我的仓库里必须有对应的镜像存在,并且在使用时通过脚本能够快速拉取所需镜像
main
