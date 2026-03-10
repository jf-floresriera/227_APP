import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_client.dart';

const _kTokenKey = 'jwt_token';
const _kUserIdKey = 'user_id';
const _kUserEmailKey = 'user_email';
const _kUserNameKey = 'user_name';

final _storage = const FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// ── AuthState ─────────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({
    this.token,
    this.userId,
    this.email,
    this.fullName,
    this.isLoading = false,
    this.error,
  });

  final String? token;
  final String? userId;
  final String? email;
  final String? fullName;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    String? token,
    String? userId,
    String? email,
    String? fullName,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSession = false,
  }) =>
      AuthState(
        token: clearSession ? null : (token ?? this.token),
        userId: clearSession ? null : (userId ?? this.userId),
        email: clearSession ? null : (email ?? this.email),
        fullName: clearSession ? null : (fullName ?? this.fullName),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ── AuthNotifier ──────────────────────────────────────────────────────────────

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await _storage.read(key: _kTokenKey);
    if (token == null) return const AuthState();

    final userId = await _storage.read(key: _kUserIdKey);
    final email = await _storage.read(key: _kUserEmailKey);
    final fullName = await _storage.read(key: _kUserNameKey);

    // Propagar token al apiClientProvider
    ref.read(authTokenProvider.notifier).state = token;

    return AuthState(token: token, userId: userId, email: email, fullName: fullName);
  }

  Future<void> login(String email, String password) async {
    state = AsyncData(
      (state.valueOrNull ?? const AuthState()).copyWith(isLoading: true, clearError: true),
    );

    try {
      // El ApiClient sin token solo sirve para el login
      final api = ApiClient(baseUrl: _kApiBaseUrl);
      final result = await api.login(email, password);

      // Actualizar el token global para que apiClientProvider lo use
      ref.read(authTokenProvider.notifier).state = result.token;

      await Future.wait([
        _storage.write(key: _kTokenKey, value: result.token),
        _storage.write(key: _kUserIdKey, value: result.userId),
        _storage.write(key: _kUserEmailKey, value: result.email),
        _storage.write(key: _kUserNameKey, value: result.fullName),
      ]);

      state = AsyncData(AuthState(
        token: result.token,
        userId: result.userId,
        email: result.email,
        fullName: result.fullName,
      ));
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const AuthState()).copyWith(
          isLoading: false,
          error: _parseError(e),
        ),
      );
    }
  }

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: _kTokenKey),
      _storage.delete(key: _kUserIdKey),
      _storage.delete(key: _kUserEmailKey),
      _storage.delete(key: _kUserNameKey),
    ]);
    ref.read(authTokenProvider.notifier).state = null;
    state = const AsyncData(AuthState());
  }

  String _parseError(Object e) {
    final msg = e.toString();
    if (msg.contains('401')) return 'Email o contraseña incorrectos';
    if (msg.contains('SocketException') || msg.contains('Connection refused')) {
      return 'Sin conexión al servidor';
    }
    return 'Error al iniciar sesión. Intenta de nuevo.';
  }
}

// Constante compartida con api_client.dart
const _kApiBaseUrl = 'http://10.0.2.2:8000/api/v1';

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Estado de auth desenvuelto (sin AsyncValue). Seguro de usar en toda la UI.
final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authProvider).valueOrNull ?? const AuthState();
});
