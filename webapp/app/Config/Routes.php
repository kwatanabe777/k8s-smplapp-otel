<?php

use CodeIgniter\Router\RouteCollection;

/**
 * @var RouteCollection $routes
 */
$routes->get('/', 'Home::index');

$routes->get('/healthcheck', 'Healthcheck::index');

$routes->get('/info', 'Info::index');

$routes->get('/test', 'Test::index');
