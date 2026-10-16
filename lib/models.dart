import 'dart:typed_data';

enum UserRole { student, agency }

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

  String get displayName =>
      role == UserRole.agency && agencyName != null && agencyName!.isNotEmpty
      ? agencyName!
      : name;
}

/// Une photo : soit une URL (serveur), soit des octets (choisie sur l'appareil).
class Photo {
  const Photo.url(String this.url) : bytes = null;
  const Photo.bytes(Uint8List this.bytes) : url = null;
  final String? url;
  final Uint8List? bytes;
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

  Listing copyWith({bool? active}) => Listing(
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
    photos: photos,
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
