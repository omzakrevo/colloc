import 'dart:math';

import 'package:flutter/services.dart';

import '../models.dart';
import '../ui/design.dart' show ThemeSettings;
import 'repository.dart';

class _Account {
  _Account(this.user, this.password, this.email);
  AppUser user;
  final String password, email;
}

class _Payment {
  _Payment(this.userId, this.notice);
  final String userId;
  PaymentNotice notice;
}

/// Données en mémoire : permet de tester toute l'app sans serveur.
/// Comptes de démo (mot de passe « demo1234 ») : etudiant@, etudiant2@, agence@, admin@demo.com.
class DemoRepository implements Repository {
  final _accounts = <_Account>[];
  final _listings = <Listing>[];
  final _payments = <_Payment>[];
  final _promos = <Promo>[];
  final _events = <AnalyticsEvent>[];
  ThemeSettings _theme = const ThemeSettings();
  AppUser? _me;
  var _seq = 100;

  @override
  Future<void> init() async {
    final s = AppUser(
      id: 'u1',
      name: 'Aminata Ouédraogo',
      phone: '+226 70 12 34 56',
      role: UserRole.student,
    );
    final s2 = AppUser(
      id: 'u2',
      name: 'Yusup Abdulla',
      phone: '+226 76 55 51 23',
      role: UserRole.student,
    );
    final a = AppUser(
      id: 'u3',
      name: 'Moussa Compaoré',
      phone: '+226 78 90 01 12',
      role: UserRole.agency,
      agencyName: 'Faso Immo',
    );
    final adm = AppUser(
      id: 'u4',
      name: 'Administrateur Colloc',
      phone: '+226 70 00 00 00',
      role: UserRole.admin,
    );
    _accounts.addAll([
      _Account(s, 'demo1234', 'etudiant@demo.com'),
      _Account(s2, 'demo1234', 'etudiant2@demo.com'),
      _Account(a, 'demo1234', 'agence@demo.com'),
      _Account(adm, 'demo1234', 'admin@demo.com'),
    ]);
    final now = DateTime.now();
    _listings.addAll([
      Listing(
        id: 'l1',
        ownerId: 'u1',
        ownerName: s.name,
        ownerRole: UserRole.student,
        kind: ListingKind.offer,
        title: "2 chambres libres près de l'Université Joseph Ki-Zerbo",
        city: 'Ouagadougou',
        neighborhood: 'Zogona',
        description: "Maison de 4 chambres, je cherche 2 colocataires sérieux. Cuisine équipée, wifi inclus, 10 min à pied de l'université.",
        rent: 30000,
        caution: 30000,
        serviceFee: 0,
        spots: 2,
        houseState: HouseState.bon,
        conditions: 'Pas de fumeurs. Eau et électricité partagées. Bail minimum 6 mois.',
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Listing(
        id: 'l2',
        ownerId: 'u3',
        ownerName: 'Faso Immo',
        ownerRole: UserRole.agency,
        kind: ListingKind.agency,
        title: 'Villa 5 chambres idéale pour colocation',
        city: 'Ouagadougou',
        neighborhood: 'Ouaga 2000',
        description: 'Grande villa avec cour, 5 chambres, 2 salons, parking. Idéale pour 4 à 5 étudiants.',
        rent: 250000,
        caution: 500000,
        serviceFee: 250000,
        spots: 5,
        houseState: HouseState.neuf,
        conditions: "Loyer total de la villa. Caution = 2 mois. Frais d'agence = 1 mois. Visite sur rendez-vous.",
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Listing(
        id: 'l3',
        ownerId: 'u2',
        ownerName: s2.name,
        ownerRole: UserRole.student,
        kind: ListingKind.request,
        title: "Étudiant en master cherche colocation près de l'Université Nazi Boni",
        city: 'Bobo-Dioulasso',
        neighborhood: 'Accart-Ville',
        description: "Étudiant en master 1, calme et sérieux, je cherche une chambre en colocation à partir du mois prochain.",
        rent: 25000,
        spots: 1,
        conditions: 'Budget max 25 000 FCFA/mois tout compris.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Listing(
        id: 'l4',
        ownerId: 'u3',
        ownerName: 'Faso Immo',
        ownerRole: UserRole.agency,
        kind: ListingKind.agency,
        title: "Studio meublé près de l'Université Norbert Zongo",
        city: 'Koudougou',
        neighborhood: 'Secteur 4',
        description: 'Studio meublé avec salle d\'eau, proche du campus. Possible à partager à deux.',
        rent: 40000,
        caution: 80000,
        serviceFee: 20000,
        spots: 2,
        houseState: HouseState.arafraichir,
        conditions: 'Paiement du loyer le 5 de chaque mois.',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      Listing(
        id: 'l5',
        ownerId: 'u1',
        ownerName: s.name,
        ownerRole: UserRole.student,
        kind: ListingKind.offer,
        title: 'Chambre libre dans une maison à cour',
        city: 'Bobo-Dioulasso',
        neighborhood: 'Sarfalao',
        description: 'Chambre dans une maison à cour partagée avec deux étudiants. Cuisine commune, douche interne.',
        rent: 20000,
        caution: 20000,
        spots: 1,
        houseState: HouseState.bon,
        conditions: 'Respect du calme après 22 h.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      Listing(
        id: 'l6',
        ownerId: 'u3',
        ownerName: 'Faso Immo',
        ownerRole: UserRole.agency,
        kind: ListingKind.agency,
        title: 'Appartement 2 chambres à partager',
        city: 'Banfora',
        neighborhood: 'Centre-ville',
        description: 'Appartement lumineux avec salon, cuisine et balcon. Idéal pour 2 à 3 étudiants.',
        rent: 60000,
        caution: 120000,
        serviceFee: 30000,
        spots: 3,
        houseState: HouseState.neuf,
        conditions: 'Contrat de 12 mois. Visite possible le week-end.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Listing(
        id: 'l7',
        ownerId: 'u2',
        ownerName: s2.name,
        ownerRole: UserRole.student,
        kind: ListingKind.request,
        title: 'Cherche colocation à Ouahigouya',
        city: 'Ouahigouya',
        neighborhood: 'Centre-ville',
        description:
            'Nouvel étudiant, je cherche une colocation calme près du centre.',
        rent: 20000,
        spots: 1,
        conditions: 'Disponible dès septembre.',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ]);
    _promos.addAll(const [
      Promo(
        id: 'p1',
        title: 'Ta coloc, sans prise de tête',
        subtitle: 'Trouve une maison ou des colocataires en quelques minutes.',
        colorA: 0xFF0F766E,
        colorB: 0xFF2DD4BF,
        sort: 0,
      ),
      Promo(
        id: 'p2',
        title: 'Agences : publiez vos logements',
        subtitle: "Photos, caution, frais : touchez des milliers d'étudiants.",
        colorA: 0xFF4338CA,
        colorB: 0xFF818CF8,
        sort: 1,
      ),
      Promo(
        id: 'p3',
        title: 'Votre publicité ici',
        subtitle: 'Boutiques, déménageurs, internet… parlez aux étudiants.',
        colorA: 0xFFEA580C,
        colorB: 0xFFFBBF24,
        sponsor: true,
        sort: 2,
        linkUrl: 'https://coloc.telimatchi.com',
      ),
    ]);
    await _attachDemoPhotos();
    _seedEvents();
  }

  /// Photos d'exemple : seulement celles présentes dans assets/houses/ (house1.jpg … house8.jpg).
  Future<void> _attachDemoPhotos() async {
    const plan = {
      'l1': ['house3', 'house5', 'house6'],
      'l2': ['house2', 'house1'],
      'l4': ['house8', 'house4'],
      'l5': ['house4', 'house5', 'house7'],
      'l6': ['house3', 'house6'],
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
      if (photos.isNotEmpty && i >= 0)
        _listings[i] = _listings[i].copyWith(photos: photos);
    }
  }

  /// Historique de visites fictif (30 jours) pour que le tableau de bord ne soit pas vide en démo.
  void _seedEvents() {
    final r = Random(7);
    final now = DateTime.now();
    const queries = [
      'coloc ouaga',
      'chambre bobo',
      'studio',
      'villa',
      'zogona',
      'pas cher',
      'koudougou',
    ];
    const cities = [
      'Ouagadougou',
      'Bobo-Dioulasso',
      'Banfora',
      'Koudougou',
      'Ouahigouya',
    ];
    for (var day = 29; day >= 0; day--) {
      final visitors = 10 + r.nextInt(12) + (30 - day) ~/ 2;
      for (var v = 0; v < visitors; v++) {
        final vid = 'seed-$day-$v', sid = 's-$day-$v';
        final dev = r.nextDouble() < .78 ? 'mobile' : 'desktop';
        var t = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: day))
            .add(Duration(minutes: 420 + r.nextInt(900)));
        void ev(
          String type, {
          String? screen,
          String? l,
          String? p,
          String? q,
          String? c,
        }) {
          t = t.add(Duration(seconds: 5 + r.nextInt(40)));
          if (t.isAfter(now)) return;
          _events.add(
            AnalyticsEvent(
              visitorId: vid,
              sessionId: sid,
              type: type,
              screen: screen,
              listingId: l,
              promoId: p,
              query: q,
              city: c,
              device: dev,
              at: t,
            ),
          );
        }

        ev('view', screen: 'accueil');
        if (r.nextDouble() < .85) ev('promo_view', p: 'p${1 + r.nextInt(3)}');
        if (r.nextDouble() < .06) ev('promo_click', p: 'p${1 + r.nextInt(3)}');
        if (r.nextDouble() < .45)
          ev('filter_city', c: cities[r.nextInt(cities.length)]);
        if (r.nextDouble() < .30)
          ev('search', q: queries[r.nextInt(queries.length)]);
        if (r.nextDouble() < .65) {
          final l = 'l${1 + r.nextInt(7)}';
          ev('listing_view', l: l);
          if (r.nextDouble() < .35)
            ev('listing_view', l: 'l${1 + r.nextInt(7)}');
          if (r.nextDouble() < .20) {
            ev('contact_click', l: l);
            if (r.nextDouble() < .4) ev('payment_notice', l: l);
          }
        }
        if (r.nextDouble() < .04) ev('signup');
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
    if (_accounts.any((a) => a.email == email.toLowerCase()))
      throw AppException('Cet e-mail est déjà utilisé.');
    final u = AppUser(
      id: 'u${_seq++}',
      name: name,
      phone: phone,
      role: role,
      agencyName: agencyName,
    );
    _accounts.add(_Account(u, password, email.toLowerCase()));
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

  String _phoneOf(String userId) =>
      _accounts.firstWhere((a) => a.user.id == userId).user.phone;

  @override
  Future<void> updatePhone(String phone) async {
    final me = _me ?? (throw AppException('Connectez-vous.'));
    final acc = _accounts.firstWhere((a) => a.user.id == me.id);
    acc.user = AppUser(
      id: me.id,
      name: me.name,
      phone: phone,
      role: me.role,
      agencyName: me.agencyName,
    );
    _me = acc.user;
  }

  @override
  Future<List<Listing>> listings(ListingFilter f) async {
    final q = f.query.trim().toLowerCase();
    return _listings.where((l) {
      if (!l.active) return false;
      if (f.kind != null && l.kind != f.kind) return false;
      if (f.city != null && l.city != f.city) return false;
      if (f.maxRent != null && l.rent > f.maxRent!) return false;
      if (q.isNotEmpty &&
          !('${l.title} ${l.city} ${l.neighborhood} ${l.description}'
              .toLowerCase()
              .contains(q)))
        return false;
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Listing>> myListings() async =>
      _listings.where((l) => l.ownerId == _me?.id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<Listing> createListing(ListingDraft d) async {
    final me = _me ?? (throw AppException('Connectez-vous pour publier.'));
    if (d.kind == ListingKind.agency && me.role != UserRole.agency) {
      throw AppException(
        "Seules les agences peuvent publier ce type d'annonce.",
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

  // ───────── paiements manuels ─────────

  @override
  Future<List<UnlockedContact>> unlockedContacts() async {
    final me = _me;
    if (me == null) return const [];
    return [
      for (final p in _payments)
        if (p.userId == me.id && p.notice.status == PaymentStatus.approved)
          () {
            final l = _listings.firstWhere((l) => l.id == p.notice.listingId);
            return UnlockedContact(
              listingId: l.id,
              name: l.ownerName,
              phone: _phoneOf(l.ownerId),
              at: p.notice.createdAt,
            );
          }(),
    ];
  }

  @override
  Future<List<PaymentMethodInfo>> paymentMethods() async => const [
    PaymentMethodInfo(
      id: 'orange',
      label: 'Orange Money',
      number: '+226 70 00 00 01',
      holder: 'Colloc (démo)',
    ),
    PaymentMethodInfo(
      id: 'moov',
      label: 'Moov Money',
      number: '+226 60 00 00 02',
      holder: 'Colloc (démo)',
    ),
    PaymentMethodInfo(
      id: 'coris',
      label: 'Coris Money',
      number: '+226 70 00 00 03',
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
    if (existing.any((p) => p.notice.status != PaymentStatus.rejected))
      throw AppException('Un avis existe déjà pour cette annonce.');
    _payments.removeWhere(existing.contains);
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

  void _admin() {
    if (_me?.isAdmin != true) throw AppException("Réservé à l'administrateur.");
  }

  @override
  Future<List<PaymentNotice>> adminPayments() async {
    _admin();
    return [for (final p in _payments) p.notice]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> reviewPayment(String id, {required bool approve}) async {
    _admin();
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

  // ───────── flyers ─────────

  @override
  Future<List<Promo>> promos() async =>
      (_promos.where((p) => p.active).toList()
        ..sort((a, b) => a.sort.compareTo(b.sort)));

  @override
  Future<List<Promo>> allPromos() async {
    _admin();
    return List.of(_promos)..sort((a, b) => a.sort.compareTo(b.sort));
  }

  @override
  Future<void> savePromo(PromoDraft d) async {
    _admin();
    final p = Promo(
      id: d.id ?? 'p${_seq++}',
      title: d.title,
      subtitle: d.subtitle,
      linkUrl: (d.linkUrl ?? '').trim().isEmpty ? null : d.linkUrl!.trim(),
      imageUrl: d.imageUrl,
      imageBytes: d.imageBytes,
      colorA: d.colorA,
      colorB: d.colorB,
      sponsor: d.sponsor,
      active: d.active,
      sort: d.sort,
    );
    final i = _promos.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      _promos[i] = p;
    } else {
      _promos.add(p);
    }
  }

  @override
  Future<void> deletePromo(String id) async {
    _admin();
    _promos.removeWhere((p) => p.id == id);
  }

  // ───────── design ─────────

  @override
  Future<ThemeSettings> themeSettings() async => _theme;

  @override
  Future<void> saveTheme(ThemeSettings s) async {
    _admin();
    _theme = s;
  }

  // ───────── statistiques ─────────

  @override
  Future<void> track(AnalyticsEvent e) async => _events.add(e);

  @override
  Future<Stats> adminStats(int days) async {
    _admin();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final from = today.subtract(Duration(days: days - 1));
    final per = _events.where((e) => !e.at.isBefore(from)).toList();
    int distinct(Iterable<AnalyticsEvent> it) =>
        it.map((e) => e.visitorId).toSet().length;
    final title = {for (final l in _listings) l.id: l.title};
    final promoTitle = {for (final p in _promos) p.id: p.title};

    List<RankItem> top(
      Iterable<AnalyticsEvent> it,
      String? Function(AnalyticsEvent) key, {
      int Function(String)? second,
      int limit = 5,
    }) {
      final m = <String, int>{};
      for (final e in it) {
        final k = key(e);
        if (k != null && k.isNotEmpty) m[k] = (m[k] ?? 0) + 1;
      }
      final l = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return [
        for (final e in l.take(limit))
          RankItem(e.key, e.value, second?.call(e.key) ?? 0),
      ];
    }

    final views = per.where((e) => e.type == 'listing_view');
    final clicks = per.where((e) => e.type == 'contact_click');
    final promoViews = per.where((e) => e.type == 'promo_view'),
        promoClicks = per.where((e) => e.type == 'promo_click');
    final sessions = per.map((e) => e.sessionId).toSet().length;
    final pv = per
        .where((e) => e.type == 'view' || e.type == 'listing_view')
        .length;
    final approved = _payments
        .where((p) => p.notice.status == PaymentStatus.approved)
        .length;

    return Stats(
      visitorsToday: distinct(_events.where((e) => !e.at.isBefore(today))),
      visitors7: distinct(
        _events.where(
          (e) => !e.at.isBefore(today.subtract(const Duration(days: 6))),
        ),
      ),
      visitors30: distinct(
        _events.where(
          (e) => !e.at.isBefore(today.subtract(const Duration(days: 29))),
        ),
      ),
      sessions: sessions,
      pageViews: pv,
      listingViews: views.length,
      searches: per.where((e) => e.type == 'search').length,
      contactClicks: clicks.length,
      paymentNotices: per.where((e) => e.type == 'payment_notice').length,
      approved: approved,
      signups: per.where((e) => e.type == 'signup').length,
      promoViews: promoViews.length,
      promoClicks: promoClicks.length,
      screensPerSession: sessions == 0 ? 0 : pv / sessions,
      funnelVisitors: distinct(per),
      funnelListing: distinct(views),
      funnelContact: distinct(clicks),
      funnelNotice: distinct(per.where((e) => e.type == 'payment_notice')),
      daily: [
        for (var i = 0; i < days; i++)
          () {
            final d0 = from.add(Duration(days: i)),
                d1 = d0.add(const Duration(days: 1));
            final day = _events.where(
              (e) => !e.at.isBefore(d0) && e.at.isBefore(d1),
            );
            return DayStat(
              d0,
              distinct(day),
              day
                  .where((e) => e.type == 'view' || e.type == 'listing_view')
                  .length,
            );
          }(),
      ],
      topListings: top(
        views,
        (e) => title[e.listingId],
        second: (t) => clicks.where((c) => title[c.listingId] == t).length,
      ),
      topSearches: top(per.where((e) => e.type == 'search'), (e) => e.query),
      topCities: top(per.where((e) => e.type == 'filter_city'), (e) => e.city),
      topPromos: top(
        promoViews,
        (e) => promoTitle[e.promoId],
        second: (t) =>
            promoClicks.where((c) => promoTitle[c.promoId] == t).length,
      ),
      devices: [
        RankItem(
          'Mobile',
          per
              .where((e) => e.device == 'mobile')
              .map((e) => e.visitorId)
              .toSet()
              .length,
        ),
        RankItem(
          'Ordinateur',
          per
              .where((e) => e.device == 'desktop')
              .map((e) => e.visitorId)
              .toSet()
              .length,
        ),
      ],
    );
  }
}
