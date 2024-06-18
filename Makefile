###########################
# containers operation
#
.PHONY: build up down login push
SHELL := /bin/bash #/bin/sh cannnot receive args at . ./setenv.sh
build:
	@. ./setenv.sh new \
    && set +a \
    && docker compose -f docker-compose.build.yaml build --progress plain \
    && IMAGE_TAG=latest && docker compose -f docker-compose.build.yaml build --progress plain

up:
	@. ./setenv.sh \
    && set +a \
    && docker compose up -d \

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
#
#### psr
#psr3: logger interface
#psr14: event dispatcher
#psr15: http server request handlers
#psr16: common interface for cache libraries
#psr18: http client
bootstrap-laravel: build up
	. ./setenv.sh && set +a \
    && composer create-project laravel/laravel .

bootstrap-laravel-otel: build up bootstrap-laravel
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

bootstrap-laravel-otel-grpc: build up bootstrap-laravel-otel
	. ./setenv.sh && set +a \
    && composer require open-telemetry/transport-grpc


bootstrap-codeigniter: build up
	. ./setenv.sh && set +a \
    && composer create-project codeigniter4/appstarter .

bootstrap-codeigniter-otel: build up bootstrap-codeigniter
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

bootstrap-codeigniter-otel-grpc: build up bootstrap-codeigniter-otel
	. ./setenv.sh && set +a \
    && composer require open-telemetry/transport-grpc


#### profiling tools
webgrind-up:
	docker compose -f docker-compose.webgrind.yaml up -d
webgrind-down:
	docker compose -f docker-compose.webgrind.yaml down


