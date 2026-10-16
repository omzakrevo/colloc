import '../models.dart';

class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Contrat unique entre l'UI et les données. Deux implémentations :
/// [DemoRepository] (mémoire) et [SupabaseRepository] (production).
abstract class Repository {
  Future<void> init();

  Future<AppUser?> currentUser();
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? agencyName,
  });
  Future<AppUser> signIn({required String email, required String password});
  Future<void> signOut();

  Future<List<Listing>> listings(ListingFilter filter);
  Future<List<Listing>> myListings();
  Future<Listing> createListing(ListingDraft draft);
  Future<void> setListingActive(String id, bool active);
  Future<void> deleteListing(String id);

  /// Contacts déjà débloqués par l'utilisateur courant.
  Future<List<UnlockedContact>> unlockedContacts();

  /// Paie [AppConfig.contactFeeFcfa] puis renvoie le contact de l'annonceur.
  /// [method] : 'wave' | 'orange' | 'mtn' | 'moov'.
  Future<UnlockedContact> payAndUnlock({
    required String listingId,
    required String method,
    required String payerPhone,
  });
}
