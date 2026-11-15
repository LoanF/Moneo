# Design — Moneo

Le système visuel de l'app. Produit : voir [PRODUCT.md](PRODUCT.md).

## Direction

Une app bancaire moderne, sombre d'abord, entièrement dessinée sur mesure : aucun écran ne
repose sur l'apparence par défaut de Material ou de Cupertino. Le rouge Moneo (`#F44336`) est
la seule couleur de marque ; il signale ce qui s'actionne et ce qui est sélectionné.

Scène d'usage : une main, debout, juste après un paiement, souvent le soir. D'où le fond presque
noir, les grandes cibles tactiles et le montant comme élément le plus gros de chaque écran.

Un thème clair complet existe (réglage Système / Clair / Sombre), avec les mêmes composants.

## Jetons — `lib/ui/theme/theme.dart`

| Rôle | Sombre | Clair |
|---|---|---|
| Fond (`ground`) | `#0B0B0D` | `#F3F3F6` |
| Carte (`card`) | `#17171A` | `#FFFFFF` |
| Surface relevée (`raised`) : champs, puces | `#222226` | `#EDEDF1` |
| Texte (`ink`) / secondaire (`inkSoft`) | `#F6F6F8` / `#A1A1AB` | `#111114` / `#62626D` |
| Marque (`brand`), dégradé `brandBright → brand → brandDeep` | `#FF6A57 → #F44336 → #C92A22` | idem |
| Entrée (`income`) / sortie (`expense`) | `#4ADE80` / `#FF6B5E` | `#15803D` / `#C62828` |
| Alerte (`warning`) | `#FBBF24` | `#92400E` |

- **Rayons** : champ 16, ligne 20, carte 26, feuille 32. Boutons et puces en capsule.
- **Espacements** : grille de 4 pt (`Gap`), marge d'écran 20, dégagement de 128 sous les listes pour le dock.
- **Typographie** : police système (SF sur iOS, Roboto sur Android), graisses 700–800 pour les titres et
  les montants, chiffres à chasse fixe (`tabular`) partout où un montant s'affiche.
- **Mouvement** (`Motion`) : 140 ms pour un appui, 260 ms pour un changement d'état, courbe `easeOutCubic`,
  léger rebond (`easeOutBack`) sur ce qu'on vient d'actionner. Tout respecte « réduire les animations ».

## Composants — `lib/ui/widgets/kit.dart`

| Composant | Rôle |
|---|---|
| `Pressable` | Appui : enfoncement, retour haptique, sémantique de bouton |
| `MCard`, `GroupCard`, `GroupTile`, `GroupLabel` | Cartes et listes groupées |
| `GlowBackdrop` | Halos rouges flous derrière les en-têtes |
| `PrimaryButton`, `SoftButton`, `RoundIconButton`, `AddButton` | Boutons (le principal porte un reflet animé) |
| `PillTabs`, `ChoicePill`, `MSwitch`, `SwitchTile` | Sélecteurs |
| `NumberTicker` | Montant qui défile jusqu'à sa valeur |
| `FadeSlideIn` | Apparition en cascade des lignes |
| `BorderBeam` | Faisceau lumineux sur le contour d'une carte |
| `RingProgress`, `BarProgress` | Jauges animées (budgets, répartition) |
| `IconBadge`, `CheckBadge` | Pastilles de catégorie ; la seconde pointe une opération d'un appui |
| `FloatingDock` | Barre de navigation flottante en verre ; l'onglet actif s'étire et affiche son nom |

Plusieurs effets sont des portages Flutter de composants Magic UI (qui n'existent qu'en React) :
number ticker, border beam, blur fade, shiny button, animated circular progress bar, dock.

## Règles

- **Le montant est le héros.** Sur l'accueil, c'est le solde du compte affiché (on glisse d'un compte à
  l'autre) ; le total de tous les comptes n'apparaît que dans la liste des comptes.
- **Jamais la couleur seule.** Une sortie porte son « − », une entrée son « + » ; un budget écrit son état
  (« Bientôt atteint », « Dépassé de… ») en plus de sa couleur.
- **Le rouge se mérite.** Action principale, élément sélectionné, onglet actif. Pas de rouge décoratif.
- **Cibles tactiles ≥ 48 px**, même quand le dessin est plus petit.
- **Chaque geste a un équivalent visible** : glisser pour pointer ou supprimer existe aussi par la pastille
  et l'appui long.
- Contrastes AA en sombre comme en clair ; en clair, le rouge qui porte du texte passe à `#D32F2F`.

## Ce qui reste des contrôles système

Les sélecteurs de date et d'heure, le curseur de seuil d'un budget, les boutons radio du mode de
mensualisation et trois boîtes de dialogue de saisie (suppression du compte, valeurs numériques des
préférences) sont les contrôles de la plateforme, recolorés par le thème.
