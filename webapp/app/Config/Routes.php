<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */
$routes->get('/', 'Home::index');

$routes->get('/healthcheck', 'Healthcheck::index');

$routes->get('/info', 'Info::index');

$routes->get('/test', 'Test::index');

$routes->get('/api/v1/http', 'Api_v1::http');
$routes->get('/api/v1/db', 'Api_v1::db');

