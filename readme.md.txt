# php-fpm containers sample
## Development only (container registry has images)
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
`./webroot`  
is document root for nginx  

`./webapp`  
is php application root.
`./webapp/public`  
is application webroot for php-fpm fastcgi root called by nginx 

application is able to be placed in `./webapp`


### Build bootstrap image with/without frameworks
- php only
```
make bootstrap
```

- laravel
```
make bootstrap-laravel
```

- laravel + opentelemetry (http)
```
make bootstrap-laravel-otel
```

- laravel + opentelemetry (grpc)
```
make bootstrap-laravel-otel-grpc
```

**Still not include source files, only build image and startup**


### Build image with source files
```bash
make build
```
> default image tag: YYYYMMDD  
> in git repository: YYYYMMDD-<commit-short-hash>  

_configurable in `setenv.sh`
by `IMAGE_TAG`_

### Push image to registry
```
make login USER=xxx PASSWORD=xxx
make push
```


## Containers environment variables
### nginx
- NGINX_ENVSUBST_FILTER=^OTEL_.\*  
  for including OTEL environment variables in nginx.conf
- OTEL_TRACE=on
- OTEL_ENDPOINT=otel-collector.tracing.svc.cluster.local:4317
- OTEL_SERVICE_NAME=smplapp-nginx
- OTEL_TRACE_CONTEXT=propagate

### php-fpm
- XDEBUG_ENABLED=1  
  **enable xdebug(default:0)**  
  _below are for opentelemetry's environment variables_
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
```bash
. ./setenv.sh
#(only once at current shell)
```

```bash
php artisan --version
```

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
