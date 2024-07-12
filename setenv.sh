#!/bin/bash
#
##### set env & shell functions #####
export PROJECT_NAME='smplapp-a'
export CONTAINER_REGISTRY='harbor.dh1.div1.opendoor.local/'
export NGINX_SERVICE_NAME='web'
export PHP_SERVICE_NAME='app'

# for container commands
export CMD_ENV=''  # set "k8s" for k3d environment
export K8S_NAMESPACE='smplapp'
export K8S_DEPLOYMENT_NAME='smplapp-phpfpm'

# For container build options
# To enable opentelemetry & transporters:
#   OTEL:               http/json
#   OTEL+PROTOBUF:      http/json http/protobuf
#   OTEL+GRPC:          http/json grpc
#   OTEL+GRPC+PROTOBUF: http/json http/protobuf grpc(grpc+protobuf)
# Otel transporter performance probably:
#   http/json > grpc > http/protobuf > grpc+protobuf
# Buildtime:
#   enabling GRPC module adds significantly big time to build extension
# == don't require php native(purephp) protobuf extension(by composer), because of so slow ==
export BUILD_OTEL=1
export BUILD_GRPC=1
export BUILD_PROTOBUF=1


################################################################################
# gen & set image-tag
#
#もし、gitのcommit hashが取れない場合は、日付のみでタグを生成する。
#そうでない場合は、日付とcommit hashの組み合わせでタグを生成するが、
#既にローカルimageキャッシュがある場合は、その最新のtagを取得する。
#If you cannot get the git commit hash, generate a tag with only the date.
#If not, generate a tag with a combination of date and commit hash, but
#If there is already a local image cache, get its latest tag.

get_new_image_tag() {
  local IMAGE_TAG
  local DATE=`date '+%Y%m%d'`
  local COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
  if [ -n "${COMMIT_HASH}" ]; then
    IMAGE_TAG=${DATE}-${COMMIT_HASH}
  else
    IMAGE_TAG=${DATE}
  fi
  echo "${IMAGE_TAG}"
}
get_locallatest_image_tag(){
  local IMAGE_TAG
  #IMAGE_TAG=$(docker images | grep ${CONTAINER_REGISTRY}${PROJECT_NAME} | awk '{print $2}' | grep -E '^[0-9]{8}-[0-9a-z]{6}' | sort -r | head -n 1)
  IMAGE_TAG=$(docker images --format "table {{.Tag}}" ${CONTAINER_REGISTRY}${PROJECT_NAME} | grep -E '^[0-9]{8}-[0-9a-z]{7}' | sort -r | head -n 1)
  if [ -z "${IMAGE_TAG}" ]; then
    IMAGE_TAG=$(docker images | grep "${CONTAINER_REGISTRY}${PROJECT_NAME}" | grep -E '^[0-9]{8}' | sort -r | head -n 1)
  fi
  IMAGE_TAG=${IMAGE_TAG:-`get_new_image_tag`} #fallback
  echo "${IMAGE_TAG}"
}
determin_image_tag(){
  local ARG=$1
  local IMAGE_TAG
  if [ "${ARG}" = "new" ]; then
    IMAGE_TAG=`get_new_image_tag`
  else
    IMAGE_TAG=`get_locallatest_image_tag`
  fi
  echo "${IMAGE_TAG}"
}
export IMAGE_TAG=`determin_image_tag "${1}"`
echo "use IMAGE_TAG:${IMAGE_TAG}"


################################################################################
# get id
#
if [ -z "${UID}" ]; then
    export UID=$(id -u)
fi
export GID=$(id -g)


################################################################################
# other environments
## use docker buildkit for Dockerfile.dockerignore
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1


################################################################################
# exec commands at container
# for get login(-l) shell & run command(-c)
container_exec() {
  local CMD="$@"
  if [ "${CMD_ENV}" = 'k8s' ]; then
    kubectl exec deployment/${K8S_DEPLOYMENT_NAME} -n ${K8S_NAMESPACE} -- sh -l -c "${CMD}"
    return $?
  else
    docker compose exec -u ${UID} ${PHP_SERVICE_NAME} sh -l -c "${CMD}"
    return $?
  fi
}

composer() {
  container_exec "${FUNCNAME[0]} $@"
  return $?
}

php() {
  container_exec "${FUNCNAME[0]} $@"
  return $?
}
