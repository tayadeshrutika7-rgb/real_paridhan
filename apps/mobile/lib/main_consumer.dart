import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/network/supabase_client.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(
    ProviderScope(
      overrides: [
        appFlavorProvider.overrideWith(() => FlavorNotifier(AppFlavor.consumer)),
      ],
      child: const ParidhanApp(flavorTitle: 'Paridhan — Local Fashion'),
    ),
  );
}

class ParidhanApp extends ConsumerWidget {
  final String flavorTitle;

  const ParidhanApp({super.key, required this.flavorTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: flavorTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
