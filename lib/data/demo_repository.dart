import 'dart:math';

import '../models.dart';
import 'repository.dart';

class _Account {
  _Account(this.user, this.password, this.email);
  final AppUser user;
  final String password, email;
}

/// Données en mémoire : permet de tester toute l'app sans serveur.
/// Comptes de démo : etudiant@demo.com / agence@demo.com — mot de passe "demo1234".
class DemoRepository implements Repository {
  final _accounts = <_Account>[];
  final _listings = <Listing>[];
  final _unlocks = <String, List<UnlockedContact>>{}; // userId -> contacts
  final _phones = <String, String>{}; // userId -> phone
  AppUser? _me;
  var _seq = 100;

  @override
  Future<void> init() async {
    final s = AppUser(
      id: 'u1',
      name: 'Aminata Diallo',
      phone: '+221 77 123 45 67',
      role: UserRole.student,
    );
    final s2 = AppUser(
      id: 'u2',
      name: 'Yusup Abdulla',
      phone: '+221 76 555 12 34',
      role: UserRole.student,
    );
    final a = AppUser(
      id: 'u3',
      name: 'Moussa Ndiaye',
      phone: '+221 78 900 11 22',
      role: UserRole.agency,
      agencyName: 'Teranga Immo',
    );
    _accounts.addAll([
      _Account(s, 'demo1234', 'etudiant@demo.com'),
      _Account(s2, 'demo1234', 'etudiant2@demo.com'),
      _Account(a, 'demo1234', 'agence@demo.com'),
    ]);
    for (final u in [s, s2, a]) {
      _phones[u.id] = u.phone;
    }
    final now = DateTime.now();
    _listings.addAll([
      Listing(
        id: 'l1',
        ownerId: 'u1',
        ownerName: s.name,
        ownerRole: UserRole.student,
        kind: ListingKind.offer,
        title: '2 chambres libres près de l\'université',
        city: 'Dakar',
        neighborhood: 'Fann',
        description: 'Appartement de 4 chambres, je cherche 2 colocataires sérieux. Cuisine équipée, wifi inclus, 10 min à pied de la fac.',
        rent: 45000,
        caution: 45000,
        serviceFee: 0,
        spots: 2,
        houseState: HouseState.bon,
        conditions: 'Pas de fumeurs. Charges (eau/électricité) partagées. Bail minimum 6 mois.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Listing(
        id: 'l2',
        ownerId: 'u3',
        ownerName: 'Teranga Immo',
        ownerRole: UserRole.agency,
        kind: ListingKind.agency,
        title: 'Villa 5 chambres idéale pour colocation',
        city: 'Dakar',
        neighborhood: 'Mermoz',
        description: 'Grande villa avec jardin, 5 chambres, 2 salons, parking. Idéale pour 4 à 5 étudiants.',
        rent: 400000,
        caution: 800000,
        serviceFee: 400000,
        spots: 5,
        houseState: HouseState.neuf,
        conditions: 'Loyer total de la villa. Caution = 2 mois. Frais d\'agence = 1 mois. Visite sur rendez-vous.',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Listing(
        id: 'l3',
        ownerId: 'u2',
        ownerName: s2.name,
        ownerRole: UserRole.student,
        kind: ListingKind.request,
        title: 'Étudiant en master cherche colocation',
        city: 'Dakar',
        neighborhood: 'Zone Plateau / Point E',
        description: 'Étudiant en master 1, calme et sérieux, je cherche une chambre en colocation à partir du mois prochain.',
        rent: 50000,
        spots: 1,
        conditions: 'Budget max 50 000 FCFA/mois tout compris.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Listing(
        id: 'l4',
        ownerId: 'u3',
        ownerName: 'Teranga Immo',
        ownerRole: UserRole.agency,
        kind: ListingKind.agency,
        title: 'Studio meublé',
        city: 'Thiès',
        neighborhood: 'Cité Niakhip',
        description: 'Studio meublé avec salle d\'eau, proche du campus. Possible à partager à deux.',
        rent: 60000,
        caution: 120000,
        serviceFee: 30000,
        spots: 2,
        houseState: HouseState.arafraichir,
        conditions: 'Paiement du loyer le 5 de chaque mois.',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
    ]);
  }

  @override
  Future<AppUser?> currentUser() async => _me;

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? agencyName,
  }) async {
    if (_accounts.any((a) => a.email == email.toLowerCase())) {
      throw AppException('Cet e-mail est déjà utilisé.');
    }
    final u = AppUser(
      id: 'u${_seq++}',
      name: name,
      phone: phone,
      role: role,
      agencyName: agencyName,
    );
    _accounts.add(_Account(u, password, email.toLowerCase()));
    _phones[u.id] = phone;
    return _me = u;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final a = _accounts.where(
      (a) => a.email == email.toLowerCase() && a.password == password,
    );
    if (a.isEmpty) throw AppException('E-mail ou mot de passe incorrect.');
    return _me = a.first.user;
  }

  @override
  Future<void> signOut() async => _me = null;

  @override
  Future<List<Listing>> listings(ListingFilter f) async {
    final q = f.query.trim().toLowerCase();
    final r = _listings.where((l) {
      if (!l.active) return false;
      if (f.kind != null && l.kind != f.kind) return false;
      if (f.maxRent != null && l.rent > f.maxRent!) return false;
      if (q.isNotEmpty &&
          !('${l.title} ${l.city} ${l.neighborhood} ${l.description}'
              .toLowerCase()
              .contains(q))) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return r;
  }

  @override
  Future<List<Promo>> promos() async => const [
    Promo(
      id: 'p1',
      title: 'Ta coloc, sans prise de tête',
      subtitle: 'Trouve une maison ou des colocataires en quelques minutes.',
      colorA: 0xFF0F766E,
      colorB: 0xFF2DD4BF,
    ),
    Promo(
      id: 'p2',
      title: 'Agences : publiez vos logements',
      subtitle: 'Photos, caution, frais : touchez des milliers d\'étudiants.',
      colorA: 0xFF4338CA,
      colorB: 0xFF818CF8,
    ),
    Promo(
      id: 'p3',
      title: 'Votre publicité ici',
      subtitle: 'Boutiques, déménageurs, internet… parlez aux étudiants.',
      colorA: 0xFFEA580C,
      colorB: 0xFFFBBF24,
      sponsor: true,
    ),
  ];

  @override
  Future<List<Listing>> myListings() async =>
      _listings.where((l) => l.ownerId == _me?.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<Listing> createListing(ListingDraft d) async {
    final me = _me ?? (throw AppException('Connectez-vous pour publier.'));
    if (d.kind == ListingKind.agency && me.role != UserRole.agency) {
      throw AppException(
        'Seules les agences peuvent publier ce type d\'annonce.',
      );
    }
    final l = Listing(
      id: 'l${_seq++}',
      ownerId: me.id,
      ownerName: me.displayName,
      ownerRole: me.role,
      kind: d.kind,
      title: d.title,
      city: d.city,
      neighborhood: d.neighborhood,
      description: d.description,
      rent: d.rent,
      caution: d.caution,
      serviceFee: d.serviceFee,
      spots: d.spots,
      houseState: d.houseState,
      conditions: d.conditions,
      photos: d.photos.map(Photo.bytes).toList(),
      createdAt: DateTime.now(),
    );
    _listings.add(l);
    return l;
  }

  @override
  Future<void> setListingActive(String id, bool active) async {
    final i = _listings.indexWhere((l) => l.id == id && l.ownerId == _me?.id);
    if (i >= 0) _listings[i] = _listings[i].copyWith(active: active);
  }

  @override
  Future<void> deleteListing(String id) async =>
      _listings.removeWhere((l) => l.id == id && l.ownerId == _me?.id);

  @override
  Future<List<UnlockedContact>> unlockedContacts() async =>
      List.of(_unlocks[_me?.id] ?? const []);

  @override
  Future<UnlockedContact> payAndUnlock({
    required String listingId,
    required String method,
    required String payerPhone,
  }) async {
    final me = _me ?? (throw AppException('Connectez-vous pour contacter.'));
    final l = _listings.firstWhere(
      (l) => l.id == listingId,
      orElse: () => throw AppException('Annonce introuvable.'),
    );
    if (l.ownerId == me.id) throw AppException('C\'est votre propre annonce.');
    await Future<void>.delayed(
      Duration(milliseconds: 600 + Random().nextInt(400)),
    ); // paiement simulé
    final list = _unlocks.putIfAbsent(me.id, () => []);
    final existing = list.where((c) => c.listingId == listingId);
    if (existing.isNotEmpty) return existing.first;
    final c = UnlockedContact(
      listingId: listingId,
      name: l.ownerName,
      phone: _phones[l.ownerId] ?? '',
      at: DateTime.now(),
    );
    list.add(c);
    return c;
  }
}
