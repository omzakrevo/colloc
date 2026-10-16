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
  const ListingFilter({this.kind, this.query = '', this.maxRent, this.city});
  final ListingKind? kind;
  final String query;
  final int? maxRent;
  final String? city;
}

/// Flyer du slider de l'accueil : pub, annonce de l'app, partenaire…
/// Géré par l'administrateur (table `coloc_promos`) : aucun déploiement nécessaire pour ajouter, modifier ou retirer une pub.
class Promo {
  const Promo({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.imageBytes,
    this.linkUrl,
    this.colorA = 0xFF0F766E,
    this.colorB = 0xFF14B8A6,
    this.sponsor = false,
    this.sort = 0,
    this.active = true,
  });
  final String id, title, subtitle;
  final String? imageUrl, linkUrl;
  final Uint8List? imageBytes;
  final int colorA, colorB, sort;

  /// Affiche la mention « Publicité ».
  final bool sponsor, active;

  bool get hasImage =>
      imageBytes != null || (imageUrl != null && imageUrl!.isNotEmpty);
}

/// Création / modification d'un flyer par l'administrateur.
class PromoDraft {
  PromoDraft({
    this.id,
    required this.title,
    this.subtitle = '',
    this.linkUrl,
    this.imageBytes,
    this.imageUrl,
    this.colorA = 0xFF0F766E,
    this.colorB = 0xFF14B8A6,
    this.sponsor = false,
    this.active = true,
    this.sort = 0,
  });
  final String? id;
  final String title, subtitle;
  final String? linkUrl, imageUrl;
  final Uint8List?
  imageBytes; // nouvelle image à envoyer ; sinon on garde imageUrl
  final int colorA, colorB, sort;
  final bool sponsor, active;
}

// ───────── statistiques de fréquentation (espace admin) ─────────

class AnalyticsEvent {
  AnalyticsEvent({
    required this.visitorId,
    required this.sessionId,
    required this.type,
    this.screen,
    this.listingId,
    this.promoId,
    this.query,
    this.city,
    this.device = 'mobile',
    DateTime? at,
  }) : at = at ?? DateTime.now();
  final String visitorId, sessionId, type, device;
  final String? screen, listingId, promoId, query, city;
  final DateTime at;
}

class DayStat {
  const DayStat(this.day, this.visitors, this.views);
  final DateTime day;
  final int visitors, views;
}

class RankItem {
  const RankItem(this.label, this.a, [this.b = 0]);
  final String label;
  final int a, b;
}

class Stats {
  const Stats({
    this.visitorsToday = 0,
    this.visitors7 = 0,
    this.visitors30 = 0,
    this.sessions = 0,
    this.pageViews = 0,
    this.listingViews = 0,
    this.searches = 0,
    this.contactClicks = 0,
    this.paymentNotices = 0,
    this.approved = 0,
    this.signups = 0,
    this.promoViews = 0,
    this.promoClicks = 0,
    this.screensPerSession = 0,
    this.funnelVisitors = 0,
    this.funnelListing = 0,
    this.funnelContact = 0,
    this.funnelNotice = 0,
    this.daily = const [],
    this.topListings = const [],
    this.topSearches = const [],
    this.topCities = const [],
    this.topPromos = const [],
    this.devices = const [],
  });
  final int visitorsToday,
      visitors7,
      visitors30,
      sessions,
      pageViews,
      listingViews,
      searches,
      contactClicks,
      paymentNotices,
      approved,
      signups,
      promoViews,
      promoClicks;
  final double screensPerSession;
  final int funnelVisitors, funnelListing, funnelContact, funnelNotice;
  final List<DayStat> daily;
  final List<RankItem> topListings, topSearches, topCities, topPromos, devices;

  factory Stats.fromJson(Map<String, dynamic> j) {
    int n(String k) => (j[k] as num?)?.toInt() ?? 0;
    List<RankItem> rank(String k) => [
      for (final r in (j[k] as List? ?? const []))
        RankItem(
          r['label'] as String? ?? '',
          (r['a'] as num?)?.toInt() ?? 0,
          (r['b'] as num?)?.toInt() ?? 0,
        ),
    ];
    return Stats(
      visitorsToday: n('visitors_today'),
      visitors7: n('visitors_7'),
      visitors30: n('visitors_30'),
      sessions: n('sessions'),
      pageViews: n('page_views'),
      listingViews: n('listing_views'),
      searches: n('searches'),
      contactClicks: n('contact_clicks'),
      paymentNotices: n('payment_notices'),
      approved: n('approved'),
      signups: n('signups'),
      promoViews: n('promo_views'),
      promoClicks: n('promo_clicks'),
      screensPerSession: (j['screens_per_session'] as num?)?.toDouble() ?? 0,
      funnelVisitors: n('funnel_visitors'),
      funnelListing: n('funnel_listing'),
      funnelContact: n('funnel_contact'),
      funnelNotice: n('funnel_notice'),
      daily: [
        for (final r in (j['daily'] as List? ?? const []))
          DayStat(
            DateTime.parse(r['day'] as String),
            (r['visitors'] as num).toInt(),
            (r['views'] as num).toInt(),
          ),
      ],
      topListings: rank('top_listings'),
      topSearches: rank('top_searches'),
      topCities: rank('top_cities'),
      topPromos: rank('top_promos'),
      devices: rank('devices'),
    );
  }
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
