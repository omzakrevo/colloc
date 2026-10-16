import 'package:flutter/services.dart';

import '../models.dart';
import 'repository.dart';

class _Account {
  _Account(this.user, this.password, this.email);
  final AppUser user;
  final String password, email;
}

/// Données en mémoire : permet de tester toute l'app sans serveur.
/// Comptes de démo : etudiant@demo.com / agence@demo.com — mot de passe "demo1234".
class _Payment {
  _Payment(this.userId, this.notice);
  final String userId;
  PaymentNotice notice;
}

class DemoRepository implements Repository {
  final _accounts = <_Account>[];
  final _listings = <Listing>[];
  final _payments = <_Payment>[];
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
    final adm = AppUser(
      id: 'u4',
      name: 'Administrateur Colloc',
      phone: '+221 70 000 00 00',
      role: UserRole.admin,
    );
    _accounts.addAll([
      _Account(adm, 'demo1234', 'admin@demo.com'),
      _Account(s, 'demo1234', 'etudiant@demo.com'),
      _Account(s2, 'demo1234', 'etudiant2@demo.com'),
      _Account(a, 'demo1234', 'agence@demo.com'),
    ]);
    for (final u in [s, s2, a, adm]) {
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

    await _attachDemoPhotos();
  }

  /// Photos d'exemple : on n'utilise que celles présentes dans assets/houses/ (house1.jpg … house8.jpg).
  Future<void> _attachDemoPhotos() async {
    const plan = {
      'l1': ['house5', 'house6', 'house4'],
      'l2': ['house2', 'house1'],
      'l4': ['house8', 'house3'],
    };
    Set<String> available;
    try {
      available = (await AssetManifest.loadFromAssetBundle(rootBundle))
          .listAssets()
          .toSet();
    } catch (_) {
      return;
    }
    for (final e in plan.entries) {
      final photos = [
        for (final n in e.value)
          if (available.contains('assets/houses/$n.jpg'))
            Photo.asset('assets/houses/$n.jpg'),
      ];
      final i = _listings.indexWhere((l) => l.id == e.key);
      if (photos.isNotEmpty && i >= 0) {
        _listings[i] = _listings[i].copyWith(photos: photos);
      }
    }
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
  Future<List<UnlockedContact>> unlockedContacts() async {
    final me = _me;
    if (me == null) return const [];
    return [
      for (final p in _payments)
        if (p.userId == me.id && p.notice.status == PaymentStatus.approved)
          UnlockedContact(
            listingId: p.notice.listingId,
            name: _listings
                .firstWhere((l) => l.id == p.notice.listingId)
                .ownerName,
            phone:
                _phones[_listings
                    .firstWhere((l) => l.id == p.notice.listingId)
                    .ownerId] ??
                '',
            at: p.notice.createdAt,
          ),
    ];
  }

  @override
  Future<List<PaymentMethodInfo>> paymentMethods() async => const [
    PaymentMethodInfo(
      id: 'wave',
      label: 'Wave',
      number: '+221 70 000 00 01',
      holder: 'Colloc (démo)',
    ),
    PaymentMethodInfo(
      id: 'orange',
      label: 'Orange Money',
      number: '+221 70 000 00 02',
      holder: 'Colloc (démo)',
    ),
  ];

  @override
  Future<PaymentNotice> submitPayment({
    required String listingId,
    required String method,
    required String payerPhone,
    required String reference,
  }) async {
    final me = _me ?? (throw AppException('Connectez-vous pour contacter.'));
    final l = _listings.firstWhere(
      (l) => l.id == listingId,
      orElse: () => throw AppException('Annonce introuvable.'),
    );
    if (l.ownerId == me.id) throw AppException("C'est votre propre annonce.");
    final existing = _payments
        .where((p) => p.userId == me.id && p.notice.listingId == listingId)
        .toList();
    if (existing.any((p) => p.notice.status != PaymentStatus.rejected)) {
      throw AppException('Un avis existe déjà pour cette annonce.');
    }
    _payments.removeWhere((p) => existing.contains(p));
    final n = PaymentNotice(
      id: 'p${_seq++}',
      listingId: listingId,
      listingTitle: l.title,
      payerName: me.displayName,
      payerPhone: payerPhone,
      method: method,
      reference: reference,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );
    _payments.add(_Payment(me.id, n));
    return n;
  }

  @override
  Future<List<PaymentNotice>> myPayments() async => [
    for (final p in _payments)
      if (p.userId == _me?.id) p.notice,
  ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<PaymentNotice>> adminPayments() async {
    if (_me?.isAdmin != true) {
      throw AppException('Réservé à l\'administrateur.');
    }
    return [for (final p in _payments) p.notice]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> reviewPayment(String id, {required bool approve}) async {
    if (_me?.isAdmin != true) {
      throw AppException('Réservé à l\'administrateur.');
    }
    final p = _payments.firstWhere(
      (p) => p.notice.id == id,
      orElse: () => throw AppException('Avis introuvable.'),
    );
    final n = p.notice;
    p.notice = PaymentNotice(
      id: n.id,
      listingId: n.listingId,
      listingTitle: n.listingTitle,
      payerName: n.payerName,
      payerPhone: n.payerPhone,
      method: n.method,
      reference: n.reference,
      createdAt: n.createdAt,
      amount: n.amount,
      status: approve ? PaymentStatus.approved : PaymentStatus.rejected,
    );
  }
}
