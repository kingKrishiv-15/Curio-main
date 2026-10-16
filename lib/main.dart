import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/curio_app.dart';
import 'core/config/supabase_config.dart';
import 'core/services/guest_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemStatusBarContrastEnforced: false,
    ),
  );
  await SupabaseConfig.initialize();
  await GuestSession.instance.load();
  runApp(const CurioApp());
}
