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
  ListingFilter filter = const ListingFilter();
  bool loading = true;
  String? error;
  bool updateAvailable = false;
  Timer? _updateTimer;

  Future<void> start() async {
    user = await repo.currentUser();
    await Future.wait([refresh(), if (user != null) loadContacts()]);
    _updateTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => checkUpdate(),
    );
    unawaited(checkUpdate());
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
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

  Future<void> loadContacts() async {
    try {
      contacts = await repo.unlockedContacts();
    } catch (_) {}
    notifyListeners();
  }

  UnlockedContact? contactFor(String listingId) {
    for (final c in contacts) {
      if (c.listingId == listingId) return c;
    }
    return null;
  }

  Future<void> signIn(String email, String password) async {
    user = await repo.signIn(email: email, password: password);
    await loadContacts();
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
    await loadContacts();
    notifyListeners();
  }

  Future<void> signOut() async {
    await repo.signOut();
    user = null;
    contacts = const [];
    notifyListeners();
  }

  Future<void> publish(ListingDraft d) async {
    await repo.createListing(d);
    await refresh();
  }

  Future<UnlockedContact> pay(
    String listingId,
    String method,
    String phone,
  ) async {
    final c = await repo.payAndUnlock(
      listingId: listingId,
      method: method,
      payerPhone: phone,
    );
    await loadContacts();
    return c;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
