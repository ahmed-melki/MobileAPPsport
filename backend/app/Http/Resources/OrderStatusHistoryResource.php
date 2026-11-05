<?php

namespace App\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class OrderStatusHistoryResource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'fromStatus' => $this->from_status,
            'toStatus' => $this->to_status,
            'comment' => $this->comment,
            'changedByUserId' => $this->changed_by_user_id,
            'createdAt' => $this->created_at?->toISOString(),
        ];
    }
}
