import 'package:colloc/data/demo_repository.dart';
import 'package:colloc/main.dart';
import 'package:colloc/models.dart';
import 'package:colloc/state/app_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DemoRepository repo;
  setUp(() async {
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
        payerPhone: '+221770000000',
        reference: 'TX123',
      );
      expect(n.status, PaymentStatus.pending);
      expect(await repo.unlockedContacts(), isEmpty); // toujours caché
      // pas de doublon tant que l'avis est en attente
      expect(
        () => repo.submitPayment(
          listingId: 'l1',
          method: 'Wave',
          payerPhone: '+221770000000',
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
      expect(c.phone, contains('77 123'));
      expect((await repo.myPayments()).single.status, PaymentStatus.approved);
    },
  );

  test('avis refusé : pas de contact, nouvel avis possible', () async {
    await repo.signIn(email: 'etudiant2@demo.com', password: 'demo1234');
    final n = await repo.submitPayment(
      listingId: 'l1',
      method: 'Wave',
      payerPhone: '+221770000000',
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
      payerPhone: '+221770000000',
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
      1,
    );
    expect(
      (await repo.listings(const ListingFilter(query: 'thiès'))).single.id,
      'l4',
    );
  });

  test('slider de pubs fourni par le dépôt', () async {
    final promos = await repo.promos();
    expect(promos.length, greaterThanOrEqualTo(3));
    expect(promos.any((p) => p.sponsor), isTrue);
  });

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
