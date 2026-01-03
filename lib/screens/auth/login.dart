import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../main_theme.dart';
import '../../services/storage/credentials_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _userFocused = false;
  bool _passFocused = false;
  bool _rememberCredentials = false;

  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();
  final _credentialsStorage = CredentialsStorage();

  @override
  void initState() {
    super.initState();
    _userFocus.addListener(() => setState(() => _userFocused = _userFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _passFocused = _passFocus.hasFocus));
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final credentials = await _credentialsStorage.loadCredentials();
      if (credentials['username'] != null && credentials['password'] != null) {
        setState(() {
          _userController.text = credentials['username']!;
          _passwordController.text = credentials['password']!;
          _rememberCredentials = true;
        });
      }
    } catch (e) {
      // Ignorar errores al cargar
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final success = await authNotifier.login(
        _userController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (!success) {
        final authState = ref.read(authNotifierProvider);
        setState(() {
          _errorMessage = authState.errorMessage ?? 'Credenciales inválidas';
        });
      } else {
        // Si el login fue exitoso, guardar o eliminar credenciales según el checkbox
        if (_rememberCredentials) {
          await _credentialsStorage.saveCredentials(
            _userController.text.trim(),
            _passwordController.text,
          );
        } else {
          await _credentialsStorage.clearCredentials();
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const isDark = false; // Siempre modo claro

    // Colores adaptativos
    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    const accentColor = Color(0xFF2563EB);
    final accentLight = isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemMovilTheme.getStatusBarStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Decoración de fondo sutil
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withAlpha(isDark ? 20 : 30),
                      accentColor.withAlpha(isDark ? 5 : 10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF06B6D4).withAlpha(isDark ? 15 : 25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Contenido principal
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: size.height * 0.06),

                          // Logo y nombre de empresa
                          Row(
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withAlpha(60),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.asset(
                                    'assets/images/logo3.png',
                                    width: 76,
                                    height: 76,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'EMSINET',
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: textColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Sistema de Gestión',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: mutedColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // Título de bienvenida
                          Text(
                            'Bienvenido de nuevo',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            'Ingresa tus credenciales para acceder al sistema de pago',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: mutedColor,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Error message
                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? const Color(0xFF7F1D1D).withAlpha(40)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFFDC2626).withAlpha(60)
                                      : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.warning_2,
                                    color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Campo Usuario
                          Text(
                            'Usuario',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _userFocused ? accentColor : borderColor,
                                width: _userFocused ? 1.5 : 1,
                              ),
                              color: _userFocused ? accentLight.withAlpha(isDark ? 30 : 50) : cardColor,
                              boxShadow: _userFocused ? [
                                BoxShadow(
                                  color: accentColor.withAlpha(20),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: TextFormField(
                              controller: _userController,
                              focusNode: _userFocus,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ingresa tu usuario',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: mutedColor.withAlpha(150),
                                ),
                                prefixIcon: Icon(
                                  Iconsax.user,
                                  color: _userFocused ? accentColor : mutedColor,
                                  size: 20,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'El usuario es requerido' : null,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Campo Contraseña
                          Text(
                            'Contraseña',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _passFocused ? accentColor : borderColor,
                                width: _passFocused ? 1.5 : 1,
                              ),
                              color: _passFocused ? accentLight.withAlpha(isDark ? 30 : 50) : cardColor,
                              boxShadow: _passFocused ? [
                                BoxShadow(
                                  color: accentColor.withAlpha(20),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: TextFormField(
                              controller: _passwordController,
                              focusNode: _passFocus,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ingresa tu contraseña',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: mutedColor.withAlpha(150),
                                ),
                                prefixIcon: Icon(
                                  Iconsax.lock,
                                  color: _passFocused ? accentColor : mutedColor,
                                  size: 20,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Icon(
                                      _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                                      color: mutedColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                suffixIconConstraints: const BoxConstraints(minHeight: 20, minWidth: 20),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                              ),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'La contraseña es requerida' : null,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Checkbox para recordar credenciales
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberCredentials,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberCredentials = value ?? false;
                                    });
                                  },
                                  activeColor: accentColor,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: _rememberCredentials ? accentColor : borderColor,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _rememberCredentials = !_rememberCredentials;
                                    });
                                  },
                                  child: Text(
                                    'Recordar usuario y contraseña',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Botón de login
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: accentColor.withAlpha(150),
                                elevation: 0,
                                shadowColor: accentColor.withAlpha(80),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Iniciar sesión',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Iconsax.arrow_right_1, size: 18),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Separador
                          Row(
                            children: [
                              Expanded(child: Divider(color: borderColor, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Icon(Iconsax.wifi, color: mutedColor.withAlpha(100), size: 16),
                              ),
                              Expanded(child: Divider(color: borderColor, thickness: 1)),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Footer con servicios
                          Center(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildServiceChip(Iconsax.wifi, 'Internet', mutedColor, borderColor),
                                    const SizedBox(width: 8),
                                    _buildServiceChip(Iconsax.video_play, 'Streaming', mutedColor, borderColor),
                                    const SizedBox(width: 8),
                                    _buildServiceChip(Iconsax.receipt_2, 'Facturación', mutedColor, borderColor),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'POWERED BY COWIB',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: mutedColor.withAlpha(150),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip(IconData icon, String label, Color mutedColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: mutedColor, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: mutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
