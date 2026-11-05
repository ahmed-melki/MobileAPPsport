<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Apex - Confirmation de commande</title>
</head>
<body style="margin:0; padding:0; background-color:#0f172a; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color:#f8fafc;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#0f172a; padding:32px 12px;">
    <tr>
        <td align="center">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:580px; background-color:#1e293b; border-radius:18px; border:1px solid #334155; overflow:hidden;">
                {{-- Header --}}
                <tr>
                    <td style="background:linear-gradient(135deg,#1e293b,#0f172a); padding:28px 28px 20px; text-align:center; border-bottom:1px solid #334155;">
                        <div style="font-size:26px; font-weight:800; letter-spacing:3px; color:#38bdf8;">APEX</div>
                        <div style="margin-top:18px; display:inline-block; background-color:rgba(74,222,128,0.12); border:1px solid #4ade80; color:#4ade80; border-radius:999px; padding:6px 16px; font-size:13px; font-weight:700;">
                            ✓ Commande bien reçue
                        </div>
                        <div style="margin-top:16px; font-size:20px; font-weight:700; color:#f1f5f9;">Merci {{ $customerName }} !</div>
                        <div style="margin-top:6px; font-size:14px; color:#94a3b8; line-height:1.6;">
                            Nous avons bien reçu votre commande. Elle est en cours de préparation et vous serez contacté avant la livraison.
                        </div>
                    </td>
                </tr>

                {{-- Order meta --}}
                <tr>
                    <td style="padding:20px 28px 4px;">
                        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#0f172a; border:1px solid #334155; border-radius:12px;">
                            <tr>
                                <td style="padding:14px 16px; font-size:12px; color:#64748b;">N° de commande<br><span style="font-size:16px; font-weight:800; color:#38bdf8; font-family:monospace;">{{ $order->order_number }}</span></td>
                                <td style="padding:14px 16px; font-size:12px; color:#64748b; text-align:right;">Date<br><span style="font-size:14px; font-weight:600; color:#e2e8f0;">{{ $date }}</span></td>
                            </tr>
                        </table>
                    </td>
                </tr>

                {{-- Items --}}
                <tr>
                    <td style="padding:20px 28px 0;">
                        <div style="font-size:13px; font-weight:700; color:#94a3b8; letter-spacing:1px; text-transform:uppercase; padding-bottom:10px;">Vos articles</div>
                        <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                            @foreach ($items as $item)
                                <tr>
                                    <td style="padding:12px 0; border-bottom:1px solid #334155;">
                                        <div style="font-size:15px; font-weight:600; color:#f1f5f9;">{{ $item['name'] }}</div>
                                        <div style="font-size:12px; color:#64748b; margin-top:3px;">{{ $item['quantity'] }} × {{ $item['unitPrice'] }}</div>
                                    </td>
                                    <td style="padding:12px 0; border-bottom:1px solid #334155; text-align:right; font-size:15px; font-weight:700; color:#f1f5f9; white-space:nowrap;">{{ $item['lineTotal'] }}</td>
                                </tr>
                            @endforeach
                        </table>
                    </td>
                </tr>

                {{-- Totals --}}
                <tr>
                    <td style="padding:16px 28px 0;">
                        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="font-size:14px;">
                            <tr>
                                <td style="padding:5px 0; color:#94a3b8;">Sous-total</td>
                                <td style="padding:5px 0; text-align:right; color:#e2e8f0;">{{ $subtotal }}</td>
                            </tr>
                            <tr>
                                <td style="padding:5px 0; color:#94a3b8;">Livraison</td>
                                <td style="padding:5px 0; text-align:right; color:{{ $shipping === 'Gratuite' ? '#4ade80' : '#e2e8f0' }};">{{ $shipping }}</td>
                            </tr>
                            <tr>
                                <td style="padding:12px 0 0; font-size:17px; font-weight:800; color:#f1f5f9; border-top:1px solid #334155;">Total</td>
                                <td style="padding:12px 0 0; text-align:right; font-size:20px; font-weight:800; color:#38bdf8; border-top:1px solid #334155;">{{ $total }}</td>
                            </tr>
                        </table>
                    </td>
                </tr>

                {{-- Address + payment --}}
                <tr>
                    <td style="padding:22px 28px 0;">
                        <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                            <tr>
                                <td valign="top" style="width:58%; padding:14px 16px; background-color:#0f172a; border:1px solid #334155; border-radius:12px;">
                                    <div style="font-size:12px; color:#64748b; font-weight:700; text-transform:uppercase; letter-spacing:1px;">Livraison</div>
                                    <div style="font-size:14px; color:#e2e8f0; line-height:1.6; margin-top:6px;">
                                        <strong>{{ $address['fullName'] ?? '' }}</strong><br>
                                        {{ $address['addressLine1'] ?? '' }}@if (! empty($address['addressLine2'])), {{ $address['addressLine2'] }}@endif<br>
                                        {{ $address['postalCode'] ?? '' }} {{ $address['city'] ?? '' }}, {{ $address['governorate'] ?? '' }}<br>
                                        📞 {{ $address['phone'] ?? '' }}
                                    </div>
                                </td>
                                <td style="width:4%;"></td>
                                <td valign="top" style="width:38%; padding:14px 16px; background-color:#0f172a; border:1px solid #334155; border-radius:12px;">
                                    <div style="font-size:12px; color:#64748b; font-weight:700; text-transform:uppercase; letter-spacing:1px;">Paiement</div>
                                    <div style="font-size:14px; color:#e2e8f0; line-height:1.6; margin-top:6px;">💵 {{ $paymentLabel }}<br><span style="color:#fbbf24;">À régler : {{ $total }}</span></div>
                                </td>
                            </tr>
                        </table>
                    </td>
                </tr>

                @if (! empty($order->notes))
                    <tr>
                        <td style="padding:16px 28px 0; font-size:13px; color:#94a3b8;"><strong style="color:#cbd5e1;">Votre note :</strong> {{ $order->notes }}</td>
                    </tr>
                @endif

                {{-- Footer --}}
                <tr>
                    <td style="padding:26px 28px 28px; text-align:center;">
                        <div style="font-size:13px; color:#94a3b8; line-height:1.6;">
                            Suivez l'état de votre commande dans l'application <strong style="color:#38bdf8;">Apex → Boutique → Commandes</strong>.<br>
                            Vous pouvez l'annuler tant qu'elle n'est pas confirmée.
                        </div>
                        <div style="margin-top:18px; font-size:11px; color:#475569;">© {{ date('Y') }} Apex · Cet email a été envoyé automatiquement, merci de ne pas y répondre.</div>
                    </td>
                </tr>
            </table>
        </td>
    </tr>
</table>
</body>
</html>
