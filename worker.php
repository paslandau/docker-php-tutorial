<?php
/**
 * @var Redis $redis
 * @var PDO $pdo
 */
[$redis, $pdo] = require_once __DIR__."/dependencies.php";

while (true) {
    $value = $redis->rPop("queue");
    if ($value !== false) {
        echo "Got value $value\n";
        $pdo->exec("INSERT INTO jobs VALUES('$value')");
        echo "Inserted!\n";
    }
    sleep(1);
}