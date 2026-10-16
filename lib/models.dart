import 'dart:typed_data';

enum UserRole { student, agency, admin }

/// Type d'annonce.
enum ListingKind {
  /// Un étudiant qui a déjà une maison et cherche des colocataires.
  offer,

  /// Un étudiant sans maison qui cherche une colocation.
  request,

  /// Une agence immobilière qui publie un logement disponible.
  agency,
}

extension ListingKindX on ListingKind {
  String get label => switch (this) {
    ListingKind.offer => 'Colocation proposée',
    ListingKind.request => 'Recherche colocation',
    ListingKind.agency => 'Agence immobilière',
  };
  bool get hasHouse => this != ListingKind.request;
}

enum HouseState { neuf, bon, arafraichir }

extension HouseStateX on HouseState {
  String get label => switch (this) {
    HouseState.neuf => 'Neuf / très bon état',
    HouseState.bon => 'Bon état',
    HouseState.arafraichir => 'À rafraîchir',
  };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.agencyName,
  });
  final String id;
  final String name;
  final String phone;
  final UserRole role;
  final String? agencyName;

  bool get isAdmin => role == UserRole.admin;

  String get displayName =>
      role == UserRole.agency && agencyName != null && agencyName!.isNotEmpty
      ? agencyName!
      : name;
}

/// Une photo : soit une URL (serveur), soit des octets (choisie sur l'appareil).
class Photo {
  const Photo.url(String this.url) : bytes = null, asset = null;
  const Photo.bytes(Uint8List this.bytes) : url = null, asset = null;
  const Photo.asset(String this.asset) : url = null, bytes = null;
  final String? url;
  final Uint8List? bytes;
  final String? asset;
}

class Listing {
  const Listing({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerRole,
    required this.kind,
    required this.title,
    required this.city,
    required this.neighborhood,
    required this.description,
    required this.createdAt,
    this.rent = 0,
    this.caution = 0,
    this.serviceFee = 0,
    this.spots = 1,
    this.houseState,
    this.conditions = '',
    this.photos = const [],
    this.active = true,
  });

  final String id;
  final String ownerId;
  final String ownerName;
  final UserRole ownerRole;
  final ListingKind kind;
  final String title;
  final String city;
  final String neighborhood;
  final String description;
  final DateTime createdAt;

  /// Loyer mensuel par personne (offre) ou budget maximum (demande), en FCFA.
  final int rent;

  /// Caution demandée, en FCFA.
  final int caution;

  /// Frais de prestation / d'agence, en FCFA.
  final int serviceFee;

  /// Nombre de places disponibles (offre/agence) ou de personnes (demande).
  final int spots;
  final HouseState? houseState;

  /// Conditions libres : durée minimale du bail, règles de la maison, etc.
  final String conditions;
  final List<Photo> photos;
  final bool active;

  /// Total à prévoir à l'entrée (1er loyer + caution + frais).
  int get entryCost => rent + caution + serviceFee;

  Listing copyWith({bool? active, List<Photo>? photos}) => Listing(
    id: id,
    ownerId: ownerId,
    ownerName: ownerName,
    ownerRole: ownerRole,
    kind: kind,
    title: title,
    city: city,
    neighborhood: neighborhood,
    description: description,
    createdAt: createdAt,
    rent: rent,
    caution: caution,
    serviceFee: serviceFee,
    spots: spots,
    houseState: houseState,
    conditions: conditions,
    photos: photos ?? this.photos,
    active: active ?? this.active,
  );
}

/// Brouillon d'annonce envoyé au dépôt de données.
class ListingDraft {
  ListingDraft({
    required this.kind,
    required this.title,
    required this.city,
    required this.neighborhood,
    required this.description,
    this.rent = 0,
    this.caution = 0,
    this.serviceFee = 0,
    this.spots = 1,
    this.houseState,
    this.conditions = '',
    this.photos = const [],
  });
  final ListingKind kind;
  final String title, city, neighborhood, description, conditions;
  final int rent, caution, serviceFee, spots;
  final HouseState? houseState;
  final List<Uint8List> photos;
}

/// Contact débloqué après paiement des frais de mise en contact.
class UnlockedContact {
  const UnlockedContact({
    required this.listingId,
    required this.name,
    required this.phone,
    required this.at,
  });
  final String listingId;
  final String name;
  final String phone;
  final DateTime at;
}

class ListingFilter {
  const ListingFilter({this.kind, this.query = '', this.maxRent});
  final ListingKind? kind;
  final String query;
  final int? maxRent;
}

/// Bandeau du slider de l'accueil : pub, annonce de l'app, partenaire…
/// Géré côté serveur (table `promos`) : ajouter/retirer une pub ne demande aucune mise à jour de l'app.
class Promo {
  const Promo({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.linkUrl,
    this.colorA = 0xFF0F766E,
    this.colorB = 0xFF14B8A6,
    this.sponsor = false,
  });
  final String id, title, subtitle;
  final String? imageUrl, linkUrl;
  final int colorA, colorB;

  /// Affiche la mention « Publicité ».
  final bool sponsor;
}

enum PaymentStatus { pending, approved, rejected }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
    PaymentStatus.pending => 'En attente de validation',
    PaymentStatus.approved => 'Validé',
    PaymentStatus.rejected => 'Refusé',
  };
}

/// Moyen de paiement accepté (numéro Mobile Money de l'administrateur).
class PaymentMethodInfo {
  const PaymentMethodInfo({
    required this.id,
    required this.label,
    required this.number,
    this.holder = '',
  });
  final String id, label, number, holder;
}

/// Avis de paiement : l'utilisateur déclare avoir payé la mise en contact,
/// l'administrateur vérifie puis valide (ce qui débloque le numéro) ou refuse.
class PaymentNotice {
  const PaymentNotice({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.payerName,
    required this.payerPhone,
    required this.method,
    required this.reference,
    required this.status,
    required this.createdAt,
    this.amount = 1000,
  });
  final String id,
      listingId,
      listingTitle,
      payerName,
      payerPhone,
      method,
      reference;
  final PaymentStatus status;
  final DateTime createdAt;
  final int amount;
}
