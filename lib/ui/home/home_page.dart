import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../editor/tx_editor.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import 'home_hero.dart';
import 'tx_tile.dart';

/// Accueil : le solde, les comptes, les actions rapides et les opérations à pointer.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  /// `true` : seulement les opérations à pointer. C'est la vue de travail par défaut.
  bool _uncheckedOnly = true;
  final _scroll = ScrollController();

  TxFilter _filter(String accountId) =>
      TxFilter(accountId: accountId, isChecked: _uncheckedOnly ? false : null);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final account = ref.read(currentAccountProvider);
      if (account != null && _scroll.position.extentAfter < 600) {
        ref.read(txListProvider(_filter(account.id)).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider);
    final account = ref.watch(currentAccountProvider);

    return Scaffold(
      body: data.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const SafeArea(
          child: Padding(
            padding: EdgeInsets.only(top: Gap.xxl),
            child: SkeletonList(rows: 7),
          ),
        ),
        error: (error, _) => SafeArea(
          child: Center(
            child: ErrorState(
              error: error,
              onRetry: () => ref.invalidate(appDataProvider),
            ),
          ),
        ),
        data: (bootstrap) {
          if (account == null) {
            return _NoAccount(
              onCreate: () => context.push('/settings/accounts'),
            );
          }
          final filter = _filter(account.id);
          final list = ref.watch(txListProvider(filter));
          final pending = pendingTxFor(ref.watch(outboxProvider), account.id);

          return Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GlowBackdrop(),
              ),
              RefreshIndicator(
                color: context.moneo.brand,
                backgroundColor: context.moneo.card,
                edgeOffset: MediaQuery.paddingOf(context).top,
                onRefresh: () async {
                  ref.read(dataVersionProvider.notifier).bump();
                  await ref.read(appDataProvider.notifier).refresh();
                },
                child: CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: HomeHero(bootstrap: bootstrap, account: account),
                    ),
                    SliverToBoxAdapter(
                      child: _QuickActions(accountId: account.id),
                    ),
                    const SliverToBoxAdapter(child: OfflineBanner()),
                    if (bootstrap.pendingRecurring > 0)
                      SliverToBoxAdapter(
                        child: _RecurringBanner(
                          count: bootstrap.pendingRecurring,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Gap.page,
                          Gap.xl,
                          Gap.page,
                          Gap.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                'Opérations',
                                style: context.text.headlineSmall,
                              ),
                            ),
                            const SizedBox(height: Gap.md),
                            PillTabs<bool>(
                              value: _uncheckedOnly,
                              onChanged: (v) =>
                                  setState(() => _uncheckedOnly = v),
                              items: [
                                (
                                  value: true,
                                  label: account.uncheckedCount > 0
                                      ? 'À pointer · ${account.uncheckedCount}'
                                      : 'À pointer',
                                ),
                                (value: false, label: 'Toutes'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (pending.isNotEmpty) ...[
                      const SliverToBoxAdapter(
                        child: GroupLabel(
                          'En attente d’envoi',
                          padding: EdgeInsets.fromLTRB(
                            Gap.page + 4,
                            Gap.sm,
                            Gap.page,
                            Gap.sm,
                          ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: pending.length,
                        itemBuilder: (_, i) =>
                            TxTile(tx: pending[i], filter: filter),
                      ),
                    ],
                    ...list.when(
                      skipLoadingOnReload: true,
                      skipLoadingOnRefresh: true,
                      loading: () => [
                        const SliverToBoxAdapter(child: SkeletonList(rows: 5)),
                      ],
                      error: (error, _) => [
                        SliverToBoxAdapter(
                          child: ErrorState(
                            error: error,
                            onRetry: () =>
                                ref.invalidate(txListProvider(filter)),
                          ),
                        ),
                      ],
                      data: (state) {
                        if (state.items.isEmpty && pending.isEmpty) {
                          return [
                            SliverToBoxAdapter(
                              child:
                                  _uncheckedOnly && account.transactionCount > 0
                                  ? EmptyState(
                                      icon: Icons.task_alt_rounded,
                                      title: 'Tout est pointé',
                                      message:
                                          'Votre suivi correspond à votre relevé. Les nouvelles opérations apparaîtront ici.',
                                      actionLabel: 'Voir toutes les opérations',
                                      onAction: () => setState(
                                        () => _uncheckedOnly = false,
                                      ),
                                    )
                                  : EmptyState(
                                      icon: Icons.receipt_long_rounded,
                                      title: 'Aucune opération',
                                      message:
                                          'Ajoutez votre première dépense ou votre premier revenu : le solde se met à jour tout seul.',
                                      actionLabel: 'Ajouter une opération',
                                      onAction: () => openTxEditor(context),
                                    ),
                            ),
                          ];
                        }
                        var index = 0;
                        return [
                          for (final group in groupByDay(state.items)) ...[
                            SliverToBoxAdapter(
                              child: GroupLabel(
                                Fmt.dayLabel(group.date),
                                padding: const EdgeInsets.fromLTRB(
                                  Gap.page + 4,
                                  Gap.md,
                                  Gap.page,
                                  Gap.sm,
                                ),
                              ),
                            ),
                            SliverList.list(
                              children: [
                                for (final tx in group.items)
                                  FadeSlideIn(
                                    key: ValueKey('in-${tx.id}'),
                                    index: index++,
                                    child: TxTile(tx: tx, filter: filter),
                                  ),
                              ],
                            ),
                          ],
                          if (state.loadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(Gap.xl),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ];
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: Gap.dock)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// En-tête : salutation, raccourcis, et le solde total qui défile jusqu'à sa valeur.
class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.accountId});
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    Widget action(
      String label,
      IconData icon,
      VoidCallback onTap, {
      bool primary = false,
    }) => Expanded(
      child: Pressable(
        onTap: onTap,
        scale: 0.93,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: primary ? c.brandGradient : null,
                color: primary ? null : c.card,
                border: Border.all(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.18)
                      : c.line,
                ),
                boxShadow: [
                  if (primary)
                    BoxShadow(
                      color: c.glow,
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                      spreadRadius: -6,
                    ),
                ],
              ),
              child: Icon(
                icon,
                color: primary ? Colors.white : c.ink,
                size: 26,
              ),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(color: c.ink),
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.md, Gap.xl, Gap.md, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          action(
            'Dépense',
            Icons.remove_rounded,
            () => openTxEditor(context, initialType: TxType.expense),
            primary: true,
          ),
          action(
            'Revenu',
            Icons.add_rounded,
            () => openTxEditor(context, initialType: TxType.income),
          ),
          action(
            'Transfert',
            Icons.swap_horiz_rounded,
            () => openTxEditor(context, initialType: TxType.transfer),
          ),
          action(
            'Rechercher',
            Icons.search_rounded,
            () => context.push('/search', extra: accountId),
          ),
        ],
      ),
    );
  }
}

/// Les comptes, en cartes à faire défiler. Celle du compte affiché est rouge, parcourue par un faisceau.
class _RecurringBanner extends StatelessWidget {
  const _RecurringBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.md),
    child: GroupCard(
      children: [
        GroupTile(
          icon: Icons.event_repeat_rounded,
          color: context.moneo.warning,
          title: '$count mensualité${count > 1 ? 's' : ''} à mettre en place',
          subtitle: 'Ajoutez d’un coup les opérations de ce mois.',
          onTap: () => context.go('/plan'),
        ),
      ],
    ),
  );
}

class _NoAccount extends StatelessWidget {
  const _NoAccount({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned(top: 0, left: 0, right: 0, child: GlowBackdrop()),
      SafeArea(
        child: Center(
          child: EmptyState(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Aucun compte',
            message:
                'Créez un compte avec son solde de départ pour commencer le suivi.',
            actionLabel: 'Créer un compte',
            onAction: onCreate,
          ),
        ),
      ),
    ],
  );
}
