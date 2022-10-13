<?php

namespace App\Domain;

use Psr\Log\LoggerInterface;
use Psr\Log\LoggerTrait;

class Logger implements LoggerInterface
{
    use LoggerTrait;

    public function __construct(
        private LoggerInterface $logger,
        private array $defaultContext = []
    ) {
    }

    public function log($level, string|\Stringable $message, array $context = []): void
    {
        $context = array_replace($this->defaultContext, $context);
        $this->logger->log($level, $message, $context);
    }
}
