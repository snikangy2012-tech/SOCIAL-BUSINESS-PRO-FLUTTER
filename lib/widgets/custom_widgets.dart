// ===== lib/widgets/custom_widgets.dart =====
// Composants réutilisables pour SOCIAL BUSINESS Pro

import 'package:flutter/material.dart';
import 'package:social_business_pro/config/constants.dart';

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

// ===== BADGE DE RÉDUCTION =====
/// Widget pour afficher le badge de réduction sur les produits
class DiscountBadge extends StatelessWidget {
  final int discountPercentage;
  final bool isActive;
  final double size;

  const DiscountBadge({
    super.key,
    required this.discountPercentage,
    this.isActive = true,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (discountPercentage <= 0 || !isActive) {
      return const SizedBox.shrink();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '-$discountPercentage%',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.28,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            Text(
              'PROMO',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== BADGE VENDEUR =====
/// Types de badges vendeur disponibles
enum VendorBadgeType {
  verified('Vérifié', Icons.verified, Color(0xFF00BCD4)),
  fast('Rapide', Icons.flash_on, Color(0xFFFF9800)),
  top('Top Vendeur', Icons.star, Color(0xFFFFD700)),
  nearby('Près de vous', Icons.location_on, Color(0xFF4CAF50)),
  popular('Populaire', Icons.local_fire_department, Color(0xFFFF5722)),
  guaranteed('Garantie', Icons.verified_user, Color(0xFF2196F3));

  final String label;
  final IconData icon;
  final Color color;

  const VendorBadgeType(this.label, this.icon, this.color);
}

/// Widget pour afficher un badge vendeur
class VendorBadge extends StatelessWidget {
  final VendorBadgeType type;
  final double fontSize;
  final double iconSize;
  final bool compact;

  const VendorBadge({
    super.key,
    required this.type,
    this.fontSize = 11,
    this.iconSize = 14,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Version compacte : juste l'icône
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: type.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          type.icon,
          size: iconSize,
          color: type.color,
        ),
      );
    }

    // Version complète : icône + texte
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: type.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type.icon,
            size: iconSize,
            color: type.color,
          ),
          const SizedBox(width: 4),
          Text(
            type.label,
            style: TextStyle(
              color: type.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== CARTE VENDEUR NEARBY =====
/// Widget pour afficher un vendeur à proximité
class NearbyVendorCard extends StatelessWidget {
  final String vendorId;
  final String vendorName;
  final String? shopName;
  final String? imageUrl;
  final double rating;
  final int reviewsCount;
  final double? distance; // en km
  final List<VendorBadgeType> badges;
  final VoidCallback onTap;

  const NearbyVendorCard({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.shopName,
    this.imageUrl,
    required this.rating,
    this.reviewsCount = 0,
    this.distance,
    this.badges = const [],
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image vendeur avec badge distance
            Stack(
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.store,
                      size: 40,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                // Badge distance
                if (distance != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            distance! < 1
                                ? '${(distance! * 1000).toInt()}m'
                                : '${distance!.toStringAsFixed(1)}km',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Infos vendeur
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom boutique ou vendeur
                  Text(
                    shopName ?? vendorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' ($reviewsCount)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Badges (max 2)
                  if (badges.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: badges
                          .take(2)
                          .map((badge) => VendorBadge(
                                type: badge,
                                compact: true,
                                iconSize: 12,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== HELPER POUR DÉTERMINER LES BADGES VENDEUR =====
/// Détermine les badges d'un vendeur en fonction de ses stats
List<VendorBadgeType> getVendorBadges({
  required bool isVerified,
  required double rating,
  required int totalSales,
  required int averageDeliveryTime,
  double? distance,
  int? shareCount,
}) {
  final List<VendorBadgeType> badges = [];

  // Badge vérifié
  if (isVerified) {
    badges.add(VendorBadgeType.verified);
  }

  // Badge rapide (livraison < 30 min)
  if (averageDeliveryTime < 30) {
    badges.add(VendorBadgeType.fast);
  }

  // Badge top vendeur (rating >= 4.5 ET ventes >= 100)
  if (rating >= 4.5 && totalSales >= 100) {
    badges.add(VendorBadgeType.top);
  }

  // Badge près de vous (distance < 2 km)
  if (distance != null && distance < 2.0) {
    badges.add(VendorBadgeType.nearby);
  }

  // Badge populaire (beaucoup de partages)
  if (shareCount != null && shareCount > 50) {
    badges.add(VendorBadgeType.popular);
  }

  // Badge garantie (rating >= 4.0 ET ventes >= 50)
  if (rating >= 4.0 && totalSales >= 50) {
    badges.add(VendorBadgeType.guaranteed);
  }

  return badges;
}

// ===== BOUTON DE PARTAGE VIRAL =====
/// Widget pour le bouton de partage viral
class ShareButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int shareCount;
  final bool compact;

  const ShareButton({
    super.key,
    required this.onPressed,
    this.shareCount = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      // Version compacte pour les cartes
      return Material(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.share,
                  size: 16,
                  color: AppColors.primary,
                ),
                if (shareCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    shareCount > 999 ? '${(shareCount / 1000).toStringAsFixed(1)}k' : '$shareCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    // Version complète pour les pages de détail
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: const Icon(Icons.share, size: 20),
      label: Text(
        shareCount > 0 ? 'Partager ($shareCount)' : 'Partager',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}