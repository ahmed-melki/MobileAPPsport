<?php

namespace App\Mail;

use App\Models\Order;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Address;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

/** Sent to the customer right after a successful checkout. */
class OrderConfirmationMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public Order $order)
    {
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            from: new Address(
                (string) config('mail.from.address', 'hello@apex.app'),
                (string) config('mail.from.name', 'Apex')
            ),
            subject: 'Apex - Confirmation de votre commande '.$this->order->order_number,
        );
    }

    public function content(): Content
    {
        $order = $this->order->loadMissing('items', 'user');
        $fmt = fn ($value) => number_format((float) $value, 3, ',', ' ').' DT';

        return new Content(
            view: 'emails.order-confirmation',
            with: [
                'order' => $order,
                'customerName' => $order->shipping_address['fullName'] ?? $order->user?->first_name ?? '',
                'address' => $order->shipping_address ?? [],
                'items' => $order->items->map(fn ($item) => [
                    'name' => $item->product_name,
                    'quantity' => $item->quantity,
                    'unitPrice' => $fmt($item->unit_price),
                    'lineTotal' => $fmt($item->line_total),
                ]),
                'subtotal' => $fmt($order->subtotal),
                'shipping' => (float) $order->shipping == 0.0 ? 'Gratuite' : $fmt($order->shipping),
                'total' => $fmt($order->total),
                'paymentLabel' => $order->payment_method === 'cash_on_delivery' ? 'Paiement à la livraison' : $order->payment_method,
                'date' => $order->created_at?->timezone('Africa/Tunis')->format('d/m/Y à H:i'),
            ],
        );
    }
}
