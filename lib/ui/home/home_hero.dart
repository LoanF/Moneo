import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Haut de l'accueil : un compte à la fois. On glisse d'un compte à l'autre, et le grand
/// chiffre est toujours le solde du compte affiché — celui dont on consulte les opérations.
class HomeHero extends ConsumerStatefulWidget {
  const HomeHero({super.key, required this.bootstrap, required this.account});
  final Bootstrap bootstrap;
  final Account account;

  @override
  ConsumerState<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends ConsumerState<HomeHero> {
  late final PageController _pages;

  List<Account> get _accounts => widget.bootstrap.activeAccounts;
  int get _index {
    final i = _accounts.indexWhere((a) => a.id == widget.account.id);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _index);
  }

  @override
  void didUpdateWidget(HomeHero old) {
    super.didUpdateWidget(old);
    // Le compte a changé ailleurs (liste des comptes) : la page suit.
    if (_pages.hasClients && _pages.page?.round() != _index) {
      _pages.animateToPage(
        _index,
        duration: context.reduceMotion
            ? const Duration(milliseconds: 1)
            : Motion.base,
        curve: Motion.curve,
      );
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _select(Account account) =>
      ref.read(selectedAccountIdProvider.notifier).select(account.id);

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    final hidden = ref.watch(devicePrefsProvider.select((p) => p.hideAmounts));
    final accounts = _accounts;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Gap.sm),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.md, 0),
            child: Row(
              children: [
                // Le nom du compte ouvre la liste des comptes (et leur total).
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Pressable(
                      onTap: () => showSheet<void>(
                        context,
                        AccountPicker(current: widget.account.id),
                      ),
                      label:
                          'Compte affiché : ${widget.account.name}. Changer de compte',
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.only(left: 6, right: 12),
                        decoration: BoxDecoration(
                          color: (context.isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: c.ink.withValues(alpha: 0.08),
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: c.brandGradient,
                                ),
                                child: Icon(
                                  accountIcon(widget.account.type),
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: Gap.sm),
                              Flexible(
                                child: AnimatedSwitcher(
                                  duration: Motion.fast,
                                  child: Text(
                                    widget.account.name,
                                    key: ValueKey(widget.account.id),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.labelLarge,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.unfold_more_rounded,
                                size: 18,
                                color: c.inkSoft,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                RoundIconButton(
                  icon: hidden
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  tooltip: hidden
                      ? 'Afficher les montants'
                      : 'Masquer les montants',
                  onTap: () => ref
                      .read(devicePrefsProvider.notifier)
                      .update((p) => p.copyWith(hideAmounts: !p.hideAmounts)),
                ),
                RoundIconButton(
                  icon: Icons.notifications_rounded,
                  tooltip: 'Notifications',
                  badge: widget.bootstrap.unreadNotifications,
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 212,
            child: PageView.builder(
              controller: _pages,
              itemCount: accounts.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => _select(accounts[i]),
              itemBuilder: (_, i) => _AccountPage(account: accounts[i]),
            ),
          ),
          if (accounts.length > 1)
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < accounts.length; i++)
                    AnimatedContainer(
                      duration: context.reduceMotion
                          ? Duration.zero
                          : Motion.base,
                      curve: Motion.curve,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _index ? c.brand : c.perforation,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

IconData accountIcon(String type) => switch (type) {
  'savings' => Icons.savings_rounded,
  'cash' => Icons.payments_rounded,
  'investment' => Icons.trending_up_rounded,
  _ => Icons.account_balance_wallet_rounded,
};

/// Le solde d'un compte : ce qu'il reste, puis ce qui est pointé et le solde du jour.
class _AccountPage extends StatelessWidget {
  const _AccountPage({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final c = context.moneo;
    Widget stat(
      String label,
      double value,
      IconData icon,
      Color tint,
    ) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 10),
        decoration: BoxDecoration(
          color: (context.isDark ? Colors.white : Colors.black).withValues(
            alpha: 0.06,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.ink.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: tint),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.text.bodySmall?.copyWith(
                      color: c.inkSoft,
                      fontSize: 12,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Amount(
                      value,
                      style: context.text.titleSmall?.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final toCheck = account.uncheckedCount == 0
        ? 'Tout est pointé'
        : '${account.uncheckedCount} opération${account.uncheckedCount > 1 ? 's' : ''} à pointer · ${Fmt.signed(account.uncheckedCredit - account.uncheckedDebit)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.page, Gap.xl, Gap.page, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde restant',
            style: context.text.bodyMedium?.copyWith(color: c.inkSoft),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Amount(
              account.balance,
              animated: true,
              style: context.text.displayMedium?.copyWith(
                color: account.balance < 0 ? c.expense : c.ink,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            toCheck,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(color: c.inkSoft),
          ),
          const Spacer(),
          Row(
            children: [
              stat(
                'Pointé',
                account.pointedBalance,
                Icons.verified_rounded,
                c.income,
              ),
              const SizedBox(width: Gap.sm),
              stat(
                'À ce jour',
                account.todayBalance,
                Icons.today_rounded,
                c.inkSoft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Liste des comptes, avec le total de ceux qui comptent dans le patrimoine.
class AccountPicker extends ConsumerWidget {
  const AccountPicker({super.key, required this.current});
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const SizedBox.shrink();
    final c = context.moneo;
    final accounts = data.activeAccounts;
    final total = accounts
        .where((a) => a.includeInTotal)
        .fold<double>(0, (sum, a) => sum + a.balance);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader('Mes comptes'),
          Flexible(
            child: SingleChildScrollView(
              child: GroupCard(
                children: [
                  for (final account in accounts)
                    GroupTile(
                      leading: IconBadge(
                        icon: accountIcon(account.type),
                        color: c.brand,
                        size: 42,
                        solid: account.id == current,
                      ),
                      title: account.name,
                      subtitle: account.uncheckedCount == 0
                          ? 'Tout est pointé'
                          : '${account.uncheckedCount} à pointer',
                      trailing: Amount(
                        account.balance,
                        style: context.text.titleMedium,
                      ),
                      onTap: () {
                        ref
                            .read(selectedAccountIdProvider.notifier)
                            .select(account.id);
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ),
          ),
          if (accounts.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Gap.page + Gap.lg,
                Gap.lg,
                Gap.page + Gap.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total des comptes',
                      style: context.text.bodyLarge?.copyWith(color: c.inkSoft),
                    ),
                  ),
                  Amount(total, style: context.text.titleLarge),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.page,
              Gap.lg,
              Gap.page,
              Gap.md,
            ),
            child: SoftButton(
              label: 'Gérer les comptes',
              icon: Icons.tune_rounded,
              expand: true,
              onPressed: () {
                Navigator.pop(context);
                context.push('/settings/accounts');
              },
            ),
          ),
        ],
      ),
    );
  }
}
