###########################
# containers operation
#
.PHONY: build pull up down login push
SHELL := /bin/bash #/bin/sh cannnot receive args at . ./setenv.sh
# create webapp/public directory temporarily for build nginx container
build:
	@. ./setenv.sh new \
    && set +a \
    && mkdir -p webapp/public \
    && docker compose -f docker-compose.build.yaml build \
    && IMAGE_TAG=latest && docker compose -f docker-compose.build.yaml build

pull:
	@. ./setenv.sh \
    && set +a \
    && IMAGE_TAG=latest && docker compose pull \

up:
	@. ./setenv.sh \
    && set +a \
    && docker compose up -d \

up-app:
	@. ./setenv.sh \
    && set +a \
    && docker compose up -d ${PHP_SERVICE_NAME}

down:
	@. ./setenv.sh \
    && set +a \
    && docker compose down \

#make login USER=your_username PASSWORD=your_password
login:
	@. ./setenv.sh \
    && set +a \
    && echo ${PASSWORD} | docker login --username ${USER} --password-stdin $${CONTAINER_REGISTRY} \

#make push USER=your_username PASSWORD=your_password
push:
	@. ./setenv.sh \
    && set +a \
    && docker compose -f docker-compose.build.yaml push \
    && IMAGE_TAG=latest && docker compose -f docker-compose.build.yaml push

###########################
# plain php-fpm
#
bootstrap: build up

###########################
# framework bootstrapping
#   firstly only up app-container to rmdir webapp/public
#     for compose create-projct
#
#### psr
#psr3: logger interface
#psr14: event dispatcher
#psr15: http server request handlers
#psr16: common interface for cache libraries
#psr18: http client
bootstrap-laravel: build up-app
	. ./setenv.sh && set +a \
    && container_exec rmdir public \
    && composer create-project laravel/laravel . \
    && docker compose up -d

bootstrap-laravel-otel: bootstrap-laravel
	. ./setenv.sh && set +a \
    && composer require open-telemetry/api \
       open-telemetry/sdk \
       open-telemetry/exporter-otlp \
       open-telemetry/opentelemetry-auto-laravel \
       open-telemetry/opentelemetry-auto-io \
       open-telemetry/opentelemetry-auto-http-async \
       open-telemetry/opentelemetry-auto-guzzle \
       open-telemetry/opentelemetry-auto-psr3 \
       open-telemetry/opentelemetry-auto-psr14 \
       open-telemetry/opentelemetry-auto-psr15 \
       open-telemetry/opentelemetry-auto-psr16 \
       open-telemetry/opentelemetry-auto-psr18 \
       open-telemetry/opentelemetry-auto-pdo

bootstrap-laravel-otel-grpc: bootstrap-laravel-otel
	. ./setenv.sh && set +a \
    && composer require open-telemetry/transport-grpc


bootstrap-codeigniter: build up-app
	. ./setenv.sh && set +a \
    && container_exec rmdir public \
    && composer create-project codeigniter4/appstarter . \
    && docker compose up -d

bootstrap-codeigniter-otel: bootstrap-codeigniter
	. ./setenv.sh && set +a \
    && composer require open-telemetry/api \
       open-telemetry/sdk \
       open-telemetry/transport-grpc \
       open-telemetry/exporter-otlp \
       open-telemetry/opentelemetry-auto-codeigniter \
       open-telemetry/opentelemetry-auto-http-async \
       open-telemetry/opentelemetry-auto-io \
       open-telemetry/opentelemetry-auto-psr3 \
       open-telemetry/opentelemetry-auto-psr14 \
       open-telemetry/opentelemetry-auto-psr15 \
       open-telemetry/opentelemetry-auto-psr16 \
       open-telemetry/opentelemetry-auto-psr18 \
       open-telemetry/opentelemetry-auto-pdo

bootstrap-codeigniter-otel-grpc: bootstrap-codeigniter-otel
	. ./setenv.sh && set +a \
    && composer require open-telemetry/transport-grpc


#### profiling tools
webgrind-up:
	docker compose -f docker-compose.webgrind.yaml up -d
webgrind-down:
	docker compose -f docker-compose.webgrind.yaml down


