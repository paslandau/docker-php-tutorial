<?php

namespace App\Commands;

use Illuminate\Console\Command;
use Illuminate\Database\Console\Migrations\MigrateCommand;
use Illuminate\Database\Console\WipeCommand;
use Psr\Log\LoggerInterface;
use Symfony\Component\Console\Input\InputOption;

class TriggerJobCommand extends Command
{
    /**
     * @var string
     */
    protected $name = "app:trigger-job";

    /**
     * @var string
     */
    protected $description = "Trigger a job from the web interface";

    /**
     * @return array<array{?string, ?string, InputOption::*, string}>
     */
    protected function getOptions(): array
    {
        return [
            [
                "job-id",
                null,
                InputOption::VALUE_OPTIONAL,
                "The id of the job",
                "_NO_ID_GIVEN_",
            ],
        ];
    }

    public function handle(LoggerInterface $logger): void
    {
        $jobId = $this->option("job-id");
        \assert(is_string($jobId));

        $logger->info("Calling php-fpm to insert job '$jobId'");
        $result = file_get_contents("http://nginx/?dispatch=" . urlencode($jobId));
        $logger->info("Result:" . $result);
        $this->info("Inserted job '$jobId' via UI");
    }
}
