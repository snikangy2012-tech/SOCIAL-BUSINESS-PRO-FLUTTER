import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class VendorCardGradient extends StatelessWidget {
  final UserModel vendor;
  final VoidCallback onTap;
  final List<Color>? gradientColors;

  const VendorCardGradient({
    super.key,
    required this.vendor,
    required this.onTap,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    // Gradients variés pour différencier visuellement les vendeurs
    final gradient = gradientColors ??
        _getGradientByIndex(vendor.id.hashCode % 5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Motif décoratif (cercles en arrière-plan)
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar vendeur
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: vendor.profile['photoURL'] != null
                            ? NetworkImage(vendor.profile['photoURL'])
                            : null,
                        child: vendor.profile['photoURL'] == null
                            ? Text(
                                vendor.displayName.isNotEmpty
                                    ? vendor.displayName[0].toUpperCase()
                                    : 'V',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: gradient.first,
                                ),
                              )
                            : null,
                      ),
                      const Spacer(),
                      // Badge vérifié
                      if (vendor.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Vérifié',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nom de la boutique
                  Text(
                    vendor.profile['businessName'] ?? vendor.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Catégorie
                  if (vendor.profile['businessCategory'] != null)
                    Text(
                      vendor.profile['businessCategory'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  const Spacer(),

                  // Statistiques
                  Row(
                    children: [
                      _StatItem(
                        icon: Icons.star,
                        value: vendor.profile['rating']?.toString() ?? '5.0',
                      ),
                      const SizedBox(width: 16),
                      _StatItem(
                        icon: Icons.shopping_bag,
                        value: '${vendor.profile['totalSales'] ?? 0}',
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getGradientByIndex(int index) {
    const gradients = [
      [Color(0xFF4CAF50), Color(0xFF81C784)], // Vert
      [Color(0xFFFFB300), Color(0xFFFFD54F)], // Or
      [Color(0xFF29B6F6), Color(0xFF4FC3F7)], // Bleu
      [Color(0xFFAB47BC), Color(0xFFBA68C8)], // Violet
      [Color(0xFFFF7043), Color(0xFFFF8A65)], // Orange
    ];
    return gradients[index];
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatItem({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
