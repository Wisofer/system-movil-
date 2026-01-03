import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../main_theme.dart';
import '../../models/cliente.dart';
import '../../models/pago.dart';
import '../../services/api/clientes_service.dart';
import '../../services/api/pagos_service.dart';
import '../../services/audio/audio_service.dart';
import '../../utils/money_formatter.dart';

class RegistrarPagoScreen extends ConsumerStatefulWidget {
  final bool embedded;
  final VoidCallback? onPagoRegistrado;

  const RegistrarPagoScreen({
    super.key,
    this.embedded = false,
    this.onPagoRegistrado,
  });

  @override
  ConsumerState<RegistrarPagoScreen> createState() => _RegistrarPagoScreenState();
}

class _RegistrarPagoScreenState extends ConsumerState<RegistrarPagoScreen> {
  // Estados
  Cliente? _clienteSeleccionado;
  ClienteConFacturas? _clienteConFacturas;
  final Set<int> _facturasSeleccionadas = {};
  bool _isLoadingClientes = false;
  bool _isLoadingFacturas = false;
  bool _isProcessingPago = false;
  List<Cliente> _resultadosBusqueda = [];

  // Controladores
  final _searchController = TextEditingController();
  final _montoRecibidoController = TextEditingController();
  final _recibidoCordobasController = TextEditingController();
  final _recibidoDolaresController = TextEditingController();
  final _observacionesController = TextEditingController();

  // Pago
  String _tipoPago = 'Fisico';
  String _moneda = PagosConfig.cordobas; // 'C$'
  String? _banco;
  String? _tipoCuenta;
  TipoCambio? _tipoCambio;

  @override
  void initState() {
    super.initState();
    _loadTipoCambio();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _montoRecibidoController.dispose();
    _recibidoCordobasController.dispose();
    _recibidoDolaresController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadTipoCambio() async {
    final pagosService = ref.read(pagosServiceProvider);
    final tc = await pagosService.getTipoCambio();
    if (mounted) setState(() => _tipoCambio = tc);
  }

  Future<void> _buscarClientes(String query) async {
    if (query.length < 2) {
      setState(() => _resultadosBusqueda = []);
      return;
    }

    setState(() => _isLoadingClientes = true);

    final clientesService = ref.read(clientesServiceProvider);
    final resultados = await clientesService.buscarClientes(query);

    if (mounted) {
      setState(() {
        _resultadosBusqueda = resultados;
        _isLoadingClientes = false;
      });
    }
  }

  Future<void> _seleccionarCliente(Cliente cliente) async {
    setState(() {
      _clienteSeleccionado = cliente;
      _resultadosBusqueda = [];
      _searchController.clear();
      _isLoadingFacturas = true;
      _facturasSeleccionadas.clear();
      _clienteConFacturas = null;
    });

    // Usar el nuevo endpoint de pagos para obtener facturas con saldo
    final pagosService = ref.read(pagosServiceProvider);
    final clienteConFacturas = await pagosService.getFacturasCliente(cliente.id);

    if (mounted) {
      setState(() {
        _clienteConFacturas = clienteConFacturas;
        _isLoadingFacturas = false;
      });
    }
  }

  List<FacturaParaPago> get _facturasPendientes {
    return _clienteConFacturas?.facturas
        .where((f) => f.puedePagar && f.saldoPendiente > 0)
        .toList() ?? [];
  }

  double get _totalSeleccionado {
    final total = _facturasPendientes
        .where((f) => _facturasSeleccionadas.contains(f.id))
        .fold(0.0, (sum, f) => sum + f.saldoPendiente);
    return MoneyFormatter.roundToDouble(total);
  }

  // TC Compra: cuando cliente paga en dólares físicos (el negocio RECIBE dólares)
  double get _tcCompra => _tipoCambio?.compra ?? 36.32;
  // TC Venta: para mostrar equivalentes y cálculos generales
  double get _tcVenta => _tipoCambio?.venta ?? 36.80;

  double get _vuelto {
    if (_tipoPago != 'Fisico' && _tipoPago != 'Mixto') return 0;
    
    if (_moneda == PagosConfig.ambos) {
      // Calcular total recibido en córdobas usando TC VENTA para dólares en pago mixto
      final recibidoCordobas = double.tryParse(_recibidoCordobasController.text) ?? 0;
      final recibidoDolares = double.tryParse(_recibidoDolaresController.text) ?? 0;
      final totalRecibidoEnCordobas = recibidoCordobas + (recibidoDolares * _tcVenta);
      final vuelto = totalRecibidoEnCordobas > _totalSeleccionado 
          ? totalRecibidoEnCordobas - _totalSeleccionado 
          : 0.0;
      return MoneyFormatter.roundToDouble(vuelto.toDouble());
    } else if (_moneda == PagosConfig.dolares) {
      // Si paga solo en dólares físicos, convertir con TC COMPRA (cliente paga en dólares, negocio recibe dólares)
      final recibido = double.tryParse(_montoRecibidoController.text) ?? 0;
      final recibidoEnCordobas = recibido * _tcCompra;
      final vuelto = recibidoEnCordobas > _totalSeleccionado 
          ? recibidoEnCordobas - _totalSeleccionado 
          : 0.0;
      return MoneyFormatter.roundToDouble(vuelto.toDouble());
    } else {
      final recibido = double.tryParse(_montoRecibidoController.text) ?? 0;
      final vuelto = recibido > _totalSeleccionado ? recibido - _totalSeleccionado : 0.0;
      return MoneyFormatter.roundToDouble(vuelto);
    }
  }

  double get _totalRecibidoAmbos {
    final recibidoCordobas = double.tryParse(_recibidoCordobasController.text) ?? 0;
    final recibidoDolares = double.tryParse(_recibidoDolaresController.text) ?? 0;
    // Usar TC VENTA para convertir dólares a córdobas en pago mixto
    final total = recibidoCordobas + (recibidoDolares * _tcVenta);
    return MoneyFormatter.roundToDouble(total);
  }

  Future<void> _procesarPago() async {
    if (_facturasSeleccionadas.isEmpty) {
      _showError('Selecciona al menos una factura');
      return;
    }

    // Validar monto recibido según el tipo de moneda
    if (_tipoPago == 'Fisico' || _tipoPago == 'Mixto') {
      if (_moneda == PagosConfig.ambos) {
        if (_totalRecibidoAmbos < _totalSeleccionado) {
          _showError('El monto total recibido es menor al total a pagar');
          return;
        }
      } else {
        final recibido = double.tryParse(_montoRecibidoController.text) ?? 0;
        if (recibido < _totalSeleccionado) {
          _showError('El monto recibido es menor al total');
          return;
        }
      }
    }

    if (_tipoPago == 'Electronico' && _banco == null) {
      _showError('Selecciona un banco');
      return;
    }

    setState(() => _isProcessingPago = true);

    try {
      final pagosService = ref.read(pagosServiceProvider);
      Map<String, dynamic>? result;

      // Preparar montos según el tipo de moneda
      // Córdobas: se redondean a enteros
      // Dólares: mantienen decimales (NO se redondean)
      final montoRecibido = _moneda == PagosConfig.ambos 
          ? _totalRecibidoAmbos 
          : (_moneda == PagosConfig.dolares
              ? double.tryParse(_montoRecibidoController.text)  // Dólares NO se redondean
              : (double.tryParse(_montoRecibidoController.text) != null 
                  ? MoneyFormatter.roundToDouble(double.tryParse(_montoRecibidoController.text)!)
                  : null));  // Córdobas SÍ se redondean
      
      final recibidoCordobas = _moneda == PagosConfig.ambos
          ? (double.tryParse(_recibidoCordobasController.text) != null
              ? MoneyFormatter.roundToDouble(double.tryParse(_recibidoCordobasController.text)!)
              : null)
          : null;
      // Los dólares NO se redondean, mantienen sus decimales
      final recibidoDolares = _moneda == PagosConfig.ambos
          ? double.tryParse(_recibidoDolaresController.text)
          : null;

      // Determinar montos físicos según moneda
      // Córdobas: redondeados | Dólares: mantienen decimales
      double? montoCordobasFisico;
      double? montoDolaresFisico;
      
      if (_tipoPago == 'Fisico' || _tipoPago == 'Mixto') {
        if (_moneda == PagosConfig.ambos) {
          montoCordobasFisico = recibidoCordobas;  // Ya redondeado
          montoDolaresFisico = recibidoDolares;  // Sin redondear
        } else if (_moneda == PagosConfig.cordobas) {
          montoCordobasFisico = _totalSeleccionado;  // Ya redondeado
        } else if (_moneda == PagosConfig.dolares) {
          // Cuando paga solo en dólares, el monto recibido NO se redondea
          montoDolaresFisico = double.tryParse(_montoRecibidoController.text);
        }
      }

      if (_facturasSeleccionadas.length == 1) {
        final facturaId = _facturasSeleccionadas.first;
        result = await pagosService.registrarPago(
          facturaId: facturaId,
          monto: _totalSeleccionado,
          moneda: _moneda,
          tipoPago: _tipoPago,
          banco: _banco,
          tipoCuenta: _tipoCuenta,
          montoCordobasFisico: montoCordobasFisico,
          montoDolaresFisico: montoDolaresFisico,
          montoCordobasElectronico: _tipoPago == 'Electronico' && _moneda == PagosConfig.cordobas ? _totalSeleccionado : null,
          montoDolaresElectronico: _tipoPago == 'Electronico' && _moneda == PagosConfig.dolares 
              ? (_totalSeleccionado / _tcVenta)  // Convertir córdobas a dólares (con decimales)
              : null,
          montoRecibido: (_tipoPago == 'Fisico' || _tipoPago == 'Mixto') ? montoRecibido : null,
          vuelto: (_tipoPago == 'Fisico' || _tipoPago == 'Mixto') ? _vuelto : null,
          // Enviar TC COMPRA cuando cliente paga solo en dólares físicos, TC VENTA cuando es mixto o electrónico
          tipoCambio: (_moneda == PagosConfig.dolares || _moneda == PagosConfig.ambos) 
              ? ((_tipoPago == 'Electronico') 
                  ? _tcVenta 
                  : (_moneda == PagosConfig.ambos ? _tcVenta : _tcCompra))
              : null,
          observaciones: _observacionesController.text,
        );
      } else {
        result = await pagosService.registrarPagoMultiple(
          facturaIds: _facturasSeleccionadas.toList(),
          montoTotal: _totalSeleccionado,
          moneda: _moneda,
          tipoPago: _tipoPago,
          banco: _banco,
          tipoCuenta: _tipoCuenta,
          montoCordobasFisico: montoCordobasFisico,
          montoDolaresFisico: montoDolaresFisico,
          montoCordobasElectronico: _tipoPago == 'Electronico' && _moneda == PagosConfig.cordobas ? _totalSeleccionado : null,
          montoDolaresElectronico: _tipoPago == 'Electronico' && _moneda == PagosConfig.dolares 
              ? (_totalSeleccionado / _tcVenta)  // Convertir córdobas a dólares (con decimales)
              : null,
          montoRecibido: (_tipoPago == 'Fisico' || _tipoPago == 'Mixto') ? montoRecibido : null,
          vuelto: (_tipoPago == 'Fisico' || _tipoPago == 'Mixto') ? _vuelto : null,
          // Enviar TC COMPRA cuando cliente paga solo en dólares físicos, TC VENTA cuando es mixto o electrónico
          tipoCambio: (_moneda == PagosConfig.dolares || _moneda == PagosConfig.ambos) 
              ? ((_tipoPago == 'Electronico') 
                  ? _tcVenta 
                  : (_moneda == PagosConfig.ambos ? _tcVenta : _tcCompra))
              : null,
          observaciones: _observacionesController.text,
        );
      }

      if (mounted) {
        if (result != null) {
          // Reproducir sonido de éxito
          ref.read(audioServiceProvider).playSuccess();
          _showSuccess('¡Pago registrado correctamente!');
          if (widget.embedded) {
            // Limpiar el formulario
            setState(() {
              _clienteSeleccionado = null;
              _clienteConFacturas = null;
              _facturasSeleccionadas.clear();
              _montoRecibidoController.clear();
              _recibidoCordobasController.clear();
              _recibidoDolaresController.clear();
              _observacionesController.clear();
              _moneda = PagosConfig.cordobas;
              _tipoPago = 'Fisico';
              _banco = null;
              _tipoCuenta = null;
            });
            widget.onPagoRegistrado?.call();
          } else {
            Navigator.pop(context, true);
          }
        } else {
          // Reproducir sonido de error
          ref.read(audioServiceProvider).playError();
          _showError('Error al registrar el pago');
        }
      }
    } catch (e) {
      // Reproducir sonido de error
      ref.read(audioServiceProvider).playError();
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isProcessingPago = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.warning_2, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

    // Si está embebido, no usar Scaffold propio
    if (widget.embedded) {
      return _buildContent(bgColor, cardColor, textColor, mutedColor, borderColor);
    }

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
            'Registrar Pago',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          centerTitle: true,
        ),
        body: _buildContent(bgColor, cardColor, textColor, mutedColor, borderColor),
      ),
    );
  }

  Widget _buildContent(Color bgColor, Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Paso 1: Buscar cliente
                    if (_clienteSeleccionado == null) ...[
                      _buildSearchSection(textColor, mutedColor, borderColor, cardColor),
                    ] else ...[
                      // Cliente seleccionado
                      _buildClienteCard(textColor, mutedColor, borderColor, cardColor),
                      
                      // Resumen del cliente
                      if (_clienteConFacturas != null) ...[
                        const SizedBox(height: 12),
                        _buildResumenCliente(mutedColor, borderColor, cardColor),
                      ],
                      
                      const SizedBox(height: 24),

                      // Paso 2: Facturas pendientes
                      _buildFacturasSection(textColor, mutedColor, borderColor, cardColor),

                      if (_facturasSeleccionadas.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        // Paso 3: Forma de pago
                        _buildPagoSection(textColor, mutedColor, borderColor, cardColor),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // Botón de pagar
            if (_facturasSeleccionadas.isNotEmpty)
              _buildBottomBar(cardColor, borderColor, textColor),
          ],
    );
  }

  Widget _buildSearchSection(Color textColor, Color mutedColor, Color borderColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buscar Cliente',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa nombre, código o cédula del cliente',
          style: GoogleFonts.inter(fontSize: 13, color: mutedColor),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _buscarClientes,
            style: GoogleFonts.inter(color: textColor),
            decoration: InputDecoration(
              hintText: 'Buscar cliente...',
              hintStyle: GoogleFonts.inter(color: mutedColor),
              prefixIcon: Icon(Iconsax.search_normal, color: mutedColor, size: 20),
              suffixIcon: _isLoadingClientes
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (_resultadosBusqueda.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _resultadosBusqueda.length,
              separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
              itemBuilder: (context, index) {
                final cliente = _resultadosBusqueda[index];
                return ListTile(
                  onTap: () => _seleccionarCliente(cliente),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2563EB).withAlpha(20),
                    child: Text(
                      cliente.iniciales,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(
                    cliente.nombre,
                    style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${cliente.codigo}${cliente.telefono != null ? ' • ${cliente.telefono}' : ''}',
                    style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
                  ),
                  trailing: Icon(Iconsax.arrow_right_3, color: mutedColor, size: 18),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildClienteCard(Color textColor, Color mutedColor, Color borderColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2563EB).withAlpha(20),
            child: Text(
              _clienteSeleccionado!.iniciales,
              style: GoogleFonts.inter(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _clienteSeleccionado!.nombre,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _clienteSeleccionado!.codigo,
                  style: GoogleFonts.inter(color: mutedColor, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _clienteSeleccionado = null;
                _clienteConFacturas = null;
                _facturasSeleccionadas.clear();
              });
            },
            icon: Icon(Iconsax.close_circle, color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCliente(Color mutedColor, Color borderColor, Color cardColor) {
    final resumen = _clienteConFacturas!.resumen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB).withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2563EB).withAlpha(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResumenItem('Pendientes', '${resumen.facturasPendientes}', const Color(0xFFF59E0B)),
          Container(width: 1, height: 30, color: borderColor),
          _buildResumenItem('Por cobrar', MoneyFormatter.formatCordobas(resumen.saldoTotalPendiente), const Color(0xFF2563EB)),
        ],
      ),
    );
  }

  Widget _buildResumenItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: color.withAlpha(180))),
      ],
    );
  }

  Widget _buildFacturasSection(Color textColor, Color mutedColor, Color borderColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Facturas Pendientes',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (_facturasPendientes.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_facturasSeleccionadas.length == _facturasPendientes.length) {
                      _facturasSeleccionadas.clear();
                    } else {
                      _facturasSeleccionadas.addAll(_facturasPendientes.map((f) => f.id));
                    }
                  });
                },
                child: Text(
                  _facturasSeleccionadas.length == _facturasPendientes.length
                      ? 'Deseleccionar'
                      : 'Seleccionar todo',
                  style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 13),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingFacturas)
          const Center(child: CircularProgressIndicator(strokeWidth: 2))
        else if (_facturasPendientes.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Iconsax.document, color: mutedColor, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Sin facturas pendientes',
                    style: GoogleFonts.inter(color: mutedColor, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Este cliente no tiene facturas por pagar',
                    style: GoogleFonts.inter(color: mutedColor.withAlpha(150), fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ...List.generate(_facturasPendientes.length, (index) {
            final factura = _facturasPendientes[index];
            final isSelected = _facturasSeleccionadas.contains(factura.id);

            return Padding(
              padding: EdgeInsets.only(bottom: index < _facturasPendientes.length - 1 ? 10 : 0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _facturasSeleccionadas.remove(factura.id);
                    } else {
                      _facturasSeleccionadas.add(factura.id);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF22C55E).withAlpha(15) : cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF22C55E) : borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF22C55E) : borderColor,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              factura.servicio?.nombre ?? 'Servicio',
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  factura.mesNombre ?? '',
                                  style: GoogleFonts.inter(color: mutedColor, fontSize: 12),
                                ),
                                if (factura.categoria.isNotEmpty) ...[
                                  Text(' • ', style: GoogleFonts.inter(color: mutedColor, fontSize: 12)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: factura.categoria == 'Internet' 
                                          ? const Color(0xFF2563EB).withAlpha(20)
                                          : const Color(0xFFF59E0B).withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      factura.categoria,
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: factura.categoria == 'Internet' 
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            MoneyFormatter.formatCordobas(factura.saldoPendiente),
                            style: GoogleFonts.inter(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          if (factura.totalPagado > 0)
                            Text(
                              'Abonado: ${MoneyFormatter.formatCordobas(factura.totalPagado)}',
                              style: GoogleFonts.inter(color: const Color(0xFF22C55E), fontSize: 11),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildVueltoWidget() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Iconsax.money_recive, color: const Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text('Vuelto:', style: GoogleFonts.inter(color: const Color(0xFFF59E0B), fontWeight: FontWeight.w500)),
            ],
          ),
          Text(
            MoneyFormatter.formatCordobas(_vuelto),
            style: GoogleFonts.inter(
              color: const Color(0xFFF59E0B),
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagoAmbosMonedas(Color textColor, Color mutedColor, Color borderColor, Color cardColor) {
    final recibidoCordobas = double.tryParse(_recibidoCordobasController.text) ?? 0;
    final recibidoDolares = double.tryParse(_recibidoDolaresController.text) ?? 0;
    // Usar TC VENTA para calcular el total recibido en córdobas en pago mixto
    final totalEnCordobas = recibidoCordobas + (recibidoDolares * _tcVenta);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Iconsax.money_4, color: const Color(0xFF22C55E), size: 20),
              const SizedBox(width: 8),
              Text(
                'Pago Físico',
                style: GoogleFonts.inter(
                  color: const Color(0xFF22C55E),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Monto total y Recibido en Córdobas
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monto (C\$)', style: GoogleFonts.inter(color: mutedColor, fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        MoneyFormatter.format(_totalSeleccionado),
                        style: GoogleFonts.inter(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recibido (C\$)', style: GoogleFonts.inter(color: mutedColor, fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _recibidoCordobasController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.inter(color: mutedColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Monto en dólares y Recibido en dólares
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Monto (\$)', style: GoogleFonts.inter(color: mutedColor, fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: mutedColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        // Usar TC VENTA para mostrar equivalente en dólares (mantiene decimales)
                        MoneyFormatter.formatDolares(_totalSeleccionado / _tcVenta),
                        style: GoogleFonts.inter(
                          color: mutedColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recibido (\$)', style: GoogleFonts.inter(color: mutedColor, fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _recibidoDolaresController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.inter(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.inter(color: mutedColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vuelto
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vuelto (C\$)', style: GoogleFonts.inter(color: mutedColor, fontSize: 11)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _vuelto > 0 
                            ? const Color(0xFFF59E0B).withAlpha(20)
                            : mutedColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        MoneyFormatter.format(_vuelto),
                        style: GoogleFonts.inter(
                          color: _vuelto > 0 ? const Color(0xFFF59E0B) : mutedColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Recibido', style: GoogleFonts.inter(color: mutedColor, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text(
                      MoneyFormatter.formatCordobas(totalEnCordobas),
                      style: GoogleFonts.inter(
                        color: totalEnCordobas >= _totalSeleccionado 
                            ? const Color(0xFF22C55E) 
                            : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagoSection(Color textColor, Color mutedColor, Color borderColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forma de Pago',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),

        // Tipo de pago
        Row(
          children: PagosConfig.tiposPago.map((tipo) {
            final isSelected = _tipoPago == tipo;
            IconData icon;
            switch (tipo) {
              case 'Fisico':
                icon = Iconsax.money_4;
                break;
              case 'Electronico':
                icon = Iconsax.card;
                break;
              default:
                icon = Iconsax.coin;
            }
            
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _tipoPago = tipo;
                  if (tipo == 'Fisico') {
                    _banco = null;
                    _tipoCuenta = null;
                  }
                }),
                child: Container(
                  margin: EdgeInsets.only(right: tipo != PagosConfig.tiposPago.last ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF2563EB) : cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : borderColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(icon, color: isSelected ? Colors.white : mutedColor, size: 20),
                      const SizedBox(height: 4),
                      Text(
                        tipo == 'Fisico' ? 'Efectivo' : (tipo == 'Electronico' ? 'Transf.' : 'Mixto'),
                        style: GoogleFonts.inter(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Moneda
        Text('Moneda', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _moneda = PagosConfig.cordobas;
                  _recibidoCordobasController.clear();
                  _recibidoDolaresController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _moneda == PagosConfig.cordobas ? const Color(0xFF2563EB) : cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _moneda == PagosConfig.cordobas ? const Color(0xFF2563EB) : borderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'C\$',
                      style: GoogleFonts.inter(
                        color: _moneda == PagosConfig.cordobas ? Colors.white : textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _moneda = PagosConfig.dolares;
                  _recibidoCordobasController.clear();
                  _recibidoDolaresController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _moneda == PagosConfig.dolares ? const Color(0xFF2563EB) : cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _moneda == PagosConfig.dolares ? const Color(0xFF2563EB) : borderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '\$',
                      style: GoogleFonts.inter(
                        color: _moneda == PagosConfig.dolares ? Colors.white : textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _moneda = PagosConfig.ambos;
                  _montoRecibidoController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _moneda == PagosConfig.ambos ? const Color(0xFF2563EB) : cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _moneda == PagosConfig.ambos ? const Color(0xFF2563EB) : borderColor,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'C\$ y \$',
                      style: GoogleFonts.inter(
                        color: _moneda == PagosConfig.ambos ? Colors.white : textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Tipo de cambio (si es $ o Ambos)
        if ((_moneda == PagosConfig.dolares || _moneda == PagosConfig.ambos) && _tipoCambio != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withAlpha(10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Iconsax.dollar_circle, color: const Color(0xFF2563EB), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Compra: ',
                            style: GoogleFonts.inter(color: const Color(0xFF2563EB).withAlpha(180), fontSize: 11),
                          ),
                          Text(
                            'C\$ ${MoneyFormatter.formatTipoCambio(_tipoCambio!.compra)}',
                            style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            ' (cliente paga \$)',
                            style: GoogleFonts.inter(color: const Color(0xFF2563EB).withAlpha(150), fontSize: 10),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Venta: ',
                            style: GoogleFonts.inter(color: const Color(0xFF2563EB).withAlpha(180), fontSize: 11),
                          ),
                          Text(
                            'C\$ ${MoneyFormatter.formatTipoCambio(_tipoCambio!.venta)}',
                            style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            ' (equivalente)',
                            style: GoogleFonts.inter(color: const Color(0xFF2563EB).withAlpha(150), fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Banco y Tipo Cuenta (si es electrónico o mixto)
        if (_tipoPago != 'Fisico') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Banco *', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _banco,
                          isExpanded: true,
                          hint: Text('Seleccionar', style: GoogleFonts.inter(color: mutedColor, fontSize: 14)),
                          items: PagosConfig.bancos.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                          onChanged: (v) => setState(() => _banco = v),
                          style: GoogleFonts.inter(color: textColor, fontSize: 14),
                          dropdownColor: cardColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tipo cuenta', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _tipoCuenta,
                          isExpanded: true,
                          hint: Text('Seleccionar', style: GoogleFonts.inter(color: mutedColor, fontSize: 14)),
                          items: PagosConfig.tiposCuenta.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) => setState(() => _tipoCuenta = v),
                          style: GoogleFonts.inter(color: textColor, fontSize: 14),
                          dropdownColor: cardColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],

        // Monto recibido (si es efectivo o mixto)
        if (_tipoPago == 'Fisico' || _tipoPago == 'Mixto') ...[
          const SizedBox(height: 16),
          
          // Si es moneda "Ambos", mostrar formulario especial
          if (_moneda == PagosConfig.ambos) ...[
            _buildPagoAmbosMonedas(textColor, mutedColor, borderColor, cardColor),
          ] else ...[
            Text('Monto Recibido', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _montoRecibidoController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(color: textColor, fontSize: 20, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: GoogleFonts.inter(color: mutedColor),
                  prefixText: _moneda == PagosConfig.cordobas ? 'C\$ ' : '\$ ',
                  prefixStyle: GoogleFonts.inter(color: mutedColor, fontSize: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),
            if (_vuelto > 0) ...[
              const SizedBox(height: 12),
              _buildVueltoWidget(),
            ],
          ],
        ],

        // Observaciones
        const SizedBox(height: 16),
        Text('Observaciones (opcional)', style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: _observacionesController,
            maxLines: 2,
            style: GoogleFonts.inter(color: textColor),
            decoration: InputDecoration(
              hintText: 'Agregar nota...',
              hintStyle: GoogleFonts.inter(color: mutedColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Color cardColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total a pagar',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      '${_facturasSeleccionadas.length} factura(s)',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B).withAlpha(150)),
                    ),
                  ],
                ),
                Text(
                  MoneyFormatter.formatCordobas(_totalSeleccionado),
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessingPago ? null : _procesarPago,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF22C55E).withAlpha(150),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isProcessingPago
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.tick_circle, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Confirmar Pago',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
