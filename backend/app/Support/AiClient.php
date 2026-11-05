<?php

namespace App\Support;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Tiny LLM client. Returns null on any problem so callers can fall back
 * to the rule engine — the app never breaks because of the AI provider.
 */
class AiClient
{
    public static function enabled(): bool
    {
        return filled(config('services.ai.key'));
    }

    /**
     * @param  array<int, array{role: string, content: string}>  $messages  role = user|assistant
     */
    public static function chat(string $system, array $messages, int $maxTokens = 700, float $temperature = 0.6): ?string
    {
        if (! self::enabled()) {
            return null;
        }

        try {
            $text = config('services.ai.provider') === 'openai'
                ? self::openAi($system, $messages, $maxTokens, $temperature)
                : self::gemini($system, $messages, $maxTokens, $temperature);

            $text = is_string($text) ? trim($text) : null;

            return $text !== '' ? $text : null;
        } catch (Throwable $e) {
            Log::warning('AI coach call failed: '.$e->getMessage());

            return null;
        }
    }

    protected static function gemini(string $system, array $messages, int $maxTokens, float $temperature): ?string
    {
        $model = config('services.ai.model', 'gemini-2.0-flash');
        // Gemini wants the conversation to start with "user" and to alternate roles.
        $contents = [];
        foreach ($messages as $m) {
            $role = $m['role'] === 'assistant' ? 'model' : 'user';
            if ($contents === [] && $role === 'model') {
                continue;
            }
            $last = array_key_last($contents);
            if ($last !== null && $contents[$last]['role'] === $role) {
                $contents[$last]['parts'][0]['text'] .= "\n".$m['content'];
            } else {
                $contents[] = ['role' => $role, 'parts' => [['text' => $m['content']]]];
            }
        }

        $response = Http::timeout(config('services.ai.timeout', 20))
            ->withHeaders(['x-goog-api-key' => config('services.ai.key')])
            ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
                'systemInstruction' => ['parts' => [['text' => $system]]],
                'contents' => $contents,
                'generationConfig' => [
                    'temperature' => $temperature,
                    'maxOutputTokens' => $maxTokens,
                ],
            ]);

        if (! $response->successful()) {
            Log::warning('Gemini error '.$response->status().': '.$response->body());

            return null;
        }

        return $response->json('candidates.0.content.parts.0.text');
    }

    protected static function openAi(string $system, array $messages, int $maxTokens, float $temperature): ?string
    {
        $baseUrl = rtrim(config('services.ai.base_url'), '/');

        $response = Http::timeout(config('services.ai.timeout', 20))
            ->withToken(config('services.ai.key'))
            ->post("{$baseUrl}/chat/completions", [
                'model' => config('services.ai.model'),
                'messages' => array_merge([['role' => 'system', 'content' => $system]], $messages),
                'max_tokens' => $maxTokens,
                'temperature' => $temperature,
            ]);

        if (! $response->successful()) {
            Log::warning('OpenAI-compatible error '.$response->status().': '.$response->body());

            return null;
        }

        return $response->json('choices.0.message.content');
    }
}
