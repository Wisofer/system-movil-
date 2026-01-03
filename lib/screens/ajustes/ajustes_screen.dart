import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings/settings_notifier.dart';
import '../../services/api/pagos_service.dart';
import '../../utils/money_formatter.dart';
import 'acerca_de_screen.dart';

class AjustesScreen extends ConsumerStatefulWidget {
  const AjustesScreen({super.key});

  @override
  ConsumerState<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends ConsumerState<AjustesScreen> {
  Map<String, dynamic>? _estadisticas;
  Map<String, dynamic>? _ingresos;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pagosService = ref.read(pagosServiceProvider);
    
    final estadisticas = await pagosService.getEstadisticas();
    final ingresos = await pagosService.getTotalIngresos();

    if (mounted) {
      setState(() {
        _estadisticas = estadisticas;
        _ingresos = ingresos;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
        final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
        
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '¿Cerrar sesión?',
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Saldrás de tu cuenta en este dispositivo.',
            style: GoogleFonts.inter(color: textColor.withAlpha(180)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cerrar sesión',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProfile = ref.watch(authNotifierProvider).userProfile;
    final settings = ref.watch(settingsNotifierProvider);

    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemMovilTheme.getStatusBarStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ajustes',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withAlpha(15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: _loadData,
                            icon: Icon(
                              Iconsax.refresh,
                              color: const Color(0xFF2563EB),
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Perfil
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withAlpha(50),
                            child: Text(
                              _getInitials(userProfile?.nombreCompleto ?? userProfile?.userName ?? 'U'),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userProfile?.nombreCompleto ?? userProfile?.userName ?? 'Usuario',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    userProfile?.role ?? 'Usuario',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Estadísticas
                if (!_isLoading && _estadisticas != null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Estadísticas de Pagos',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildEstadisticasSection(cardColor, textColor, mutedColor, borderColor),
                  ),
                ],

                // Ingresos
                if (!_isLoading && _ingresos != null) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                      child: Text(
                        'Ingresos',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildIngresosSection(cardColor, textColor, mutedColor, borderColor),
                  ),
                ],

                // Opciones
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Cuenta',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          _buildThemeToggle(
                            isDark: isDark,
                            themeMode: settings.themeMode,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            onChanged: (ThemeMode mode) {
                              ref.read(settingsNotifierProvider.notifier).setThemeMode(mode);
                            },
                          ),
                          Divider(color: borderColor, height: 1),
                          _buildOptionItem(
                            icon: Iconsax.info_circle,
                            title: 'Acerca de',
                            subtitle: 'Versión 1.0.0',
                            textColor: textColor,
                            mutedColor: mutedColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AcercaDeScreen()),
                            ),
                          ),
                          Divider(color: borderColor, height: 1),
                          _buildOptionItem(
                            icon: Iconsax.logout,
                            title: 'Cerrar sesión',
                            subtitle: 'Salir de tu cuenta',
                            textColor: const Color(0xFFDC2626),
                            mutedColor: const Color(0xFFDC2626).withAlpha(150),
                            onTap: _logout,
                            iconColor: const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Espacio final
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadisticasSection(Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    final general = _estadisticas?['general'] ?? {};
    final porTipoPago = _estadisticas?['porTipoPago'] ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Pagos',
                  '${general['totalPagos'] ?? 0}',
                  Iconsax.receipt,
                  const Color(0xFF2563EB),
                  cardColor,
                  textColor,
                  borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Ingresos',
                  'C\$${_formatNumber(general['totalIngresos'])}',
                  Iconsax.money_4,
                  const Color(0xFF22C55E),
                  cardColor,
                  textColor,
                  borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Por tipo de pago',
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressBar(
                  'Efectivo',
                  porTipoPago['fisico']?['cantidad'] ?? 0,
                  porTipoPago['fisico']?['porcentaje']?.toDouble() ?? 0,
                  const Color(0xFF22C55E),
                  textColor,
                  mutedColor,
                ),
                const SizedBox(height: 10),
                _buildProgressBar(
                  'Transferencia',
                  porTipoPago['electronico']?['cantidad'] ?? 0,
                  porTipoPago['electronico']?['porcentaje']?.toDouble() ?? 0,
                  const Color(0xFF2563EB),
                  textColor,
                  mutedColor,
                ),
                const SizedBox(height: 10),
                _buildProgressBar(
                  'Mixto',
                  porTipoPago['mixto']?['cantidad'] ?? 0,
                  porTipoPago['mixto']?['porcentaje']?.toDouble() ?? 0,
                  const Color(0xFF8B5CF6),
                  textColor,
                  mutedColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngresosSection(Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Hoy',
              'C\$${_formatNumber(_ingresos?['ingresosHoy'])}',
              Iconsax.calendar_1,
              const Color(0xFFF59E0B),
              cardColor,
              textColor,
              borderColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Este mes',
              'C\$${_formatNumber(_ingresos?['ingresosMesActual'])}',
              Iconsax.calendar,
              const Color(0xFF2563EB),
              cardColor,
              textColor,
              borderColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    Color cardColor,
    Color textColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              color: textColor.withAlpha(120),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int count, double percentage, Color color, Color textColor, Color mutedColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: textColor, fontSize: 13),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(1)}%)',
              style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: mutedColor.withAlpha(30),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color mutedColor,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (iconColor ?? textColor).withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? textColor, size: 22),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
      ),
      trailing: Icon(Iconsax.arrow_right_3, color: mutedColor, size: 18),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final value = number is double ? number : (number as num).toDouble();
    final roundedValue = MoneyFormatter.roundToDouble(value);
    if (roundedValue >= 1000000) {
      return '${MoneyFormatter.format(roundedValue / 1000000)}M';
    } else if (roundedValue >= 1000) {
      return '${MoneyFormatter.format(roundedValue / 1000)}K';
    }
    return MoneyFormatter.format(roundedValue);
  }

  Widget _buildThemeToggle({
    required bool isDark,
    required ThemeMode themeMode,
    required Color textColor,
    required Color mutedColor,
    required Function(ThemeMode) onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withAlpha(15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDark ? Iconsax.moon : Iconsax.sun_1,
          color: const Color(0xFF2563EB),
          size: 22,
        ),
      ),
      title: Text(
        'Modo oscuro',
        style: GoogleFonts.inter(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        isDark ? 'Activado' : 'Desactivado',
        style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
      ),
      trailing: Switch(
        value: isDark,
        onChanged: (value) {
          onChanged(value ? ThemeMode.dark : ThemeMode.light);
        },
        activeColor: const Color(0xFF2563EB),
      ),
    );
  }
}

