<?php

namespace Tests\Feature\App\Http\Controllers;

use App\Jobs\InsertInDbJob;
use Illuminate\Database\DatabaseManager;
use Illuminate\Queue\QueueManager;
use Illuminate\Routing\UrlGenerator;
use Tests\TestCase;

class HomeControllerTest extends TestCase
{
    public function setUp(): void
    {
        parent::setUp();

        $this->setupDatabase();
        $this->setupQueue();
    }

    /**
     * @dataProvider __invoke_dataProvider
     * @param array<string> $params
     */
    public function test___invoke(array $params, string $expected): void
    {
        $urlGenerator = $this->getDependency(UrlGenerator::class);

        $url = $urlGenerator->route("home", $params);

        $response = $this->get($url);

        $response
            ->assertStatus(200)
            ->assertSee($expected, false)
        ;
    }

    /**
     * @return array<string, mixed>
     */
    public function __invoke_dataProvider(): array
    {
        return [
            "default"           => [
                "params"   => [],
                "expected" => <<<TEXT
                        <li><a href="?dispatch=foo">Dispatch job 'foo' to the queue.</a></li>
                        <li><a href="?queue">Show the queue.</a></li>
                        <li><a href="?db">Show the DB.</a></li>
                    TEXT
                ,
            ],
            "database is empty" => [
                "params"   => ["db"],
                "expected" => <<<TEXT
                        Items in db
                    array (
                    )
                    TEXT
                ,
            ],
            "queue is empty"    => [
                "params"   => ["queue"],
                "expected" => <<<TEXT
                        Items in queue
                    array (
                    )
                    TEXT
                ,
            ],
        ];
    }

    public function test_shows_existing_items_in_database(): void
    {
        $databaseManager = $this->getDependency(DatabaseManager::class);

        $databaseManager->insert("INSERT INTO `jobs` (id, value) VALUES(1, 'foo');");

        $urlGenerator = $this->getDependency(UrlGenerator::class);

        $params = ["db"];
        $url    = $urlGenerator->route("home", $params);

        $response = $this->get($url);

        $expected = <<<TEXT
                Items in db
            array (
              0 => 
              (object) array(
                 'id' => 1,
                 'value' => 'foo',
              ),
            )
            TEXT;

        $response
            ->assertStatus(200)
            ->assertSee($expected, false)
        ;
    }

    public function test_shows_existing_items_in_queue(): void
    {
        $queueManager = $this->getDependency(QueueManager::class);

        $job = new InsertInDbJob("foo");
        $queueManager->push($job);

        $urlGenerator = $this->getDependency(UrlGenerator::class);

        $params = ["queue"];
        $url    = $urlGenerator->route("home", $params);

        $response = $this->get($url);

        $expectedJobsCount = <<<TEXT
                Items in queue
            array (
              0 => '{
            TEXT;

        $expected = <<<TEXT
            \\\\"jobId\\\\";s:3:\\\\"foo\\\\";
            TEXT;

        $response
            ->assertStatus(200)
            ->assertSee($expectedJobsCount, false)
            ->assertSee($expected, false)
        ;
    }
}
