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
  Future<List<Promo>> promos();

  Future<List<Listing>> myListings();
  Future<Listing> createListing(ListingDraft draft);
  Future<void> setListingActive(String id, bool active);
  Future<void> deleteListing(String id);

  /// Contacts débloqués (= paiements validés par l'administrateur) de l'utilisateur courant.
  Future<List<UnlockedContact>> unlockedContacts();

  /// Numéros Mobile Money où envoyer les frais de mise en contact.
  Future<List<PaymentMethodInfo>> paymentMethods();

  /// Émet un avis de paiement (statut « en attente »). Le contact reste caché jusqu'à validation.
  Future<PaymentNotice> submitPayment({
    required String listingId,
    required String method,
    required String payerPhone,
    required String reference,
  });

  /// Avis de paiement de l'utilisateur courant.
  Future<List<PaymentNotice>> myPayments();

  /// Administrateur : tous les avis de paiement.
  Future<List<PaymentNotice>> adminPayments();

  /// Administrateur : valide (débloque le contact) ou refuse un avis.
  Future<void> reviewPayment(String id, {required bool approve});
}
