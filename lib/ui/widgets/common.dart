import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../state/providers.dart';
import '../theme/theme.dart';
import 'kit.dart';

export 'kit.dart';

// ── Icônes de catégories ─────────────────────────────────────────────────────

/// Catalogue d'icônes proposé pour les catégories (une seule famille, arrondie).
const categoryIcons = <String, IconData>{
  'category': Icons.category_rounded,
  'home': Icons.home_rounded,
  'shopping_cart': Icons.shopping_cart_rounded,
  'shopping_bag': Icons.shopping_bag_rounded,
  'restaurant': Icons.restaurant_rounded,
  'fastfood': Icons.fastfood_rounded,
  'coffee': Icons.coffee_rounded,
  'directions_car': Icons.directions_car_rounded,
  'local_gas_station': Icons.local_gas_station_rounded,
  'train': Icons.train_rounded,
  'flight': Icons.flight_rounded,
  'subscriptions': Icons.subscriptions_rounded,
  'language': Icons.language_rounded,
  'smartphone': Icons.smartphone_rounded,
  'medical_services': Icons.medical_services_rounded,
  'fitness_center': Icons.fitness_center_rounded,
  'movie': Icons.movie_rounded,
  'celebration': Icons.celebration_rounded,
  'card_giftcard': Icons.card_giftcard_rounded,
  'checkroom': Icons.checkroom_rounded,
  'pets': Icons.pets_rounded,
  'school': Icons.school_rounded,
  'shield': Icons.shield_rounded,
  'account_balance': Icons.account_balance_rounded,
  'savings': Icons.savings_rounded,
  'work': Icons.work_rounded,
  'local_atm': Icons.local_atm_rounded,
  'swap_horiz': Icons.swap_horiz_rounded,
  'flash_on': Icons.bolt_rounded,
};

IconData categoryIcon(String? code) =>
    categoryIcons[code] ?? Icons.category_rounded;

/// Couleurs proposées pour les catégories.
const categoryPalette = [
  0xFFF44336,
  0xFFEC4899,
  0xFFA855F7,
  0xFF6366F1,
  0xFF3B82F6,
  0xFF06B6D4,
  0xFF14B8A6,
  0xFF22C55E,
  0xFF84CC16,
  0xFFEAB308,
  0xFFF97316,
  0xFF92705A,
  0xFF64748B,
];

/// Pastille d'icône d'une catégorie.
class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      IconBadge(icon: icon, color: color, size: size);
}

// ── Montants ─────────────────────────────────────────────────────────────────

/// Un montant, avec chiffres alignés. Masqué si l'utilisateur a choisi de cacher les montants.
class Amount extends ConsumerWidget {
  const Amount(
    this.value, {
    super.key,
    this.style,
    this.signed = false,
    this.colored = false,
    this.textAlign,
    this.animated = false,
  });
  final double value;
  final TextStyle? style;

  /// Affiche le « + » des entrées.
  final bool signed;

  /// Colore les entrées en vert et les sorties en rouge (toujours avec leur signe).
  final bool colored;
  final TextAlign? textAlign;

  /// Fait défiler le nombre jusqu'à sa valeur.
  final bool animated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(devicePrefsProvider.select((p) => p.hideAmounts));
    String format(double v) => signed ? Fmt.signed(v) : Fmt.money(v);
    var base = (style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: tabular,
    );
    if (colored && value != 0) {
      base = base.copyWith(
        color: value > 0 ? context.moneo.income : context.moneo.expense,
      );
    }
    if (hidden) {
      return Text(
        '•••• €',
        textAlign: textAlign,
        maxLines: 1,
        softWrap: false,
        semanticsLabel: 'Montant masqué',
        style: base,
      );
    }
    if (animated) {
      return NumberTicker(value: value, format: format, style: base);
    }
    return Text(
      format(value),
      textAlign: textAlign,
      maxLines: 1,
      softWrap: false,
      style: base,
    );
  }
}

// ── Séparateurs et titres ────────────────────────────────────────────────────

/// Filet de séparation.
class Perforation extends StatelessWidget {
  const Perforation({super.key, this.axis = Axis.horizontal, this.color});
  final Axis axis;
  final Color? color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: axis == Axis.vertical ? 1 : null,
      height: axis == Axis.horizontal ? 1 : null,
      color: color ?? context.moneo.line,
    ),
  );
}

/// Titre de section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      Gap.page + 4,
      Gap.xl,
      Gap.page,
      Gap.sm,
    ),
  });
  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) =>
      GroupLabel(title, trailing: trailing, padding: padding);
}

// ── États : chargement, vide, erreur ─────────────────────────────────────────

/// Bloc qui tient la place d'un contenu en cours de chargement, traversé par un reflet.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 10});
  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.reduceMotion ? _controller.stop() : _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.6 + _controller.value * 3.2, 0),
              end: Alignment(-0.6 + _controller.value * 3.2, 0),
              colors: [c.raised, Color.lerp(c.raised, c.ink, 0.10)!, c.raised],
            ),
          ),
        ),
      ),
    );
  }
}

/// Liste fantôme affichée pendant le premier chargement.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.rows = 6});
  final int rows;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Chargement',
    child: Column(
      children: [
        for (var i = 0; i < rows; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
            child: MCard(
              radius: Radii.tile,
              padding: const EdgeInsets.all(Gap.md),
              child: Row(
                children: [
                  const Skeleton(width: 46, height: 46, radius: 16),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton(width: 120.0 + (i % 3) * 30),
                        const SizedBox(height: Gap.sm),
                        const Skeleton(width: 90, height: 12),
                      ],
                    ),
                  ),
                  const Skeleton(width: 70),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// État vide : dit ce qui manque et propose l'action qui le remplit.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.xxl,
        vertical: Gap.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    c.brand.withValues(alpha: 0.28),
                    c.brand.withValues(alpha: 0.04),
                  ],
                ),
                border: Border.all(color: c.brand.withValues(alpha: 0.25)),
              ),
              child: Icon(
                icon,
                size: 32,
                color: context.isDark ? c.brandBright : c.brandDeep,
              ),
            ),
          ),
          const SizedBox(height: Gap.lg),
          Text(
            title,
            style: context.text.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gap.sm),
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(color: c.inkSoft),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: Gap.xl),
            SoftButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

/// Erreur de chargement avec un bouton pour réessayer.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final e = ApiException.from(error);
    return EmptyState(
      icon: e.offline ? Icons.cloud_off_rounded : Icons.error_outline_rounded,
      title: e.offline ? 'Pas de connexion' : 'Chargement impossible',
      message: e.message,
      actionLabel: 'Réessayer',
      onAction: onRetry,
    );
  }
}

/// Bandeau affiché quand l'app travaille sur ses données en cache.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineProvider);
    final waiting = ref.watch(outboxProvider).length;
    if (!offline && waiting == 0) return const SizedBox.shrink();
    final c = context.moneo;
    final message = waiting > 0
        ? '$waiting opération${waiting > 1 ? 's' : ''} en attente d’envoi'
        : 'Hors ligne · dernières données connues';
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.xs, Gap.xs),
        decoration: BoxDecoration(
          color: c.highlight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.warning.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Icon(Icons.cloud_off_rounded, size: 18, color: c.warning),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Text(
                message,
                style: context.text.labelMedium?.copyWith(color: c.ink),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(appDataProvider.notifier).refresh(),
              style: TextButton.styleFrom(
                foregroundColor: c.ink,
                minimumSize: const Size(48, 44),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Retours utilisateur ──────────────────────────────────────────────────────

void showMessage(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

void showError(BuildContext context, Object error) =>
    showMessage(context, ApiException.from(error).message);

/// Exécute une action réseau et affiche l'erreur éventuelle. Renvoie `true` en cas de succès.
Future<bool> guard(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (success != null && context.mounted) showMessage(context, success);
    return true;
  } catch (error) {
    if (context.mounted) showError(context, error);
    return false;
  }
}

/// Demande de confirmation, dans une feuille maison plutôt qu'une boîte de dialogue système.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final result = await showSheet<bool>(
    context,
    Builder(
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: context.text.titleLarge),
              ),
              const SizedBox(height: Gap.sm),
              Text(
                message,
                style: context.text.bodyMedium?.copyWith(
                  color: context.moneo.inkSoft,
                ),
              ),
              const SizedBox(height: Gap.xl),
              if (destructive)
                Pressable(
                  onTap: () => Navigator.pop(context, true),
                  scale: 0.97,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.scheme.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      confirmLabel,
                      style: context.text.labelLarge?.copyWith(
                        color: context.scheme.onError,
                        fontSize: 16.5,
                      ),
                    ),
                  ),
                )
              else
                PrimaryButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.pop(context, true),
                ),
              const SizedBox(height: Gap.sm),
              SoftButton(
                label: 'Annuler',
                expand: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Feuille modale qui remonte avec le clavier et respecte les zones sûres.
Future<T?> showSheet<T>(
  BuildContext context,
  Widget child, {
  bool expand = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  useRootNavigator: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: expand
        ? FractionallySizedBox(heightFactor: 0.94, child: child)
        : child,
  ),
);

/// En-tête commun des feuilles : titre et bouton de fermeture.
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.md, Gap.md),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: context.text.headlineSmall),
          ),
        ),
        if (action != null) action!,
        RoundIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Fermer',
          size: 40,
          onTap: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

/// Bouton principal qui affiche sa progression et se désactive pendant l'envoi.
class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) =>
      PrimaryButton(label: label, icon: icon, busy: busy, onPressed: onPressed);
}
