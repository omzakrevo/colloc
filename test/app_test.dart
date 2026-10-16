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

  test('contact caché tant que non payé, visible après paiement', () async {
    await repo.signIn(email: 'etudiant2@demo.com', password: 'demo1234');
    expect(await repo.unlockedContacts(), isEmpty);
    final c = await repo.payAndUnlock(
      listingId: 'l1',
      method: 'wave',
      payerPhone: '+221770000000',
    );
    expect(c.phone, contains('77 123'));
    expect((await repo.unlockedContacts()).length, 1);
    // un second paiement ne recrée pas de contact
    await repo.payAndUnlock(
      listingId: 'l1',
      method: 'wave',
      payerPhone: '+221770000000',
    );
    expect((await repo.unlockedContacts()).length, 1);
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

  testWidgets("l'app démarre et affiche les annonces", (tester) async {
    final state = AppState(repo);
    await tester.pumpWidget(ColocApp(state: state));
    await state.start();
    await tester.pumpAndSettle();
    expect(
      find.text('MODE DÉMO · données fictives, aucun paiement réel'),
      findsOneWidget,
    );
    expect(find.textContaining('2 chambres libres'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    state.dispose(); // arrête le timer de vérification de mise à jour
  });
}
