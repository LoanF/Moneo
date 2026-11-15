import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

/// Ouvre la saisie d'une opération : nouvelle, modification (`existing`) ou copie (`template`).
Future<void> openTxEditor(
  BuildContext context, {
  Tx? existing,
  Tx? template,
  TxType? initialType,
}) => showSheet<void>(
  context,
  TxEditor(existing: existing, template: template, initialType: initialType),
  expand: true,
);

/// Saisie d'une opération. Pensée pour aller vite : le montant a le focus à l'ouverture,
/// un libellé déjà utilisé remplit catégorie et moyen de paiement, la date vaut aujourd'hui.
class TxEditor extends ConsumerStatefulWidget {
  const TxEditor({super.key, this.existing, this.template, this.initialType});
  final Tx? existing;
  final Tx? template;

  /// Sens présélectionné quand la saisie est ouverte depuis une action rapide.
  final TxType? initialType;

  @override
  ConsumerState<TxEditor> createState() => _TxEditorState();
}

class _TxEditorState extends ConsumerState<TxEditor> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _cheque = TextEditingController();
  final _external = TextEditingController();
  final _noteFocus = FocusNode();

  late TxType _type;
  late String _accountId;
  String? _toAccountId;
  String? _categoryId;
  String? _methodId;
  late String _date;
  bool _checked = false;
  bool _busy = false;
  String? _amountError;

  /// L'utilisateur a choisi le sens lui-même : un moyen de paiement ne le change plus.
  bool _typeTouched = false;
  List<Suggestion> _suggestions = const [];
  Timer? _debounce;

  Tx? get _source => widget.existing ?? widget.template;
  bool get _editing => widget.existing != null;
  bool get _isTransferEdit =>
      _editing && widget.existing!.type == TxType.transfer;

  @override
  void initState() {
    super.initState();
    final data = ref.read(appDataProvider).value!;
    final source = _source;
    _type = source?.type ?? widget.initialType ?? TxType.expense;
    _accountId =
        source?.accountId ??
        ref.read(currentAccountProvider)?.id ??
        data.activeAccounts.first.id;
    _categoryId = source?.categoryId;
    _methodId = source?.paymentMethodId;
    _date = widget.existing?.date ?? Fmt.today();
    _checked = widget.existing?.isChecked ?? false;
    _typeTouched = source != null || widget.initialType != null;
    if (source != null) {
      _amount.text = Fmt.plain(
        source.amount.abs(),
      ).replaceAll(RegExp(r'[\s  ]'), '');
      _note.text = source.note ?? '';
      if (widget.existing != null) _cheque.text = source.chequeNumber ?? '';
      _external.text = source.counterparty ?? '';
    }
    _note.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    _note.dispose();
    _cheque.dispose();
    _external.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    _debounce?.cancel();
    final query = _note.text.trim();
    if (query.length < 2 || _type == TxType.transfer) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final found = await ref.read(apiProvider).suggestions(query);
        if (mounted && _note.text.trim() == query) {
          setState(
            () => _suggestions = found
                .where(
                  (s) =>
                      s.note.toLowerCase() != query.toLowerCase() ||
                      _categoryId == null,
                )
                .take(4)
                .toList(),
          );
        }
      } catch (_) {
        /* les suggestions sont un confort : aucune erreur affichée */
      }
    });
  }

  void _applySuggestion(Suggestion s) {
    HapticFeedback.selectionClick();
    setState(() {
      _note.removeListener(_onNoteChanged);
      _note.text = s.note;
      _note.addListener(_onNoteChanged);
      _categoryId = s.categoryId ?? _categoryId;
      _methodId = s.paymentMethodId ?? _methodId;
      if (!_typeTouched) _type = s.type;
      if (_amount.text.trim().isEmpty) {
        _amount.text = Fmt.plain(s.amount).replaceAll(RegExp(r'[\s  ]'), '');
      }
      _suggestions = const [];
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _selectMethod(PaymentMethod method) {
    setState(() {
      _methodId = _methodId == method.id ? null : method.id;
      // Comme dans le classeur : « Versement » présélectionne un revenu, « Carte » une dépense.
      if (!_typeTouched && _methodId != null && _type != TxType.transfer) {
        _type = method.defaultIncome ? TxType.income : TxType.expense;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: Fmt.parse(_date),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: 'Date de l’opération',
    );
    if (picked != null) setState(() => _date = Fmt.iso(picked));
  }

  Future<void> _save() async {
    final data = ref.read(appDataProvider).value!;
    final amount = Fmt.parseAmount(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Saisissez un montant supérieur à zéro');
      return;
    }
    if (_type == TxType.transfer &&
        !_isTransferEdit &&
        _toAccountId == null &&
        _external.text.trim().isEmpty) {
      showMessage(
        context,
        'Choisissez le compte de destination, ou nommez le compte externe.',
      );
      return;
    }
    // Comme le classeur : une date antérieure au début du suivi demande confirmation.
    final start = data.user.settings.trackingStartDate;
    if (!_editing && start != null && _date.compareTo(start) < 0) {
      final ok = await confirm(
        context,
        title: 'Date antérieure au suivi',
        message:
            'Votre suivi commence le ${Fmt.longDate(start)}. Enregistrer quand même cette opération du ${Fmt.longDate(_date)} ?',
        confirmLabel: 'Enregistrer',
        destructive: false,
      );
      if (!ok) return;
    }

    setState(() => _busy = true);
    final note = _note.text.trim();
    try {
      final actions = ref.read(txActionsProvider);
      if (_editing) {
        await actions.update(widget.existing!.id, {
          'amount': amount,
          'date': _date,
          'note': note.isEmpty ? null : note,
          'isChecked': _checked,
          if (!_isTransferEdit) ...{
            'type': _type.wire,
            'accountId': _accountId,
            'categoryId': _categoryId,
            'paymentMethodId': _methodId,
            if (_cheque.text.trim() != (widget.existing!.chequeNumber ?? ''))
              'chequeNumber': _cheque.text.trim().isEmpty
                  ? null
                  : _cheque.text.trim(),
          },
        });
        if (mounted) Navigator.pop(context);
        return;
      }
      final queued = await actions.create(
        TxDraft(
          accountId: _accountId,
          type: _type,
          amount: amount,
          date: _date,
          note: note.isEmpty ? null : note,
          categoryId: _type == TxType.transfer ? null : _categoryId,
          paymentMethodId: _type == TxType.transfer ? null : _methodId,
          chequeNumber: _cheque.text.trim().isEmpty
              ? null
              : _cheque.text.trim(),
          isChecked: _checked,
          toAccountId: _toAccountId,
          counterparty: _external.text.trim().isEmpty
              ? null
              : _external.text.trim(),
        ),
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              queued
                  ? 'Enregistrée sur l’appareil, envoyée dès le retour du réseau'
                  : 'Opération ajoutée',
            ),
          ),
        );
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const SizedBox.shrink();
    final c = context.moneo;
    final accounts = data.activeAccounts;
    final method = data.paymentMethod(_methodId);
    final isCheque =
        method?.kind == PaymentKind.cheque && _type == TxType.expense;
    final nextCheque = data.chequebooks
        .where(
          (b) =>
              b.isActive && (b.accountId == _accountId || b.accountId == null),
        )
        .firstOrNull;
    final skipNote = data.user.settings.skipNote;
    final today = Fmt.today();
    final yesterday = Fmt.iso(DateTime.now().subtract(const Duration(days: 1)));
    final amountColor = switch (_type) {
      TxType.expense => c.ink,
      TxType.income => c.income,
      TxType.transfer => c.ink,
    };
    final sign = switch (_type) {
      TxType.expense => '−',
      TxType.income => '+',
      TxType.transfer => '',
    };

    return Column(
      children: [
        SheetHeader(
          _editing
              ? 'Modifier l’opération'
              : (widget.template != null
                    ? 'Copier l’opération'
                    : 'Nouvelle opération'),
        ),
        Expanded(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.xl),
            children: [
              if (!_isTransferEdit)
                PillTabs<TxType>(
                  accent: true,
                  value: _type,
                  items: [
                    for (final t in TxType.values) (value: t, label: t.label),
                  ],
                  onChanged: (v) => setState(() {
                    _type = v;
                    _typeTouched = true;
                  }),
                ),
              const SizedBox(height: Gap.xl),

              // Montant : le chiffre est le héros de l'écran. Clavier numérique, virgule ou point acceptés.
              Semantics(
                label: 'Montant',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    if (sign.isNotEmpty)
                      ExcludeSemantics(
                        child: Text(
                          '$sign ',
                          style: context.text.displaySmall?.copyWith(
                            color: amountColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    Flexible(
                      child: IntrinsicWidth(
                        child: TextField(
                          key: const Key('amount'),
                          controller: _amount,
                          autofocus: !_editing,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: skipNote
                              ? TextInputAction.done
                              : TextInputAction.next,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,\s]'),
                            ),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          textAlign: TextAlign.center,
                          cursorColor: c.brand,
                          cursorWidth: 3,
                          style: context.text.displayMedium?.copyWith(
                            fontFeatures: tabular,
                            color: amountColor,
                            fontSize: 52,
                          ),
                          onChanged: (_) {
                            if (_amountError != null) {
                              setState(() => _amountError = null);
                            }
                          },
                          onSubmitted: (_) =>
                              skipNote ? null : _noteFocus.requestFocus(),
                          decoration: InputDecoration(
                            filled: false,
                            isCollapsed: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: '0',
                            hintStyle: context.text.displayMedium?.copyWith(
                              color: c.perforation,
                              fontSize: 52,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ExcludeSemantics(
                      child: Text(
                        ' €',
                        style: context.text.displaySmall?.copyWith(
                          color: c.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: Motion.fast,
                child: _amountError == null
                    ? const SizedBox(width: double.infinity, height: Gap.sm)
                    : Padding(
                        padding: const EdgeInsets.only(top: Gap.sm),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            _amountError!,
                            textAlign: TextAlign.center,
                            style: context.text.bodySmall?.copyWith(
                              color: context.scheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: Gap.md),

              TextField(
                controller: _note,
                focusNode: _noteFocus,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: _type == TxType.transfer
                      ? 'Note (facultative)'
                      : 'Libellé (facultatif)',
                  hintText: _type == TxType.transfer
                      ? 'Épargne du mois'
                      : 'Boulangerie, plein d’essence…',
                  counterText: '',
                ),
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: Gap.sm),
                Wrap(
                  spacing: Gap.sm,
                  runSpacing: Gap.sm,
                  children: [
                    for (final s in _suggestions)
                      ChoicePill(
                        label: '${s.note} · ${Fmt.money(s.amount)}',
                        selected: false,
                        onTap: () => _applySuggestion(s),
                        icon: Icons.history_rounded,
                      ),
                  ],
                ),
              ],

              if (accounts.length > 1 && !_isTransferEdit) ...[
                _Label(
                  _type == TxType.transfer ? 'Depuis le compte' : 'Compte',
                ),
                _ChoiceRow(
                  children: [
                    for (final a in accounts)
                      ChoicePill(
                        label: a.name,
                        selected: a.id == _accountId,
                        onTap: () => setState(() {
                          _accountId = a.id;
                          if (_toAccountId == a.id) _toAccountId = null;
                        }),
                      ),
                  ],
                ),
              ],

              if (_type == TxType.transfer && !_isTransferEdit) ...[
                const _Label('Vers'),
                _ChoiceRow(
                  children: [
                    for (final a in accounts.where((a) => a.id != _accountId))
                      ChoicePill(
                        label: a.name,
                        selected: a.id == _toAccountId,
                        onTap: () => setState(() => _toAccountId = a.id),
                      ),
                    ChoicePill(
                      label: 'Compte externe',
                      selected: _toAccountId == null,
                      onTap: () => setState(() => _toAccountId = null),
                    ),
                  ],
                ),
                if (_toAccountId == null) ...[
                  const SizedBox(height: Gap.md),
                  TextField(
                    controller: _external,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nom du compte externe',
                      hintText: 'PEA, compte joint…',
                    ),
                  ),
                ],
              ],

              if (_type != TxType.transfer) ...[
                const _Label('Catégorie'),
                _CategoryButton(
                  label: _categoryId == null
                      ? 'Choisir une catégorie'
                      : data.categoryLabel(_categoryId),
                  category: data.category(_categoryId),
                  root:
                      data.category(data.category(_categoryId)?.parentId) ??
                      data.category(_categoryId),
                  onTap: () async {
                    final picked = await showSheet<String>(
                      context,
                      CategoryPicker(selected: _categoryId),
                      expand: true,
                    );
                    if (picked != null) {
                      setState(
                        () => _categoryId = picked.isEmpty ? null : picked,
                      );
                    }
                  },
                ),
                if (data.paymentMethods.isNotEmpty) ...[
                  const _Label('Moyen de paiement'),
                  _ChoiceRow(
                    children: [
                      for (final m in data.paymentMethods)
                        ChoicePill(
                          label: m.name,
                          selected: m.id == _methodId,
                          onTap: () => _selectMethod(m),
                        ),
                    ],
                  ),
                ],
                if (isCheque) ...[
                  const SizedBox(height: Gap.md),
                  TextField(
                    controller: _cheque,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Numéro du chèque',
                      helperText: _editing
                          ? null
                          : nextCheque == null
                          ? 'Aucun chéquier actif : saisissez le numéro, ou créez un chéquier dans les réglages.'
                          : 'Laissez vide pour utiliser le prochain numéro : ${nextCheque.nextNumber}',
                    ),
                  ),
                ],
              ],

              const _Label('Date'),
              _ChoiceRow(
                children: [
                  ChoicePill(
                    label: 'Aujourd’hui',
                    selected: _date == today,
                    onTap: () => setState(() => _date = today),
                  ),
                  ChoicePill(
                    label: 'Hier',
                    selected: _date == yesterday,
                    onTap: () => setState(() => _date = yesterday),
                  ),
                  ChoicePill(
                    label: _date == today || _date == yesterday
                        ? 'Autre date'
                        : Fmt.longDate(_date),
                    selected: false,
                    onTap: _pickDate,
                    icon: Icons.calendar_today_rounded,
                  ),
                  _QuickDay(
                    onDate: (date) => setState(() => _date = Fmt.iso(date)),
                  ),
                ],
              ),

              const SizedBox(height: Gap.md),
              SwitchTile(
                title: 'Déjà pointée',
                subtitle: 'L’opération figure sur votre relevé bancaire.',
                value: _checked,
                onChanged: (v) => setState(() => _checked = v),
              ),
            ],
          ),
        ),
        // Le bouton reste collé au-dessus du clavier : pas besoin de défiler pour valider.
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Gap.page,
              Gap.sm,
              Gap.page,
              Gap.md,
            ),
            child: SubmitButton(
              label: _editing ? 'Enregistrer' : 'Ajouter',
              icon: Icons.check_rounded,
              busy: _busy,
              onPressed: _save,
            ),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.lg, bottom: Gap.sm),
    child: Text(
      text,
      style: context.text.labelLarge?.copyWith(color: context.moneo.inkSoft),
    ),
  );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Gap.sm,
    runSpacing: Gap.sm,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// Saisie rapide du jour, héritée du classeur : « 14 » donne le 14 du mois en cours.
class _QuickDay extends StatefulWidget {
  const _QuickDay({required this.onDate});
  final ValueChanged<DateTime> onDate;

  @override
  State<_QuickDay> createState() => _QuickDayState();
}

class _QuickDayState extends State<_QuickDay> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String value) {
    if (value.trim().isEmpty) return;
    final date = Fmt.parseQuickDate(value);
    setState(() => _invalid = date == null);
    if (date != null) {
      widget.onDate(date);
      _controller.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 132,
    child: TextField(
      controller: _controller,
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9/.\-]')),
        LengthLimitingTextInputFormatter(10),
      ],
      onSubmitted: _submit,
      decoration: InputDecoration(
        isDense: true,
        labelText: 'Jour (ex. 14)',
        errorText: _invalid ? 'Date inconnue' : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: 10,
        ),
      ),
    ),
  );
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.label,
    required this.category,
    required this.root,
    required this.onTap,
  });
  final String label;
  final Category? category, root;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.scheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.field),
      side: BorderSide(color: context.moneo.perforation),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: Gap.sm,
        ),
        child: Row(
          children: [
            CategoryBadge(
              icon: categoryIcon(root?.iconCode),
              color: root == null
                  ? context.moneo.perforation
                  : Color(root!.colorValue),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Text(
                label,
                style: context.text.bodyLarge?.copyWith(
                  color: category == null ? context.moneo.inkSoft : null,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

/// Choix d'une catégorie sur deux niveaux, avec recherche. Renvoie l'identifiant choisi,
/// ou une chaîne vide pour « sans catégorie ».
class CategoryPicker extends ConsumerStatefulWidget {
  const CategoryPicker({super.key, this.selected, this.rootsOnly = false});
  final String? selected;

  /// Ne propose que les catégories principales (budgets).
  final bool rootsOnly;

  @override
  ConsumerState<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<CategoryPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appDataProvider).value;
    if (data == null) return const SizedBox.shrink();
    final query = _query.trim().toLowerCase();
    bool matches(Category c) =>
        query.isEmpty || c.name.toLowerCase().contains(query);

    final tiles = <Widget>[];
    for (final root in data.rootCategories) {
      final children = widget.rootsOnly
          ? const <Category>[]
          : data.childrenOf(root.id);
      final visible = matches(root)
          ? children
          : children.where(matches).toList();
      if (!matches(root) && visible.isEmpty) continue;
      final color = Color(root.colorValue);
      tiles.add(
        GroupTile(
          leading: CategoryBadge(
            icon: categoryIcon(root.iconCode),
            color: color,
          ),
          title: root.name,
          trailing: widget.selected == root.id
              ? Icon(Icons.check_rounded, color: context.scheme.primary)
              : null,
          onTap: () => Navigator.pop(context, root.id),
        ),
      );
      for (final child in visible) {
        tiles.add(
          GroupTile(
            title: child.name,
            trailing: widget.selected == child.id
                ? Icon(Icons.check_rounded, color: context.scheme.primary)
                : null,
            onTap: () => Navigator.pop(context, child.id),
          ),
        );
      }
    }

    return Column(
      children: [
        SheetHeader(
          'Catégorie',
          action: widget.selected == null
              ? null
              : TextButton(
                  onPressed: () => Navigator.pop(context, ''),
                  child: const Text('Aucune'),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.sm),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Rechercher une catégorie',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        Expanded(
          child: tiles.isEmpty
              ? const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Aucune catégorie',
                  message: 'Aucune catégorie ne correspond à cette recherche.',
                )
              : ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: tiles,
                ),
        ),
      ],
    );
  }
}
