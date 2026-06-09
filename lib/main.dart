import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import 'services/storage.dart';
import 'services/widget_bridge.dart';
import 'services/widget_platform.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/root_scaffold.dart';
import 'widgets/bp_home_widget_preview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (widgetPlatformSupported) {
    HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }
  runApp(const BpCompanionApp());
}

class BpCompanionApp extends StatefulWidget {
  const BpCompanionApp({super.key});

  @override
  State<BpCompanionApp> createState() => _BpCompanionAppState();
}

class _BpCompanionAppState extends State<BpCompanionApp>
    with WidgetsBindingObserver {
  late final AppState _appState;

  static const _showWidgetPreview =
      bool.fromEnvironment('SHOW_WIDGET_PREVIEW', defaultValue: false);

  @override
  void initState() {
    super.initState();
    _appState = AppState(Storage())..init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appState.reloadFromWidgetStorage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      child: MaterialApp(
        title: '轻松血压',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: _showWidgetPreview
            ? const Scaffold(
                backgroundColor: Color(0xFFF6F7F9),
                body: Center(child: BpHomeWidgetPreview()),
              )
            : const RootScaffold(),
      ),
    );
  }
}
