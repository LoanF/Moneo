import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../editor/tx_editor.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Titre et sous-titre d'une opération, partagés par la liste et la recherche.
({String title, String subtitle}) describeTx(Tx tx, Bootstrap data) {
  final category = data.categoryLabel(tx.categoryId);
  final method = data.paymentMethod(tx.paymentMethodId);
  final details = <String>[];

  String title;
  if (tx.type == TxType.transfer) {
    title = (tx.note?.isNotEmpty ?? false) ? tx.note! : 'Transfert';
    details.add(
      tx.counterparty != null
          ? (tx.amount < 0
                ? 'Vers ${tx.counterparty}'
                : 'Depuis ${tx.counterparty}')
          : (tx.amount < 0 ? 'Sortie du compte' : 'Entrée sur le compte'),
    );
  } else if (tx.note?.isNotEmpty ?? false) {
    title = tx.note!;
    if (tx.categoryId != null) details.add(category);
  } else {
    title = category;
  }
  if (tx.chequeNumber != null) {
    details.add('Chèque n° ${tx.chequeNumber}');
  } else if (method != null) {
    details.add(method.name);
  }
  if (tx.recurringPaymentId != null) details.add('mensuel');
  return (title: title, subtitle: details.join(' · '));
}

/// Icône et couleur d'une opération : celles de sa catégorie principale.
({IconData icon, Color color}) txVisual(Tx tx, Bootstrap data, MoneoColors c) {
  if (tx.type == TxType.transfer) {
    return (icon: Icons.swap_horiz_rounded, color: const Color(0xFF3B82F6));
  }
  final category = data.category(tx.categoryId);
  final root = data.category(category?.parentId) ?? category;
  if (root == null) {
    return (
      icon: tx.amount > 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
      color: tx.amount > 0 ? c.income : c.inkSoft,
    );
  }
  return (icon: categoryIcon(root.iconCode), color: Color(root.colorValue));
}

/// Une opération, dans sa carte. La pastille pointe d'un appui, la carte ouvre la modification,
/// un glissement pointe (vers la droite) ou supprime (vers la gauche).
class TxTile extends ConsumerWidget {
  const TxTile({
    super.key,
    required this.tx,
    required this.filter,
    this.showDate = false,
    this.showAccount = false,
  });
  final Tx tx;

  /// Filtre de la liste qui contient cette ligne (pour la mise à jour immédiate à l'écran).
  final TxFilter filter;
  final bool showDate;
  final bool showAccount;

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool checked,
  ) async {
    final list = ref.read(txListProvider(filter).notifier);
    list.patchLocal(
      (items) => [
        for (final t in items)
          t.id == tx.id ? t.copyWith(isChecked: checked) : t,
      ],
    );
    final ok = await guard(
      context,
      () => ref.read(txActionsProvider).setChecked([tx.id], checked),
    );
    if (!ok) {
      list.patchLocal(
        (items) => [
          for (final t in items)
            t.id == tx.id ? t.copyWith(isChecked: !checked) : t,
        ],
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final transfer = tx.type == TxType.transfer && tx.transferId != null;
    final sure = await confirm(
      context,
      title: transfer
          ? 'Supprimer ce transfert ?'
          : 'Supprimer cette opération ?',
      message: transfer
          ? 'Les deux écritures du transfert seront supprimées, sur les deux comptes.'
          : 'Le solde du compte sera recalculé.',
      confirmLabel: 'Supprimer',
    );
    if (!sure || !context.mounted) return;
    await guard(
      context,
      () => ref.read(txActionsProvider).delete(tx.id),
      success: 'Opération supprimée',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const SizedBox.shrink();
    final c = context.moneo;
    final (:title, :subtitle) = describeTx(tx, data);
    final visual = txVisual(tx, data, c);
    final future = tx.date.compareTo(Fmt.today()) > 0;
    final meta = [
      if (showAccount) data.account(tx.accountId)?.name,
      if (showDate) Fmt.shortDate(tx.date),
      if (future && !showDate) 'à venir',
    ].whereType<String>().join(' · ');
    final muted = tx.isChecked;

    final card = Pressable(
      onTap: tx.pending ? null : () => openTxEditor(context, existing: tx),
      onLongPress: tx.pending
          ? null
          : () {
              HapticFeedback.mediumImpact();
              _showActions(context, ref);
            },
      scale: 0.985,
      haptic: false,
      child: MCard(
        radius: Radii.tile,
        padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.xs, Gap.lg, Gap.xs),
        child: Row(
          children: [
            if (tx.pending)
              SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: Tooltip(
                    message: 'En attente d’envoi',
                    child: IconBadge(
                      icon: Icons.schedule_send_rounded,
                      color: c.warning,
                    ),
                  ),
                ),
              )
            else
              CheckBadge(
                checked: tx.isChecked,
                icon: visual.icon,
                color: visual.color,
                onChanged: (v) => _toggle(context, ref, v),
              ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium?.copyWith(
                      color: muted ? c.inkSoft : c.ink,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodySmall?.copyWith(color: c.inkSoft),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Gap.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Amount(
                  tx.amount,
                  signed: true,
                  colored: !muted,
                  style: context.text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: muted ? c.inkSoft : null,
                  ),
                ),
                if (muted || meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (muted) 'Pointée',
                      if (meta.isNotEmpty) meta,
                    ].join(' · '),
                    style: context.text.bodySmall?.copyWith(
                      color: muted ? c.income : c.inkSoft,
                      fontWeight: muted ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    final padded = Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      child: card,
    );
    if (tx.pending) return padded;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.tile),
        child: Dismissible(
          key: ValueKey('tx-${tx.id}'),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              await _toggle(context, ref, !tx.isChecked);
            } else {
              await _delete(context, ref);
            }
            return false;
          },
          background: _SwipeBackground(
            alignment: Alignment.centerLeft,
            color: c.income,
            icon: tx.isChecked ? Icons.undo_rounded : Icons.check_rounded,
            label: tx.isChecked ? 'Dépointer' : 'Pointer',
          ),
          secondaryBackground: _SwipeBackground(
            alignment: Alignment.centerRight,
            color: context.scheme.error,
            icon: Icons.delete_rounded,
            label: 'Supprimer',
          ),
          child: card,
        ),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final c = context.moneo;
    showSheet<void>(
      context,
      Builder(
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Gap.md),
            child: GroupCard(
              children: [
                GroupTile(
                  icon: tx.isChecked ? Icons.undo_rounded : Icons.check_rounded,
                  color: c.income,
                  title: tx.isChecked ? 'Dépointer' : 'Pointer',
                  onTap: () {
                    Navigator.pop(sheet);
                    _toggle(context, ref, !tx.isChecked);
                  },
                ),
                if (tx.type != TxType.transfer)
                  GroupTile(
                    icon: Icons.copy_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'Dupliquer à aujourd’hui',
                    onTap: () {
                      Navigator.pop(sheet);
                      openTxEditor(context, template: tx);
                    },
                  ),
                GroupTile(
                  icon: Icons.delete_rounded,
                  danger: true,
                  title: 'Supprimer',
                  onTap: () {
                    Navigator.pop(sheet);
                    _delete(context, ref);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
  });
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final foreground = context.isDark ? Colors.black : Colors.white;
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground),
          const SizedBox(width: Gap.sm),
          Text(
            label,
            style: context.text.labelLarge?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// Regroupe des opérations par jour, en conservant leur ordre.
List<({String date, List<Tx> items})> groupByDay(List<Tx> items) {
  final groups = <({String date, List<Tx> items})>[];
  for (final tx in items) {
    if (groups.isEmpty || groups.last.date != tx.date) {
      groups.add((date: tx.date, items: [tx]));
    } else {
      groups.last.items.add(tx);
    }
  }
  return groups;
}
