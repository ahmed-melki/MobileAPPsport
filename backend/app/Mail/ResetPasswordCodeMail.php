<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Address;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ResetPasswordCodeMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public string $code)
    {
    }

    public function envelope(): Envelope
    {
        return new Envelope(
            from: new Address(
                (string) config('mail.from.address', 'hello@apex.app'),
                (string) config('mail.from.name', 'Apex')
            ),
            subject: 'Apex - Réinitialisation de votre mot de passe',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.reset-password-code',
            with: [
                'code' => $this->code,
                'appName' => config('app.name', 'Apex'),
            ],
        );
    }
}
