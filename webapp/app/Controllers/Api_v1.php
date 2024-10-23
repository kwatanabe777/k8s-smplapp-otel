<?php

namespace App\Controllers;

use CodeIgniter\API\ResponseTrait;
use CodeIgniter\Controller;

use GuzzleHttp;
use PDO;

class Api_v1 extends Controller
{
    use ResponseTrait;

    public function http()
    {
        log_message('info', 'Api_v1::http() called');

        $form = ['fizz' => 'buzz'];
        $client = new GuzzleHttp\Client();
        $r = $client->post('http://httpbin.org/post', [
            'headers' => [
                'X-Foo' => 'Bar'
            ],
            'form_params' => $form,
            'sink' => '/tmp/savefile.output',
        ]);

        //return view('api_v1', ['response' => $r->getBody()] );
        return $this->respond(json_decode($r->getBody()));
    }

    public function db()
    {
        log_message('info', 'pdo query, Api_v1::db() called');

        // codeigniter postgre (not supported by opentelemetry)
        //$db = \Config\Database::connect('default');
        //$query = $db->query('SELECT current_timestamp');
        //$result = $query->getResultArray();

        // pdo-pgsql
        $dsn_exp = 'pgsql:host='  .getenv('APP_JHOTEL_DBHOST').' options=\'--client_encoding=UTF8\''
                   .';port='      .getenv('APP_JHOTEL_DBPORT')
                   .';dbname='    .getenv('APP_JHOTEL_DBNAME')
                   .';user='      .getenv('APP_JHOTEL_DBUSER')
                   .';password='  .getenv('APP_JHOTEL_DBPASS');
        $dbh = new PDO($dsn_exp);
        $stmt = $dbh->query('SELECT agt_id, xpath(\'/root/crp_nam/child::text()\', vw_info) as crp_nam from jhotel_mst_agent LIMIT 100');
        $result = $stmt->fetchAll(PDO::FETCH_ASSOC);

        return $this->respond($result);
    }
}
