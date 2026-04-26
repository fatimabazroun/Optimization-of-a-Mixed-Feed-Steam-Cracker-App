import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FieldInfoTooltip extends StatelessWidget {
  final String description;
  const FieldInfoTooltip({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.30),
        builder: (_) => _InfoDialog(description: description),
      ),
      child: const Padding(
        padding: EdgeInsets.only(left: 5),
        child: Icon(Icons.info_outline, size: 13, color: AppColors.textLight),
      ),
    );
  }
}

class _InfoDialog extends StatelessWidget {
  final String description;
  const _InfoDialog({required this.description});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.20), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.info_outline, color: AppColors.cyan, size: 17),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Field Info',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkBase),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: const TextStyle(fontSize: 13, color: AppColors.textMedium, height: 1.65),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: AppColors.tealGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Got it',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
