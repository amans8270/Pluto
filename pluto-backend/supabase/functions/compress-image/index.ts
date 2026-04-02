// Supabase Edge Function - Image Compression with WASM
// Uses magick-wasm to resize and convert images to WebP

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { ImageMagick, initialize } from "https://esm.sh/@aspect-build/magick-wasm@0.0.26";

// CORS headers
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// Configuration
const MAX_WIDTH = 1200;
const MAX_HEIGHT = 1200;
const WEBP_QUALITY = 85;
const BUCKET_NAME = "photos";

serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Initialize ImageMagick WASM
    await initialize();

    // Get Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse form data
    const formData = await req.formData();
    const file = formData.get("file") as File;
    const userId = formData.get("user_id") as string;
    const folder = formData.get("folder") as string || "photos";

    if (!file || !userId) {
      return new Response(
        JSON.stringify({ error: "file and user_id are required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Read file as array buffer
    const inputBuffer = new Uint8Array(await file.arrayBuffer());

    // Process image with ImageMagick WASM
    const outputBuffer = await ImageMagick.read(inputBuffer, (img) => {
      // Resize if larger than max dimensions
      if (img.width > MAX_WIDTH || img.height > MAX_HEIGHT) {
        const ratio = Math.min(MAX_WIDTH / img.width, MAX_HEIGHT / img.height);
        const newWidth = Math.round(img.width * ratio);
        const newHeight = Math.round(img.height * ratio);
        img.resize(newWidth, newHeight);
      }

      // Convert to RGB if needed (for WebP compatibility)
      if (img.channels > 3) {
        img.alpha("remove");
      }

      // Convert to WebP format
      img.format = "webp";
      img.quality = WEBP_QUALITY;

      return img.write((data) => new Uint8Array(data));
    });

    // Generate unique filename
    const timestamp = Date.now();
    const randomId = crypto.randomUUID().split("-")[0];
    const filePath = `${userId}/${folder}/${timestamp}_${randomId}.webp`;

    // Upload compressed image to Supabase Storage
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from(BUCKET_NAME)
      .upload(filePath, outputBuffer, {
        contentType: "image/webp",
        upsert: false,
      });

    if (uploadError) {
      console.error("Upload error:", uploadError);
      return new Response(
        JSON.stringify({ error: "Failed to upload image" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Get public URL
    const { data: urlData } = supabase.storage
      .from(BUCKET_NAME)
      .getPublicUrl(filePath);

    const publicUrl = urlData.publicUrl;

    // Calculate compression stats
    const originalSize = inputBuffer.length;
    const compressedSize = outputBuffer.length;
    const compressionRatio = ((1 - compressedSize / originalSize) * 100).toFixed(1);

    return new Response(
      JSON.stringify({
        success: true,
        url: publicUrl,
        path: filePath,
        stats: {
          original_size_bytes: originalSize,
          compressed_size_bytes: compressedSize,
          compression_ratio: `${compressionRatio}%`,
        },
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error:", error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
