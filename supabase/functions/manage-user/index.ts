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

    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    // Admin client with service role
    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Validate calling user's JWT explicitly with token
    const {
      data: { user: caller },
      error: userError,
    } = await supabaseAdmin.auth.getUser(token);

    if (userError || !caller) {
      return new Response(
        JSON.stringify({
          error: `Sesi tidak valid atau telah berakhir: ${userError?.message || "Token tidak valid. Silakan login ulang."}`,
        }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

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

    const shopSlug = Array.isArray(profile.shops)
      ? (profile.shops[0] as any)?.slug
      : (profile.shops as any)?.slug;
    if (!shopSlug) {
      return new Response(
        JSON.stringify({ error: "Toko tidak memiliki slug yang valid." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json();
    const { action, username, email, full_name, role, user_id, password, new_password } = body;

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
      // Username regex check: only lowercase alphanumeric, _, ., - (3 to 30 chars), no spaces
      const usernameRegex = /^[a-z0-9_.-]{3,30}$/;
      if (!usernameRegex.test(cleanUsername)) {
        return new Response(
          JSON.stringify({
            error:
              "Username hanya boleh menggunakan huruf kecil, angka, titik (.), strip (-), atau garis bawah (_) tanpa spasi (3-30 karakter).",
          }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      if (email && email.trim().length > 0) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email.trim())) {
          return new Response(
            JSON.stringify({ error: "Format email pemulihan tidak valid (contoh: user@gmail.com)." }),
            { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
          );
        }
      }

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
        let errorMsg = createError.message;
        const lower = errorMsg.toLowerCase();
        if (
          lower.includes("a user with this email already exists") ||
          lower.includes("user already registered")
        ) {
          errorMsg = `Username '${cleanUsername}' atau email pemulihan sudah terdaftar di sistem. Gunakan username lain.`;
        } else if (lower.includes("password should be at least 6 characters")) {
          errorMsg = "Password minimal 6 karakter.";
        } else if (lower.includes("email is not valid") || lower.includes("invalid email")) {
          errorMsg = "Format email atau username tidak valid.";
        }
        return new Response(
          JSON.stringify({ error: `Gagal membuat akun: ${errorMsg}` }),
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

    if (action === "reset_password" || action === "set_password") {
      const passwordToSet = new_password || password;
      if (!user_id || !passwordToSet) {
        return new Response(
          JSON.stringify({ error: "user_id dan password baru wajib diisi." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      if (typeof passwordToSet !== "string" || passwordToSet.length < 6) {
        return new Response(
          JSON.stringify({ error: "Password baru minimal 6 karakter." }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Verify target profile exists in caller's shop
      const { data: targetProfile, error: targetError } = await supabaseAdmin
        .from("profiles")
        .select("id, username, role")
        .eq("id", user_id)
        .eq("shop_id", profile.shop_id)
        .single();
        
      if (targetError || !targetProfile) {
        return new Response(
          JSON.stringify({ error: "Pengguna tidak ditemukan di toko ini." }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Execute password update directly via Supabase Auth Admin
      const { error: updateAuthError } = await supabaseAdmin.auth.admin.updateUserById(
        user_id,
        { password: passwordToSet }
      );

      if (updateAuthError) {
        return new Response(
          JSON.stringify({ error: `Gagal memperbarui password: ${updateAuthError.message}` }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      // Record in audit_logs
      try {
        await supabaseAdmin.from("audit_logs").insert({
          actor_id: caller.id,
          action: "update",
          table_name: "profiles",
          record_id: user_id,
          old_data: { action: "password_reset", target_user: targetProfile.username },
          new_data: { updated_by: profile.role },
          shop_id: profile.shop_id,
        });
      } catch (_) {
        // Non-blocking
      }

      return new Response(
        JSON.stringify({
          message: `Password untuk @${targetProfile.username} berhasil diperbarui.`,
        }),
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
