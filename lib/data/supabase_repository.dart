import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models.dart';
import 'repository.dart';

/// Implémentation de production (Supabase : Auth + Postgres + Storage + Edge Function).
/// Schéma : supabase/schema.sql.
class SupabaseRepository implements Repository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<void> init() => Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  Future<AppUser> _profile(String id) async {
    final p = await _db.from('profiles').select().eq('id', id).single();
    return AppUser(
      id: id,
      name: p['name'] as String,
      phone: (p['phone'] as String?) ?? '',
      role: p['role'] == 'agency' ? UserRole.agency : UserRole.student,
      agencyName: p['agency_name'] as String?,
    );
  }

  @override
  Future<AppUser?> currentUser() async {
    final u = _db.auth.currentUser;
    return u == null ? null : _profile(u.id);
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
        data: {
          'name': name,
          'phone': phone,
          'role': role.name,
          'agency_name': agencyName,
        },
      );
      if (res.session == null) {
        throw AppException(
          'Compte créé. Confirmez votre e-mail puis connectez-vous.',
        );
      }
      return await _profile(res.user!.id);
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
      return await _profile(res.user!.id);
    } on AuthException catch (e) {
      throw AppException(e.message);
    }
  }

  @override
  Future<void> signOut() => _db.auth.signOut();

  Listing _listing(Map<String, dynamic> r) => Listing(
    id: r['id'] as String,
    ownerId: r['owner_id'] as String,
    ownerName: r['owner_name'] as String,
    ownerRole: r['owner_role'] == 'agency' ? UserRole.agency : UserRole.student,
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
    var q = _db.from('listings').select().eq('active', true);
    if (f.kind != null) q = q.eq('kind', f.kind!.name);
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
        .from('listings')
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
    final me = await _profile(user.id);
    final urls = <String>[];
    for (final bytes in d.photos) {
      final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
      await _db.storage
          .from('listing-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      urls.add(_db.storage.from('listing-photos').getPublicUrl(path));
    }
    final row = await _db
        .from('listings')
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
      _db.from('listings').update({'active': active}).eq('id', id);

  @override
  Future<void> deleteListing(String id) =>
      _db.from('listings').delete().eq('id', id);

  @override
  Future<List<UnlockedContact>> unlockedContacts() async {
    final rows = await _db.rpc('my_unlocked_contacts') as List;
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
  Future<UnlockedContact> payAndUnlock({
    required String listingId,
    required String method,
    required String payerPhone,
  }) async {
    final res = await _db.functions.invoke(
      'pay-contact',
      body: {
        'listing_id': listingId,
        'method': method,
        'payer_phone': payerPhone,
      },
    );
    if (res.status != 200) {
      final msg = res.data is Map ? (res.data['error'] as String?) : null;
      throw AppException(msg ?? 'Paiement impossible pour le moment.');
    }
    final all = await unlockedContacts();
    return all.firstWhere(
      (c) => c.listingId == listingId,
      orElse: () => throw AppException('Paiement en attente de confirmation.'),
    );
  }
}
