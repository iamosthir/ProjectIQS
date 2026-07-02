<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

trait HandlesImageUploads
{
    /**
     * Validate an uploaded image, store it under the given public-disk folder,
     * and return its storage-relative path plus a public URL. The form then
     * submits that path (e.g. `logo_path`), keeping create/update plain JSON
     * and the mobile contract (relative paths through assetUrl) unchanged.
     *
     * Relies on the host controller's $this->ok() (from RespondsWithApi).
     */
    protected function uploadImage(Request $request, string $folder): JsonResponse
    {
        $request->validate([
            'file' => ['required', 'image', 'mimes:jpeg,jpg,png,webp,gif', 'max:5120'],
        ]);

        $path = $request->file('file')->store($folder, 'public');

        return $this->ok([
            'path' => $path,
            'url' => Storage::disk('public')->url($path),
        ], __('Image uploaded.'));
    }
}
