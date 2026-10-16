#!/usr/bin/env python3
"""Envoie le site web Colloc (build/web) sur l'hébergement LWS par SFTP — même principe que le déploiement de Telima.

Variables d'environnement (jamais dans le dépôt : secrets GitHub ou variables de votre PC) :
    LWS_HOST   serveur SFTP LWS               LWS_USER / LWS_PASS   identifiants (ou LWS_KEY = clé privée)
    LWS_DIR    dossier du sous-domaine        ex. /coloc.telimatchi.com  (ou /htdocs/coloc, selon votre LWS)
    LWS_PORT   facultatif (22 par défaut)

Utilisation :
    python scripts/deploy_lws.py            # simulation : liste ce qui serait envoyé
    python scripts/deploy_lws.py --yes      # envoie réellement
    python scripts/deploy_lws.py --yes --htaccess   # envoie aussi le .htaccess (sauvegarde l'ancien en .htaccess.bak)

Ne supprime jamais rien sur le serveur. N'envoie que les fichiers absents ou de taille différente
(les fichiers qui décident de la mise à jour sont toujours renvoyés).
"""
import argparse
import os
import posixpath
import sys
from pathlib import Path

try:
    import paramiko
except ImportError:
    sys.exit("Installez d'abord paramiko :  pip install paramiko")

WEB = Path(__file__).resolve().parent.parent / "build" / "web"
ALWAYS_SEND = {"index.html", "version.json", "flutter_bootstrap.js", "flutter_service_worker.js", "main.dart.js", "manifest.json"}

HTACCESS = """# Colloc : application Flutter web (sous-domaine)
<IfModule mod_mime.c>
  AddType application/wasm .wasm
  AddType application/json .json
  AddType text/javascript .js .mjs
</IfModule>
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/css text/javascript application/javascript application/json application/wasm image/svg+xml font/ttf font/otf text/plain
</IfModule>
<IfModule mod_headers.c>
  # Ces fichiers se revalident à chaque visite : c'est ce qui déclenche « Une nouvelle version est disponible »
  <FilesMatch "(index\\.html|version\\.json|flutter_bootstrap\\.js|flutter_service_worker\\.js|main\\.dart\\.js|manifest\\.json)$">
    Header set Cache-Control "no-cache"
  </FilesMatch>
  <FilesMatch "\\.(wasm|otf|ttf|png|webp|ico|jpg|jpeg|svg)$">
    Header set Cache-Control "public, max-age=2592000"
  </FilesMatch>
</IfModule>
<IfModule mod_rewrite.c>
  RewriteEngine On
  # L'application gère elle-même ses écrans : tout chemin inconnu renvoie vers index.html
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteCond %{REQUEST_URI} !^/\\.well-known/
  RewriteRule ^ index.html [L]
</IfModule>
"""


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--yes", action="store_true", help="envoyer réellement (sinon simulation)")
    ap.add_argument("--htaccess", action="store_true", help="envoyer aussi un .htaccess (sauvegarde l'ancien)")
    args = ap.parse_args()

    if not WEB.is_dir():
        sys.exit(f"Dossier introuvable : {WEB}\nCompilez d'abord : flutter build web --release --no-web-resources-cdn")

    host, user = os.environ.get("LWS_HOST"), os.environ.get("LWS_USER")
    password, key = os.environ.get("LWS_PASS"), os.environ.get("LWS_KEY")
    base = os.environ.get("LWS_DIR") or "."
    port = int(os.environ.get("LWS_PORT") or "22")
    if not (host and user and (password or key)):
        manquantes = [n for n, v in (("LWS_HOST", host), ("LWS_USER", user)) if not v]
        if not (password or key):
            manquantes.append("LWS_PASS (ou LWS_KEY)")
        sys.exit("Variables manquantes ou vides : " + ", ".join(manquantes) + ". Voir l'en-tête du script.")

    files = sorted(p.relative_to(WEB).as_posix() for p in WEB.rglob("*") if p.is_file() and p.name != ".last_build_id")

    transport = paramiko.Transport((host, port))
    if key:
        transport.connect(username=user, pkey=paramiko.RSAKey.from_private_key_file(key))
    else:
        transport.connect(username=user, password=password)
    sftp = paramiko.SFTPClient.from_transport(transport)

    def mkdirs(path: str) -> None:
        cur = ""
        for part in path.split("/"):
            if not part:
                cur = "/"
                continue
            cur = posixpath.join(cur, part) if cur else part
            try:
                sftp.stat(cur)
            except IOError:
                sftp.mkdir(cur)

    todo = []
    for rel in files:
        data = (WEB / rel).read_bytes()
        remote = posixpath.join(base, rel)
        try:
            same = rel not in ALWAYS_SEND and sftp.stat(remote).st_size == len(data)
        except IOError:
            same = False
        if not same:
            todo.append((rel, remote, data))

    print(f"{len(files)} fichiers locaux, {len(todo)} à envoyer vers {host}:{base}")
    for rel, _, data in todo:
        print(f"  {'envoi' if args.yes else 'à envoyer'} : {rel} ({len(data) / 1024:.0f} Ko)")

    if args.yes:
        mkdirs(base)
        # version.json en dernier : les visiteurs ne voient « nouvelle version » qu'une fois tout le reste en place
        todo.sort(key=lambda t: t[0] == "version.json")
        for rel, remote, data in todo:
            mkdirs(posixpath.dirname(remote))
            with sftp.open(remote, "wb") as fh:
                fh.write(data)
        if args.htaccess:
            ht = posixpath.join(base, ".htaccess")
            try:
                sftp.stat(ht)
                sftp.rename(ht, ht + ".bak")
                print("Ancien .htaccess sauvegardé en .htaccess.bak")
            except IOError:
                pass
            with sftp.open(ht, "wb") as fh:
                fh.write(HTACCESS.encode("utf-8"))
            print(".htaccess envoyé.")
        print("Terminé.")
    else:
        print("Simulation seulement. Relancez avec --yes pour envoyer.")
    sftp.close()
    transport.close()


if __name__ == "__main__":
    main()
