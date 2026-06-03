import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/storage.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/root_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BpCompanionApp());
}

class BpCompanionApp extends StatelessWidget {
  const BpCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(Storage())..init(),
      child: MaterialApp(
        title: '轻松血压',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const RootScaffold(),
      ),
    );
  }
}
