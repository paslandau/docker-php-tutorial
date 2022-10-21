<?php

namespace App\Http\Controllers;

use App\Jobs\InsertInDbJob;
use Illuminate\Contracts\View\Factory;
use Illuminate\Contracts\View\View;
use Illuminate\Database\DatabaseManager;
use Illuminate\Foundation\Bus\DispatchesJobs;
use Illuminate\Http\Request;
use Illuminate\Queue\QueueManager;
use Illuminate\Queue\RedisQueue;
use Illuminate\Routing\Controller;
use Psr\Log\LoggerInterface;
use Redis;

class HomeController extends Controller
{
    use DispatchesJobs;

    public function __construct(private readonly Factory $factory)
    {
    }

    public function __invoke(
        Request $request,
        QueueManager $queueManager,
        DatabaseManager $databaseManager,
        LoggerInterface $logger
    ): View {
        $logger->info("Handling HTTP request: " . $request->getUri());

        /**
         * @var string|null $jobId
         */
        $jobId = $request->input("dispatch") ?? null;
        if ($jobId !== null) {
            $job = new InsertInDbJob($jobId);
            $this->dispatch($job);

            return $this->getView("Adding item '$jobId' to queue");
        }

        if ($request->has("queue")) {

            /**
             * @var RedisQueue $redisQueue
             */
            $redisQueue = $queueManager->connection();
            $redis      = $redisQueue->getRedis()->connection();
            /**
             * @var Redis $redis
             */
            $queueItems = $redis->lRange("queues:default", 0, 99999);

            $content = "Items in queue\n" . var_export($queueItems, true);

            return $this->getView($content);
        }

        if ($request->has("db")) {
            $items = $databaseManager->select($databaseManager->raw("SELECT * FROM jobs"));

            $content = "Items in db\n" . var_export($items, true);

            return $this->getView($content);
        }
        $content = <<<HTML
            <ul>
                <li><a href="?dispatch=foo">Dispatch job 'foo' to the queue.</a></li>
                <li><a href="?queue">Show the queue.</a></li>
                <li><a href="?db">Show the DB.</a></li>
                <li><a href="/info">Show the build info.</a></li>
            </ul>
            HTML;

        return $this->getView($content);
    }

    private function getView(string $content): View
    {
        return $this->factory->make('home')->with(["content" => $content]);
    }
}
