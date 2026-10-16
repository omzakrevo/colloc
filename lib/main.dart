import 'package:flutter/material.dart';

import 'config.dart';
import 'data/demo_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'state/app_state.dart';
import 'ui/design.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Repository repo = AppConfig.isDemo
      ? DemoRepository()
      : SupabaseRepository();
  await repo.init();
  final state = AppState(repo);
  await state.loadTheme(); // le design choisi par l'admin s'applique dès la première image
  // aperçu d'un design sans l'enregistrer : https://…/?design=pop (ocean, soleil, minimal, nuit, pop)
  final preview = DesignId.values.where(
    (d) => d.name == Uri.base.queryParameters['design'],
  );
  if (preview.isNotEmpty)
    state.applyTheme(ThemeSettings(design: preview.first));
  runApp(ColocApp(state: state));
  await state.start();
}

class ColocApp extends StatelessWidget {
  const ColocApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: 'Colloc',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(D.s),
        // clé = version du design : toute l'interface se reconstruit quand l'admin change de design
        home: Shell(key: ValueKey(state.themeVersion)),
      ),
    ),
  );
}
