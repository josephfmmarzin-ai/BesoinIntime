# Besoin Intime — mod Project Zomboid (Build 41)

Ajoute un **besoin intime** au personnage : une jauge cachée qui monte avec le temps et fait grimper le stress (moodle *Anxieux → Stressé*) et la tristesse si elle est ignorée. La satisfaire — seul ou avec un autre joueur en multi — fait baisser stress, tristesse et ennui. **Aucune animation** : une simple action chronométrée, discrète.

## Installation
1. Télécharger le dépôt (*Code → Download ZIP*) ou cloner.
2. Copier le dossier `BesoinIntime` (celui qui contient `mod.info`) dans `Zomboid/mods/`  
   Windows : `C:\Users\<toi>\Zomboid\mods\BesoinIntime\`
3. Lancer le jeu → **Mods** → activer *Besoin Intime*.  
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
mod.info
poster.png
media/sandbox-options.txt
media/lua/shared/BesoinIntime_Shared.lua   # logique, effets, vérifications
media/lua/client/BesoinIntime_Client.lua   # action, menu, panneau, multi côté client
media/lua/server/BesoinIntime_Server.lua   # relais des propositions entre joueurs
media/lua/shared/Translate/{EN,FR}/        # traductions (FR en Cp1252)
```

## Licence
Libre d'utilisation et de modification.
