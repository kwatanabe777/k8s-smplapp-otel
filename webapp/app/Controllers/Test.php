<?php

namespace App\Controllers;

use PDO;

class Test extends BaseController
{
    public function index(): string
    {
        log_message('info', 'Posrgre query, Test::index() called');

        // codeigniter postgre (not supported by opentelemetry)
        $db = \Config\Database::connect('default');
        $query = $db->query('SELECT current_timestamp');
        $result = $query->getResultArray();
        
        //// pdo-pgsql
        //$dsn_exp = 'pgsql:host='  .getenv('APP_JHOTEL_DBHOST').' options=\'--client_encoding=UTF8\''
        //           .';port='      .getenv('APP_JHOTEL_DBPORT')
        //           .';dbname='    .getenv('APP_JHOTEL_DBNAME')
        //           .';user='      .getenv('APP_JHOTEL_DBUSER')
        //           .';password='  .getenv('APP_JHOTEL_DBPASS');
        //$dbh = new PDO($dsn_exp);
        //$stmt = $dbh->query('SELECT agt_id, xpath(\'/root/crp_nam/child::text()\', vw_info) as crp_nam from jhotel_mst_agent LIMIT 100');
        //$result = $stmt->fetchAll(PDO::FETCH_ASSOC);

        //return view('test_page1', ['query_result' => json_encode($result)] );
        return view('test_page1', ['query_result' => ($result)] );
    }

}
