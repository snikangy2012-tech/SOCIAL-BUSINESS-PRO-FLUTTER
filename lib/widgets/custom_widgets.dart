// ===== lib/widgets/custom_widgets.dart =====
// Composants réutilisables pour SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import '../config/constants.dart';

// ===== CHAMP DE TEXTE PERSONNALISÉ =====
class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final bool isRequired;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec indicateur requis
        RichText(
          text: TextSpan(
            text: widget.label,
            style: const TextStyle(
              fontSize: AppFontSizes.md,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            children: widget.isRequired
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ]
                : null,
          ),
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        // Champ de texte
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword ? _isObscured : false,
          validator: widget.validator,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.icon != null 
                ? Icon(widget.icon, color: AppColors.primary)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : null,
            
            // Style du champ
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            
            // Couleurs de remplissage
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

// ===== BOUTON PERSONNALISÉ =====
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final bool isOutlined;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: width ?? double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : (icon != null ? Icon(icon) : const SizedBox.shrink()),
          label: Text(text),
          style: OutlinedButton.styleFrom(
            foregroundColor: backgroundColor ?? AppColors.primary,
            side: BorderSide(
              color: backgroundColor ?? AppColors.primary,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : (icon != null ? Icon(icon) : const SizedBox.shrink()),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

// ===== SÉLECTEUR DE TYPE D'UTILISATEUR =====
class UserTypeSelector extends StatelessWidget {
  final UserType selectedType;
  final void Function(UserType) onChanged;

  const UserTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Je suis un :',
          style: TextStyle(
            fontSize: AppFontSizes.md,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: AppSpacing.sm),
        
        Row(
          children: [
            Expanded(
              child: _UserTypeCard(
                type: UserType.vendeur,
                title: 'Vendeur',
                subtitle: 'Je vends mes produits',
                icon: Icons.store,
                color: AppColors.primary,
                isSelected: selectedType == UserType.vendeur,
                onTap: () => onChanged(UserType.vendeur),
              ),
            ),
            
            const SizedBox(width: AppSpacing.sm),
            
            Expanded(
              child: _UserTypeCard(
                type: UserType.acheteur,
                title: 'Acheteur',
                subtitle: 'J\'achète des produits',
                icon: Icons.shopping_bag,
                color: AppColors.secondary,
                isSelected: selectedType == UserType.acheteur,
                onTap: () => onChanged(UserType.acheteur),
              ),
            ),
            
            const SizedBox(width: AppSpacing.sm),
            
            Expanded(
              child: _UserTypeCard(
                type: UserType.livreur,
                title: 'Livreur',
                subtitle: 'Je livre les commandes',
                icon: Icons.delivery_dining,
                color: AppColors.success,
                isSelected: selectedType == UserType.livreur,
                onTap: () => onChanged(UserType.livreur),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Carte de sélection de type d'utilisateur
class _UserTypeCard extends StatelessWidget {
  final UserType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withValues(alpha:0.1)
              : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: AppFontSizes.xs,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ===== LOGO DE L'APP =====
class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({
    super.key,
    this.size = 100,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha:0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.store,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
        
        if (showText) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontSize: AppFontSizes.xxl,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            AppConstants.slogan,
            style: TextStyle(
              fontSize: AppFontSizes.md,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}