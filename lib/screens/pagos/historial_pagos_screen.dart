import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../main_theme.dart';
import '../../models/pago.dart';
import '../../services/api/pagos_service.dart';
import '../../utils/money_formatter.dart';

class HistorialPagosScreen extends ConsumerStatefulWidget {
  const HistorialPagosScreen({super.key});

  @override
  ConsumerState<HistorialPagosScreen> createState() => _HistorialPagosScreenState();
}

class _HistorialPagosScreenState extends ConsumerState<HistorialPagosScreen> {
  List<Pago> _pagos = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _filterTipoPago;
  String? _filterBanco;
  DateTime? _filterFechaInicio;
  DateTime? _filterFechaFin;
  ResumenDia? _resumenDia;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final pagosService = ref.read(pagosServiceProvider);
    
    // Cargar pagos
    final response = await pagosService.getPagos(
      pagina: _currentPage,
      tipoPago: _filterTipoPago,
      banco: _filterBanco,
      fechaInicio: _filterFechaInicio,
      fechaFin: _filterFechaFin,
    );
    
    // Cargar resumen del día
    final resumen = await pagosService.getResumenDia();

    if (mounted) {
      setState(() {
        _pagos = response.pagos;
        _totalPages = response.totalPages;
        _resumenDia = resumen;
        _isLoading = false;
      });
    }
  }

  void _showFiltersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FiltersSheet(
        tipoPago: _filterTipoPago,
        banco: _filterBanco,
        fechaInicio: _filterFechaInicio,
        fechaFin: _filterFechaFin,
        onApply: (tipo, banco, inicio, fin) {
          setState(() {
            _filterTipoPago = tipo;
            _filterBanco = banco;
            _filterFechaInicio = inicio;
            _filterFechaFin = fin;
            _currentPage = 1;
          });
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemMovilTheme.getStatusBarStyle(isDark),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Historial de Pagos',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Stack(
                children: [
                  Icon(Iconsax.filter, color: textColor),
                  if (_filterTipoPago != null || _filterBanco != null || _filterFechaInicio != null)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: _showFiltersSheet,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Resumen del día
              if (_resumenDia != null)
                SliverToBoxAdapter(
                  child: _buildResumenDia(cardColor, textColor, mutedColor, borderColor),
                ),

              // Lista de pagos
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_pagos.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.document, size: 64, color: mutedColor.withAlpha(100)),
                        const SizedBox(height: 16),
                        Text(
                          'Sin pagos registrados',
                          style: GoogleFonts.inter(
                            color: mutedColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_filterTipoPago != null || _filterBanco != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _filterTipoPago = null;
                                _filterBanco = null;
                                _filterFechaInicio = null;
                                _filterFechaFin = null;
                              });
                              _loadData();
                            },
                            child: const Text('Limpiar filtros'),
                          ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPagoCard(
                        _pagos[index],
                        cardColor,
                        textColor,
                        mutedColor,
                        borderColor,
                      ),
                      childCount: _pagos.length,
                    ),
                  ),
                ),

              // Paginación
              if (_totalPages > 1)
                SliverToBoxAdapter(
                  child: _buildPagination(textColor, mutedColor),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenDia(Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen de Hoy',
                style: GoogleFonts.inter(
                  color: Colors.white.withAlpha(200),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _resumenDia?.fechaFormateada ?? DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: GoogleFonts.inter(
                  color: Colors.white.withAlpha(180),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _resumenDia?.montoTotal != null 
                          ? MoneyFormatter.formatCordobas(_resumenDia!.montoTotal)
                          : 'C\$0',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total recaudado',
                      style: GoogleFonts.inter(
                        color: Colors.white.withAlpha(180),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_resumenDia?.totalPagos ?? 0}',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Pagos',
                      style: GoogleFonts.inter(
                        color: Colors.white.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_resumenDia?.porTipoPago != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildTipoPagoResumen('Efectivo', _resumenDia!.porTipoPago!.fisico.cantidad, _resumenDia!.porTipoPago!.fisico.monto),
                const SizedBox(width: 12),
                _buildTipoPagoResumen('Transfer.', _resumenDia!.porTipoPago!.electronico.cantidad, _resumenDia!.porTipoPago!.electronico.monto),
                const SizedBox(width: 12),
                _buildTipoPagoResumen('Mixto', _resumenDia!.porTipoPago!.mixto.cantidad, _resumenDia!.porTipoPago!.mixto.monto),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTipoPagoResumen(String label, int cantidad, double monto) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$cantidad',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withAlpha(150),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagoCard(Pago pago, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    final fechaFormat = DateFormat('dd MMM yyyy HH:mm', 'es');

    Color tipoPagoColor;
    IconData tipoPagoIcon;
    switch (pago.tipoPago) {
      case 'Electronico':
        tipoPagoColor = const Color(0xFF2563EB);
        tipoPagoIcon = Iconsax.card;
        break;
      case 'Mixto':
        tipoPagoColor = const Color(0xFF8B5CF6);
        tipoPagoIcon = Iconsax.coin;
        break;
      default:
        tipoPagoColor = const Color(0xFF22C55E);
        tipoPagoIcon = Iconsax.money_4;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tipoPagoColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tipoPagoIcon, color: tipoPagoColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pago.factura?.cliente?.nombre ?? 'Cliente',
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      pago.factura?.numero ?? 'Factura #${pago.id}',
                      style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MoneyFormatter.formatByMoneda(pago.monto, pago.moneda),
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tipoPagoColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          pago.tipoPago == 'Electronico' ? 'Transfer.' : pago.tipoPago,
                          style: GoogleFonts.inter(
                            color: tipoPagoColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Iconsax.calendar, size: 14, color: mutedColor),
              const SizedBox(width: 6),
              Text(
                pago.fechaPago != null ? fechaFormat.format(pago.fechaPago!) : 'Sin fecha',
                style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
              ),
              if (pago.banco != null) ...[
                const SizedBox(width: 16),
                Icon(Iconsax.bank, size: 14, color: mutedColor),
                const SizedBox(width: 6),
                Text(
                  pago.banco!,
                  style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
                ),
              ],
            ],
          ),
          if (pago.observaciones != null && pago.observaciones!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: mutedColor.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.note, size: 14, color: mutedColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pago.observaciones!,
                      style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination(Color textColor, Color mutedColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _currentPage > 1
                ? () {
                    setState(() => _currentPage--);
                    _loadData();
                  }
                : null,
            icon: Icon(
              Iconsax.arrow_left_2,
              color: _currentPage > 1 ? textColor : mutedColor.withAlpha(100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Página $_currentPage de $_totalPages',
              style: GoogleFonts.inter(color: mutedColor, fontSize: 13),
            ),
          ),
          IconButton(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() => _currentPage++);
                    _loadData();
                  }
                : null,
            icon: Icon(
              Iconsax.arrow_right_3,
              color: _currentPage < _totalPages ? textColor : mutedColor.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }
}

// Sheet de filtros
class _FiltersSheet extends StatefulWidget {
  final String? tipoPago;
  final String? banco;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final Function(String?, String?, DateTime?, DateTime?) onApply;

  const _FiltersSheet({
    this.tipoPago,
    this.banco,
    this.fechaInicio,
    this.fechaFin,
    required this.onApply,
  });

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _tipoPago;
  late String? _banco;
  late DateTime? _fechaInicio;
  late DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _tipoPago = widget.tipoPago;
    _banco = widget.banco;
    _fechaInicio = widget.fechaInicio;
    _fechaFin = widget.fechaFin;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Filtrar Pagos',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Tipo de pago
          Text('Tipo de pago', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [null, ...PagosConfig.tiposPago].map((tipo) {
              final isSelected = _tipoPago == tipo;
              return GestureDetector(
                onTap: () => setState(() => _tipoPago = tipo),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : borderColor,
                    ),
                  ),
                  child: Text(
                    tipo ?? 'Todos',
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Banco
          Text('Banco', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [null, ...PagosConfig.bancos].map((banco) {
              final isSelected = _banco == banco;
              return GestureDetector(
                onTap: () => setState(() => _banco = banco),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : borderColor,
                    ),
                  ),
                  child: Text(
                    banco ?? 'Todos',
                    style: GoogleFonts.inter(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null, null, null);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Limpiar',
                    style: GoogleFonts.inter(color: mutedColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(_tipoPago, _banco, _fechaInicio, _fechaFin);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Aplicar Filtros',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

