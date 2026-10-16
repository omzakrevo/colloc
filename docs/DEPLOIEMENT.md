# Déploiement et mises à jour

## Principe

> Vous me demandez une modification → je la code, je push sur `main` → la CI teste, construit et **déploie toute seule**
> → les utilisateurs voient « Une nouvelle version est disponible – Mettre à jour ».

| Cible | Déclencheur | Résultat |
|---|---|---|
| Page de test (démo) | push sur `main` | GitHub Pages `https://<user>.github.io/colloc/` |
| Web/PWA production | push sur `main` | AWS S3 + CloudFront (+ invalidation du cache) |
| Android | tag `vX.Y.Z` ou manuel | APK sur la Release GitHub + AAB (Play Store) |

La version web est une PWA : sur téléphone, « Ajouter à l'écran d'accueil » l'installe comme une application.
À chaque déploiement, `version.json` change ; l'app le vérifie toutes les 5 min et propose la mise à jour.

## 1. Page de test (gratuit, sans serveur)

1. GitHub → *Settings → Pages → Source : GitHub Actions*.
2. Après un push sur `main`, l'URL apparaît dans l'onglet *Actions → Demo page*.

## 2. Backend (Supabase)

1. Créez un projet sur supabase.com ; dans *SQL Editor*, exécutez `supabase/schema.sql`.
2. *Authentication → Providers → Email* : désactivez « Confirm email » pour une inscription immédiate (ou gardez-le activé).
3. **Paiement manuel validé par un administrateur** (pas d'agrégateur pour l'instant) :
   - Renseignez vos numéros Mobile Money : table `app_settings`, ligne `payment_methods` (JSON : `id`, `label`, `number`, `holder`).
   - Créez le compte administrateur : inscrivez-vous normalement dans l'app, puis dans le SQL Editor :
     `update public.profiles set role = 'admin' where id = (select id from auth.users where email = 'vous@exemple.com');`
     (le rôle admin ne peut pas être obtenu depuis l'app).
   - Fonctionnement : l'utilisateur envoie 1 000 FCFA à votre numéro, puis émet un **avis de paiement** dans l'app
     (son numéro payeur + référence). L'onglet **Paiements** de l'admin (badge = nombre d'avis en attente) permet de
     **Valider** (le numéro de l'annonceur est alors débloqué chez l'utilisateur, qui voit l'état se mettre à jour tout seul)
     ou de **Refuser** (l'utilisateur peut émettre un nouvel avis).
   - L'admin n'est pas notifié par e-mail/SMS : il voit les avis en ouvrant l'app. Une notification pourra être ajoutée.
   - Plus tard, un paiement automatique (CinetPay, PayDunya, Wave Business…) pourra remplacer la validation manuelle.
4. Notez `Project URL` et la clé publique (anon/publishable).

## 3. AWS (web)

1. CloudFormation → créer une pile avec `infra/web-hosting.yml` (région au choix, ex. `eu-west-3`).
   Si le fournisseur OIDC GitHub existe déjà dans le compte : `CreateGitHubOidcProvider=false` + son ARN.
2. Dans les *Outputs* : `S3Bucket`, `CloudFrontDistributionId`, `DeployRoleArn`, `SiteUrl`.
3. GitHub → *Settings → Secrets and variables → Actions* :

| Secret | Valeur |
|---|---|
| `S3_BUCKET` | output `S3Bucket` |
| `CLOUDFRONT_DISTRIBUTION_ID` | output `CloudFrontDistributionId` |
| `AWS_ROLE_ARN` | output `DeployRoleArn` (ou à la place `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`) |
| `AWS_REGION` | ex. `eu-west-3` (même région que la pile) |
| `SUPABASE_URL`, `SUPABASE_ANON_KEY` | étape 2 |

4. Push sur `main` (ou *Actions → Deploy web (AWS) → Run workflow*). Le site est sur `SiteUrl`.
   Nom de domaine perso : ajoutez-le à CloudFront (certificat ACM en `us-east-1`).

Tant que le secret `S3_BUCKET` n'existe pas, le workflow `Deploy web (AWS)` ne fait rien (il est ignoré proprement).

## 4. Android

- Test : *Actions → Android build → Run workflow* → télécharger l'artefact (APK à installer directement).
- Version publiée : `git tag v1.0.0 && git push --tags` → APK sur la page *Releases*.
- Play Store : créez un keystore, ajoutez les secrets `ANDROID_KEYSTORE_B64` (base64), `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` ; l'AAB signé est produit par la même CI.
- Sans keystore, l'APK est signé avec la clé debug : suffisant pour tester, pas pour le Play Store.
- Les apps natives ne s'auto-mettent pas à jour hors store ; pour des mises à jour instantanées du code Dart sur mobile,
  on peut ajouter **Shorebird** plus tard.

## 5. Développement local

```bash
flutter pub get && flutter analyze && flutter test
flutter run -d chrome                                   # démo
flutter run -d chrome --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...   # réel
```

## 6. Slider de l'accueil (publicités)

Les bannières viennent de la table `promos` (Supabase → Table Editor). Pour ajouter une pub : nouvelle ligne avec
`title`, `subtitle`, éventuellement `image_url` (visuel) et `link_url` (ouvert au clic), `color_a`/`color_b` (dégradé,
hex sans `#`), `sponsor = true` pour afficher « PUBLICITÉ », `sort` pour l'ordre, `active = false` pour la retirer.
Aucune mise à jour de l'app n'est nécessaire. En mode démo, 3 bannières d'exemple sont fournies.

## 7. Logo et icônes

Source : `brand/logo.svg` (arrondi) et `brand/logo-square.svg` (plein cadre, iOS/maskable). Les icônes web, Android et iOS
en sont dérivées ; le logo animé de l'app est `lib/ui/logo.dart` (même géométrie).

## 8. Images de maisons d'exemple (illustrations)

Les images de démo (`assets/houses/house1.jpg` … `house8.jpg` : villa, villa moderne, immeuble, maison à cour, chambre, salon,
cuisine, studio) sont des **illustrations dessinées en code**, pas des photographies. Elles se régénèrent avec
`python3 scripts/make_houses.py` (SVG dans `brand/houses/`) puis `node scripts/render_houses.js` (rendu JPG via Chromium).
Pour utiliser de vraies photos, remplacez simplement les fichiers `assets/houses/house*.jpg` (JPG, ~1200 px de large) et poussez sur `main`.
Les vraies annonces utilisent les photos envoyées par les publieurs.
