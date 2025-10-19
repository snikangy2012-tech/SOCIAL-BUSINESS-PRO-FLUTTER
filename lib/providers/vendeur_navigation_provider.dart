import 'package:flutter/material.dart';

class VendeurNavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void goToProducts() => setIndex(1);
  void goToOrders() => setIndex(2);
  void goToProfile() => setIndex(3);
  void goToDashboard() => setIndex(0);
}