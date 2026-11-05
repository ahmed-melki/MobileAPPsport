<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\AdminStoreProductRequest;
use App\Http\Requests\AdminUpdateProductRequest;
use App\Http\Requests\AdminUpdateStockRequest;
use App\Http\Resources\ProductResource;
use App\Models\Product;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AdminProductController extends Controller
{
    /**
     * All products for the admin, including deactivated ones.
     */
    public function index(Request $request): JsonResponse
    {
        $products = Product::withTrashed()
            ->when($request->filled('search'), fn ($q) => $q->where(fn ($w) => $w->where('name', 'like', '%'.$request->string('search').'%')->orWhere('brand', 'like', '%'.$request->string('search').'%')))
            ->when($request->filled('category'), fn ($q) => $q->where('category', $request->input('category')))
            ->orderByRaw('deleted_at IS NOT NULL')
            ->orderBy('name')
            ->get();

        return ApiResponse::success(ProductResource::collection($products));
    }

    public function restore(string $slug): JsonResponse
    {
        $product = Product::onlyTrashed()->where('slug', $slug)->first();
        if (! $product) {
            return ApiResponse::error('Product not found.', [], 404);
        }

        $product->restore();

        return ApiResponse::success(new ProductResource($product->fresh()), 'Product reactivated successfully.');
    }

    public function store(AdminStoreProductRequest $request): JsonResponse
    {
        $slug = $request->filled('slug')
            ? Str::slug($request->input('slug'))
            : Str::slug($request->input('name'));

        // If slug collision occurs, append unique suffix
        $originalSlug = $slug;
        $counter = 1;
        while (Product::withTrashed()->where('slug', $slug)->exists()) {
            $slug = "{$originalSlug}-{$counter}";
            $counter++;
        }

        $product = Product::create([
            'slug' => $slug,
            'name' => $request->input('name'),
            'brand' => $request->input('brand'),
            'category' => $request->input('category'),
            'price' => $request->input('price'),
            'description' => $request->input('description'),
            'features' => $request->input('features', []),
            'color_key' => $request->input('colorKey'),
            'icon_key' => $request->input('iconKey'),
            'badge_key' => $request->input('badgeKey'),
            'stock_quantity' => $request->input('stockQuantity'),
            'rating' => 0.0,
            'review_count' => 0,
        ]);

        return ApiResponse::success(new ProductResource($product), 'Product created successfully.', [], 201);
    }

    public function update(AdminUpdateProductRequest $request, string $slug): JsonResponse
    {
        $product = Product::where('slug', $slug)->first();
        if (! $product) {
            return ApiResponse::error('Product not found.', [], 404);
        }

        $data = [];
        if ($request->has('name')) $data['name'] = $request->input('name');
        if ($request->has('slug')) $data['slug'] = Str::slug($request->input('slug'));
        if ($request->has('brand')) $data['brand'] = $request->input('brand');
        if ($request->has('category')) $data['category'] = $request->input('category');
        if ($request->has('price')) $data['price'] = $request->input('price');
        if ($request->has('description')) $data['description'] = $request->input('description');
        if ($request->has('features')) $data['features'] = $request->input('features');
        if ($request->has('colorKey')) $data['color_key'] = $request->input('colorKey');
        if ($request->has('iconKey')) $data['icon_key'] = $request->input('iconKey');
        if ($request->has('badgeKey')) $data['badge_key'] = $request->input('badgeKey');
        if ($request->has('stockQuantity')) $data['stock_quantity'] = $request->input('stockQuantity');

        $product->update($data);

        return ApiResponse::success(new ProductResource($product->fresh()), 'Product updated successfully.');
    }

    public function updateStock(AdminUpdateStockRequest $request, string $slug): JsonResponse
    {
        $product = Product::where('slug', $slug)->first();
        if (! $product) {
            return ApiResponse::error('Product not found.', [], 404);
        }

        $product->update(['stock_quantity' => $request->input('stockQuantity')]);

        return ApiResponse::success(new ProductResource($product->fresh()), 'Product stock updated successfully.');
    }

    public function deactivate(string $slug): JsonResponse
    {
        $product = Product::where('slug', $slug)->first();
        if (! $product) {
            return ApiResponse::error('Product not found.', [], 404);
        }

        $product->delete();

        return ApiResponse::success(new ProductResource($product), 'Product deactivated successfully.');
    }
}
