import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/network/supabase_client.dart';
import 'core/routing/app_router.dart';
import 'main_consumer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(
    ProviderScope(
      overrides: [
        appFlavorProvider.overrideWith(() => FlavorNotifier(AppFlavor.seller)),
      ],
      child: const ParidhanApp(flavorTitle: 'Paridhan Seller Studio'),
    ),
  );
}
