// Edge Function `pay-contact` : encaisse les 1 000 FCFA de mise en contact puis débloque le contact.
//
// PAYMENT_MODE=sandbox  -> débloque sans débiter (tests uniquement)
// PAYMENT_MODE=live     -> à brancher sur votre agrégateur Mobile Money (CinetPay, PayDunya, Wave Business…)
// autre / absent        -> 501 (rien n'est débloqué : sécurisé par défaut)
//
// Déploiement : supabase functions deploy pay-contact
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const FEE_FCFA = 1000;
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const url = Deno.env.get("SUPABASE_URL")!;
  const authed = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: { user } } = await authed.auth.getUser();
  if (!user) return json({ error: "Connexion requise." }, 401);

  const { listing_id, method, payer_phone } = await req.json().catch(() => ({}));
  if (!listing_id || !method || !payer_phone) return json({ error: "Requête invalide." }, 400);

  const admin = createClient(url, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { data: listing } = await admin.from("listings").select("id, owner_id, active").eq("id", listing_id).maybeSingle();
  if (!listing || !listing.active) return json({ error: "Annonce introuvable." }, 404);
  if (listing.owner_id === user.id) return json({ error: "C'est votre propre annonce." }, 400);

  const { data: existing } = await admin.from("contact_unlocks").select("status")
    .eq("user_id", user.id).eq("listing_id", listing_id).maybeSingle();
  if (existing?.status === "paid") return json({ ok: true });

  const mode = Deno.env.get("PAYMENT_MODE");
  let providerRef: string | null = null;

  if (mode === "sandbox") {
    providerRef = "sandbox";
  } else if (mode === "live") {
    // TODO: appeler l'API de l'agrégateur Mobile Money ici (montant FEE_FCFA, numéro payer_phone, méthode `method`),
    // attendre/valider la confirmation (idéalement via webhook), puis renseigner providerRef.
    return json({ error: "Paiement live non configuré." }, 501);
  } else {
    return json({ error: "Paiement non disponible pour le moment." }, 501);
  }

  const { error } = await admin.from("contact_unlocks").upsert(
    { user_id: user.id, listing_id, amount: FEE_FCFA, provider: method, provider_ref: providerRef, status: "paid" },
    { onConflict: "user_id,listing_id" },
  );
  if (error) return json({ error: "Enregistrement impossible." }, 500);
  return json({ ok: true });
});
