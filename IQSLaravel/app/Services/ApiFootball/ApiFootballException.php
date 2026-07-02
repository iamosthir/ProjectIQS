<?php

namespace App\Services\ApiFootball;

use RuntimeException;

class ApiFootballException extends RuntimeException
{
    public function __construct(string $message, public readonly bool $rateLimited = false)
    {
        parent::__construct($message);
    }
}
