<?php

namespace App\Controllers;

class Test extends BaseController
{
    public function index(): string
    {
        log_message('error', 'this is error level, Test::index() called');
        log_message('debug', 'this is debug level, Test::index() called');
        log_message('info', 'this is info level, Test::index() called');
        return view('test_page1');
    }
}
