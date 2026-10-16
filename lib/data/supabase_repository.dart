import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models.dart';
import '../ui/design.dart' show ThemeSettings;
import 'repository.dart';

/// Implémentation de production (Supabase : Auth + Postgres + Storage).
/// Toutes les tables/fonctions sont préfixées `coloc_` (projet Supabase partagé avec d'autres applis) :
/// voir supabase/migrations/*_coloc_01_schema.sql.
class SupabaseRepository implements Repository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<void> init() => Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  UserRole _role(Object? r) => switch (r) {
    'agency' => UserRole.agency,
    'admin' => UserRole.admin,
    _ => UserRole.student,
  };

  /// Profil Colloc de l'utilisateur connecté ; créé à la volée s'il n'existe pas encore
  /// (ex. un compte créé pour une autre application du même projet Supabase).
  Future<AppUser> _profile(User u) async {
    Map<String, dynamic>? p = await _db
        .from('coloc_profiles')
        .select()
        .eq('id', u.id)
        .maybeSingle();
    if (p == null) {
      final m = u.userMetadata ?? {};
      await _db.rpc(
        'coloc_ensure_profile',
        params: {
          'p_name':
              (m['name'] ?? m['full_name'] ?? (u.email ?? '').split('@').first)
                  .toString(),
          'p_phone': (m['phone'] ?? '').toString(),
          'p_role': 'student',
          'p_agency': null,
        },
      );
      p = await _db.from('coloc_profiles').select().eq('id', u.id).single();
    }
    return AppUser(
      id: u.id,
      name: p['name'] as String,
      phone: (p['phone'] as String?) ?? '',
      role: _role(p['role']),
      agencyName: p['agency_name'] as String?,
    );
  }

  @override
  Future<AppUser?> currentUser() async {
    final u = _db.auth.currentUser;
    return u == null ? null : _profile(u);
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? agencyName,
  }) async {
    try {
      final res = await _db.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
      );
      if (res.session == null)
        throw AppException(
          'Compte créé. Confirmez votre e-mail puis connectez-vous.',
        );
      await _db.rpc(
        'coloc_ensure_profile',
        params: {
          'p_name': name,
          'p_phone': phone,
          'p_role': role.name,
          'p_agency': agencyName,
        },
      );
      return await _profile(res.user!);
    } on AuthException catch (e) {
      throw AppException(e.message);
    }
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _db.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return await _profile(res.user!);
    } on AuthException catch (e) {
      throw AppException(e.message);
    }
  }

  @override
  Future<void> signOut() => _db.auth.signOut();

  @override
  Future<void> updatePhone(String phone) async {
    try {
      await _db.rpc('coloc_update_phone', params: {'p_phone': phone});
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  // ───────── annonces ─────────

  Listing _listing(Map<String, dynamic> r) => Listing(
    id: r['id'] as String,
    ownerId: r['owner_id'] as String,
    ownerName: r['owner_name'] as String,
    ownerRole: _role(r['owner_role']),
    kind: ListingKind.values.byName(r['kind'] as String),
    title: r['title'] as String,
    city: r['city'] as String,
    neighborhood: (r['neighborhood'] as String?) ?? '',
    description: (r['description'] as String?) ?? '',
    rent: (r['rent'] as num?)?.toInt() ?? 0,
    caution: (r['caution'] as num?)?.toInt() ?? 0,
    serviceFee: (r['service_fee'] as num?)?.toInt() ?? 0,
    spots: (r['spots'] as num?)?.toInt() ?? 1,
    houseState: r['house_state'] == null
        ? null
        : HouseState.values.byName(r['house_state'] as String),
    conditions: (r['conditions'] as String?) ?? '',
    photos: ((r['photos'] as List?) ?? const [])
        .map((u) => Photo.url(u as String))
        .toList(),
    active: r['active'] as bool? ?? true,
    createdAt: DateTime.parse(r['created_at'] as String),
  );

  @override
  Future<List<Listing>> listings(ListingFilter f) async {
    var q = _db.from('coloc_listings').select().eq('active', true);
    if (f.kind != null) q = q.eq('kind', f.kind!.name);
    if (f.city != null) q = q.eq('city', f.city!);
    if (f.maxRent != null) q = q.lte('rent', f.maxRent!);
    final text = f.query.trim().replaceAll(RegExp(r'[,%()]'), ' ');
    if (text.isNotEmpty) {
      q = q.or(
        'title.ilike.%$text%,city.ilike.%$text%,neighborhood.ilike.%$text%,description.ilike.%$text%',
      );
    }
    final rows = await q.order('created_at', ascending: false).limit(100);
    return rows.map<Listing>(_listing).toList();
  }

  @override
  Future<List<Listing>> myListings() async {
    final uid = _db.auth.currentUser!.id;
    final rows = await _db
        .from('coloc_listings')
        .select()
        .eq('owner_id', uid)
        .order('created_at', ascending: false);
    return rows.map<Listing>(_listing).toList();
  }

  @override
  Future<Listing> createListing(ListingDraft d) async {
    final user =
        _db.auth.currentUser ??
        (throw AppException('Connectez-vous pour publier.'));
    final me = await _profile(user);
    final urls = <String>[];
    for (final bytes in d.photos) {
      final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await _db.storage
          .from('coloc-listing-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      urls.add(_db.storage.from('coloc-listing-photos').getPublicUrl(path));
    }
    final row = await _db
        .from('coloc_listings')
        .insert({
          'owner_id': user.id,
          'owner_name': me.displayName,
          'owner_role': me.role.name,
          'kind': d.kind.name,
          'title': d.title,
          'city': d.city,
          'neighborhood': d.neighborhood,
          'description': d.description,
          'rent': d.rent,
          'caution': d.caution,
          'service_fee': d.serviceFee,
          'spots': d.spots,
          'house_state': d.houseState?.name,
          'conditions': d.conditions,
          'photos': urls,
        })
        .select()
        .single();
    return _listing(row);
  }

  @override
  Future<void> setListingActive(String id, bool active) =>
      _db.from('coloc_listings').update({'active': active}).eq('id', id);

  @override
  Future<void> deleteListing(String id) =>
      _db.from('coloc_listings').delete().eq('id', id);

  // ───────── paiements manuels ─────────

  @override
  Future<List<UnlockedContact>> unlockedContacts() async {
    final rows = await _db.rpc('coloc_my_unlocked_contacts') as List;
    return rows
        .map(
          (r) => UnlockedContact(
            listingId: r['listing_id'] as String,
            name: r['name'] as String,
            phone: (r['phone'] as String?) ?? '',
            at: DateTime.parse(r['at'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<List<PaymentMethodInfo>> paymentMethods() async {
    final row = await _db
        .from('coloc_app_settings')
        .select('value')
        .eq('key', 'payment_methods')
        .maybeSingle();
    final list = (row?['value'] as List?) ?? const [];
    return [
      for (final m in list)
        PaymentMethodInfo(
          id: m['id'] as String,
          label: m['label'] as String,
          number: m['number'] as String,
          holder: (m['holder'] as String?) ?? '',
        ),
    ];
  }

  PaymentNotice _notice(Map<String, dynamic> r) => PaymentNotice(
    id: r['id'] as String,
    listingId: r['listing_id'] as String,
    listingTitle: (r['listing_title'] as String?) ?? '',
    payerName: (r['payer_name'] as String?) ?? '',
    payerPhone: (r['payer_phone'] as String?) ?? '',
    method: (r['method'] as String?) ?? '',
    reference: (r['reference'] as String?) ?? '',
    status: PaymentStatus.values.byName(r['status'] as String),
    createdAt: DateTime.parse(r['created_at'] as String),
    amount: (r['amount'] as num?)?.toInt() ?? 1000,
  );

  @override
  Future<PaymentNotice> submitPayment({
    required String listingId,
    required String method,
    required String payerPhone,
    required String reference,
  }) async {
    try {
      await _db.rpc(
        'coloc_request_unlock',
        params: {
          'p_listing': listingId,
          'p_method': method,
          'p_phone': payerPhone,
          'p_reference': reference,
        },
      );
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
    final mine = await myPayments();
    return mine.firstWhere((p) => p.listingId == listingId);
  }

  @override
  Future<List<PaymentNotice>> myPayments() async {
    final rows = await _db.rpc('coloc_my_payments') as List;
    return rows
        .map<PaymentNotice>((r) => _notice(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PaymentNotice>> adminPayments() async {
    try {
      final rows = await _db.rpc('coloc_admin_payments') as List;
      return rows
          .map<PaymentNotice>((r) => _notice(r as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  @override
  Future<void> reviewPayment(String id, {required bool approve}) async {
    try {
      await _db.rpc(
        'coloc_admin_review_payment',
        params: {'p_id': id, 'p_approve': approve},
      );
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  // ───────── flyers ─────────

  static int _hex(String? h, int fallback) {
    final v = int.tryParse((h ?? '').replaceAll('#', ''), radix: 16);
    return v == null ? fallback : (0xFF000000 | v);
  }

  static String _toHex(int c) =>
      (c & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

  Promo _promo(Map<String, dynamic> r) => Promo(
    id: r['id'] as String,
    title: (r['title'] as String?) ?? '',
    subtitle: (r['subtitle'] as String?) ?? '',
    imageUrl: r['image_url'] as String?,
    linkUrl: r['link_url'] as String?,
    colorA: _hex(r['color_a'] as String?, 0xFF0F766E),
    colorB: _hex(r['color_b'] as String?, 0xFF14B8A6),
    sponsor: r['sponsor'] as bool? ?? false,
    sort: (r['sort'] as num?)?.toInt() ?? 0,
    active: r['active'] as bool? ?? true,
  );

  @override
  Future<List<Promo>> promos() async {
    final rows = await _db
        .from('coloc_promos')
        .select()
        .eq('active', true)
        .order('sort');
    return rows.map<Promo>(_promo).toList();
  }

  @override
  Future<List<Promo>> allPromos() async {
    final rows = await _db.from('coloc_promos').select().order('sort');
    return rows.map<Promo>(_promo).toList();
  }

  @override
  Future<void> savePromo(PromoDraft d) async {
    var imageUrl = d.imageUrl;
    if (d.imageBytes != null) {
      final path = 'flyers/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await _db.storage
          .from('coloc-promo-images')
          .uploadBinary(
            path,
            d.imageBytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      imageUrl = _db.storage.from('coloc-promo-images').getPublicUrl(path);
    }
    final row = {
      'title': d.title,
      'subtitle': d.subtitle,
      'image_url': imageUrl,
      'link_url': (d.linkUrl ?? '').trim().isEmpty ? null : d.linkUrl!.trim(),
      'color_a': _toHex(d.colorA),
      'color_b': _toHex(d.colorB),
      'sponsor': d.sponsor,
      'active': d.active,
      'sort': d.sort,
    };
    try {
      if (d.id == null) {
        await _db.from('coloc_promos').insert(row);
      } else {
        await _db.from('coloc_promos').update(row).eq('id', d.id!);
      }
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  @override
  Future<void> deletePromo(String id) async {
    try {
      await _db.from('coloc_promos').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  // ───────── design ─────────

  @override
  Future<ThemeSettings> themeSettings() async {
    final row = await _db
        .from('coloc_app_settings')
        .select('value')
        .eq('key', 'theme')
        .maybeSingle();
    return ThemeSettings.fromJson(
      (row?['value'] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  Future<void> saveTheme(ThemeSettings s) async {
    try {
      await _db.rpc('coloc_admin_set_theme', params: {'p_value': s.toJson()});
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  // ───────── statistiques ─────────

  @override
  Future<void> track(AnalyticsEvent e) async {
    try {
      await _db.rpc(
        'coloc_track',
        params: {
          'p_visitor': e.visitorId,
          'p_session': e.sessionId,
          'p_type': e.type,
          'p_screen': e.screen,
          'p_listing': e.listingId,
          'p_promo': e.promoId,
          'p_query': e.query,
          'p_city': e.city,
          'p_device': e.device,
        },
      );
    } catch (_) {
      // les statistiques ne doivent jamais gêner l'utilisateur
    }
  }

  @override
  Future<Stats> adminStats(int days) async {
    try {
      final r = await _db.rpc('coloc_admin_stats', params: {'p_days': days});
      return Stats.fromJson((r as Map).cast<String, dynamic>());
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }
}
