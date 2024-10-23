# php-fpm containers sample
                                                                    by kwatanabe
                                                                    last updated:2024-10-23 15:23.

## Overview
- php-fpm & nginx containers with opentelemetry extension(with grpc/protobuf)
- php-fpm communicates with nginx via fastcgi unix domain socket
- configurable Xdebug extension
- php web frameworks: Laravel, Codeigniter is supported
- with image build & composer tools


## Development only (if container registry already has images)
if use remote registry, setenv.sh is needed to be configured.
```
PROJECT_NAME=
CONTAINER_REGISTRY=
IMAGE_NAME_WEB=
IMAGE_NAME_APP=
IMAGE_TAG=
```
IMAGE_TAG is autoconfigured if not set.  
But, If the local image cache is empty and the image is to be retrieved remotely, such as the first time pull, IMAGE_TAG must be set.  
IMAGE_TAG is common for both web & app images.

- pull & up containers  
```bash
make up
```

- down containers  
```bash
make down
```

## Build nginx+php-fpm containers images

### Configure php-fpm container build
setenv.sh
```bash
export BUILD_OTEL=1      #enable opentelemetry extension
export BUILD_GRPC=1      #enable grpc extension(take so long time to build)
export BUILD_PROTOBUF=1  #enable protobuf extension(recommended always on)
```

### webroot
`./webapp`  
will be copied to php-fpm application root.  

`./webapp/public`  
will be copied to public root of nginx  
(except for .php files for safe, eg. `webapp/public/**/*.php` will be copied to php-fpm.)

- application is able to be placed in `./webapp`  
  static files is able to be placed in `./webapp/public`

### Build bootstrap image with/without frameworks
clean up entirely under webapp directory & do
- php only
```
make bootstrap
```

- laravel/codeigniter
```
make bootstrap-{laravel, codeigniter}
```

- laravel/codeigniter + opentelemetry (http)
```
make bootstrap-{laravel, codeigniter}-otel
```

- laravel/codeigniter + opentelemetry (grpc)
```
make bootstrap-{laravel, codeigniter}-otel-grpc
```

**Note: At this point, the image does not yet contain the application,  
only the php container is started to execute the php/composer command to install the framework**

### Build image with source files
```bash
make build
```
> default image tag: YYYYMMDD  
> in git repository: YYYYMMDD-\<commit-short-hash\>  

_configurable in `setenv.sh` by `IMAGE_TAG`_  
**:latest** tag is also created.

### Push image to registry
registry & project is defined in setenv.sh  
project_name is container registry project name such as `gcr.io/xxxxx`.
```
CONTAINER_REGISTRY=  
PROJECT_NAME=  
```
```
make login USER=xxx PASSWORD=xxx
make push
```


## Containers configurable runtime environment variables
### nginx
- NGINX_ENVSUBST_FILTER=\^NGINX_.\*|\^OTEL_.\*|\^FASTCGI_.\*
  enable ENV variables substituion filter

- NGINX_LISTEN_PORT
- NGINX_PROXY_READ_TIMEOUT
- NGINX_PROXY_CONNECT_TIMEOUT
- NGINX_PROXY_SEND_TIMEOUT
- FASTCGI_READ_TIMEOUT
- FASTCGI_PARAMS_ADDFILE=fastcgi_params-codeigniter-development  
  Parameters pre-definition file for pass to php-fpm via SAPI.  
  This file is included at nginx starting.  
  Located in containers/nginx/conf
  - fastcgi_params-codeigniter-development  
    CI_ENVIRONMENT=development
  - fastcgi_params-codeigniter-staging  
    CI_ENVIRONMENT=staging
  - fastcgi_params-codeigniter-production  
    CI_ENVIRONMENT=production
  - fastcgi_params-laravel-development  
    APP_ENV=development
  - fastcgi_params-laravel-staging  
    APP_ENV=staging
  - fastcgi_params-laravel-production  
    APP_ENV=production
  - empty  
	no additional parameters
  - fastcgi_params-common  
    fastcgi_params-common is always included

_for including OTEL environment variables in nginx.conf_
- OTEL_TRACE=on
- OTEL_ENDPOINT=otel-collector.tracing.svc.cluster.local:4317
- OTEL_SERVICE_NAME=smplapp-nginx
- OTEL_TRACE_CONTEXT=propagate

### php-fpm
- DEV_ENABLED=1
  php.ini-development or php.ini-production (default:0)
- XDEBUG_ENABLED=1  
  **enable xdebug(default:0) & JIT is disabled by php**  
- XDEBUG_CLIENT_HOST=host.docker.internal
- XDEBUG_CLIENT_PORT=9003

_belows are for php-fpm tuning parameters(if needed)_
- PM_MAX_CHILDREN=5
- PM_START_SERVERS=2
- PM_MIN_SPARE_SERVERS=1
- PM_MAX_SPARE_SERVERS=2
- PM_MAX_SPAWN_RATE=2
- PM_PROCESS_IDLE_TIMEOUT=10s
- PM_MAX_REQUESTS=500

_belows are for opentelemetry's environment variables_
- OTEL_PHP_AUTOLOAD_ENABLED=true
- OTEL_SERVICE_NAME=smplapp-app
- OTEL_TRACES_EXPORTER=otlp/console/none  
**TRANSPORTER PROTOCOLS: http/json, http/protobuf, grpc**
- OTEL_EXPORTER_OTLP_PROTOCOL=http/json / http/protobuf grpc
- OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.tracing.svc.cluster.local:4317
- OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector.tracing.svc.cluster.local:4318
- OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://otel-collector.tracing.svc.cluster.local:4317/v1/traces
- OTEL_EXPORTER_OTLP_METRICS_ENDPOINT=http://otel-collector.tracing.svc.cluster.local:4317/v1/metrics
- OTEL_METRICS_EXPORTER=otlp/console/one
- OTEL_LOGS_EXPORTER=none
- OTEL_PROPAGATORS="baggage,tracecontext"

## Use php & composer command
pre-defined docker compose/kubectl exec wrapped funtions for php & composer commands executing inside container.  
or if k8s environment, set CMD_ENV to "k8s" in setenv.sh  
or otherwise (docker environment) set CMD_ENV to empty in setenv.sh.  
**If you want to bootstrap the image,  
Note that CMD_ENV must be empty to run the composer command because docker is required.**
```bash
. ./setenv.sh
#(only once is needed at current shell)
```

- ex) laravel
```bash
php artisan --version
```
- ex) codeigniter
```bash
php spark list
```

- composer
```bash
composer --version
```

- Generate php binaray wrapper for upstream development tools (eg. vscode) if needed
```bash
create_wrapper
./php --version
```
Can be relocated to directories within valid PATH variables.  
if you changed variables in setenv.sh, you need to run create_wrapper again for recreation.

## Additional
webgrind php-profiling tool at :8088  
and mount ./xdebug directory  
(Current webgrind has glitches and does not work perfectly)
```make
make webgrind-up
make webgrind-down
```

