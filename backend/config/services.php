<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    /*
    | AI coach (optional). Without AI_API_KEY the coach still works with the
    | built-in rule engine. Providers:
    |   gemini : Google AI Studio key (free tier) — AI_MODEL e.g. gemini-2.0-flash
    |   openai : any OpenAI-compatible API (OpenAI, Groq, OpenRouter...) —
    |            set AI_BASE_URL (e.g. https://api.groq.com/openai/v1) and AI_MODEL
    */
    'ai' => [
        'provider' => env('AI_PROVIDER', 'gemini'),
        'key' => env('AI_API_KEY'),
        'model' => env('AI_MODEL', 'gemini-2.0-flash'),
        'base_url' => env('AI_BASE_URL', 'https://api.openai.com/v1'),
        'timeout' => (int) env('AI_TIMEOUT', 20),
    ],

];
