<?php
/**
 * @var PDO $pdo
 */
[, $pdo] = require_once __DIR__."/dependencies.php";

$options = getopt("d", ["drop"]);
$drop = $options["d"] ?? $options["drop"] ?? null;
if ($drop !== null) {
    echo "Dropping table 'jobs'\n";
    $pdo->exec("DROP TABLE IF EXISTS jobs");
    echo "Done\n";
}

echo "Creating table 'jobs'\n";
$pdo->exec("CREATE TABLE IF NOT EXISTS jobs (value VARCHAR(255) CHARACTER SET utf8)");
echo "Done\n";
