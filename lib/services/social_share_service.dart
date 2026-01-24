import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';

class SocialShareService {
  /// Partager un produit sur les réseaux sociaux
  static Future<void> shareProduct(ProductModel product, {String? vendorName}) async {
    try {
      final String shareText = '''
🛍️ ${product.name}

💰 Prix: ${product.price.toStringAsFixed(0)} FCFA
${product.description.isNotEmpty ? '\n📝 ${product.description}\n' : ''}
${vendorName != null ? '🏪 Vendeur: $vendorName\n' : ''}
📱 Téléchargez SOCIAL BUSINESS Pro pour commander!

🔗 https://socialbusinesspro.ci/products/${product.id}
''';

      await Share.share(
        shareText,
        subject: product.name,
      );

      debugPrint('✅ Produit partagé: ${product.id}');
    } catch (e) {
      debugPrint('❌ Erreur partage produit: $e');
      rethrow;
    }
  }

  /// Partager directement sur WhatsApp
  static Future<void> shareToWhatsApp({
    required String text,
    String? phoneNumber,
  }) async {
    try {
      String url;

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        // Message direct à un numéro (WhatsApp Business)
        final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        url = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(text)}';
      } else {
        // Partage général
        url = 'whatsapp://send?text=${Uri.encodeComponent(text)}';
      }

      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ Partagé sur WhatsApp');
      } else {
        throw Exception('WhatsApp non installé');
      }
    } catch (e) {
      debugPrint('❌ Erreur partage WhatsApp: $e');
      rethrow;
    }
  }

  /// Partager sur Facebook (via navigateur)
  static Future<void> shareToFacebook(String url) async {
    try {
      final facebookUrl = Uri.parse(
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(url)}',
      );

      if (await canLaunchUrl(facebookUrl)) {
        await launchUrl(facebookUrl, mode: LaunchMode.externalApplication);
        debugPrint('✅ Partagé sur Facebook');
      } else {
        throw Exception('Impossible d\'ouvrir Facebook');
      }
    } catch (e) {
      debugPrint('❌ Erreur partage Facebook: $e');
      rethrow;
    }
  }

  /// Partager une boutique vendeur
  static Future<void> shareVendorShop({
    required String vendorId,
    required String shopName,
    String? description,
  }) async {
    try {
      final String shareText = '''
🏪 Découvrez ma boutique: $shopName

${description ?? 'Visitez ma boutique sur SOCIAL BUSINESS Pro!'}

📱 Téléchargez l'app pour commander:
🔗 https://socialbusinesspro.ci/vendors/$vendorId

#SocialBusinessPro #CommerceCI #MadeInCotedIvoire
''';

      await Share.share(shareText, subject: shopName);
      debugPrint('✅ Boutique partagée: $vendorId');
    } catch (e) {
      debugPrint('❌ Erreur partage boutique: $e');
      rethrow;
    }
  }

  /// Générer un lien de parrainage vendeur
  static Future<void> shareReferralLink({
    required String vendorId,
    required String vendorName,
  }) async {
    try {
      final String referralLink = 'https://socialbusinesspro.ci/refer/$vendorId';

      final String shareText = '''
🎁 $vendorName vous invite à rejoindre SOCIAL BUSINESS Pro!

✨ Inscrivez-vous avec mon lien de parrainage et profitez d'avantages exclusifs!

🔗 $referralLink

#Parrainage #SocialBusinessPro
''';

      await Share.share(shareText, subject: 'Invitation SOCIAL BUSINESS Pro');
      debugPrint('✅ Lien de parrainage partagé: $vendorId');
    } catch (e) {
      debugPrint('❌ Erreur partage parrainage: $e');
      rethrow;
    }
  }

  /// Contacter un vendeur via WhatsApp Business
  static Future<void> contactVendorWhatsApp({
    required String vendorPhone,
    required String vendorName,
    String? productName,
  }) async {
    try {
      String message = 'Bonjour $vendorName, ';

      if (productName != null) {
        message += 'je suis intéressé(e) par votre produit "$productName" vu sur SOCIAL BUSINESS Pro.';
      } else {
        message += 'j\'ai vu votre boutique sur SOCIAL BUSINESS Pro et je souhaite en savoir plus.';
      }

      await shareToWhatsApp(
        text: message,
        phoneNumber: vendorPhone,
      );
    } catch (e) {
      debugPrint('❌ Erreur contact WhatsApp vendeur: $e');
      rethrow;
    }
  }
}
