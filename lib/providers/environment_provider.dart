import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppState { dev, test, prod }

class EnvironmentProvider extends ChangeNotifier {
  static const String _envKey = 'app_env_override';
  AppState _currentState = AppState.prod;
  bool _isInitialized = false;

  AppState get currentState => _currentState;
  bool get isInitialized => _isInitialized;

  bool get isDev => _currentState == AppState.dev;
  bool get isTest => _currentState == AppState.test;
  bool get isProd => _currentState == AppState.prod;

  EnvironmentProvider() {
    _loadEnvironment();
  }

  Future<void> _loadEnvironment() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final envString = prefs.getString(_envKey);
      
      if (envString != null) {
        _currentState = AppState.values.firstWhere(
          (mode) => mode.toString() == envString,
          orElse: () => _getDefaultEnvironment(),
        );
      } else {
        _currentState = _getDefaultEnvironment();
      }
    } catch (e) {
      print('Error loading environment mode: $e');
      _currentState = _getDefaultEnvironment();
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  AppState _getDefaultEnvironment() {
    const defaultEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');
    switch (defaultEnv.toLowerCase()) {
      case 'dev':
      case 'development':
        return AppState.dev;
      case 'test':
        return AppState.test;
      case 'prod':
      case 'production':
      default:
        return AppState.prod;
    }
  }

  Future<void> setEnvironment(AppState state) async {
    if (_currentState == state) return;
    
    _currentState = state;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_envKey, state.toString());
    } catch (e) {
      print('Error saving environment mode: $e');
    }
  }
}
