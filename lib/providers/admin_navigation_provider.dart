// ===== lib/providers/admin_navigation_provider.dart =====
// Provider pour gérer la navigation entre les écrans admin

import 'package:flutter/foundation.dart';

class AdminNavigationProvider with ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Méthode pour réinitialiser au dashboard
  void resetToHome() {
    if (_currentIndex != 0) {
      _currentIndex = 0;
      notifyListeners();
    }
  }
}
