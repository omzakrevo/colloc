import 'package:colloc/cities.dart';
import 'package:colloc/data/demo_repository.dart';
import 'package:colloc/main.dart';
import 'package:colloc/models.dart';
import 'package:colloc/state/app_state.dart';
import 'package:colloc/ui/design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DemoRepository repo;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = DemoRepository();
    await repo.init();
  });

  test(
    'paiement manuel : contact caché jusqu\'à validation par l\'admin',
    () async {
      await repo.signIn(email: 'etudiant2@demo.com', password: 'demo1234');
      expect(await repo.unlockedContacts(), isEmpty);
      final n = await repo.submitPayment(
        listingId: 'l1',
        method: 'Wave',
        payerPhone: '+22670000000',
        reference: 'TX123',
      );
      expect(n.status, PaymentStatus.pending);
      expect(await repo.unlockedContacts(), isEmpty); // toujours caché
      // pas de doublon tant que l'avis est en attente
      expect(
        () => repo.submitPayment(
          listingId: 'l1',
          method: 'Wave',
          payerPhone: '+22670000000',
          reference: '',
        ),
        throwsA(isA<Exception>()),
      );
      // un utilisateur normal ne peut pas valider
      expect(
        () => repo.reviewPayment(n.id, approve: true),
        throwsA(isA<Exception>()),
      );
      await repo.signOut();

      await repo.signIn(email: 'admin@demo.com', password: 'demo1234');
      expect((await repo.adminPayments()).single.payerName, 'Yusup Abdulla');
      await repo.reviewPayment(n.id, approve: true);
      await repo.signOut();

      await repo.signIn(email: 'etudiant2@demo.com', password: 'demo1234');
      final c = (await repo.unlockedContacts()).single;
      expect(c.phone, contains('70 12'));
      expect((await repo.myPayments()).single.status, PaymentStatus.approved);
    },
  );

  test('avis refusé : pas de contact, nouvel avis possible', () async {
    await repo.signIn(email: 'etudiant2@demo.com', password: 'demo1234');
    final n = await repo.submitPayment(
      listingId: 'l1',
      method: 'Wave',
      payerPhone: '+22670000000',
      reference: '',
    );
    await repo.signOut();
    await repo.signIn(email: 'admin@demo.com', password: 'demo1234');
    await repo.reviewPayment(n.id, approve: false);
    await repo.signOut();
    await repo.signIn(email: 'etudiant2@demo.com', password: 'demo1234');
    expect(await repo.unlockedContacts(), isEmpty);
    final again = await repo.submitPayment(
      listingId: 'l1',
      method: 'Wave',
      payerPhone: '+22670000000',
      reference: 'OK',
    );
    expect(again.status, PaymentStatus.pending);
  });

  test('seule une agence peut publier une annonce agence', () async {
    await repo.signIn(email: 'etudiant@demo.com', password: 'demo1234');
    final draft = ListingDraft(
      kind: ListingKind.agency,
      title: 't',
      city: 'Dakar',
      neighborhood: '',
      description: '',
    );
    expect(() => repo.createListing(draft), throwsA(isA<Exception>()));
    await repo.signOut();
    await repo.signIn(email: 'agence@demo.com', password: 'demo1234');
    final l = await repo.createListing(draft);
    expect(
      (await repo.listings(const ListingFilter())).any((x) => x.id == l.id),
      isTrue,
    );
  });

  test('filtres par type et recherche', () async {
    expect(
      (await repo.listings(const ListingFilter(kind: ListingKind.request)))
          .length,
      2,
    );
    expect(
      (await repo.listings(const ListingFilter(query: 'koudougou'))).single.id,
      'l4',
    );
  });

  test('slider de pubs fourni par le dépôt', () async {
    final promos = await repo.promos();
    expect(promos.length, greaterThanOrEqualTo(3));
    expect(promos.any((p) => p.sponsor), isTrue);
  });

  test('villes du Burkina et filtre par ville', () async {
    final ouaga = await repo.listings(const ListingFilter(city: 'Ouagadougou'));
    expect(ouaga.map((l) => l.id), containsAll(['l1', 'l2']));
    expect(ouaga.every((l) => l.city == 'Ouagadougou'), isTrue);
    expect(
      (await repo.listings(const ListingFilter(city: 'Banfora'))).single.id,
      'l6',
    );
    expect(
      kCities.map((c) => c.name),
      containsAll(['Ouagadougou', 'Bobo-Dioulasso', 'Banfora']),
    );
  });

  test("l'admin gère les flyers, les visiteurs ne peuvent pas", () async {
    await repo.signIn(email: 'etudiant@demo.com', password: 'demo1234');
    expect(
      () => repo.savePromo(PromoDraft(title: 'x')),
      throwsA(isA<Exception>()),
    );
    expect(() => repo.deletePromo('p1'), throwsA(isA<Exception>()));
    await repo.signOut();
    await repo.signIn(email: 'admin@demo.com', password: 'demo1234');
    await repo.savePromo(
      PromoDraft(title: 'Flyer test', linkUrl: 'https://exemple.com', sort: 9),
    );
    await repo.savePromo(
      PromoDraft(id: 'p1', title: 'Titre modifié', active: false),
    );
    final visible = await repo.promos();
    expect(
      visible.any(
        (p) => p.title == 'Flyer test' && p.linkUrl == 'https://exemple.com',
      ),
      isTrue,
    );
    expect(
      visible.any((p) => p.id == 'p1'),
      isFalse,
    ); // désactivé : n'apparaît plus sur le site
    expect(
      (await repo.allPromos()).firstWhere((p) => p.id == 'p1').title,
      'Titre modifié',
    );
    await repo.deletePromo('p2');
    expect((await repo.allPromos()).any((p) => p.id == 'p2'), isFalse);
  });

  test('statistiques réservées à l\'admin, et les actions des visiteurs sont comptées', () async {
    expect(() => repo.adminStats(7), throwsA(isA<Exception>()));
    await repo.track(
      AnalyticsEvent(
        visitorId: 'v-new',
        sessionId: 's-new',
        type: 'view',
        screen: 'accueil',
      ),
    );
    await repo.track(
      AnalyticsEvent(
        visitorId: 'v-new',
        sessionId: 's-new',
        type: 'listing_view',
        listingId: 'l1',
      ),
    );
    await repo.track(
      AnalyticsEvent(
        visitorId: 'v-new',
        sessionId: 's-new',
        type: 'contact_click',
        listingId: 'l1',
      ),
    );
    await repo.signIn(email: 'admin@demo.com', password: 'demo1234');
    final st = await repo.adminStats(14);
    expect(st.daily.length, 14);
    expect(st.visitorsToday, greaterThan(0));
    expect(st.visitors30, greaterThanOrEqualTo(st.visitors7));
    expect(st.funnelVisitors, greaterThanOrEqualTo(st.funnelListing));
    expect(st.funnelListing, greaterThanOrEqualTo(st.funnelContact));
    expect(st.topListings, isNotEmpty);
    expect(st.devices, isNotEmpty);
  });

  test(
    'design : réglage réservé à l\'admin, 5 designs vraiment différents',
    () async {
      await repo.signIn(email: 'etudiant@demo.com', password: 'demo1234');
      expect(
        () => repo.saveTheme(const ThemeSettings(design: DesignId.pop)),
        throwsA(isA<Exception>()),
      );
      await repo.signOut();
      await repo.signIn(email: 'admin@demo.com', password: 'demo1234');
      await repo.saveTheme(
        const ThemeSettings(design: DesignId.nuit, primary: 0xFF16A34A),
      );
      final t = await repo.themeSettings();
      expect(t.design, DesignId.nuit);
      expect(t.primary, 0xFF16A34A);
      expect(ThemeSettings.fromJson(t.toJson()).design, DesignId.nuit);

      final specs = [
        for (final id in DesignId.values)
          buildDesign(ThemeSettings(design: id)),
      ];
      expect(specs.map((d) => d.bg).toSet().length, 5);
      expect(specs.map((d) => d.headerStyle).toSet().length, 5);
      expect(specs.map((d) => d.cardStyle).toSet(), {
        CardStyle.overlay,
        CardStyle.row,
        CardStyle.poster,
      });
      expect(specs.where((d) => d.dark).length, 1);
      // la couleur principale choisie par l'admin remplace celle du design
      expect(
        buildDesign(
          const ThemeSettings(design: DesignId.ocean, primary: 0xFFDC2626),
        ).primary.toARGB32(),
        0xFFDC2626,
      );
    },
  );

  testWidgets("l'app démarre et affiche les annonces", (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final state = AppState(repo);
    await tester.pumpWidget(ColocApp(state: state));
    await state.start();
    await tester.pump(const Duration(seconds: 2));
    expect(
      find.text('MODE DÉMO · données fictives, aucun paiement réel'),
      findsOneWidget,
    );
    expect(find.textContaining('2 chambres libres'), findsOneWidget);
    expect(find.text('Ta coloc, sans prise de tête'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose(); // arrête le timer de vérification de mise à jour
  });
}
