// ===== lib/models/admin_role_model.dart =====
// Modèle pour les rôles et privilèges des administrateurs

import 'package:cloud_firestore/cloud_firestore.dart';

/// Privilèges disponibles pour les administrateurs
enum AdminPrivilege {
  // Gestion des utilisateurs
  viewUsers,           // Voir la liste des utilisateurs
  manageUsers,         // Gérer (suspendre, activer) les utilisateurs
  deleteUsers,         // Supprimer des utilisateurs

  // Gestion des vendeurs
  viewVendors,         // Voir les vendeurs
  manageVendors,       // Gérer les vendeurs (KYC, vérification)

  // Gestion des livreurs
  viewDelivery,        // Voir les livreurs
  manageDelivery,      // Gérer les livreurs (KYC, vérification)

  // Gestion des produits
  viewProducts,        // Voir les produits
  manageProducts,      // Gérer (modifier, supprimer) les produits

  // Gestion des commandes
  viewOrders,          // Voir les commandes
  manageOrders,        // Gérer les commandes

  // Gestion financière
  viewFinance,         // Voir les statistiques financières (SUPER ADMIN ONLY)
  manageFinance,       // Gérer les revenus et commissions (SUPER ADMIN ONLY)

  // Gestion des abonnements
  viewSubscriptions,   // Voir les abonnements
  manageSubscriptions, // Gérer les abonnements

  // Gestion des administrateurs
  viewAdmins,          // Voir la liste des admins (SUPER ADMIN ONLY)
  manageAdmins,        // Créer, modifier, supprimer des admins (SUPER ADMIN ONLY)

  // Gestion du contenu
  viewReports,         // Voir les signalements
  manageReports,       // Gérer les signalements

  // Paramètres système
  viewSettings,        // Voir les paramètres
  manageSettings,      // Modifier les paramètres système (SUPER ADMIN ONLY)
}

/// Types de rôles administrateurs prédéfinis
enum AdminRoleType {
  superAdmin,          // Accès total à tout
  admin,               // Gestion générale (utilisateurs, produits, commandes)
  moderator,           // Modération (signalements, contenu)
  support,             // Support client (voir uniquement, pas de modifications)
  finance,             // Gestion financière limitée (voir finances, abonnements)
}

class AdminRole {
  final AdminRoleType type;
  final String name;
  final String description;
  final List<AdminPrivilege> privileges;

  const AdminRole({
    required this.type,
    required this.name,
    required this.description,
    required this.privileges,
  });

  /// Rôles prédéfinis
  static const AdminRole superAdmin = AdminRole(
    type: AdminRoleType.superAdmin,
    name: 'Super Administrateur',
    description: 'Accès total à toutes les fonctionnalités',
    privileges: AdminPrivilege.values, // Tous les privilèges
  );

  static const AdminRole admin = AdminRole(
    type: AdminRoleType.admin,
    name: 'Administrateur',
    description: 'Gestion des utilisateurs, produits et commandes',
    privileges: [
      AdminPrivilege.viewUsers,
      AdminPrivilege.manageUsers,
      AdminPrivilege.viewVendors,
      AdminPrivilege.manageVendors,
      AdminPrivilege.viewDelivery,
      AdminPrivilege.manageDelivery,
      AdminPrivilege.viewProducts,
      AdminPrivilege.manageProducts,
      AdminPrivilege.viewOrders,
      AdminPrivilege.manageOrders,
      AdminPrivilege.viewSubscriptions,
      AdminPrivilege.viewReports,
      AdminPrivilege.manageReports,
    ],
  );

  static const AdminRole moderator = AdminRole(
    type: AdminRoleType.moderator,
    name: 'Modérateur',
    description: 'Modération du contenu et gestion des signalements',
    privileges: [
      AdminPrivilege.viewUsers,
      AdminPrivilege.viewVendors,
      AdminPrivilege.viewProducts,
      AdminPrivilege.manageProducts,
      AdminPrivilege.viewReports,
      AdminPrivilege.manageReports,
    ],
  );

  static const AdminRole support = AdminRole(
    type: AdminRoleType.support,
    name: 'Support Client',
    description: 'Consultation uniquement (pas de modifications)',
    privileges: [
      AdminPrivilege.viewUsers,
      AdminPrivilege.viewVendors,
      AdminPrivilege.viewDelivery,
      AdminPrivilege.viewProducts,
      AdminPrivilege.viewOrders,
      AdminPrivilege.viewSubscriptions,
    ],
  );

  static const AdminRole finance = AdminRole(
    type: AdminRoleType.finance,
    name: 'Gestionnaire Financier',
    description: 'Gestion des abonnements et consultation financière',
    privileges: [
      AdminPrivilege.viewUsers,
      AdminPrivilege.viewVendors,
      AdminPrivilege.viewDelivery,
      AdminPrivilege.viewSubscriptions,
      AdminPrivilege.manageSubscriptions,
      AdminPrivilege.viewOrders,
    ],
  );

  /// Obtenir un rôle par son type
  static AdminRole getRole(AdminRoleType type) {
    switch (type) {
      case AdminRoleType.superAdmin:
        return superAdmin;
      case AdminRoleType.admin:
        return admin;
      case AdminRoleType.moderator:
        return moderator;
      case AdminRoleType.support:
        return support;
      case AdminRoleType.finance:
        return finance;
    }
  }

  /// Obtenir tous les rôles disponibles
  static List<AdminRole> getAllRoles() {
    return [superAdmin, admin, moderator, support, finance];
  }

  /// Vérifier si ce rôle a un privilège spécifique
  bool hasPrivilege(AdminPrivilege privilege) {
    return privileges.contains(privilege);
  }

  /// Vérifier si ce rôle a tous les privilèges donnés
  bool hasAllPrivileges(List<AdminPrivilege> requiredPrivileges) {
    return requiredPrivileges.every((p) => privileges.contains(p));
  }

  /// Vérifier si ce rôle a au moins un des privilèges donnés
  bool hasAnyPrivilege(List<AdminPrivilege> requiredPrivileges) {
    return requiredPrivileges.any((p) => privileges.contains(p));
  }
}

/// Extension du modèle utilisateur pour les admins
class AdminUser {
  final String uid;
  final String email;
  final String displayName;
  final AdminRoleType role;
  final bool isSuperAdmin;
  final List<AdminPrivilege> customPrivileges; // Privilèges personnalisés
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy; // UID du super admin qui a créé cet admin

  AdminUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isSuperAdmin,
    this.customPrivileges = const [],
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  /// Obtenir tous les privilèges (rôle + custom)
  List<AdminPrivilege> get allPrivileges {
    final rolePrivileges = AdminRole.getRole(role).privileges;
    return {...rolePrivileges, ...customPrivileges}.toList();
  }

  /// Vérifier si cet admin a un privilège
  bool hasPrivilege(AdminPrivilege privilege) {
    if (isSuperAdmin) return true; // Super admin a tous les privilèges
    return allPrivileges.contains(privilege);
  }

  /// Conversion depuis Firestore
  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: AdminRoleType.values.firstWhere(
        (r) => r.name == data['adminRole'],
        orElse: () => AdminRoleType.admin,
      ),
      isSuperAdmin: data['isSuperAdmin'] ?? false,
      customPrivileges: (data['customPrivileges'] as List<dynamic>?)
              ?.map((p) => AdminPrivilege.values.firstWhere(
                    (priv) => priv.name == p,
                    orElse: () => AdminPrivilege.viewUsers,
                  ))
              .toList() ??
          [],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
    );
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'userType': 'admin',
      'adminRole': role.name,
      'isSuperAdmin': isSuperAdmin,
      'customPrivileges': customPrivileges.map((p) => p.name).toList(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
    };
  }

  /// Copie avec modifications
  AdminUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    AdminRoleType? role,
    bool? isSuperAdmin,
    List<AdminPrivilege>? customPrivileges,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return AdminUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      customPrivileges: customPrivileges ?? this.customPrivileges,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
