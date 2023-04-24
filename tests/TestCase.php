<?php

namespace Tests;

use App\Commands\SetupDbCommand;
use Illuminate\Database\Connectors\MySqlConnector;
use Illuminate\Database\DatabaseManager;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Queue\Console\ClearCommand;
use Illuminate\Queue\QueueManager;
use PDOException;
use RuntimeException;

abstract class TestCase extends BaseTestCase
{
    use CreatesApplication;

    /**
     * @template T
     * @param class-string<T> $className
     * @return T
     */
    protected function getDependency(string $className)
    {
        return $this->app->get($className);
    }

    protected function setupDatabase(): void
    {
        $databaseManager = $this->getDependency(DatabaseManager::class);

        $actualConnection  = $databaseManager->getDefaultConnection();
        $testingConnection = "testing";
        if ($actualConnection !== $testingConnection) {
            throw new RuntimeException("Database tests are only allowed to run on default connection '$testingConnection'. The current default connection is '$actualConnection'.");
        }

        $this->ensureDatabaseExists($databaseManager);

        $this->artisan(SetupDbCommand::class, ["--drop" => true]);
    }

    protected function setupQueue(): void
    {
        $queueManager = $this->getDependency(QueueManager::class);

        $actualDriver  = $queueManager->getDefaultDriver();
        $testingDriver = "testing";
        if ($actualDriver !== $testingDriver) {
            throw new RuntimeException("Queue tests are only allowed to run on default driver '$testingDriver'. The current default driver is '$actualDriver'.");
        }

        $this->artisan(ClearCommand::class);
    }

    protected function ensureDatabaseExists(DatabaseManager $databaseManager): void
    {
        $connection = $databaseManager->connection();

        try {
            $connection->getPdo();
        } catch (PDOException $e) {
            // e.g. SQLSTATE[HY000] [1049] Unknown database 'testing'
            if ($e->getCode() !== 1049) {
                throw $e;
            }
            /**
             * @var array<string, mixed> $config
             */
            $config             = $connection->getConfig();
            $config["database"] = "";

            $connector = new MySqlConnector();
            $pdo       = $connector->connect($config);
            $database  = $connection->getDatabaseName();
            $pdo->exec("CREATE DATABASE IF NOT EXISTS `{$database}`;");
        }
    }
}
