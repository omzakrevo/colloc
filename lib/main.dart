import 'package:flutter/material.dart';

import 'config.dart';
import 'data/demo_repository.dart';
import 'data/repository.dart';
import 'data/supabase_repository.dart';
import 'state/app_state.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Repository repo = AppConfig.isDemo
      ? DemoRepository()
      : SupabaseRepository();
  await repo.init();
  final state = AppState(repo);
  runApp(ColocApp(state: state));
  await state.start();
}

class ColocApp extends StatelessWidget {
  const ColocApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: MaterialApp(
      title: 'Colloc',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const Shell(),
    ),
  );
}
