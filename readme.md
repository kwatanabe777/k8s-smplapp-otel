# php-fpm containers sample
                                                                    by kwatanabe
                                                                    last updated:2024-07-11 19:40.
## Development only (container registry already has images)
- pull & up containers  
```bash
make up
```

- down containers  
```bash
make down
```

## Build nginx+php-fpm containers images

### Configure container build
setenv.sh
```bash
export BUILD_OTEL=1      #enable opentelemetry extension
export BUILD_GRPC=1      #enable grpc extension(so long to build)
export BUILD_PROTOBUF=1  #enable protobuf extension(recommended always on)
```

### webroot
`./webapp`  
will be copied to php-fpm application root.  

`./webapp/public`  
will be copied to public root of nginx  (except for .php files for safe)
& `webapp/public/**/*.php` will be copied to php-fpm.

- application is able to be placed in `./webapp`  
& static files is able to be placed in `./webapp/public`

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

**Still not include application source files, only build image and startup**


### Build image with source files
```bash
make build
```
> default image tag: YYYYMMDD  
> in git repository: YYYYMMDD-\<commit-short-hash\>  

_configurable in `setenv.sh` by `IMAGE_TAG`_  
**:latest** tag is also created.

### Push image to registry
registry & project is defined in .env
CONTAINER_REGISTRY=${CONTAINER_REGISTRY}
PROJECT_NAME=${PROJECT_NAME}
```
make login USER=xxx PASSWORD=xxx
make push
```


## Containers environment variables
### nginx
- NGINX_ENVSUBST_FILTER=\^OTEL_.\*|\^FASTCGI_PARAMS_ADDFILE  
  enable ENV variables substituion filter

- FASTCGI_PARAMS_ADDFILE=fastcgi_params-codeigniter-development  
  Parameters pre-definition file for pass to php-fpm.    
  This file is included at nginx starting.  
  Located in containers/nginx/conf
  - fastcgi_params-codeigniter-development  
    CI_ENVIRONMENT=development
  - fastcgi_params-codeigniter-production  
    CI_ENVIRONMENT=production
  - fastcgi_params-laravel-development  
    APP_ENV=development
  - fastcgi_params-laravel-production  
    APP_ENV=production
  - fastcgi_params-common  
    fastcgi_params-common is always included

  for including OTEL environment variables in nginx.conf
- OTEL_TRACE=on
- OTEL_ENDPOINT=otel-collector.tracing.svc.cluster.local:4317
- OTEL_SERVICE_NAME=smplapp-nginx
- OTEL_TRACE_CONTEXT=propagate

### php-fpm
- XDEBUG_ENABLED=1  
  **enable xdebug(default:0)**  
- XDEBUG_CLIENT_HOST=host.docker.internal
- XDEBUG_CLIENT_PORT=9003
- DEV_ENABLED=1
  php.ini-development or php.ini-production (default:0)

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
pre-defined docker exec wrapped funtions for php & composer command
```bash
. ./setenv.sh
#(only once is needed at current shell)
```
- ex) laravel
```bash
php artisan --version
```

- composer
```bash
composer --version
```

## Additional
webgrind php-profiling tool at :8088  
and mount ./xdebug directory
```make
make webgrind-up
make webgrind-down
```

