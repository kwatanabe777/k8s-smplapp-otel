#!/bin/bash
#
##### set env & shell functions #####
export PROJECT_NAME='smplapp-a'
export CONTAINER_REGISTRY='harbor.dh1.div1.opendoor.local/'
export IMAGE_NAME_WEB='web-otel'
export IMAGE_NAME_APP='app-otel'
#export IMAGE_TAG=''
export NGINX_SERVICE_NAME='web'
export PHP_SERVICE_NAME='app'

# for container commands
export CMD_ENV=''  # set "k8s" for kubernetes environment, otherwise empty.
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
# auto IMAGE_TAG generation
#
# 環境変数:IMAGE_TAGが既に設定されていればそれを使用する。
# そうでなければ、以下の優先順位でTAGを生成する。
#  gitのcommit hashが存在する場合は、YYYYMMDD-commithashでTAGを生成する。
#  既にローカルimageキャッシュがある場合は、latest以外の最新(降順の最初)のTAGを利用する。
#  両方存在する場合は新しい方を利用する。
#  そうでない場合は、日付:YYYYMMDDでTAGを生成する
# If the environment variable:IMAGE_TAG is already set, use it.
# Otherwise, generate TAG in the following order of precedence.
#  If you in the git working directory, use YYYYMMDD-commithash to generate TAG.
#  If there is already a local image cache, use the latest TAG(first in descending order) other than 'latest'.
#  If both exist, use the newest one.
#  Otherwise, generate a TAG from the only date: YYYYYMMDD.

get_date() {
  echo `date '+%Y%m%d'`
}

get_locallatest_image_datetag(){
  # get latest local imagecache date and tag
  echo $(docker images --format "table {{.CreatedAt}},{{.Tag}}" ${CONTAINER_REGISTRY}${PROJECT_NAME}/* | awk 'NR>1' | sort -r | grep -v latest | head -n1)
}

get_locallatest_git_datecommithash() {
  # get latest date and commit hash(short)
  echo $(git log -1 --format='%ci,%h' 2>/dev/null)
}

date_localepoch() {
  # delete extra timezone
  local CUT_EXTRA="$(echo ${@} | awk '{print $1,$2,$3}')"
  # local epoch time
  echo $(date -d "${CUT_EXTRA}" '+%s')
}

date_ymd() {
  echo $(date -d "@$(date_localepoch ${@})" '+%Y%m%d')
}

compare_date() {
  local DATE1=${1}
  local DATE2=${2}
  if [ ${DATE1} -gt ${DATE2} ]; then
    echo "1"
  elif [ ${DATE1} -lt ${DATE2} ]; then
    echo "-1"
  else
    echo "0"
  fi
}

determin_image_tag(){
  local CACHE_DATETAG=$(get_locallatest_image_datetag)
  local CACHE_DATE=$(echo "${CACHE_DATETAG}" | awk -F, '{print $1}')
  local GIT_DATEHASH=$(get_locallatest_git_datecommithash)
  local GIT_DATE=$(echo "${GIT_DATEHASH}" | awk -F, '{print $1}')
  local CMP_RESULT
  local DATE=$(get_date)
  local IMAGE_TAG

  if [ -n "${GIT_DATEHASH}" -a -z "${CACHE_DATETAG}" ]; then
    IMAGE_TAG=$(date_ymd ${GIT_DATE})-$(echo "${GIT_DATEHASH}" | awk -F, '{print $2}')
    echo -n 'found commithash, ' >&2

  elif [ -n "${CACHE_DATETAG}" -a -z "${GIT_DATEHASH}" ]; then
    IMAGE_TAG=$(echo "${CACHE_DATETAG}" | awk -F, '{print $2}')
    echo -n 'found localimagecache, ' >&2

  elif [ -n "${CACHE_DATETAG}" -a -n "${GIT_DATEHASH}" ]; then
    echo -n 'set newertag ' >&2
    CMP_RESULT=$(compare_date $(date_localepoch "${GIT_DATE}") $(date_localepoch "${CACHE_DATE}") )
    if [ "${CMP_RESULT}" -eq 1 ]; then
      IMAGE_TAG=$(date_ymd "${GIT_DATE}")-$(echo "${GIT_DATEHASH}" | awk -F, '{print $2}')
      echo -n '(commithash), ' >&2
    elif [ "${CMP_RESULT}" -eq -1 ]; then
      IMAGE_TAG=$(echo "${CACHE_DATETAG}" | awk -F, '{print $2}')
      echo -n '(localimagecache), ' >&2
    fi

  elif [ -z "${CACHE_DATETAG}" -a -z "${GIT_DATEHASH}" ]; then
    IMAGE_TAG=${DATE}
    echo -n 'no taginfo ' >&2
  fi

  echo "${IMAGE_TAG}"
}

if [ -n "${IMAGE_TAG}" ]; then
  echo "use predefined IMAGE_TAG:${IMAGE_TAG}"
else
  IMAGE=$(determin_image_tag)
  echo "use auto IMAGE_TAG:${IMAGE}"
  # if called by make, export IMAGE_TAG
  if [ "$(ps -o command --no-header $PPID | awk '{print $1}')" = 'make' ]; then
    export IMAGE_TAG=${IMAGE}
  fi
fi


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
    kubectl exec deployment/${K8S_DEPLOYMENT_NAME} -n ${K8S_NAMESPACE} -it -- sh -l -c "${CMD}"
    return $?
  else
    IMAGE_TAG=${IMAGE} docker compose exec -u ${UID} ${PHP_SERVICE_NAME} sh -l -c "${CMD}"
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

# generate php command wrapper
create_wrapper() {
  echo '#!/bin/bash' > ./php
  declare -x > ./php
  declare -f container_exec >> ./php
  declare -f php >> ./php
  echo "pushd ${PWD} >/dev/null >&1" >> ./php
  echo "php \"\$@\"" >> ./php
  chmod +x ./php
}

