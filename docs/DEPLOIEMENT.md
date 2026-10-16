# Déploiement et mises à jour (LWS + Supabase)

## Principe

> Vous me demandez une modification → je la code et je pousse sur `main` → GitHub teste, compile et **envoie le site sur LWS**
> (`coloc.telimatchi.com`) → les visiteurs voient « Une nouvelle version est disponible – Mettre à jour ».

| Cible | Déclencheur | Résultat |
|---|---|---|
| Site de production | push sur `main` | LWS, sous-domaine `coloc.telimatchi.com` (SFTP, comme Telima) |
| Page de test (démo, données fictives) | push sur `main` | GitHub Pages `https://omzakrevo.github.io/colloc/` |
| Android | tag `vX.Y.Z` ou manuel | APK sur la Release GitHub + AAB |

Le site est une PWA : sur téléphone, « Ajouter à l'écran d'accueil » l'installe comme une application.
Aperçu d'un design sans l'enregistrer : `https://coloc.telimatchi.com/?design=pop` (ocean, soleil, minimal, nuit, pop).

## 1. Sous-domaine sur LWS (une seule fois)

1. Espace client LWS → **Noms de domaine / Sous-domaines** : créer `coloc` sur `telimatchi.com`, avec un dossier dédié
   (ex. `coloc.telimatchi.com`). Activer le SSL/HTTPS (certificat gratuit) pour ce sous-domaine.
2. Noter le chemin SFTP de ce dossier (celui que vous utilisez pour Telima, mais celui du sous-domaine) → secret `LWS_DIR`.

## 2. Secrets GitHub (dépôt `omzakrevo/colloc` → Settings → Secrets and variables → Actions)

Les secrets d'un dépôt ne sont pas partagés avec un autre : il faut les recréer ici, avec **les mêmes valeurs que Telima**
sauf `LWS_DIR`.

| Secret | Valeur |
|---|---|
| `LWS_HOST`, `LWS_USER`, `LWS_PASS`, `LWS_PORT` | identiques à ceux de Telima |
| `LWS_DIR` | dossier du sous-domaine `coloc` (étape 1) |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | identiques à ceux de Telima (même projet Supabase, voir ci-dessous) |

Tant que `LWS_*` n'existent pas, le workflow `Deploy web (LWS)` ne fait rien. Premier envoi :
Actions → **Deploy web (LWS)** → Run workflow (le `.htaccess` est envoyé : cache, réécriture ; l'ancien est sauvegardé).
Si votre LWS n'applique pas le HTTPS automatiquement, activez « Forcer HTTPS » dans le panneau LWS.

## 3. Supabase : même projet que Telima

Colloc utilise le projet Supabase **TELIMA** sans toucher à Telima :
- toutes les tables/fonctions Colloc sont préfixées `coloc_` (aucun nom déjà utilisé, vérifié) ;
- aucun déclencheur n'est ajouté sur `auth.users` (le profil Colloc est créé par l'app) ;
- la migration est **additive** : `supabase/migrations/20261016120000_coloc_01_schema.sql` (testée sur un Postgres local :
  un étudiant ne peut ni se faire admin, ni lire les contacts d'autrui, ni voir les statistiques).

À savoir : les comptes (`auth.users`) sont communs à toutes les applications du projet. Une inscription Colloc déclenche donc
aussi les déclencheurs déjà présents des autres applications (création d'une ligne dans `businessbook_members`/`profiles`),
sans erreur mais sans utilité. Un utilisateur Telima peut se connecter à Colloc avec le même e-mail et mot de passe.
Si vous préférez une séparation totale, créez un projet Supabase dédié et exécutez la même migration.

Application de la migration : SQL Editor Supabase (coller le fichier) ou demandez-moi de l'appliquer.
Ensuite :
1. **Administrateur** : inscrivez-vous dans l'app, puis dans le SQL Editor :
   `update public.coloc_profiles set role = 'admin' where id = (select id from auth.users where email = 'vous@exemple.com');`
2. **Numéros de paiement** : table `coloc_app_settings`, ligne `payment_methods` (JSON : `id`, `label`, `number`, `holder`).
3. Authentication → Email : désactiver « Confirm email » si vous voulez une inscription immédiate.

## 4. Paiement manuel validé par l'administrateur

L'utilisateur envoie 1 000 FCFA à votre numéro Mobile Money, puis émet un **avis de paiement** (son numéro + référence).
Dans l'app, onglet **Admin → Paiements** (badge = avis en attente) : **Valider** (le numéro de l'annonceur apparaît chez
l'utilisateur) ou **Refuser** (il peut refaire un avis). L'admin n'est pas notifié par SMS/e-mail : il voit les avis en ouvrant l'app.

## 5. Espace administrateur (onglet « Admin »)

- **Paiements** : valider / refuser les avis.
- **Statistiques** : visiteurs (aujourd'hui, 7 j, 30 j), pages vues, annonces consultées, clics « Contacter », avis, validations,
  courbe par jour, entonnoir (visiteurs → annonce vue → clic Contacter → avis), pages par session, annonces et recherches
  les plus vues, villes, flyers (vues, clics, taux de clic), appareils. Les visiteurs sont anonymes (identifiant aléatoire),
  l'activité de l'administrateur n'est pas comptée.
- **Flyers** : ajouter / modifier / masquer / supprimer les flyers du slider (image, titre, sous-titre, lien, couleurs,
  mention « Publicité »). Les visiteurs peuvent cliquer sur un flyer : affichage en grand + bouton vers le lien.
- **Design** : 5 designs très différents (Océan, Soleil, Minimal, Nuit, Pop) + couleur principale et couleur d'accent au choix.
  « Appliquer à tout le site » change le site pour tous les visiteurs, sans redéploiement.

## 6. Villes

Villes universitaires du Burkina : Ouagadougou, Bobo-Dioulasso, Banfora, Koudougou, Ouahigouya, Fada N'Gourma, Dédougou,
Kaya, Tenkodogo, Dori (liste, universités et quartiers dans `lib/cities.dart`, faciles à compléter).

## 7. Android

- Test : Actions → **Android build** → Run workflow → télécharger l'APK.
- Version publiée : `git tag v1.0.0 && git push --tags` → APK sur la page *Releases*.
- Play Store : secrets `ANDROID_KEYSTORE_B64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` (comme Telima).
  Sans keystore, l'APK est signé avec la clé debug (suffisant pour tester).

## 8. Images de maisons d'exemple (illustrations)

Les images de démo (`assets/houses/house1.jpg` … `house8.jpg`) sont des illustrations dessinées en code
(`python3 scripts/make_houses.py` puis `node scripts/render_houses.js`). Pour de vraies photos, remplacez les fichiers et poussez.
Les vraies annonces utilisent les photos envoyées par les publieurs.

## 9. Développement local

```bash
flutter pub get && flutter analyze && flutter test
flutter run -d chrome                                   # démo (données fictives ; comptes etudiant@/agence@/admin@demo.com, mot de passe demo1234)
flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...   # réel
```
