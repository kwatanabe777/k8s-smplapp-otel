<?php

namespace App\Controllers;

class Healthcheck extends BaseController
{
    public function index(): string
    {
        log_message('info', 'healthchecked.');
        return "OK";
    }
}
