import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.21.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Header otorisasi tidak ditemukan." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

    const supabaseAuthClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user: caller },
      error: userError,
    } = await supabaseAuthClient.auth.getUser();

    if (userError || !caller) {
      return new Response(
        JSON.stringify({ error: "Sesi tidak valid atau telah berakhir." }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("is_platform_admin")
      .eq("id", caller.id)
      .single();

    if (profileError || !profile?.is_platform_admin) {
      return new Response(
        JSON.stringify({ error: "Akses ditolak. Hanya platform admin yang dapat membuat toko." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { shop_name, shop_slug, owner_username, owner_email, owner_full_name, owner_password } = body;

    if (!shop_name || !shop_slug || !owner_username || !owner_full_name || !owner_password) {
      return new Response(
        JSON.stringify({ error: "Semua field wajib diisi (termasuk password pemilik)." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (owner_password.length < 6) {
      return new Response(
        JSON.stringify({ error: "Password pemilik minimal 6 karakter." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!/^[a-z0-9\-]+$/.test(shop_slug)) {
      return new Response(
        JSON.stringify({ error: "Slug toko hanya boleh berisi huruf kecil, angka, dan strip." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (["platform", "admin", "default", "system"].includes(shop_slug)) {
      return new Response(
        JSON.stringify({ error: `Slug '${shop_slug}' adalah kata kunci khusus sistem yang tidak dapat digunakan.` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Insert shop
    const { data: shopData, error: shopError } = await supabaseAdmin
      .from("shops")
      .insert({ slug: shop_slug, name: shop_name })
      .select()
      .single();

    if (shopError || !shopData) {
      return new Response(
        JSON.stringify({ error: shopError?.message || "Gagal membuat toko." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const cleanUsername = owner_username.trim().toLowerCase();
    const syntheticEmail = `${cleanUsername}.${shop_slug}@users.serviso.app`;
    const recoveryEmail = owner_email?.trim() || syntheticEmail;

    const { data: userData, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email: syntheticEmail,
        password: owner_password,
        email_confirm: true,
        user_metadata: {
          username: cleanUsername,
          full_name: owner_full_name.trim(),
          role: "admin", // Owner is always admin
          email: recoveryEmail,
          shop_id: shopData.id,
        },
      });

    if (createError) {
      // Rollback: hapus shop yang baru dibuat agar tidak ada orphaned shop
      await supabaseAdmin.from("shops").delete().eq("id", shopData.id);
      return new Response(
        JSON.stringify({ error: `Gagal membuat akun pemilik: ${createError.message}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ message: "Toko dan owner berhasil dibuat.", shop: shopData, user: userData.user }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Terjadi kesalahan server." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
