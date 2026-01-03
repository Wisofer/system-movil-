import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final bgColor = isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Acerca de',
          style: GoogleFonts.inter(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Logo y nombre de la app
            const SizedBox(height: 40),
            _buildAppLogo(isDark),
            const SizedBox(height: 24),
            Text(
              'System Movil',
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Sistema de Pagos',
              style: GoogleFonts.inter(
                color: mutedColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Versión 1.0.0',
                style: GoogleFonts.inter(
                  color: const Color(0xFF22C55E),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Sección desarrollador
            _buildSectionTitle('Desarrollado por', textColor),
            const SizedBox(height: 12),
            _buildDeveloperCard(cardColor, textColor, mutedColor, borderColor),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo(bool isDark) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(40),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Icon(
        Iconsax.mobile,
        color: Colors.white,
        size: 48,
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDeveloperCard(Color cardColor, Color textColor, Color mutedColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'CW',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COWIB',
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Software Development',
                      style: GoogleFonts.inter(
                        color: mutedColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withAlpha(10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Creamos soluciones tecnológicas innovadoras para impulsar el crecimiento de tu negocio. Especializados en desarrollo móvil y sistemas empresariales.',
              style: GoogleFonts.inter(
                color: textColor.withAlpha(200),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

}
