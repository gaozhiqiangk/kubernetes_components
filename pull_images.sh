#!/bin/bash

set -e

DOCKERHUB_REPO_NAME=solomonlinux
NOIMAGEFILE=`mktemp noimagefile.XXX`

# 安装依赖软件包
app_install(){
	if ! which jq &> /dev/null; then
		yum -y install epel-release &> /dev/null
		yum -y install jq &> /dev/null
	fi
}

# 镜像名称转换
image_tag_convert(){
        local SRC_IMAGE=$1
        local DEST_IMAGE="${DOCKERHUB_REPO_NAME}/$(echo ${SRC_IMAGE} | tr '/' '.')"
        echo $DEST_IMAGE
}

# 检查我的仓库是否存在镜像
image_tag_check(){
        local RESULT=$(curl -s https://hub.docker.com/v2/repositories/${DOCKERHUB_REPO_NAME}/$1/tags/$2/ | jq -r .name)
        if [ "$RESULT" == "null" ]; then
                return "1"
        else
                return "0"
        fi
}

# 拉取镜像,如果存在就拉取,不存在就报告
pull_image(){
	local SRC_IMAGE=$1
	local DEST_IMAGE=$(image_tag_convert $SRC_IMAGE)
        local IMAGE=$(echo $DEST_IMAGE | cut -d/ -f2 | cut -d: -f1)
        local TAG=$(echo $DEST_IMAGE | cut -d: -f2)

        if ! $(image_tag_check $IMAGE $TAG); then
        #if ! true; then
		echo -e "镜像(\033[5;31m${SRC_IMAGE}\033[0m)在远程不存在"
		echo $SRC_IMAGE >> $NOIMAGEFILE
        else
                docker pull $DEST_IMAGE &> /dev/null
                docker tag $DEST_IMAGE $SRC_IMAGE &> /dev/null
                docker rmi $DEST_IMAGE &> /dev/null
                [ $? -eq 0 ] && echo -e "镜像(\033[32m${SRC_IMAGE}\033[0m)同步本地完成"
        fi
}

app_install

for IMAGE in $@; do
	TEST=$(docker images --format {{.Repository}}:{{.Tag}}) &> /dev/null
	if echo $TEST | grep "$IMAGE" &> /dev/null; then
		echo -e "镜像(\033[31m${IMAGE}\033[0m)在本地已存在"	
	else
		pull_image $IMAGE
	fi
	shift
done

if [ ! -z $(cat $NOIMAGEFILE) ]; then
	echo -e "\n下列镜像不存在,请到github提交镜像"
	cat $NOIMAGEFILE
	echo -e "==>\033[5;31mhttps://github.com/solomonlinux/kubernetes_components/blob/master/kubeadm_components.txt\033[0m<=="
fi
rm -rf $NOIMAGEFILE
