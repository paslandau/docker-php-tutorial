<?php
error_reporting(E_ALL | E_STRICT);
ini_set('display_errors', 1);

/**
 * @var Redis $redis
 * @var PDO $pdo
 */
[$redis, $pdo] = require_once __DIR__."/../dependencies.php";

$jobId = $_GET["dispatch"] ?? null;
if ($jobId !== null) {
    echo "Adding item '$jobId' to queue\n";
    $redis->lPush("queue", $jobId);
}
elseif (isset($_GET["queue"])) {
    echo "Items in queue\n";
    var_dump($redis->lRange("queue", 0, 9999999));
}
elseif (isset($_GET["db"])) {
    $stmt = $pdo->query("SELECT * FROM jobs");
    echo "Items in db\n";
    var_dump($stmt->fetchAll(PDO::FETCH_COLUMN));
}else{
    echo <<<HTML
        <ul>
            <li><a href="?dispatch=foo">Dispatch job 'foo' to the queue.</a></li>
            <li><a href="?queue">Show the queue.</a></li>
            <li><a href="?db">Show the DB.</a></li>
        </ul>
        HTML;
}
