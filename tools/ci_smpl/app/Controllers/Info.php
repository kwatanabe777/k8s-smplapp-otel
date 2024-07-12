<?php

namespace App\Controllers;

class Info extends BaseController
{
    public function index(): string
    {
        //return view('welcome_message');
        return phpinfo();
    }
}
