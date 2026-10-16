import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../data/repository.dart';
import '../models.dart';
import '../ui/design.dart';
import '../util/update_check.dart';

class AppState extends ChangeNotifier {
  AppState(this.repo);
  final Repository repo;

  AppUser? user;
  List<Listing> listings = const [];
  List<UnlockedContact> contacts = const [];
  List<Promo> promos = const [];
  List<PaymentNotice> payments = const [];
  List<PaymentNotice> adminPayments = const [];
  List<PaymentMethodInfo> paymentMethods = const [];
  ListingFilter filter = const ListingFilter();
  bool loading = true;
  String? error;
  bool updateAvailable = false;
  Timer? _updateTimer;
  Timer? _pollTimer;

  // onglets (conservés quand le design change et que l'interface est reconstruite)
  String shellTab = 'feed';
  int adminTab = 0;

  // (permet à l'UI de demander un rafraîchissement après un simple changement d'onglet)
  void notifyListeners_() => notifyListeners();

  // design choisi par l'admin
  ThemeSettings theme = const ThemeSettings();
  int themeVersion = 0;

  // statistiques (anonymes)
  String _visitorId = '';
  final String _sessionId = _rand(12);
  String device = 'mobile';

  static String _rand(int n) {
    final r = Random.secure();
    return List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  Future<void> initAnalytics() async {
    try {
      final p = await SharedPreferences.getInstance();
      _visitorId = p.getString('coloc_vid') ?? '';
      if (_visitorId.isEmpty) {
        _visitorId = _rand(20);
        await p.setString('coloc_vid', _visitorId);
      }
    } catch (_) {
      _visitorId = _rand(20);
    }
  }

  /// Enregistre une action du visiteur. N'enregistre pas l'activité de l'administrateur.
  void track(
    String type, {
    String? screen,
    String? listingId,
    String? promoId,
    String? query,
    String? city,
  }) {
    if (user?.isAdmin == true) return;
    if (_visitorId.isEmpty) _visitorId = _rand(20);
    unawaited(
      repo
          .track(
            AnalyticsEvent(
              visitorId: _visitorId,
              sessionId: _sessionId,
              type: type,
              screen: screen,
              listingId: listingId,
              promoId: promoId,
              query: query,
              city: city,
              device: device,
            ),
          )
          .catchError((Object _) {}),
    );
  }

  // ───────── design ─────────

  void applyTheme(ThemeSettings t) {
    theme = t;
    D.s = buildDesign(t);
    themeVersion++;
    notifyListeners();
  }

  Future<void> loadTheme() async {
    try {
      applyTheme(
        await repo.themeSettings().timeout(const Duration(seconds: 3)),
      );
    } catch (_) {}
  }

  Future<void> saveTheme(ThemeSettings t) async {
    await repo.saveTheme(t);
    applyTheme(t);
  }

  // ───────── démarrage ─────────

  Future<void> start() async {
    await initAnalytics();
    user = await repo.currentUser();
    await Future.wait([
      refresh(),
      loadPromos(),
      if (user != null) loadAccount(),
    ]);
    _updateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => checkUpdate(),
    );
    unawaited(checkUpdate());
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> checkUpdate() async {
    final latest = await fetchLatestVersion();
    if (latest != null &&
        latest != AppConfig.appVersion &&
        AppConfig.appVersion != 'dev') {
      updateAvailable = true;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      listings = await repo.listings(filter);
    } catch (e) {
      error = 'Impossible de charger les annonces. Vérifiez votre connexion.';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> setFilter(ListingFilter f) {
    if (f.query.trim().isNotEmpty && f.query != filter.query)
      track('search', query: f.query.trim());
    if (f.city != null && f.city != filter.city)
      track('filter_city', city: f.city);
    filter = f;
    return refresh();
  }

  Future<void> loadPromos() async {
    try {
      promos = await repo.promos();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> loadContacts() async {
    try {
      contacts = await repo.unlockedContacts();
    } catch (_) {}
    notifyListeners();
  }

  /// Contacts + avis de paiement (+ file d'attente admin). Relance un sondage tant qu'un avis est en attente,
  /// pour que le numéro apparaisse dès que l'administrateur valide.
  Future<void> loadAccount() async {
    try {
      final r = await Future.wait([repo.unlockedContacts(), repo.myPayments()]);
      contacts = r[0] as List<UnlockedContact>;
      payments = r[1] as List<PaymentNotice>;
      if (user?.isAdmin == true) adminPayments = await repo.adminPayments();
    } catch (_) {}
    _pollTimer?.cancel();
    if (user != null &&
        payments.any((p) => p.status == PaymentStatus.pending)) {
      _pollTimer = Timer(const Duration(seconds: 20), loadAccount);
    }
    notifyListeners();
  }

  Future<void> loadPaymentMethods() async {
    try {
      paymentMethods = await repo.paymentMethods();
    } catch (_) {}
    notifyListeners();
  }

  PaymentNotice? paymentFor(String listingId) {
    for (final p in payments) {
      if (p.listingId == listingId) return p;
    }
    return null;
  }

  int get pendingAdminCount =>
      adminPayments.where((p) => p.status == PaymentStatus.pending).length;

  UnlockedContact? contactFor(String listingId) {
    for (final c in contacts) {
      if (c.listingId == listingId) return c;
    }
    return null;
  }

  // ───────── compte ─────────

  Future<void> signIn(String email, String password) async {
    user = await repo.signIn(email: email, password: password);
    track('login');
    await loadAccount();
    notifyListeners();
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? agencyName,
  }) async {
    user = await repo.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: role,
      agencyName: agencyName,
    );
    track('signup');
    await loadAccount();
    notifyListeners();
  }

  Future<void> signOut() async {
    await repo.signOut();
    user = null;
    contacts = const [];
    payments = const [];
    adminPayments = const [];
    _pollTimer?.cancel();
    notifyListeners();
  }

  Future<void> updatePhone(String phone) async {
    await repo.updatePhone(phone);
    final u = user;
    if (u != null)
      user = AppUser(
        id: u.id,
        name: u.name,
        phone: phone,
        role: u.role,
        agencyName: u.agencyName,
      );
    notifyListeners();
  }

  Future<void> publish(ListingDraft d) async {
    await repo.createListing(d);
    await refresh();
  }

  Future<void> submitPayment(
    String listingId,
    String method,
    String payerPhone,
    String reference,
  ) async {
    await repo.submitPayment(
      listingId: listingId,
      method: method,
      payerPhone: payerPhone,
      reference: reference,
    );
    track('payment_notice', listingId: listingId);
    await loadAccount();
  }

  Future<void> review(String id, {required bool approve}) async {
    await repo.reviewPayment(id, approve: approve);
    await loadAccount();
  }

  // ───────── admin : flyers ─────────

  Future<void> savePromo(PromoDraft d) async {
    await repo.savePromo(d);
    await loadPromos();
  }

  Future<void> deletePromo(String id) async {
    await repo.deletePromo(id);
    await loadPromos();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
