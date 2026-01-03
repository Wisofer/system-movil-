import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../main_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_navbar.dart';
import '../services/api/pagos_service.dart';
import '../services/api/dashboard_service.dart';
import '../models/pago.dart';
import '../models/dashboard.dart';
import 'pagos/registrar_pago_screen.dart';
import 'pagos/historial_pagos_screen.dart';
import 'ajustes/ajustes_screen.dart';
import '../utils/money_formatter.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  ResumenDia? _resumenDia;
  DashboardData? _dashboard;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final pagosService = ref.read(pagosServiceProvider);
    final dashboardService = ref.read(dashboardServiceProvider);

    final resumen = await pagosService.getResumenDia();
    final dashboard = await dashboardService.getDashboard();

    if (mounted) {
      setState(() {
        _resumenDia = resumen;
        _dashboard = dashboard;
        _isLoading = false;
      });
    }
  }

  void _navigateToRegistrarPago() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrarPagoScreen()),
    );
    
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF8FAFC);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemMovilTheme.getStatusBarStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header fijo
              const AppHeader(),

              // Contenido
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    _DashboardContent(
                      isLoading: _isLoading,
                      resumenDia: _resumenDia,
                      dashboard: _dashboard,
                      onRefresh: _loadData,
                      onRegistrarPago: _navigateToRegistrarPago,
                    ),
                    _CobrarContent(onPagoRegistrado: _loadData),
                    const AjustesScreen(),
                  ],
                ),
              ),

              // Navbar fijo
              AppNavbar(
                currentIndex: _selectedIndex,
                onTap: (index) => setState(() => _selectedIndex = index),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DASHBOARD CONTENT
// ============================================================================
class _DashboardContent extends StatelessWidget {
  final bool isLoading;
  final ResumenDia? resumenDia;
  final DashboardData? dashboard;
  final VoidCallback onRefresh;
  final VoidCallback onRegistrarPago;

  const _DashboardContent({
    required this.isLoading,
    this.resumenDia,
    this.dashboard,
    required this.onRefresh,
    required this.onRegistrarPago,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen del día
            _buildResumenDia(textColor, mutedColor, cardColor, borderColor),
            
            const SizedBox(height: 24),

            // Acciones rápidas
            _buildQuickActions(context, textColor, mutedColor, cardColor, borderColor),
            
            const SizedBox(height: 24),

            // Estadísticas generales
            if (dashboard != null)
              _buildDashboardStats(textColor, mutedColor, cardColor, borderColor),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenDia(Color textColor, Color mutedColor, Color cardColor, Color borderColor) {
    final dateFormat = DateFormat('EEEE, d MMMM', 'es');
    final today = dateFormat.format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hoy',
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                today,
                style: GoogleFonts.inter(
                  color: mutedColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Recaudado',
                  value: resumenDia?.montoTotal != null 
                      ? MoneyFormatter.formatCordobas(resumenDia!.montoTotal)
                      : 'C\$0',
                  icon: Iconsax.money_4,
                  color: const Color(0xFF22C55E),
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
              Container(width: 1, height: 60, color: borderColor),
              Expanded(
                child: _StatItem(
                  label: 'Pagos',
                  value: '${resumenDia?.totalPagos ?? 0}',
                  icon: Iconsax.receipt,
                  color: const Color(0xFF2563EB),
                  textColor: textColor,
                  mutedColor: mutedColor,
                ),
              ),
            ],
          ),
          if (resumenDia?.porTipoPago != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                _TipoPagoChip(
                  label: 'Efectivo',
                  count: resumenDia!.porTipoPago!.fisico.cantidad,
                  color: const Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                _TipoPagoChip(
                  label: 'Transfer.',
                  count: resumenDia!.porTipoPago!.electronico.cantidad,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                _TipoPagoChip(
                  label: 'Mixto',
                  count: resumenDia!.porTipoPago!.mixto.cantidad,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Color textColor, Color mutedColor, Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Iconsax.document_text,
                title: 'Historial',
                subtitle: 'Ver pagos',
                color: const Color(0xFF2563EB),
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                mutedColor: mutedColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistorialPagosScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Iconsax.search_normal,
                title: 'Buscar',
                subtitle: 'Clientes',
                color: const Color(0xFFF59E0B),
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                mutedColor: mutedColor,
                onTap: onRegistrarPago,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardStats(Color textColor, Color mutedColor, Color cardColor, Color borderColor) {
    final clientes = dashboard?.clientes;
    final facturas = dashboard?.facturas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumen General',
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
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
            children: [
              _DashboardRow(
                icon: Iconsax.people,
                label: 'Clientes activos',
                value: '${clientes?.activos ?? 0}',
                color: const Color(0xFF2563EB),
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              Divider(color: borderColor, height: 24),
              _DashboardRow(
                icon: Iconsax.document,
                label: 'Facturas pendientes',
                value: '${facturas?.pendientes ?? 0}',
                color: const Color(0xFFF59E0B),
                textColor: textColor,
                mutedColor: mutedColor,
              ),
              Divider(color: borderColor, height: 24),
              _DashboardRow(
                icon: Iconsax.money_4,
                label: 'Por cobrar',
                value: 'C\$${_formatNumber(facturas?.montoPendiente)}',
                color: const Color(0xFFDC2626),
                textColor: textColor,
                mutedColor: mutedColor,
              ),
            ],
          ),
        ),
      ],
    );
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
}

// ============================================================================
// COBRAR CONTENT - Pantalla de cobros
// ============================================================================
class _CobrarContent extends StatelessWidget {
  final VoidCallback? onPagoRegistrado;

  const _CobrarContent({this.onPagoRegistrado});

  @override
  Widget build(BuildContext context) {
    return RegistrarPagoScreen(
      embedded: true,
      onPagoRegistrado: onPagoRegistrado,
    );
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color textColor;
  final Color mutedColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.inter(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: mutedColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _TipoPagoChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TipoPagoChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color.withAlpha(180),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: mutedColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final Color mutedColor;

  const _DashboardRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(color: mutedColor, fontSize: 13),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
