<?php

namespace App\Commands;

use Illuminate\Console\Command;
use Illuminate\Database\Console\Migrations\MigrateCommand;
use Illuminate\Database\Console\WipeCommand;
use Symfony\Component\Console\Input\InputOption;

class SetupDbCommand extends Command
{
    /**
     * @var string
     */
    protected $name = "app:setup-db";

    /**
     * @var string
     */
    protected $description = "Run the application database setup";

    /**
     * @return array<array{?string, ?string, InputOption::*, string}>
     */
    protected function getOptions(): array
    {
        return [
            [
                "drop",
                null,
                InputOption::VALUE_NONE,
                "If given, the existing database tables are dropped and recreated.",
            ],
        ];
    }

    public function handle(): void
    {
        $drop = $this->option("drop");
        if ($drop) {
            $this->info("Dropping all database tables...");

            $this->call(WipeCommand::class);

            $this->info("Done.");
        }

        $this->info("Running database migrations...");

        $this->call(MigrateCommand::class);

        $this->info("Done.");
    }
}
