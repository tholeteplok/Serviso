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

    // Client for checking calling user's JWT
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

    // Admin client with service role
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    // Verify caller role in profiles
    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("role, shop_id, shops(slug)")
      .eq("id", caller.id)
      .single();

    if (profileError || profile?.role !== "admin" || !profile.shop_id) {
      return new Response(
        JSON.stringify({ error: "Akses ditolak. Hanya pemilik toko yang dapat mengelola user." }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const shopSlug = (profile.shops as any)?.slug;
    if (!shopSlug) {
      return new Response(
        JSON.stringify({ error: "Toko tidak memiliki slug yang valid." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { action, username, email, full_name, role, user_id, password } = body;

    if (action === "create") {
      if (!username || !full_name || !password) {
        return new Response(
          JSON.stringify({ error: "Username, nama lengkap, dan password wajib diisi." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      if (password.length < 6) {
        return new Response(
          JSON.stringify({ error: "Password minimal 6 karakter." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const cleanUsername = username.trim().toLowerCase();
      // Check if username exists in the same shop
      const { data: existing } = await supabaseAdmin
        .from("profiles")
        .select("id")
        .eq("username", cleanUsername)
        .eq("shop_id", profile.shop_id)
        .maybeSingle();

      if (existing) {
        return new Response(
          JSON.stringify({ error: `Username '${cleanUsername}' sudah digunakan di toko ini.` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const syntheticEmail = `${cleanUsername}.${shopSlug}@users.serviso.app`;
      const recoveryEmail = email?.trim() || syntheticEmail;

      const { data: userData, error: createError } =
        await supabaseAdmin.auth.admin.createUser({
          email: syntheticEmail,
          password: password,
          email_confirm: true,
          user_metadata: {
            username: cleanUsername,
            full_name: full_name.trim(),
            role: role === "admin" ? "admin" : "kasir",
            email: recoveryEmail,
            shop_id: profile.shop_id,
          },
        });

      if (createError) {
        return new Response(
          JSON.stringify({ error: `Gagal membuat akun: ${createError.message}` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ message: `Pengguna '${cleanUsername}' berhasil dibuat.`, user: userData.user }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "deactivate" || action === "activate") {
      if (!user_id) {
        return new Response(
          JSON.stringify({ error: "user_id wajib diisi." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const isActive = action === "activate";
      // ensure user is in the same shop
      const { error: updateError } = await supabaseAdmin
        .from("profiles")
        .update({ is_active: isActive })
        .eq("id", user_id)
        .eq("shop_id", profile.shop_id);

      if (updateError) {
        return new Response(
          JSON.stringify({ error: updateError.message }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      if (!isActive) {
        // Ban user to revoke active session
        await supabaseAdmin.auth.admin.updateUserById(user_id, {
          ban_duration: "876000h",
        });
      } else {
        // Unban user
        await supabaseAdmin.auth.admin.updateUserById(user_id, {
          ban_duration: "none",
        });
      }

      return new Response(
        JSON.stringify({ message: "Status pengguna berhasil diperbarui." }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (action === "reset_password") {
      if (!user_id) {
        return new Response(
          JSON.stringify({ error: "user_id wajib diisi." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const { data: targetProfile } = await supabaseAdmin
        .from("profiles")
        .select("email, username")
        .eq("id", user_id)
        .eq("shop_id", profile.shop_id)
        .single();
        
      if (!targetProfile) {
        return new Response(
          JSON.stringify({ error: "Pengguna tidak ditemukan." }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const targetEmail = targetProfile?.email || `${targetProfile?.username}.${shopSlug}@users.serviso.app`;
      const { error: resetError } = await supabaseAdmin.auth.resetPasswordForEmail(
        targetEmail
      );

      if (resetError) {
        return new Response(
          JSON.stringify({ error: resetError.message }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(
        JSON.stringify({ message: `Email reset password terkirim ke ${targetEmail}` }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ error: "Aksi tidak dikenali." }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Terjadi kesalahan server." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
