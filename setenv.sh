##### set env & shell functions #####
export PHP_SERVICE_NAME='app'
export CONTAINER_REGISTRY='harbor.dh1.div1.opendoor.local/'
export PROJECT='smplapp'

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


# gen image tag
DATE=`date '+%Y%m%d'`
COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
ARG1=$1
new_image_tag() {
  local IMAGE_TAG
  if [ -n "${COMMIT_HASH}" ]; then
  	IMAGE_TAG=${DATE}-${COMMIT_HASH}
  else
  	IMAGE_TAG=${DATE}
  fi
  echo ${IMAGE_TAG}
}
locallatest_image_tag(){
  local IMAGE_TAG
  if [ -n "${COMMIT_HASH}" ]; then
    IMAGE_TAG=$(docker images --format '{{.Tag}}' | grep "${COMMIT_HASH}" | sort -r | head -n 1)
  else
    IMAGE_TAG=$(docker images | grep "${CONTAINER_REGISTRY}${PROJECT}" | grep -E '^[0-9]{8}' | sort -r | head -n 1)
  fi
  echo ${IMAGE_TAG}
}
determin_image_tag(){
  local IMAGE_TAG
  if [ "${ARG1}" = "new" ]; then
    IMAGE_TAG=`new_image_tag`
  else
    IMAGE_TAG=`locallatest_image_tag`
  fi
  echo ${IMAGE_TAG}
}
export IMAGE_TAG=`determin_image_tag`
echo "use IMAGE_TAG:${IMAGE_TAG}"


# get id
if [ -z "${UID}" ]; then
	export UID=$(id -u)
fi
export GID=$(id -g)

# customize commands from container
# for get login(-l) shell & run command(-c)
composer() {
	CMD="composer $@"
	docker compose exec -u ${UID} ${PHP_SERVICE_NAME} sh -l -c "${CMD}"
}

php() {
	CMD="php $@"
	docker compose exec -u ${UID} ${PHP_SERVICE_NAME} sh -l -c "${CMD}"
}
