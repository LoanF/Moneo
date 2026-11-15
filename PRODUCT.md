# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

Deux publics à égalité (confirmé par le propriétaire du projet) :

- **L'habitué** : une personne qui tient ses comptes elle-même, opération par opération, et les rapproche de son relevé bancaire. Elle vient d'un classeur Excel de suivi (`Comptes.xlsm`) et connaît son vocabulaire : pointage, mensualisation, libellé principal / secondaire. Elle saisit plusieurs opérations par jour, souvent debout, d'une main, juste après un paiement.
- **Le nouveau venu** : quelqu'un qui installe l'app sans mode d'emploi et doit comprendre chaque écran sans explication.

L'app doit être rapide pour le premier sans perdre le second.

## Product Purpose

Moneo est un carnet de comptes personnel : on y saisit soi-même chaque dépense, revenu et transfert, on suit le solde de chaque compte et on pointe les opérations quand elles apparaissent sur le relevé. Il n'y a pas de connexion bancaire.

Le succès : saisir une opération en quelques secondes, connaître à tout moment ce qu'il reste réellement (solde restant, solde pointé, solde à ce jour), et ne jamais avoir à rouvrir le classeur Excel.

## Positioning

Un suivi tenu à la main, mais sans la friction du tableur : l'app reprend toute la logique du classeur d'origine (pointage, mensualités avec montant par mois, chéquiers numérotés, transferts en double écriture, tableau croisé) et y ajoute ce qu'un classeur ne fait pas (saisie sur téléphone, hors-ligne, alertes, prévision de solde).

## Operating Context

- Saisie mobile au quotidien, parfois sans réseau ; l'app doit fonctionner hors-ligne et se synchroniser ensuite.
- Rapprochement périodique avec le relevé bancaire : on parcourt les opérations non pointées et on les coche.
- En début de mois : mise en place des opérations mensuelles (loyer, abonnements, salaire).
- Reprise de l'historique depuis le classeur `Comptes.xlsm` (import), sauvegarde et export.
- Backend : API Moneo v2 (`moneo-api`), une seule source de vérité pour les soldes.

## Capabilities and Constraints

- Comptes multiples ; soldes calculés par le serveur (jamais saisis ni stockés).
- Opérations : dépense, revenu, transfert entre comptes ou vers un compte externe ; catégorie à deux niveaux ; moyen de paiement ; note libre ; pointage.
- Mensualités : montant par défaut, exceptions par mois, trois modes (tout le mois d'un coup, à l'échéance, manuel).
- Chéquiers avec numérotation automatique.
- Budgets par catégorie, statistiques, prévision de solde, tableau croisé.
- Notifications dans l'app et push ; heures calmes.
- Connexion par email / mot de passe ou Google ; les formulaires doivent fonctionner nativement avec les gestionnaires de mots de passe (Proton Pass, 1Password, Bitwarden, trousseau iCloud).
- Verrouillage biométrique de l'app.
- Langue : français. Devise : euro par défaut.
- Terminologie à conserver : « pointer / pointé », « mensualité », « solde restant », « solde pointé ».

## Brand Commitments

- Nom : **Moneo**.
- Logo existant conservé : `assets/images/Moneo.svg`, `assets/images/logo.png`.
- Couleur de marque conservée comme couleur principale : rouge `#F44336`.
- Typographie et reste du style : libres.

## Evidence on Hand

- Classeur de référence `Comptes.xlsm` (structure et macros analysées ; environ 2 400 écritures réelles, 20 catégories, 11 mensualités).
- Aucune donnée d'usage, témoignage ou chiffre marketing : ne pas en inventer.

## Product Principles

1. **La saisie d'abord.** Tout ce qui ralentit l'ajout d'une opération est un défaut.
2. **Un chiffre de confiance.** Les soldes affichés sont ceux du serveur ; l'interface ne les recalcule ni ne les arrondit à sa façon.
3. **Parité avec le classeur.** Rien de ce que faisait le classeur ne doit manquer.
4. **Lisible sans mode d'emploi.** Le vocabulaire de l'habitué est conservé, mais chaque terme se comprend dans son contexte.
5. **Les données appartiennent à l'utilisateur.** Export complet, suppression de compte réelle, rien envoyé à des tiers sans nécessité.

## Accessibility & Inclusion

Contrastes WCAG AA en thème clair et sombre, cibles tactiles d'au moins 44–48 px, respect de la taille de texte système et du réglage « réduire les animations », libellés pour les lecteurs d'écran, et jamais d'information portée par la couleur seule (dépense et revenu se distinguent aussi par le signe).
