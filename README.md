# EDG Restaurants

Application web (PWA) de planification mensuelle du personnel de restaurants.
Un seul fichier applicatif : `index.html` (HTML + CSS + JavaScript, sans framework).

## Contenu
- `index.html` : toute l'application (génération de planning, export Excel, thème sombre)
- `sw.js`, `manifest.webmanifest`, icônes : installation sur téléphone (PWA) et cache hors ligne
- `_headers` : en-têtes de sécurité (Netlify / Cloudflare Pages)
- `sql/` : scripts à exécuter dans Supabase (base de données et règles de sécurité)
- `outils/sauvegarde_supabase.py` : sauvegarde des données (nécessite la clé secrète, jamais dans le dépôt)

## Services utilisés
Supabase (comptes et données), Brevo (emails), Netlify (hébergement), UptimeRobot (surveillance).

## Mise à jour
1. Modifier `index.html`
2. Changer le numéro de cache dans `sw.js` (ex. `edg-v27` -> `edg-v28`)
3. Déployer le dossier complet

© 2026 Maxime Dey. Tous droits réservés.
