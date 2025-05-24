import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:goal_timer/core/config/env_config.dart';

// ProviderScopeでアプリをラップするために使用するプロバイダーコンテナ
final providerContainer = ProviderContainer();

// カウンター状態のプロバイダー
final counterStateProvider = StateProvider<int>((ref) => 0);

// Supabase初期化プロバイダー
final supabaseInitProvider = FutureProvider<void>((ref) async {
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );
});

// Supabase初期化状態プロバイダー
final supabaseInitializedProvider = StateProvider<bool>((ref) {
  final asyncValue = ref.watch(supabaseInitProvider);
  return asyncValue.when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Supabaseクライアントプロバイダー
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
