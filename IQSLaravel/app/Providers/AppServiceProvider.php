<?php

namespace App\Providers;

use App\Services\ApiFootball\ApiFootballClient;
use App\Services\Notification\FcmSender;
use App\Services\Notification\KreaitFcmSender;
use App\Services\Notification\LogFcmSender;
use App\Services\Sms\LogOtpSender;
use App\Services\Sms\OtpSender;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Resolve the OTP sender from the configured driver (config/otp.php).
        $this->app->bind(OtpSender::class, function (): OtpSender {
            return match (config('otp.driver')) {
                'log' => new LogOtpSender,
                default => new LogOtpSender,
            };
        });

        // FCM transport driver (config/services.php fcm.driver).
        $this->app->bind(FcmSender::class, function (): FcmSender {
            return match (config('services.fcm.driver')) {
                'kreait', 'fcm' => new KreaitFcmSender,
                default => new LogFcmSender,
            };
        });

        // API-Football v3 HTTP client (§2.4).
        $this->app->singleton(ApiFootballClient::class, function (): ApiFootballClient {
            $config = config('services.api_football');

            return new ApiFootballClient(
                key: $config['key'] ?? null,
                baseUrl: $config['base_url'],
                timezone: $config['timezone'],
                dailyLimit: (int) $config['daily_limit'],
            );
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // super-admin bypasses every gate/permission check (§1.3).
        Gate::before(function ($user, string $ability) {
            return method_exists($user, 'hasRole') && $user->hasRole('super-admin') ? true : null;
        });
    }
}
