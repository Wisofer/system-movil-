import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main_theme.dart';
import 'profile_menu.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? const Color(0xFFFAFAFA) : const Color(0xFF0F172A);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemMovilTheme.getStatusBarStyle(isDark),
      child: Container(
        color: isDark ? const Color(0xFF0A0A0B) : const Color(0xFFF8FAFC),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
        children: [
          // Logo compacto
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo3.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          
          // Título compacto
          Expanded(
            child: Text(
              'EMSINET',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
          
          // Perfil - con funcionalidad
          GestureDetector(
            onTap: () => ProfileMenu.show(context, ref),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: Icon(Iconsax.user, color: mutedColor, size: 18),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
