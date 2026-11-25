// ignore_for_file: deprecated_member_use

import 'package:dam_yar/core/services/local_notification_service.dart';
import 'package:dam_yar/features/navigation/main_shell.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/livestock_enums.dart';
import '../../data/storage/local_storage_service.dart';

class OnboardingPage extends StatefulWidget {
  final LocalStorageService storageService;
  final LocalNotificationService notificationService;

  const OnboardingPage({
    super.key,
    required this.storageService,
    required this.notificationService,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  SpeciesType? _selectedSpecies = SpeciesType.sheep;
  bool _saving = false;

  Future<void> _finishOnboarding() async {
    if (_saving) return;
    setState(() => _saving = true);

    await widget.storageService
        .setPreferredSpecies(_selectedSpecies?.name);
    await widget.storageService.setOnboardingCompleted(true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
       builder: (_) => MainShell(
          storageService: widget.storageService,
          notificationService: widget.notificationService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شروع سریع'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'بدون نیاز به اینترنت، سلامت و تکرار واکسن گله را کنترل کن',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'اطلاعات روی گوشی ذخیره می‌شوند و یادآورهای واکسن، درمان و منع مصرف سر ساعت به تو هشدار می‌دهند.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'نوع دام اصلی شما کدام است؟ (قابل تغییر در ادامه)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...SpeciesType.values.map((species) {
                final isSelected = _selectedSpecies == species;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selectedSpecies = species),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen.withValues(alpha: 0.08)
                            : AppTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected
                                ? AppTheme.primaryGreen
                                : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            species.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'آبستنی ~${species.gestationDays} روز',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _finishOnboarding,
                child: Text(_saving ? 'در حال آماده‌سازی...' : 'ورود به برنامه'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}