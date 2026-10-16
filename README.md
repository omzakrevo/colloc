# Colloc

Application **Flutter** (web/PWA + Android + iOS) pour aider les étudiants à trouver une colocation.

- **Étudiant avec une maison** → publie une offre de colocation (photos, état, loyer, caution, frais, conditions).
- **Étudiant sans maison** → publie une demande de colocation (budget, quartier, durée…).
- **Agence immobilière** → publie des logements disponibles (photos, état, caution, frais de prestation, conditions).
- **Mise en contact : 1 000 FCFA** par annonce contactée. Paiement manuel : l'utilisateur envoie les 1 000 FCFA en Mobile Money, émet un avis de paiement, et
  **l'administrateur valide** ; le numéro de l'annonceur n'est révélé qu'après validation.

## Essayer tout de suite (mode démo)

Sans aucune configuration, l'app tourne en **mode démo** (données fictives, paiement simulé, aucun serveur) :

```bash
flutter run -d chrome            # ou: flutter build web --no-web-resources-cdn
```

Comptes de démo : `etudiant@demo.com`, `etudiant2@demo.com`, `agence@demo.com`, `admin@demo.com` — mot de passe `demo1234`
(boutons « connexion rapide » sur l'écran de connexion).

La CI publie cette même version démo sur **GitHub Pages** (voir `docs/DEPLOIEMENT.md`) : c'est la page de test.

## Architecture

```
lib/
  models.dart              # Listing, AppUser, ListingDraft, ...
  config.dart              # SUPABASE_URL / SUPABASE_ANON_KEY / APP_VERSION (--dart-define), prix du contact
  data/repository.dart     # contrat unique UI <-> données
  data/demo_repository.dart      # mémoire (mode démo)
  data/supabase_repository.dart  # production (Auth + Postgres + Storage)
  state/app_state.dart     # état global (ChangeNotifier)
  ui/                      # écrans : annonces, détail, publication, profil, connexion, paiement
supabase/schema.sql              # tables, RLS, bucket photos
infra/web-hosting.yml            # CloudFormation : S3 + CloudFront + rôle GitHub OIDC
.github/workflows/               # ci, deploy-web (AWS), demo-pages, android
```

Déploiement, mises à jour automatiques et configuration du paiement : **`docs/DEPLOIEMENT.md`**.
