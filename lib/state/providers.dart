import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/api_client.dart';
import '../core/config.dart';
import '../core/local_store.dart';
import '../data/api.dart';
import '../data/models.dart';

// ── Infrastructure ───────────────────────────────────────────────────────────

final localStoreProvider = Provider<LocalStore>((ref) => FileLocalStore());
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => const SecureTokenStore(),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    baseUrl: AppConfig.apiUrl,
    tokens: ref.watch(tokenStoreProvider),
  );
  client.onSessionExpired = () => ref.read(sessionProvider.notifier).expire();
  return client;
});

final apiProvider = Provider<MoneoApi>(
  (ref) => MoneoApi(ref.watch(apiClientProvider)),
);

Json deviceInfo() => {
  'platform': Platform.operatingSystem,
  'deviceName': switch (Platform.operatingSystem) {
    'ios' => 'iPhone',
    'android' => 'Téléphone Android',
    final other => other,
  },
};

// ── Préférences propres à l'appareil ─────────────────────────────────────────

class DevicePrefs {
  const DevicePrefs({
    this.themeMode = ThemeMode.system,
    this.biometricLock = false,
    this.autoLockMinutes = 1,
    this.hideAmounts = false,
  });
  final ThemeMode themeMode;
  final bool biometricLock;
  final int autoLockMinutes;

  /// Masque les montants à l'écran (pour consulter l'app en public).
  final bool hideAmounts;

  factory DevicePrefs.fromJson(Json j) => DevicePrefs(
    themeMode: ThemeMode.values.firstWhere(
      (m) => m.name == j['themeMode'],
      orElse: () => ThemeMode.system,
    ),
    biometricLock: j['biometricLock'] as bool? ?? false,
    autoLockMinutes: (j['autoLockMinutes'] as num?)?.toInt() ?? 1,
    hideAmounts: j['hideAmounts'] as bool? ?? false,
  );

  Json toJson() => {
    'themeMode': themeMode.name,
    'biometricLock': biometricLock,
    'autoLockMinutes': autoLockMinutes,
    'hideAmounts': hideAmounts,
  };

  DevicePrefs copyWith({
    ThemeMode? themeMode,
    bool? biometricLock,
    int? autoLockMinutes,
    bool? hideAmounts,
  }) => DevicePrefs(
    themeMode: themeMode ?? this.themeMode,
    biometricLock: biometricLock ?? this.biometricLock,
    autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
    hideAmounts: hideAmounts ?? this.hideAmounts,
  );
}

/// Valeur initiale lue avant `runApp` (voir `main.dart`) pour éviter un flash de thème.
final initialDevicePrefsProvider = Provider<DevicePrefs>(
  (ref) => const DevicePrefs(),
);

class DevicePrefsNotifier extends Notifier<DevicePrefs> {
  @override
  DevicePrefs build() => ref.watch(initialDevicePrefsProvider);

  void update(DevicePrefs Function(DevicePrefs) change) {
    state = change(state);
    unawaited(
      ref.read(localStoreProvider).write('device_prefs', state.toJson()),
    );
  }
}

final devicePrefsProvider = NotifierProvider<DevicePrefsNotifier, DevicePrefs>(
  DevicePrefsNotifier.new,
);

/// `true` quand l'app est verrouillée et attend la biométrie.
class LockNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(initialDevicePrefsProvider).biometricLock;
  void lock() => state = true;
  void unlock() => state = false;
}

final lockProvider = NotifierProvider<LockNotifier, bool>(LockNotifier.new);

// ── Session ──────────────────────────────────────────────────────────────────

/// Utilisateur connecté, ou `null`. Chargé depuis le cache pour que l'app s'ouvre sans réseau.
class SessionNotifier extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    final client = ref.watch(apiClientProvider);
    if (await client.accessToken() == null) return null;

    final cached = await ref.read(localStoreProvider).read('bootstrap');
    if (cached is Json) {
      try {
        return Bootstrap.fromJson(cached).user;
      } catch (_) {
        /* cache d'une ancienne version : on interroge le serveur */
      }
    }
    try {
      return Bootstrap.fromJson(
        await ref.read(apiProvider).bootstrapRaw(),
      ).user;
    } on ApiException catch (error) {
      if (error.status == 401) return null;
      rethrow;
    }
  }

  Future<void> _open(AuthResult result) async {
    await ref
        .read(apiClientProvider)
        .setTokens(access: result.access, refresh: result.refresh);
    ref.read(lockProvider.notifier).unlock();
    state = AsyncData(result.user);
  }

  Future<void> login(String email, String password) async =>
      _open(await ref.read(apiProvider).login(email, password, deviceInfo()));

  Future<void> register(String username, String email, String password) async =>
      _open(
        await ref
            .read(apiProvider)
            .register(username, email, password, deviceInfo()),
      );

  Future<void> google(String idToken) async =>
      _open(await ref.read(apiProvider).google(idToken, deviceInfo()));

  void setUser(AppUser user) => state = AsyncData(user);

  Future<void> _close() async {
    await ref.read(apiClientProvider).clearTokens();
    await ref.read(localStoreProvider).write('bootstrap', null);
    await ref.read(localStoreProvider).write('outbox', null);
    state = const AsyncData(null);
  }

  Future<void> logout() async {
    // La révocation côté serveur est tentée, mais ne doit jamais empêcher de se déconnecter.
    try {
      await ref.read(apiProvider).logout();
    } catch (_) {}
    await _close();
  }

  Future<void> deleteAccount({String? password, String? confirmEmail}) async {
    await ref
        .read(apiProvider)
        .deleteAccount(password: password, confirmEmail: confirmEmail);
    await _close();
  }

  /// Le serveur a refusé le renouvellement : retour à l'écran de connexion.
  void expire() => unawaited(_close());
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, AppUser?>(
  SessionNotifier.new,
);

// ── Données de l'app ─────────────────────────────────────────────────────────

/// Le serveur est-il injoignable ? Les données affichées viennent alors du cache.
class OfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void set(bool value) {
    if (state != value) state = value;
  }
}

final offlineProvider = NotifierProvider<OfflineNotifier, bool>(
  OfflineNotifier.new,
);

/// Incrémenté à chaque changement de données : listes et statistiques se rechargent.
class DataVersion extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final dataVersionProvider = NotifierProvider<DataVersion, int>(DataVersion.new);

/// Écoute du flux temps réel. Désactivée dans les tests, où aucun serveur ne répond.
final realtimeEnabledProvider = Provider<bool>((ref) => true);

/// Comptes, catalogue, mensualités et budgets : l'état que tous les écrans partagent.
class AppDataNotifier extends AsyncNotifier<Bootstrap> {
  CancelToken? _realtime;
  Timer? _debounce;
  bool _disposed = false;

  @override
  Future<Bootstrap> build() async {
    final userId = ref.watch(sessionProvider.select((s) => s.value?.id));
    if (userId == null) throw const ApiException('Session fermée', status: 401);

    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _realtime?.cancel();
      _debounce?.cancel();
    });

    final cached = await ref.read(localStoreProvider).read('bootstrap');
    Bootstrap? fromCache;
    if (cached is Json) {
      try {
        fromCache = Bootstrap.fromJson(cached);
      } catch (_) {}
    }
    if (fromCache != null) {
      // Affichage immédiat du dernier état connu, puis mise à jour en arrière-plan.
      unawaited(Future.microtask(refresh));
      unawaited(_listen());
      return fromCache;
    }
    final fresh = await _fetch();
    unawaited(_listen());
    return fresh;
  }

  Future<Bootstrap> _fetch() async {
    final raw = await ref.read(apiProvider).bootstrapRaw();
    final data = Bootstrap.fromJson(raw);
    await ref.read(localStoreProvider).write('bootstrap', raw);
    ref.read(offlineProvider.notifier).set(false);
    ref.read(sessionProvider.notifier).setUser(data.user);
    return data;
  }

  /// Recharge l'état depuis le serveur. Hors-ligne, l'état en cache est conservé.
  Future<void> refresh() async {
    try {
      final data = await _fetch();
      if (_disposed) return;
      state = AsyncData(data);
      unawaited(ref.read(outboxProvider.notifier).flush());
    } on ApiException catch (error) {
      if (_disposed) return;
      if (error.offline) {
        ref.read(offlineProvider.notifier).set(true);
      } else if (state.value == null) {
        state = AsyncError(error, StackTrace.current);
      }
    }
  }

  /// Exécute une modification puis recharge tout ce qui en dépend.
  Future<T> mutate<T>(Future<T> Function(MoneoApi api) action) async {
    final result = await action(ref.read(apiProvider));
    ref.read(dataVersionProvider.notifier).bump();
    await refresh();
    return result;
  }

  void _onRemoteChange() {
    // Une rafale d'événements (import, mensualités) ne déclenche qu'un rechargement.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_disposed) return;
      ref.read(dataVersionProvider.notifier).bump();
      unawaited(refresh());
    });
  }

  Future<void> _listen() async {
    if (!ref.read(realtimeEnabledProvider)) return;
    var delay = const Duration(seconds: 2);
    while (!_disposed) {
      _realtime = CancelToken();
      try {
        await for (final _ in ref.read(apiProvider).realtime(_realtime!)) {
          delay = const Duration(seconds: 2);
          _onRemoteChange();
        }
      } catch (_) {
        /* connexion coupée : on réessaie plus bas */
      }
      if (_disposed) return;
      await Future<void>.delayed(delay);
      if (delay.inSeconds < 60) delay *= 2;
      // Au retour du réseau, on rattrape ce qui a pu changer pendant la coupure.
      if (!_disposed) unawaited(refresh());
    }
  }
}

final appDataProvider = AsyncNotifierProvider<AppDataNotifier, Bootstrap>(
  AppDataNotifier.new,
);

/// Compte affiché sur l'accueil. `null` = compte par défaut de l'utilisateur, sinon le premier.
class SelectedAccount extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String id) => state = id;
}

final selectedAccountIdProvider = NotifierProvider<SelectedAccount, String?>(
  SelectedAccount.new,
);

final currentAccountProvider = Provider<Account?>((ref) {
  final data = ref.watch(appDataProvider).value;
  if (data == null) return null;
  final accounts = data.activeAccounts;
  if (accounts.isEmpty) return null;
  final wanted =
      ref.watch(selectedAccountIdProvider) ??
      data.user.settings.defaultAccountId;
  return accounts.firstWhere(
    (a) => a.id == wanted,
    orElse: () => accounts.first,
  );
});

// ── File d'attente hors-ligne ────────────────────────────────────────────────

/// Créations d'opérations faites sans réseau, rejouées dès que le serveur répond.
/// Chaque brouillon porte un identifiant généré ici : le rejouer deux fois ne crée pas de doublon.
class OutboxNotifier extends Notifier<List<Json>> {
  bool _flushing = false;

  @override
  List<Json> build() {
    unawaited(_load());
    return const [];
  }

  Future<void> _load() async {
    final saved = await ref.read(localStoreProvider).read('outbox');
    if (saved is List && saved.isNotEmpty) {
      state = [
        for (final item in saved) Map<String, dynamic>.from(item as Map),
      ];
    }
  }

  Future<void> _save() => ref
      .read(localStoreProvider)
      .write('outbox', state.isEmpty ? null : state);

  Future<void> add(TxDraft draft) async {
    state = [...state, draft.toJson()];
    await _save();
  }

  Future<void> flush() async {
    if (_flushing || state.isEmpty) return;
    _flushing = true;
    try {
      final accepted = await ref.read(apiProvider).replay(state);
      state = [
        for (final d in state)
          if (!accepted.contains(d['id'])) d,
      ];
      await _save();
      if (accepted.isNotEmpty) {
        ref.read(dataVersionProvider.notifier).bump();
        unawaited(ref.read(appDataProvider.notifier).refresh());
      }
    } on ApiException {
      // Toujours hors-ligne : on réessaiera au prochain rafraîchissement.
    } finally {
      _flushing = false;
    }
  }
}

/// Opérations en attente pour un compte, présentées comme des opérations normales.
List<Tx> pendingTxFor(List<Json> outbox, String accountId) => [
  for (final d in outbox)
    if (d['accountId'] == accountId)
      Tx(
        id: d['id'] as String,
        accountId: accountId,
        categoryId: d['categoryId'] as String?,
        paymentMethodId: d['paymentMethodId'] as String?,
        amount: d['type'] == 'expense'
            ? -(d['amount'] as num).toDouble().abs()
            : (d['amount'] as num).toDouble().abs(),
        type: TxType.parse(d['type']),
        date: d['date'] as String,
        note: d['note'] as String?,
        isChecked: d['isChecked'] as bool? ?? false,
        pending: true,
      ),
];

final outboxProvider = NotifierProvider<OutboxNotifier, List<Json>>(
  OutboxNotifier.new,
);

// ── Opérations ───────────────────────────────────────────────────────────────

class TxListState {
  const TxListState({
    required this.items,
    required this.total,
    required this.sumCredit,
    required this.sumDebit,
    this.loadingMore = false,
    this.fromCache = false,
  });
  final List<Tx> items;
  final int total;
  final double sumCredit, sumDebit;
  final bool loadingMore, fromCache;

  bool get hasMore => items.length < total;

  TxListState copyWith({List<Tx>? items, int? total, bool? loadingMore}) =>
      TxListState(
        items: items ?? this.items,
        total: total ?? this.total,
        sumCredit: sumCredit,
        sumDebit: sumDebit,
        loadingMore: loadingMore ?? this.loadingMore,
        fromCache: fromCache,
      );
}

/// Liste paginée d'opérations pour un jeu de filtres.
class TxListNotifier extends AsyncNotifier<TxListState> {
  TxListNotifier(this.filter);
  final TxFilter filter;
  static const _pageSize = 60;

  String get _cacheKey => 'tx_${filter.accountId}_${filter.isChecked}';
  bool get _cacheable =>
      filter.accountId != null &&
      filter.activeCount == 0 &&
      (filter.query ?? '').isEmpty;

  @override
  Future<TxListState> build() async {
    ref.watch(dataVersionProvider);
    final store = ref.read(localStoreProvider);
    try {
      final page = await ref
          .read(apiProvider)
          .transactions(filter, limit: _pageSize);
      if (_cacheable) {
        unawaited(
          store.write(_cacheKey, [for (final t in page.items) t.toJson()]),
        );
      }
      return TxListState(
        items: page.items,
        total: page.total,
        sumCredit: page.sumCredit,
        sumDebit: page.sumDebit,
      );
    } on ApiException catch (error) {
      if (!error.offline || !_cacheable) rethrow;
      final cached = await store.read(_cacheKey);
      if (cached is! List) rethrow;
      ref.read(offlineProvider.notifier).set(true);
      final items = [
        for (final t in cached)
          Tx.fromJson(Map<String, dynamic>.from(t as Map)),
      ];
      return TxListState(
        items: items,
        total: items.length,
        sumCredit: 0,
        sumDebit: 0,
        fromCache: true,
      );
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(apiProvider)
          .transactions(filter, limit: _pageSize, offset: current.items.length);
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          total: page.total,
          loadingMore: false,
        ),
      );
    } on ApiException {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }

  /// Applique un changement à l'écran avant la réponse du serveur.
  void patchLocal(List<Tx> Function(List<Tx>) change) {
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(items: change(current.items)));
    }
  }
}

final txListProvider =
    AsyncNotifierProvider.family<TxListNotifier, TxListState, TxFilter>(
      TxListNotifier.new,
    );

const _uuid = Uuid();

/// Actions sur les opérations, partagées par tous les écrans.
class TxActions {
  TxActions(this.ref);
  final Ref ref;

  Future<void> _changed() async {
    ref.read(dataVersionProvider.notifier).bump();
    await ref.read(appDataProvider.notifier).refresh();
  }

  /// Crée une opération. Renvoie `true` si elle a été mise en file d'attente faute de réseau.
  Future<bool> create(TxDraft draft) async {
    final withId = TxDraft(
      id: draft.id ?? _uuid.v4(),
      accountId: draft.accountId,
      type: draft.type,
      amount: draft.amount,
      date: draft.date,
      note: draft.note,
      categoryId: draft.categoryId,
      paymentMethodId: draft.paymentMethodId,
      chequeNumber: draft.chequeNumber,
      isChecked: draft.isChecked,
      toAccountId: draft.toAccountId,
      counterparty: draft.counterparty,
    );
    try {
      await ref.read(apiProvider).createTransaction(withId);
      await _changed();
      return false;
    } on ApiException catch (error) {
      // Un transfert touche deux comptes : on ne le met pas en attente, on demande de réessayer.
      if (!error.offline || draft.type == TxType.transfer) rethrow;
      await ref.read(outboxProvider.notifier).add(withId);
      ref.read(offlineProvider.notifier).set(true);
      return true;
    }
  }

  Future<void> update(String id, Json patch) async {
    await ref.read(apiProvider).updateTransaction(id, patch);
    await _changed();
  }

  Future<void> delete(String id) async {
    await ref.read(apiProvider).deleteTransaction(id);
    await _changed();
  }

  Future<void> setChecked(List<String> ids, bool checked) async {
    await ref.read(apiProvider).setChecked(ids, checked);
    await _changed();
  }
}

final txActionsProvider = Provider<TxActions>(TxActions.new);

// ── Statistiques et notifications ────────────────────────────────────────────

typedef StatsRange = ({String from, String to, String? accountId});

final summaryProvider = FutureProvider.family<Summary, StatsRange>((ref, r) {
  ref.watch(dataVersionProvider);
  return ref.watch(apiProvider).summary(r.from, r.to, accountId: r.accountId);
});

final monthlyProvider = FutureProvider.family<List<MonthTotal>, String?>((
  ref,
  accountId,
) {
  ref.watch(dataVersionProvider);
  return ref.watch(apiProvider).monthly(accountId: accountId);
});

final balanceHistoryProvider =
    FutureProvider.family<List<BalancePoint>, StatsRange>((ref, r) {
      ref.watch(dataVersionProvider);
      return ref
          .watch(apiProvider)
          .balanceHistory(r.from, r.to, accountId: r.accountId);
    });

final forecastProvider = FutureProvider.family<Forecast, String?>((
  ref,
  accountId,
) {
  ref.watch(dataVersionProvider);
  return ref.watch(apiProvider).forecast(accountId: accountId);
});

typedef PivotQuery = ({
  String from,
  String to,
  String granularity,
  String? accountId,
});

final pivotProvider = FutureProvider.family<Pivot, PivotQuery>((ref, q) {
  ref.watch(dataVersionProvider);
  return ref
      .watch(apiProvider)
      .pivot(q.from, q.to, q.granularity, accountId: q.accountId);
});

final pendingRecurringProvider = FutureProvider<List<Occurrence>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(apiProvider).pendingRecurring();
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(apiProvider).notifications();
});

final sessionsProvider = FutureProvider.autoDispose<List<DeviceSession>>(
  (ref) => ref.watch(apiProvider).sessions(),
);
