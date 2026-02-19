import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  /// İsteğe bağlı: CTA butonlarda "Devam Et" yanında ok ikonu (Apple HIG uyumu)
  final IconData? trailingIcon;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [AppColors.goldSoft, AppColors.gold],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            overlayColor: AppColors.gold.withOpacity(0.25),
          ),
          child: trailingIcon != null
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 8),
                    Icon(trailingIcon, color: Colors.black, size: 20),
                  ],
                )
              : Text(text, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
