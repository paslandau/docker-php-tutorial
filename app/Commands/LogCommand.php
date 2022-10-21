<?php

namespace App\Commands;

use Illuminate\Console\Command;
use Illuminate\Database\Console\Migrations\MigrateCommand;
use Illuminate\Database\Console\WipeCommand;
use Psr\Log\LoggerInterface;
use Symfony\Component\Console\Input\InputOption;
use Webmozart\Assert\Assert;

class LogCommand extends Command
{
    /**
     * @var string
     */
    protected $name = "app:log";

    /**
     * @var string
     */
    protected $description = "Write a line in the application log";

    /**
     * @return array<array{?string, ?string, InputOption::*, string}>
     */
    protected function getOptions(): array
    {
        return [
            [
                "message",
                null,
                InputOption::VALUE_OPTIONAL,
                "If given, the message is written in the log file",
                "_NO MESSAGE_"
            ],
        ];
    }

    public function handle(LoggerInterface $logger): void
    {
        $message = $this->option("message");
        \assert(is_string($message));

        $logger->info($message);
    }
}
