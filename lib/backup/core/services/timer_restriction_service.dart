import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing timer mode restrictions based on user plan
class TimerRestrictionService {
  static const List<String> _allTimerModes = [
    'normal',
    'countdown',
    'countup',
    'pomodoro',
  ];

  static const List<String> _freeTimerModes = [
    'normal',
    'countdown',
    'countup',
  ];

  String _currentUserPlan = 'guest';

  /// Set user plan for testing purposes
  void setUserPlan(String plan) {
    _currentUserPlan = plan;
  }

  /// Check if user can use a specific timer mode
  bool canUseTimerMode(String mode) {
    switch (_currentUserPlan) {
      case 'premium':
        return _allTimerModes.contains(mode);
      case 'free':
      case 'guest':
        return _freeTimerModes.contains(mode);
      default:
        return false;
    }
  }

  /// Get list of available timer modes for current user
  List<String> getAvailableTimerModes() {
    switch (_currentUserPlan) {
      case 'premium':
        return List.from(_allTimerModes);
      case 'free':
      case 'guest':
        return List.from(_freeTimerModes);
      default:
        return [];
    }
  }

  /// Get list of restricted timer modes for current user
  List<String> getRestrictedTimerModes() {
    final available = getAvailableTimerModes();
    return _allTimerModes.where((mode) => !available.contains(mode)).toList();
  }

  /// Get restriction message for a specific mode
  String getRestrictionMessage(String mode) {
    if (canUseTimerMode(mode)) {
      return '';
    }
    return 'プレミアムプランで利用可能';
  }

  /// Get current plan display name
  String getCurrentPlan() {
    switch (_currentUserPlan) {
      case 'guest':
        return 'Free';
      case 'free':
        return 'Free';
      case 'premium':
        return 'Premium';
      default:
        return 'Unknown';
    }
  }

  /// Initialize user plan based on current authentication state
  Future<void> initializeUserPlan() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user is authenticated
    final isAuthenticated = prefs.getBool('is_authenticated') ?? false;
    if (isAuthenticated) {
      final isPremium = prefs.getBool('is_premium') ?? false;
      _currentUserPlan = isPremium ? 'premium' : 'free';
    } else {
      // Check if user has temp data (guest user)
      final tempUserId = prefs.getString('temp_user_id');
      _currentUserPlan = tempUserId != null ? 'guest' : 'guest';
    }
  }

  /// Update user plan when authentication state changes
  Future<void> updateUserPlan() async {
    await initializeUserPlan();
  }

  /// Check if timer mode is premium-only
  bool isPremiumOnlyMode(String mode) {
    return mode == 'pomodoro';
  }

  /// Get premium upgrade message for restricted features
  String getPremiumUpgradeMessage() {
    return 'プレミアムプランにアップグレードして、ポモドーロタイマーなど全ての機能をご利用ください。';
  }

  /// Check if user should see premium features
  bool shouldShowPremiumFeatures() {
    return _currentUserPlan != 'premium';
  }

  /// Get plan-specific limitations as a map
  Map<String, dynamic> getPlanLimitations() {
    switch (_currentUserPlan) {
      case 'guest':
        return {
          'max_goals': 1,
          'log_retention_days': 7,
          'available_timers': _freeTimerModes,
          'premium_features': false,
        };
      case 'free':
        return {
          'max_goals': 3,
          'log_retention_days': 30,
          'available_timers': _freeTimerModes,
          'premium_features': false,
        };
      case 'premium':
        return {
          'max_goals': -1, // unlimited
          'log_retention_days': -1, // unlimited
          'available_timers': _allTimerModes,
          'premium_features': true,
        };
      default:
        return {
          'max_goals': 0,
          'log_retention_days': 0,
          'available_timers': <String>[],
          'premium_features': false,
        };
    }
  }
}
