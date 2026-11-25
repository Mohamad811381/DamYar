// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'داشبورد'),
    (Icons.pets_outlined, Icons.pets_rounded, 'دام‌ها'),
      (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'انبار و مالی'),
    (Icons.vaccines_outlined, Icons.vaccines_rounded, 'دارو دادن'),
  ];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return MediaQuery(
      data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.1)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 6),
          child: Container(
            height: 54,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppTheme.cardWhite.withOpacity(0.96),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD1D5DB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final n = _items.length;
                final selW = c.maxWidth * 0.40;
                final otherW = (c.maxWidth - selW) / (n - 1);

                return Row(
                  children: [
                    for (var i = 0; i < n; i++)
                      _NavItem(
                        icon: _items[i].$1,
                        selectedIcon: _items[i].$2,
                        label: _items[i].$3,
                        selected: i == currentIndex,
                        width: i == currentIndex ? selW : otherW,
                        onTap: () => onChanged(i),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = AppTheme.primaryGreen;
    final color = selected ? accent : AppTheme.textMuted;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: selected ? accent.withOpacity(0.35) : Colors.transparent,
            ),
          ),
          child: Center(
            child: ClipRect(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(selected ? selectedIcon : icon, size: 21, color: color),
                  if (selected) ...[
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
