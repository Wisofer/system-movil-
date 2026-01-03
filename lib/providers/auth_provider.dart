import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_profile.dart';
import '../services/auth/auth_service.dart';
import '../services/storage/token_storage.dart';
import '../utils/jwt_decoder.dart';
import 'providers.dart';

/// Estado inmutable del módulo de autenticación.
@immutable
class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isInitialized = false,
    this.isLoading = false,
    this.userToken,
    this.userProfile,
    this.errorMessage,
  });

  final bool isAuthenticated;
  final bool isInitialized;
  final bool isLoading;
  final String? userToken;
  final UserProfile? userProfile;
  final String? errorMessage;

  String? get currentUserId => userProfile?.userId;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isInitialized,
    bool? isLoading,
    String? userToken,
    UserProfile? userProfile,
    String? errorMessage,
    bool clearError = false,
    bool clearProfile = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      userToken: userToken ?? this.userToken,
      userProfile: clearProfile ? null : (userProfile ?? this.userProfile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  static AuthState initial() => const AuthState();
}

/// Notifier responsable de toda la lógica de autenticación usando Riverpod.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this.ref) : super(AuthState.initial()) {
    _initialize();
  }

  final Ref ref;

  late final Dio _dio;
  late final TokenStorage _tokenStorage;
  AuthApi? _authApi;
  bool _servicesInitialized = false;

  Future<void> _initialize() async {
    try {
      _dio = ref.read(dioProvider);
      _tokenStorage = TokenStorage();
      _authApi = AuthApi(_dio, _tokenStorage);
      _servicesInitialized = true;
      await _initializeAuth();
    } catch (e) {
      state = state.copyWith(
        isInitialized: true,
        isAuthenticated: false,
        userToken: null,
        clearProfile: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _initializeAuth() async {
    if (!_servicesInitialized) return;

    try {
      final savedToken = await _tokenStorage.getAccessToken();
      if (savedToken != null && savedToken.isNotEmpty) {
        // Verificar si el token está expirado
        if (JwtDecoder.isTokenExpired(savedToken)) {
          // Token expirado, limpiar y pedir login
          await _clearAuthState();
        } else {
          // Token válido, configurar header
          _dio.options.headers['Authorization'] = 'Bearer $savedToken';
          state = state.copyWith(
            userToken: savedToken,
            isAuthenticated: true,
          );
          // Cargar perfil del usuario
          await loadUserProfile();
        }
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          userToken: null,
          clearProfile: true,
        );
      }
    } catch (e) {
      await _clearAuthState();
    } finally {
      state = state.copyWith(isInitialized: true);
    }
  }

  /// Limpia el estado de autenticación
  Future<void> _clearAuthState() async {
    await _tokenStorage.clear();
    _dio.options.headers.remove('Authorization');
    state = state.copyWith(
      isAuthenticated: false,
      userToken: null,
      clearProfile: true,
      errorMessage: null,
    );
  }

  /// Iniciar sesión
  Future<bool> login(String usuario, String contrasena) async {
    if (_authApi == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Login retorna datos del usuario
      final userData = await _authApi!.login(usuario, contrasena);
      
      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo recuperar el token de acceso.',
        );
        return false;
      }

      _dio.options.headers['Authorization'] = 'Bearer $token';

      // Crear perfil desde los datos del login
      final profile = UserProfile(
        userId: userData['id']?.toString() ?? '',
        userName: userData['nombreUsuario'] ?? '',
        role: userData['rol'] ?? '',
        nombre: userData['nombreCompleto'] ?? userData['nombreUsuario'] ?? '',
        apellido: '',
        email: userData['nombreUsuario'],
      );

      state = state.copyWith(
        userToken: token,
        isAuthenticated: true,
        isLoading: false,
        userProfile: profile,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      await _authApi?.revoke();
    } catch (_) {
      // Ignorar errores
    } finally {
      await _clearAuthState();
      state = AuthState.initial().copyWith(isInitialized: true);
    }
  }

  /// Verificar si hay un token válido
  Future<bool> verifyToken() async {
    try {
      final access = await _tokenStorage.getAccessToken();
      if (access == null || access.isEmpty) return false;
      
      // Verificar con el servidor si es posible
      if (_authApi != null) {
        return await _authApi!.verificarToken();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cargar perfil del usuario
  Future<bool> loadUserProfile() async {
    if (_authApi == null || !state.isAuthenticated) {
      return false;
    }

    try {
      final profile = await _authApi!.getProfile();
      state = state.copyWith(userProfile: profile);
      return true;
    } catch (e) {
      final message = e.toString();
      
      if (message.contains('401') || message.contains('Sesión expirada')) {
        await _clearAuthState();
        return false;
      }
      
      // Si no se puede cargar, usar datos del token
      if (state.userToken != null && state.userProfile == null) {
        final fallback = _buildProfileFromToken(state.userToken!);
        if (fallback != null) {
          state = state.copyWith(userProfile: fallback);
          return true;
        }
      }
      
      return false;
    }
  }

  /// Construir un perfil básico desde el token JWT
  UserProfile? _buildProfileFromToken(String token) {
    final userId = JwtDecoder.getUserId(token);
    if (userId == null) return null;

    final userName = JwtDecoder.getUserName(token) ?? 'Usuario';
    final role = JwtDecoder.getUserRole(token) ?? 'Usuario';

    return UserProfile(
      userId: userId,
      userName: userName,
      role: role,
      nombre: userName,
      apellido: '',
      email: userName,
    );
  }
}

/// Provider de Riverpod para exponer el estado y la lógica de autenticación.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
