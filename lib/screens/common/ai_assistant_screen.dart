// ===== lib/screens/common/ai_assistant_screen.dart =====
// Écran de chat avec l'assistant IA

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/constants.dart';
import '../../models/ai_assistant_models.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/subscription_service.dart';
import '../../providers/auth_provider_firebase.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final List<AIMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoadingSubscription = true;

  String _userType = 'acheteur';
  String? _userId;
  String _subscriptionTier = 'BASIQUE';
  AIAccessLevel _accessLevel = AIAccessLevel.basic;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user != null) {
      _userType = user.userType.value;
      _userId = user.id;

      // Récupérer l'abonnement réel
      await _loadSubscription();
    }

    // Message de bienvenue avec niveau
    final welcomeContent = AIAssistantService.getWelcomeMessage(_userType, user?.displayName);
    final tierInfo = _getTierInfoMessage();

    final welcomeMessage = AIMessage(
      id: 'welcome',
      content: '$welcomeContent\n\n$tierInfo',
      isUser: false,
      timestamp: DateTime.now(),
      type: AIMessageType.quickReplies,
      metadata: {
        'quickReplies': AIAssistantService.getQuickReplies(_userType),
      },
    );

    if (mounted) {
      setState(() {
        _messages.add(welcomeMessage);
        _isLoadingSubscription = false;
      });
    }

    // Charger les alertes pour PRO+ (après le message de bienvenue)
    if (_userId != null && (_accessLevel == AIAccessLevel.pro || _accessLevel == AIAccessLevel.premium)) {
      await _loadAlerts();
    }
  }

  Future<void> _loadAlerts() async {
    try {
      final context = await AIAssistantService.loadUserContext(
        userId: _userId!,
        userType: _userType,
      );

      if (context != null && mounted) {
        final alerts = AIAssistantService.generateAlerts(context);
        if (alerts.isNotEmpty) {
          final alertMessage = AIMessage(
            id: 'alerts_${DateTime.now().millisecondsSinceEpoch}',
            content: AIAssistantService.formatAlertsAsMessage(alerts),
            isUser: false,
            timestamp: DateTime.now(),
            type: AIMessageType.text,
            metadata: {
              'source': 'smart_alerts',
              'alerts': alerts.map((a) => {
                'type': a.type.name,
                'title': a.title,
                'route': a.actionRoute,
              }).toList(),
            },
          );

          setState(() {
            _messages.add(alertMessage);
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur chargement alertes: $e');
    }
  }

  Future<void> _loadSubscription() async {
    if (_userId == null) return;

    try {
      if (_userType == 'vendeur') {
        final sub = await _subscriptionService.getVendeurSubscription(_userId!);
        if (sub != null) {
          _subscriptionTier = sub.tier.name.toUpperCase();
        }
      } else if (_userType == 'livreur') {
        final sub = await _subscriptionService.getLivreurSubscription(_userId!);
        if (sub != null) {
          _subscriptionTier = sub.tier.name.toUpperCase();
        }
      } else {
        // Acheteur = toujours gratuit mais accès basic
        _subscriptionTier = 'GRATUIT';
      }

      _accessLevel = AIAssistantService.getAccessLevel(
        userType: _userType,
        subscriptionTier: _subscriptionTier,
      );
    } catch (e) {
      debugPrint('❌ Erreur chargement abonnement: $e');
      _subscriptionTier = 'BASIQUE';
      _accessLevel = AIAccessLevel.basic;
    }
  }

  String _getTierInfoMessage() {
    // Acheteur = toujours gratuit illimité
    if (_userType == 'acheteur') {
      return '✨ Assistance IA gratuite et illimitée';
    }

    switch (_accessLevel) {
      case AIAccessLevel.premium:
        return '👑 Mode PREMIUM actif • IA illimitée';
      case AIAccessLevel.pro:
        return '💼 Mode PRO actif • 50 questions IA/semaine';
      case AIAccessLevel.basic:
        final tierName = _userType == 'livreur' ? 'STARTER' : 'BASIQUE';
        return '🔒 Mode $tierName • Passez PRO pour l\'IA avancée';
      case AIAccessLevel.none:
        return '';
    }
  }

  Widget _buildTierBadge() {
    if (_isLoadingSubscription) {
      return const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (_accessLevel) {
      case AIAccessLevel.premium:
        badgeColor = Colors.amber;
        badgeText = 'PREMIUM';
        badgeIcon = Icons.workspace_premium;
        break;
      case AIAccessLevel.pro:
        badgeColor = Colors.blue.shade300;
        badgeText = 'PRO';
        badgeIcon = Icons.verified;
        break;
      default:
        if (_userType == 'acheteur') {
          // Acheteur = badge gratuit
          badgeColor = Colors.green;
          badgeText = 'GRATUIT';
          badgeIcon = Icons.card_giftcard;
          break;
        }
        badgeColor = Colors.grey.shade400;
        badgeText = _userType == 'livreur' ? 'STARTER' : 'BASIC';
        badgeIcon = Icons.lock_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(
            badgeText,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    final route = _userType == 'vendeur'
        ? '/vendeur-subscription'
        : '/livreur-subscription';

    final isPro = _accessLevel == AIAccessLevel.pro;
    final targetPlan = isPro ? 'PREMIUM' : 'PRO';
    final price = isPro ? '10 000' : '5 000';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isPro ? Icons.workspace_premium : Icons.rocket_launch,
              color: isPro ? Colors.amber : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text('Passez $targetPlan !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPro
                  ? 'Débloquez l\'IA illimitée :'
                  : 'Débloquez l\'assistant IA avancé :',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            if (isPro) ...[
              _buildUpgradeFeature(Icons.all_inclusive, 'Questions IA illimitées'),
              _buildUpgradeFeature(Icons.support_agent, 'Support VIP prioritaire'),
              _buildUpgradeFeature(Icons.trending_down, _userType == 'vendeur' ? 'Commission réduite (7%)' : 'Commission réduite (15%)'),
            ] else ...[
              _buildUpgradeFeature(Icons.psychology, '50 questions IA/semaine'),
              _buildUpgradeFeature(Icons.insights, 'Analyse de vos données'),
              _buildUpgradeFeature(Icons.notifications_active, 'Alertes intelligentes'),
            ],
            const SizedBox(height: 16),
            Text(
              '$targetPlan : $price FCFA/mois',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isPro ? Colors.amber.shade700 : AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Fermer l'assistant
              context.push(route);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isPro ? Colors.amber : AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Voir les plans'),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.success),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = AIMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Simuler un délai de frappe
    await Future.delayed(const Duration(milliseconds: 500));

    // Obtenir la réponse
    final response = await AIAssistantService.getResponse(
      query: text,
      userType: _userType,
      accessLevel: _accessLevel,
      userId: _userId,
    );

    if (mounted) {
      setState(() {
        _messages.add(response);
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleAction(Map<String, dynamic> metadata) {
    final intent = metadata['intent'] as String?;

    Navigator.of(context).pop(); // Fermer l'assistant

    if (intent == 'product_search') {
      final searchTerm = metadata['searchTerm'] as String?;
      final encodedQuery = Uri.encodeComponent(searchTerm ?? '');
      context.push('/acheteur/search?q=$encodedQuery');
    } else {
      final route = metadata['actionRoute'] as String;
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'SOCIAL Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTierBadge(),
                    ],
                  ),
                  Text(
                    _isTyping ? 'écrit...' : 'En ligne',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_accessLevel != AIAccessLevel.premium && _userType != 'acheteur')
            IconButton(
              icon: const Icon(Icons.upgrade),
              tooltip: _accessLevel == AIAccessLevel.basic ? 'Passer PRO' : 'Passer PREMIUM',
              onPressed: _showUpgradeDialog,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: Container(
              color: AppColors.backgroundSecondary,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          ),

          // Zone de saisie
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AIMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),

                // Quick replies si disponibles
                if (message.type == AIMessageType.quickReplies &&
                    message.metadata?['quickReplies'] != null)
                  _buildQuickReplies(
                    List<String>.from(message.metadata!['quickReplies']),
                  ),

                // Bouton action si disponible
                if (message.metadata?['actionRoute'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAction(message.metadata!),
                      icon: Icon(
                        message.metadata?['intent'] == 'product_search'
                            ? Icons.search
                            : Icons.open_in_new,
                        size: 18,
                      ),
                      label: Text(
                        message.metadata?['actionLabel'] as String? ?? 'Ouvrir',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(List<String> replies) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: replies.map((reply) {
          return InkWell(
            onTap: () => _sendMessage(reply),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary),
              ),
              child: Text(
                reply,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.smart_toy, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Posez votre question...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: const TextStyle(fontSize: 15),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_messageController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('À propos'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SOCIAL Assistant est votre guide personnel.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            _buildHelpItem(Icons.lightbulb_outline, 'Posez des questions sur l\'appli'),
            _buildHelpItem(Icons.touch_app, 'Utilisez les suggestions rapides'),
            _buildHelpItem(Icons.upgrade, 'Passez PRO pour plus de fonctionnalités'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
