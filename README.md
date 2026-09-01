# Besoin Intime — mod Project Zomboid (Build 41 et Build 42)

Ajoute un **besoin intime** au personnage : une jauge cachée qui monte avec le temps et fait grimper le stress (moodle *Anxieux → Stressé*) et la tristesse si elle est ignorée. La satisfaire — seul ou avec un autre joueur en multi — fait baisser stress, tristesse et ennui. **Aucune animation** : une simple action chronométrée, discrète.

## Compatibilité
- **Build 42** (testé pour 42.20.x stable) : fichiers dans `42/` + `common/`, traductions UTF-8 avec `%%`.
- **Build 41** (legacy) : fichiers à la racine (`mod.info`, `media/`).
Le même dossier fonctionne sur les deux versions, chaque build lit sa partie.

## Installation
1. Télécharger le zip de la [dernière release](../../releases/latest) (ou *Code → Download ZIP*).
2. Dézipper et copier le dossier `BesoinIntime` dans `Zomboid/mods/` :  
   Windows : `C:\Users\<toi>\Zomboid\mods\BesoinIntime\`  
   Le dossier doit contenir `mod.info`, `42/`, `common/` et `media/`.
3. Lancer le jeu → **Mods** (Build 42 : *Mod Manager*) → activer *Besoin Intime*.  
   En multijoueur, le mod doit aussi être installé côté serveur.

## Utilisation
- **Clic droit → Besoin intime** : état, *Se soulager* (seul), *Proposer un moment intime à …* (multi, l'autre joueur reçoit une fenêtre Oui/Non), afficher/masquer la jauge.
- **Touche J** : afficher/masquer la jauge (modifiable dans *Options → Touches*). Le panneau se déplace à la souris.

## Mécanique (valeurs par défaut)
| Élément | Valeur |
|---|---|
| Temps pour atteindre 100 % | 48 h de jeu |
| Stress au-dessus de 50 % | +0.006 / 10 min à 100 % (proportionnel) |
| Tristesse au-dessus de 75 % | +0.3 / 10 min |
| Soulagement | stress −0.4, tristesse −15, ennui −10, panique −10, fatigue +0.04 |
| Avec partenaire | effets ×1.5 |
| Bloqué si | zombie à < 8 cases, dans un véhicule, besoin < 20 % |

Tout est réglable dans **Options Sandbox → page « Besoin intime »**.

## Structure
```
mod.info, poster.png, media/       # Build 41 (traductions FR en Cp1252)
42/mod.info, 42/poster.png, 42/media/   # Build 42 (traductions UTF-8, % écrit %%)
common/                            # requis par Build 42, vide
media/lua/shared/BesoinIntime_Shared.lua   # logique, effets, vérifications
media/lua/client/BesoinIntime_Client.lua   # action, menu, panneau, multi côté client
media/lua/server/BesoinIntime_Server.lua   # relais des propositions entre joueurs
```

## Historique
- **1.1.0** — compatibilité Build 42 (42.20.x), dossier `42/` + `common/`, traductions UTF-8 et `%%`.
- **1.0.0** — version initiale Build 41.

## Licence
Libre d'utilisation et de modification.
