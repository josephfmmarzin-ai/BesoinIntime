# Besoin Intime / Intimate Need — Project Zomboid Build 42

🇫🇷 [Français](#français) · 🇬🇧 [English](#english)

**Steam Workshop : https://steamcommunity.com/sharedfiles/filedetails/?id=3794394776**  
Workshop ID `3794394776` · Mod ID `BesoinIntime`

---

## Français

Ajoute un **besoin intime réaliste** au personnage : une jauge cachée monte avec le temps et fait grimper le stress (moodle *Anxieux → Stressé*) puis la tristesse si elle est ignorée. On y répond **à l'intérieur, sur un lit ou un canapé**, seul ou avec un autre joueur en multijoueur. **Aucune animation, aucun contenu explicite** : une action chronométrée classique, discrète.

### Installation
**Steam Workshop** (recommandé) : [s'abonner au mod](https://steamcommunity.com/sharedfiles/filedetails/?id=3794394776), puis l'activer dans le Mod Manager.

**Manuelle** : télécharger `BesoinIntime-v3.0.1.zip` dans la [dernière release](../../releases/latest), dézipper, et copier le dossier `BesoinIntime` dans `C:\Users\<toi>\Zomboid\mods\`. Le dossier doit contenir `mod.info`, `42/` et `common/`. Activer *Besoin Intime* dans le Mod Manager. En multijoueur, le serveur doit aussi avoir le mod.

### Utilisation
- **Clic droit sur un lit, canapé, fauteuil, chaise** (ou juste à côté), ou **dans un véhicule à l'arrêt** → **Besoin intime** → *Prendre un moment pour soi*. Pendant le moment : pose assise, cache noir, petit son en boucle, puis souffle + carillon.
- **Clic droit sur un autre joueur** (multi) → *Proposer un moment intime à …* ; il reçoit une fenêtre Oui / Non.
- **Icône de moodle** dans la colonne de droite à partir de 70 % de besoin (orange → rouge, seuil réglable), verte pendant la sérénité ; survol = description ; déplaçable.
- **Touche J** : afficher la jauge détaillée (masquée par défaut, modifiable dans *Options → Touches*).
- Une option grisée affiche la raison au survol (dehors, pas de lit, zombies, épuisé, affamé, quelqu'un à proximité…).

### Mécanique (valeurs par défaut, toutes réglables en Sandbox)
| Élément | Valeur |
|---|---|
| Temps pour atteindre 100 % | 72 h de jeu |
| Stress au-dessus de 50 % | jusqu'à +0.005 / 10 min |
| Tristesse au-dessus de 75 % | jusqu'à +0.25 / 10 min |
| Délai entre deux moments | 2 h de jeu (possible même à 0 %, effet réduit) |
| Soulagement | stress −0.35, tristesse −12, ennui −20, panique −10, fatigue +0.05 |
| Bon lit / mauvais lit | ×1.2 / ×0.8 |
| Avec partenaire | ×1.5, action plus longue |
| Sérénité après | 3 h de jeu sans montée |
| Bloqué si | dehors, pas de lit, véhicule, fatigue > 85 %, faim/soif > 70 %, zombie < 10 cases, autre joueur < 8 cases |

### Structure
```
mod.info, poster.png            # métadonnées (Mod Manager / Workshop)
42/mod.info, 42/media/          # code Build 42
42/media/lua/shared/BesoinIntime_Shared.lua   # logique, vérifications, effets
42/media/lua/client/BesoinIntime_Client.lua   # action, menu, panneau, multi (client)
42/media/lua/server/BesoinIntime_Server.lua   # relais des propositions (serveur)
42/media/lua/shared/Translate/{EN,FR}/        # traductions (UTF-8)
common/                          # requis par Build 42
```

---

## English

Adds a **realistic intimate need**: a hidden gauge rises over time and increases stress (*Anxious → Stressed* moodle) and then unhappiness if ignored. Satisfy it **indoors, on a bed or couch**, alone or with another player in multiplayer. **No animation, no explicit content**: a regular, discreet timed action.

### Install
**Steam Workshop** (recommended): [subscribe](https://steamcommunity.com/sharedfiles/filedetails/?id=3794394776), then enable it in the Mod Manager.

**Manual**: download `BesoinIntime-v3.0.1.zip` from the [latest release](../../releases/latest), unzip, and copy the `BesoinIntime` folder into `C:\Users\<you>\Zomboid\mods\`. The folder must contain `mod.info`, `42/` and `common/`. Enable *Besoin Intime* in the Mod Manager. In multiplayer the server needs the mod too.

### Usage
- **Right-click a bed, couch, armchair, chair** (or stand next to one), or **in a parked vehicle** → **Intimate need** → *Take some time for yourself*. During the moment: sitting pose, black censor box, small looping sound, then a sigh + chime.
- **Right-click another player** (MP) → *Propose an intimate moment to …*; they get a Yes / No dialog.
- **Moodle icon** in the right column from 70 % need (orange → red, threshold tunable), green during serenity; hover for details; draggable.
- **J key**: show the detailed gauge (hidden by default, rebindable in *Options → Keys*).
- A greyed option shows the reason on hover (outdoors, no bed, zombies, exhausted, hungry, someone nearby…).

### Mechanics (defaults, all tunable in Sandbox)
| Item | Value |
|---|---|
| Time to reach 100 % | 72 in-game hours |
| Stress above 50 % | up to +0.005 / 10 min |
| Unhappiness above 75 % | up to +0.25 / 10 min |
| Cooldown between moments | 2 in-game hours (works even at 0 %, reduced effect) |
| Relief | stress −0.35, unhappiness −12, boredom −20, panic −10, fatigue +0.05 |
| Good / bad bed | ×1.2 / ×0.8 |
| With a partner | ×1.5, longer action |
| Serenity afterwards | 3 in-game hours without gain |
| Blocked if | outdoors, no bed, vehicle, fatigue > 85 %, hunger/thirst > 70 %, zombie < 10 tiles, other player < 8 tiles |

---

## Changelog
- **3.0.1** — Fix: the censor overlay blocked right-clicks on the world (fullscreen UI element); it is now 0x0 and never captures the mouse. Removed duplicate translations from `common/`.
- **3.0.0** — Works on any seat: beds (single, double, bunk), couches, armchairs, chairs, benches, and parked vehicles (engine on or off). Vanilla sitting pose on furniture. Black censor box drawn over the character during the moment, synced to other players in MP. Sounds: looping 'tortoise' squeaks during the moment, relief sigh + chime at the end (synthesized, heard by nearby players). All tunable/disable-able in Sandbox.
- **2.3.0** — The action now derives from the vanilla `ISSitOnGround` action: the character really sits on the bed during the moment (same pose as 'Sit on ground'), then stands up. Falls back to a plain timed action if unavailable.
- **2.2.2** — Fix from console.txt: Build 42 removed `Stats:getThirst()` and sprite `Is(IsoFlagType.bed)`; the action could not start and every right-click logged an error. Both calls are now guarded. Lua files are pure ASCII with escaped accents (correct display regardless of engine encoding).
- **2.2.1** — Moodle icon now appears at 70 % need (Sandbox: *Moodle appears at*).
- **2.2.0** — Built-in moodle icon in the right column (from the 'In the mood' stage, green during serenity, tooltip, draggable, no dependency). Character walks to the bed and uses the vanilla sitting pose during the action. Sleep bonus during serenity. Gauge panel hidden by default (J to show).
- **2.1.0** — Action available at any need level (pleasure / anti-boredom), with a cooldown (2 h) and an effect scaled by the gauge (40 % at 0 %, 100 % at 100 %). Boredom relief raised to 20. State shown in the menu title. Accents fixed in fallback texts.
- **2.0.1** — Fix: built-in FR/EN texts (no more raw `IGUI_…` keys if Translate files fail to load), translations also in `common/`, safer bed detection, no more errors from the J key / tooltips, context menu protected, wider panel.
- **2.0.0** — Final version, Build 42 only (42.20.x). Realistic mode: indoors + bed/couch, bed quality, exhaustion/hunger checks, privacy on by default, serenity period. Context menu only on beds / players. FR + EN. Workshop-ready.
- **1.1.0** — Build 42 compatibility layer.
- **1.0.0** — Initial Build 41 release.

## License
Free to use and modify. / Libre d'utilisation et de modification.
