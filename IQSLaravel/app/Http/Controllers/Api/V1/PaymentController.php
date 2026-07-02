<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\Payable;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\InitiatePaymentRequest;
use App\Http\Resources\PaymentResource;
use App\Models\Payment;
use App\Services\Payment\PaymentException;
use App\Services\Payment\PaymentService;
use App\Support\Enums\PaymentGatewayType;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function __construct(private readonly PaymentService $payments) {}

    public function index(Request $request): JsonResponse
    {
        $payments = Payment::query()
            ->where('user_id', $request->user()->id)
            ->latest()
            ->paginate($this->perPage($request))
            ->appends($request->query());

        return $this->ok(PaymentResource::collection($payments));
    }

    public function initiate(InitiatePaymentRequest $request): JsonResponse
    {
        $payable = $this->resolvePayable($request->string('payable_type'), $request->integer('payable_id'));

        if ($payable === null) {
            return $this->fail(__('The item to pay for could not be found.'), null, 404);
        }

        if ($payable->getPayerId() !== $request->user()->id) {
            return $this->fail(__('This item is not payable by you.'), null, 403);
        }

        try {
            $payment = $this->payments->initiate(
                $payable,
                PaymentGatewayType::from($request->string('gateway')),
                $request->user(),
            );
        } catch (PaymentException $e) {
            return $this->fail($e->getMessage(), null, 502);
        }

        return $this->created(new PaymentResource($payment), __('Payment created.'));
    }

    public function status(Request $request, string $number): JsonResponse
    {
        $payment = Payment::query()
            ->where('payment_number', $number)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        return $this->ok(new PaymentResource($payment));
    }

    /**
     * Resolve a payable model from its API key (config/payments.php).
     */
    protected function resolvePayable(string $key, int $id): ?Payable
    {
        $class = config('payments.payables.'.$key);

        if (! is_string($class) || ! class_exists($class)) {
            return null;
        }

        $model = $class::find($id);

        return $model instanceof Payable ? $model : null;
    }
}
