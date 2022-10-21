<?php

namespace App\Domain;

use Psr\Log\LoggerInterface;
use Psr\Log\LoggerTrait;

class Logger implements LoggerInterface
{
    use LoggerTrait;

    /**
     * @param LoggerInterface $logger
     * @param array<string, mixed> $defaultContext
     */
    public function __construct(
        private LoggerInterface $logger,
        private array $defaultContext = []
    ) {
    }

    /**
     * @param array<string, mixed> $context
     */
    public function log($level, string|\Stringable $message, array $context = []): void
    {
        $context = array_replace($this->defaultContext, $context);
        $this->logger->log($level, $message, $context);
    }
}
