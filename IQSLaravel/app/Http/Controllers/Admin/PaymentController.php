<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\PaymentAdminResource;
use App\Http\Resources\Admin\WebhookAdminResource;
use App\Models\Payment;
use App\Models\PaymentWebhook;
use App\Services\Payment\PaymentService;
use App\Support\Enums\PaymentStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Spatie\QueryBuilder\AllowedFilter;
use Spatie\QueryBuilder\QueryBuilder;

class PaymentController extends Controller
{
    public function __construct(private readonly PaymentService $payments) {}

    public function index(Request $request): JsonResponse
    {
        $payments = QueryBuilder::for(Payment::class)
            ->allowedFilters([
                AllowedFilter::exact('status'),
                AllowedFilter::exact('gateway'),
                AllowedFilter::exact('user_id'),
                AllowedFilter::partial('payment_number'),
            ])
            ->allowedSorts(['created_at', 'amount', 'paid_at'])
            ->defaultSort('-created_at')
            ->with('user')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(PaymentAdminResource::collection($payments));
    }

    public function webhooks(Request $request): JsonResponse
    {
        $webhooks = PaymentWebhook::query()
            ->when($request->filled('gateway'), fn ($q) => $q->where('gateway', $request->string('gateway')))
            ->when($request->filled('processed'), fn ($q) => $q->where('processed', $request->boolean('processed')))
            ->latest('created_at')
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(WebhookAdminResource::collection($webhooks));
    }

    public function show(Payment $payment): JsonResponse
    {
        return $this->ok(new PaymentAdminResource($payment->load('user', 'webhooks')));
    }

    public function refund(Payment $payment): JsonResponse
    {
        if ($payment->status !== PaymentStatus::Paid) {
            return $this->fail(__('Only paid payments can be refunded.'), null, 422);
        }

        $this->payments->refund($payment);

        return $this->ok(new PaymentAdminResource($payment->fresh()->load('user')), __('Payment refunded.'));
    }
}
