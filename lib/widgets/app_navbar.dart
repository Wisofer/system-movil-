import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';

class AppNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppNavbar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  static const _items = [
    _NavItem(icon: Iconsax.home_2, activeIcon: Iconsax.home_25, label: 'Inicio'),
    _NavItem(icon: Iconsax.money_recive, activeIcon: Iconsax.money_recive, label: 'Cobrar'),
    _NavItem(icon: Iconsax.setting_2, activeIcon: Iconsax.setting_2, label: 'Ajustes'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27272A) : const Color(0xFFE2E8F0);
    final mutedColor = isDark ? const Color(0xFF71717A) : const Color(0xFF64748B);
    const accentColor = Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isActive = index == currentIndex;

            // El botón del medio (Cobrar) es especial
            if (index == 1) {
              return _CobrarButton(
                isActive: isActive,
                onTap: () => onTap?.call(index),
              );
            }

            return _NavItemWidget(
              icon: isActive ? item.activeIcon : item.icon,
              label: item.label,
              isActive: isActive,
              activeColor: accentColor,
              inactiveColor: mutedColor,
              onTap: () => onTap?.call(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onTap;

  const _NavItemWidget({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : inactiveColor;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 24 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CobrarButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback? onTap;

  const _CobrarButton({
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withAlpha(50),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.money_recive, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cobrar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
