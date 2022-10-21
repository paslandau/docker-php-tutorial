<?php

namespace App\Providers;

use App\Commands\LogCommand;
use App\Commands\SetupDbCommand;
use App\Commands\TriggerJobCommand;
use Illuminate\Contracts\Config\Repository;
use Illuminate\Log\Logger;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;
use Psr\Log\LoggerInterface;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        $this->commands([
            SetupDbCommand::class,
            LogCommand::class,
            TriggerJobCommand::class,
        ]);

        $this->mergeConfigFrom(__DIR__ . "/../../config/custom.php", "custom");

        /**
         * Note:
         * We are using our own Logger class to apply a default context for each log line
         * because the Laravel-native `Log::shareContext()` did not work when running in
         * a PHP worker controlled via supervisor.
         *
         * @see https://laravel.com/docs/9.x/logging#contextual-information
         */
        $this->app->singleton(LoggerInterface::class, function () {
            /**
             * @var LoggerInterface $log
             */
            $log = $this->app->get("log");

            /**
             * @var Repository $config
             */
            $config = $this->app->get(Repository::class);

            $serviceName    = (string) $config->get("custom.service");
            $defaultContext = [
                'pid'     => getmypid(),
                'service' => $serviceName,
            ];
            return new \App\Domain\Logger($log, $defaultContext);
        });
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
    }
}
