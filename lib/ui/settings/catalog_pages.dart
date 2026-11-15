import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

String _plain(double v) => Fmt.plain(v).replaceAll(RegExp(r'[\s  ]'), '');

/// Enregistre via l'API, recharge l'état, ferme la feuille en cas de succès.
Future<void> _submit(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function(MoneoApi api) action,
) async {
  final ok = await guard(
    context,
    () => ref.read(appDataProvider.notifier).mutate(action),
  );
  if (ok && context.mounted) Navigator.pop(context);
}

/// Squelette commun d'une feuille d'édition : titre, champs, bouton, suppression éventuelle.
class _EditorSheet extends StatefulWidget {
  const _EditorSheet({
    required this.title,
    required this.children,
    required this.onSave,
    this.onDelete,
  });
  final String title;
  final List<Widget> children;
  final Future<void> Function() onSave;
  final Future<void> Function()? onDelete;

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  final _form = GlobalKey<FormState>();
  bool _busy = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    await widget.onSave();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(
              widget.title,
              action: widget.onDelete == null
                  ? null
                  : IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_rounded),
                      tooltip: 'Supprimer',
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...widget.children,
                  const SizedBox(height: Gap.xl),
                  SubmitButton(
                    label: 'Enregistrer',
                    icon: Icons.check_rounded,
                    busy: _busy,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _nameField(
  TextEditingController controller, {
  String label = 'Nom',
  String? hint,
  bool autofocus = false,
}) => TextFormField(
  controller: controller,
  autofocus: autofocus,
  textCapitalization: TextCapitalization.sentences,
  validator: (v) => (v?.trim().isEmpty ?? true) ? 'Ce champ est requis' : null,
  decoration: InputDecoration(labelText: label, hintText: hint),
);

Widget _fieldLabel(BuildContext context, String text) => Padding(
  padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.sm),
  child: Text(
    text,
    style: context.text.labelLarge?.copyWith(color: context.moneo.inkSoft),
  ),
);

// ── Comptes ──────────────────────────────────────────────────────────────────

class AccountsPage extends ConsumerWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    final accounts = data?.accounts ?? const <Account>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Comptes')),
      floatingActionButton: AddButton(
        label: 'Compte',
        icon: Icons.add_rounded,
        onPressed: () => showSheet<void>(context, const AccountEditor()),
      ),
      body: accounts.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Aucun compte',
                message:
                    'Un compte regroupe vos opérations et porte un solde de départ.',
                actionLabel: 'Créer un compte',
                onAction: () => showSheet<void>(context, const AccountEditor()),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.dock),
              itemCount: accounts.length,
              onReorderItem: (from, to) {
                final ids = [for (final a in accounts) a.id];
                ids.insert(to, ids.removeAt(from));
                guard(
                  context,
                  () => ref
                      .read(appDataProvider.notifier)
                      .mutate((api) => api.reorderAccounts(ids)),
                );
              },
              itemBuilder: (context, i) {
                final a = accounts[i];
                return GroupTile(
                  key: ValueKey(a.id),
                  title: a.name,
                  subtitle: [
                    accountTypeLabels[a.type] ?? 'Compte',
                    if (a.archived) 'archivé',
                    if (!a.includeInTotal) 'hors total',
                  ].join(' · '),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Amount(a.balance, style: context.text.titleMedium),
                      const SizedBox(width: Gap.sm),
                      ReorderableDragStartListener(
                        index: i,
                        child: const Icon(
                          Icons.drag_handle_rounded,
                          semanticLabel: 'Réordonner',
                        ),
                      ),
                    ],
                  ),
                  onTap: () =>
                      showSheet<void>(context, AccountEditor(existing: a)),
                );
              },
            ),
    );
  }
}

class AccountEditor extends ConsumerStatefulWidget {
  const AccountEditor({super.key, this.existing});
  final Account? existing;

  @override
  ConsumerState<AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<AccountEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _initial = TextEditingController(
    text: widget.existing == null
        ? ''
        : _plain(widget.existing!.initialBalance),
  );
  late final _threshold = TextEditingController(
    text: widget.existing?.lowBalanceThreshold == null
        ? ''
        : _plain(widget.existing!.lowBalanceThreshold!),
  );
  late String _type = widget.existing?.type ?? 'checking';
  late bool _inTotal = widget.existing?.includeInTotal ?? true;
  late bool _archived = widget.existing?.archived ?? false;

  @override
  void dispose() {
    _name.dispose();
    _initial.dispose();
    _threshold.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return _EditorSheet(
      title: existing == null ? 'Nouveau compte' : 'Modifier le compte',
      onSave: () => _submit(
        context,
        ref,
        (api) => api.saveAccount(existing?.id, {
          'name': _name.text.trim(),
          'type': _type,
          'initialBalance': Fmt.parseAmount(_initial.text) ?? 0,
          'lowBalanceThreshold': Fmt.parseAmount(_threshold.text),
          'includeInTotal': _inTotal,
          if (existing != null) 'archived': _archived,
        }),
      ),
      onDelete: existing == null
          ? null
          : () async {
              final sure = await confirm(
                context,
                title: 'Supprimer « ${existing.name} » ?',
                message:
                    'Ses ${existing.transactionCount} opérations et ses mensualités seront supprimées définitivement. '
                    'Pour le garder dans l’historique, archivez-le plutôt.',
                confirmLabel: 'Supprimer le compte',
              );
              if (sure && context.mounted) {
                await _submit(
                  context,
                  ref,
                  (api) => api.deleteAccountById(existing.id),
                );
              }
            },
      children: [
        _nameField(
          _name,
          hint: 'Compte courant, Livret A…',
          autofocus: existing == null,
        ),
        _fieldLabel(context, 'Type'),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final e in accountTypeLabels.entries)
              ChoicePill(
                label: e.value,
                selected: _type == e.key,
                onTap: () => setState(() => _type = e.key),
              ),
          ],
        ),
        const SizedBox(height: Gap.lg),
        TextFormField(
          controller: _initial,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Solde de départ',
            suffixText: '€',
            helperText:
                'Le solde du compte au moment où votre suivi commence. Tous les soldes en découlent.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _threshold,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: const InputDecoration(
            labelText: 'Alerte de solde bas (facultatif)',
            suffixText: '€',
            helperText: 'Vide : le seuil général des réglages s’applique.',
          ),
        ),
        SwitchTile(
          title: 'Compter dans le total',
          value: _inTotal,
          onChanged: (v) => setState(() => _inTotal = v),
        ),
        if (existing != null)
          SwitchTile(
            title: 'Archivé',
            subtitle: 'Masqué de l’accueil, historique conservé.',
            value: _archived,
            onChanged: (v) => setState(() => _archived = v),
          ),
      ],
    );
  }
}

// ── Catégories ───────────────────────────────────────────────────────────────

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const Scaffold();
    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      floatingActionButton: AddButton(
        label: 'Catégorie',
        icon: Icons.add_rounded,
        onPressed: () => showSheet<void>(context, const CategoryEditor()),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.dock),
        children: [
          for (final root in data.rootCategories)
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.md),
              child: GroupCard(
                children: [
                  GroupTile(
                    leading: CategoryBadge(
                      icon: categoryIcon(root.iconCode),
                      color: Color(root.colorValue),
                    ),
                    title: root.name,
                    trailing: IconButton(
                      onPressed: () => showSheet<void>(
                        context,
                        CategoryEditor(parent: root),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'Ajouter une sous-catégorie à ${root.name}',
                    ),
                    onTap: () => showSheet<void>(
                      context,
                      CategoryEditor(existing: root),
                    ),
                  ),
                  for (final child in data.childrenOf(root.id))
                    GroupTile(
                      leading: SizedBox(
                        width: 42,
                        height: 28,
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(root.colorValue),
                            ),
                          ),
                        ),
                      ),
                      title: child.name,
                      onTap: () => showSheet<void>(
                        context,
                        CategoryEditor(existing: child, parent: root),
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

class CategoryEditor extends ConsumerStatefulWidget {
  const CategoryEditor({super.key, this.existing, this.parent});
  final Category? existing;
  final Category? parent;

  @override
  ConsumerState<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<CategoryEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _icon =
      widget.existing?.iconCode ?? widget.parent?.iconCode ?? 'category';
  late int _color =
      widget.existing?.colorValue ??
      widget.parent?.colorValue ??
      categoryPalette.first;

  bool get _isSub => widget.parent != null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return _EditorSheet(
      title: existing != null
          ? 'Modifier la catégorie'
          : (_isSub
                ? 'Sous-catégorie de ${widget.parent!.name}'
                : 'Nouvelle catégorie'),
      onSave: () => _submit(
        context,
        ref,
        (api) => api.saveCategory(existing?.id, {
          'name': _name.text.trim(),
          'iconCode': _icon,
          'colorValue': _color,
          if (existing == null && _isSub) 'parentId': widget.parent!.id,
        }),
      ),
      onDelete: existing == null
          ? null
          : () async {
              final sure = await confirm(
                context,
                title: 'Supprimer « ${existing.name} » ?',
                message:
                    'Ses sous-catégories seront supprimées aussi. Les opérations sont conservées, sans catégorie.',
                confirmLabel: 'Supprimer',
              );
              if (sure && context.mounted) {
                await _submit(
                  context,
                  ref,
                  (api) => api.deleteCategory(existing.id),
                );
              }
            },
      children: [
        _nameField(_name, autofocus: existing == null),
        if (!_isSub) ...[
          _fieldLabel(context, 'Couleur'),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final value in categoryPalette)
                Semantics(
                  button: true,
                  selected: _color == value,
                  label: 'Couleur ${categoryPalette.indexOf(value) + 1}',
                  child: InkResponse(
                    onTap: () => setState(() => _color = value),
                    radius: 26,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(value),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == value
                              ? context.moneo.ink
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: _color == value
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          _fieldLabel(context, 'Icône'),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final e in categoryIcons.entries)
                Semantics(
                  button: true,
                  selected: _icon == e.key,
                  label: 'Icône ${e.key.replaceAll('_', ' ')}',
                  child: InkResponse(
                    onTap: () => setState(() => _icon = e.key),
                    radius: 26,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _icon == e.key
                            ? context.scheme.primaryContainer
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _icon == e.key
                              ? context.scheme.primary
                              : context.moneo.line,
                        ),
                      ),
                      child: Icon(
                        e.value,
                        size: 22,
                        color: _icon == e.key
                            ? context.scheme.onPrimaryContainer
                            : context.moneo.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Moyens de paiement et chéquiers ──────────────────────────────────────────

class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  static IconData iconOf(PaymentKind kind) => switch (kind) {
    PaymentKind.card => Icons.credit_card_rounded,
    PaymentKind.cheque => Icons.edit_document,
    PaymentKind.directDebit => Icons.sync_alt_rounded,
    PaymentKind.transfer => Icons.swap_horiz_rounded,
    PaymentKind.cash => Icons.payments_rounded,
    PaymentKind.other => Icons.more_horiz_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const Scaffold();
    return Scaffold(
      appBar: AppBar(title: const Text('Moyens de paiement')),
      floatingActionButton: AddButton(
        label: 'Moyen de paiement',
        icon: Icons.add_rounded,
        onPressed: () => showSheet<void>(context, const PaymentMethodEditor()),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.dock),
        children: [
          GroupCard(
            children: [
              for (final m in data.paymentMethods)
                GroupTile(
                  icon: iconOf(m.kind),
                  color: const Color(0xFF14B8A6),
                  title: m.name,
                  subtitle:
                      '${m.kind.label} · présélectionne ${m.defaultIncome ? 'un revenu' : 'une dépense'}',
                  onTap: () => showSheet<void>(
                    context,
                    PaymentMethodEditor(existing: m),
                  ),
                ),
            ],
          ),
          SectionHeader(
            'Chéquiers',
            trailing: TextButton.icon(
              onPressed: () =>
                  showSheet<void>(context, const ChequebookEditor()),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajouter'),
            ),
          ),
          if (data.chequebooks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.page),
              child: Text(
                'Déclarez votre chéquier : chaque paiement par chèque prendra automatiquement le numéro suivant.',
                style: context.text.bodyMedium?.copyWith(
                  color: context.moneo.inkSoft,
                ),
              ),
            ),
          for (final b in data.chequebooks)
            GroupTile(
              icon: Icons.menu_book_rounded,
              title: b.name,
              subtitle: [
                'Prochain chèque : n° ${b.nextNumber}',
                data.account(b.accountId)?.name ?? 'tous les comptes',
                if (!b.isActive) 'terminé',
              ].join(' · '),
              onTap: () =>
                  showSheet<void>(context, ChequebookEditor(existing: b)),
            ),
        ],
      ),
    );
  }
}

class PaymentMethodEditor extends ConsumerStatefulWidget {
  const PaymentMethodEditor({super.key, this.existing});
  final PaymentMethod? existing;

  @override
  ConsumerState<PaymentMethodEditor> createState() =>
      _PaymentMethodEditorState();
}

class _PaymentMethodEditorState extends ConsumerState<PaymentMethodEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late PaymentKind _kind = widget.existing?.kind ?? PaymentKind.card;
  late bool _income = widget.existing?.defaultIncome ?? false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return _EditorSheet(
      title: existing == null
          ? 'Nouveau moyen de paiement'
          : 'Modifier le moyen de paiement',
      onSave: () => _submit(
        context,
        ref,
        (api) => api.savePaymentMethod(existing?.id, {
          'name': _name.text.trim(),
          'kind': _kind.wire,
          'defaultDirection': _income ? 'income' : 'expense',
        }),
      ),
      onDelete: existing == null
          ? null
          : () async {
              final sure = await confirm(
                context,
                title: 'Supprimer « ${existing.name} » ?',
                message:
                    'Les opérations sont conservées, sans moyen de paiement.',
                confirmLabel: 'Supprimer',
              );
              if (sure && context.mounted) {
                await _submit(
                  context,
                  ref,
                  (api) => api.deletePaymentMethod(existing.id),
                );
              }
            },
      children: [
        _nameField(
          _name,
          hint: 'Carte bancaire, PayPal…',
          autofocus: existing == null,
        ),
        _fieldLabel(context, 'Nature'),
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            for (final k in PaymentKind.values)
              ChoicePill(
                label: k.label,
                selected: _kind == k,
                onTap: () => setState(() => _kind = k),
              ),
          ],
        ),
        _fieldLabel(context, 'À la saisie, présélectionner'),
        PillTabs<bool>(
          value: _income,
          items: [
            (value: false, label: 'Une dépense'),
            (value: true, label: 'Un revenu'),
          ],
          onChanged: (v) => setState(() => _income = v),
        ),
      ],
    );
  }
}

class ChequebookEditor extends ConsumerStatefulWidget {
  const ChequebookEditor({super.key, this.existing});
  final Chequebook? existing;

  @override
  ConsumerState<ChequebookEditor> createState() => _ChequebookEditorState();
}

class _ChequebookEditorState extends ConsumerState<ChequebookEditor> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _next = TextEditingController(
    text: '${widget.existing?.nextNumber ?? ''}',
  );
  late String? _accountId = widget.existing?.accountId;
  late bool _active = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider).value!;
    final existing = widget.existing;
    return _EditorSheet(
      title: existing == null ? 'Nouveau chéquier' : 'Modifier le chéquier',
      onSave: () => _submit(
        context,
        ref,
        (api) => api.saveChequebook(existing?.id, {
          'name': _name.text.trim(),
          'nextNumber': int.parse(_next.text),
          'accountId': _accountId,
          'isActive': _active,
        }),
      ),
      onDelete: existing == null
          ? null
          : () async {
              final sure = await confirm(
                context,
                title: 'Supprimer ce chéquier ?',
                message:
                    'Les numéros déjà attribués restent sur les opérations.',
                confirmLabel: 'Supprimer',
              );
              if (sure && context.mounted) {
                await _submit(
                  context,
                  ref,
                  (api) => api.deleteChequebook(existing.id),
                );
              }
            },
      children: [
        _nameField(_name, hint: 'Chéquier 2026', autofocus: existing == null),
        const SizedBox(height: Gap.md),
        TextFormField(
          controller: _next,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          validator: (v) => (int.tryParse(v ?? '') ?? 0) >= 1
              ? null
              : 'Indiquez le numéro du prochain chèque',
          decoration: const InputDecoration(
            labelText: 'Numéro du prochain chèque',
            helperText:
                'Le numéro imprimé sur le premier chèque encore dans le carnet.',
          ),
        ),
        if (data.activeAccounts.length > 1) ...[
          _fieldLabel(context, 'Compte'),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              ChoicePill(
                label: 'Tous',
                selected: _accountId == null,
                onTap: () => setState(() => _accountId = null),
              ),
              for (final a in data.activeAccounts)
                ChoicePill(
                  label: a.name,
                  selected: _accountId == a.id,
                  onTap: () => setState(() => _accountId = a.id),
                ),
            ],
          ),
        ],
        SwitchTile(
          title: 'En cours d’utilisation',
          subtitle:
              'Désactivez un carnet terminé : le suivant prend le relais.',
          value: _active,
          onChanged: (v) => setState(() => _active = v),
        ),
      ],
    );
  }
}
