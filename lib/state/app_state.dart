import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../data/repository.dart';
import '../models.dart';
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

  Future<void> start() async {
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
        (payments.any((p) => p.status == PaymentStatus.pending))) {
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

  Future<void> signIn(String email, String password) async {
    user = await repo.signIn(email: email, password: password);
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
    await loadAccount();
  }

  Future<void> review(String id, {required bool approve}) async {
    await repo.reviewPayment(id, approve: approve);
    await loadAccount();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
