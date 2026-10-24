#!/usr/bin/env python3
"""Sauvegarde des données EDG Restaurants (Supabase) en fichiers JSON datés.

Utilisation (sur ton ordinateur, jamais dans l'appli ni sur Netlify) :
  1. pip install requests
  2. Supabase > Project Settings > API > copie la clé "service_role" (SECRÈTE)
  3. Mac/Linux :  export SUPABASE_SERVICE_KEY="ta_cle"      Windows (PowerShell) :  $env:SUPABASE_SERVICE_KEY="ta_cle"
  4. python3 sauvegarde_supabase.py
Un dossier "sauvegardes/AAAA-MM-JJ" est créé. Lance-le chaque semaine. Garde les fichiers hors du dépôt public.
"""
import os, sys, json, datetime, requests

URL = "https://acubokitaezcnlmasxbk.supabase.co"
KEY = os.environ.get("SUPABASE_SERVICE_KEY")
if not KEY:
    sys.exit("Définis d'abord la variable SUPABASE_SERVICE_KEY (voir en haut du fichier).")

dossier = os.path.join("sauvegardes", datetime.date.today().isoformat())
os.makedirs(dossier, exist_ok=True)
H = {"apikey": KEY, "Authorization": "Bearer " + KEY}

for table in ("profiles", "app_data"):
    lignes, debut = [], 0
    while True:
        r = requests.get(f"{URL}/rest/v1/{table}?select=*", headers={**H, "Range": f"{debut}-{debut+999}"}, timeout=60)
        r.raise_for_status()
        lot = r.json()
        lignes += lot
        if len(lot) < 1000:
            break
        debut += 1000
    with open(os.path.join(dossier, table + ".json"), "w", encoding="utf-8") as f:
        json.dump(lignes, f, ensure_ascii=False, indent=1)
    print(f"{table}: {len(lignes)} lignes sauvegardées")
print("OK ->", dossier)
