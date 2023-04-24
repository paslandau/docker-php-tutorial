<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\DatabaseManager;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;

class InsertInDbJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;

    public function __construct(
        public readonly string $jobId
    ) {
    }

    public function handle(DatabaseManager $databaseManager): void
    {
        $databaseManager->insert("INSERT INTO `jobs`(value) VALUES(?)", [$this->jobId]);
    }
}
