import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/social_share_service.dart';
import '../config/constants.dart';

class SocialShareButton extends StatelessWidget {
  final VoidCallback? onShare;
  final IconData icon;
  final String label;
  final Color? color;

  const SocialShareButton({
    super.key,
    this.onShare,
    this.icon = Icons.share,
    this.label = 'Partager',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onShare,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? AppColors.primary,
        side: BorderSide(color: color ?? AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// Bottom sheet avec options de partage social
class SocialShareBottomSheet extends StatelessWidget {
  final String shareText;
  final String? shareUrl;

  const SocialShareBottomSheet({
    super.key,
    required this.shareText,
    this.shareUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Partager sur',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Options de partage
          _ShareOption(
            icon: Icons.share,
            label: 'Autres applications',
            color: AppColors.primary,
            onTap: () async {
              Navigator.pop(context);
              await Share.share(shareText);
            },
          ),
          const SizedBox(height: 12),

          _ShareOption(
            icon: Icons.chat,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () async {
              Navigator.pop(context);
              try {
                await SocialShareService.shareToWhatsApp(text: shareText);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('WhatsApp non installé'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 12),

          if (shareUrl != null)
            _ShareOption(
              icon: Icons.facebook,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await SocialShareService.shareToFacebook(shareUrl!);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Impossible d\'ouvrir Facebook'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
