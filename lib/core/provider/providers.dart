import 'package:flutter_riverpod/flutter_riverpod.dart';

// ProviderScopeでアプリをラップするために使用するプロバイダーコンテナ
final providerContainer = ProviderContainer();

// カウンター状態のプロバイダー
final counterStateProvider = StateProvider<int>((ref) => 0);
