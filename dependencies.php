<?php

$redis = new Redis();
$redis->connect("redis");
$redis->auth('secret_redis_password');
$redis->select(0);

$dsn      = 'mysql:dbname=application_db;host=mysql';
$user     = 'root';
$password = 'secret_mysql_root_password';
$pdo      = new PDO($dsn, $user, $password);

return [$redis, $pdo];
