import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:system_movil/services/api/api_config.dart';
import 'package:system_movil/services/storage/token_storage.dart';
import 'package:system_movil/providers/network/error_interceptor.dart';
import 'package:system_movil/providers/network/token_refresh_interceptor.dart';

/// Provides a singleton TokenStorage (secure storage for access/refresh tokens)
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// Provides a configured Dio client with base URL, timeouts and an interceptor
/// that injects the Authorization header from TokenStorage when available.
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final access = await tokenStorage.getAccessToken();
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        } else {
          options.headers.remove('Authorization');
        }
      } catch (_) {
        // Ignore read errors; proceed without Authorization
      }
      handler.next(options);
    },
  ));
  
  // Interceptor de refresh de tokens (maneja automáticamente los 401)
  final tokenRefreshInterceptor = TokenRefreshInterceptor(tokenStorage);
  tokenRefreshInterceptor.setOriginalDio(dio);
  dio.interceptors.add(tokenRefreshInterceptor);
  
  // Interceptor de errores (debe ir al final)
  dio.interceptors.add(ErrorInterceptor());

  return dio;
});
