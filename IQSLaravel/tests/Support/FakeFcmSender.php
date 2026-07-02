<?php

namespace Tests\Support;

use App\Services\Notification\FcmSender;

/**
 * Records pushes and simulates invalid tokens for the notification tests.
 */
class FakeFcmSender implements FcmSender
{
    /** @var list<string> */
    public array $sentTokens = [];

    /** @var list<string> */
    public array $invalidTokens = [];

    public int $calls = 0;

    public function send(array $tokens, string $title, string $body, array $data = [], ?string $image = null): array
    {
        $this->calls++;
        $this->sentTokens = array_merge($this->sentTokens, $tokens);

        return array_values(array_intersect($tokens, $this->invalidTokens));
    }
}
