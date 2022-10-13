<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\DatabaseManager;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Psr\Log\LoggerInterface;

class InsertInDbJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;

    public function __construct(
        public readonly string $jobId
    ) {
    }

    public function handle(DatabaseManager $databaseManager, LoggerInterface $logger): void
    {
        $logger->info("Inserting a job '{$this->jobId}'");
        $databaseManager->insert("INSERT INTO `jobs`(value) VALUES(?)", [$this->jobId]);
    }
}
