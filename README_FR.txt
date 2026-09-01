BESOIN INTIME — mod Project Zomboid (Build 41)
==============================================

INSTALLATION
1. Copier le dossier "BesoinIntime" dans :
   Windows : C:\Users\<toi>\Zomboid\mods\
   Linux   : ~/Zomboid/mods/
   (le fichier mod.info doit se trouver dans Zomboid/mods/BesoinIntime/mod.info)
2. Lancer le jeu > Mods > activer "Besoin Intime".
3. Nouvelle partie ou partie existante : les deux fonctionnent.
   En multijoueur, le mod doit aussi etre installe sur le serveur.

UTILISATION
- Clic droit n'importe ou > "Besoin intime" :
    * Etat : voir le palier et le pourcentage
    * Se soulager : action chronometree (seul)
    * Proposer un moment intime a <joueur> : en multi, quand un autre joueur
      est sur la case cliquee. Il recoit une fenetre Oui/Non.
    * Afficher / masquer la jauge
- Touche J : afficher / masquer la jauge (modifiable dans Options > Touches).
- La jauge est deplacable a la souris.

MECANIQUE
- Le besoin monte de 0 a 100 en 48 h de jeu (reglable).
- Au-dessus de 50 %, le stress monte progressivement (moodle Anxieux > Stresse),
  au-dessus de 75 % la tristesse aussi.
- Se soulager remet le besoin a 0, retire du stress (-0.4 = ~1,5 niveau de
  moodle), de la tristesse, de l'ennui, un peu de panique, et ajoute un peu
  de fatigue. Avec un partenaire, effets x1.5.
- L'action est bloquee / interrompue si un zombie est a moins de 8 cases,
  dans un vehicule, ou si le besoin est sous 20 %.
- Aucune animation : le personnage reste sur place, barre de progression
  classique, petit texte au-dessus de la tete.

REGLAGES (Options Sandbox > page "Besoin intime")
Vitesse de montee, gain de stress, force du soulagement, bonus partenaire,
seuil minimum, duree de l'action, detection zombies, intimite requise.

MODIFIER LES VALEURS A LA MAIN
media/lua/shared/BesoinIntime_Shared.lua -> fonctions tickPlayer / applyRelief.
Textes : media/lua/shared/Translate/FR/*.txt (encodage Cp1252 obligatoire).
