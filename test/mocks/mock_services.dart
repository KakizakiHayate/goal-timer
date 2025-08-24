import 'package:flutter/foundation.dart';

/// Mock implementation of TempUserService for testing
class MockTempUserService {
  final Map<String, dynamic> _mockPrefs = {};
  bool _shouldFailOperations = false;
  int _operationDelay = 0;

  /// Configure mock to simulate failures
  void setShouldFail(bool shouldFail) {
    _shouldFailOperations = shouldFail;
  }

  /// Configure mock to simulate delays
  void setOperationDelay(int milliseconds) {
    _operationDelay = milliseconds;
  }

  /// Reset mock state
  void reset() {
    _mockPrefs.clear();
    _shouldFailOperations = false;
    _operationDelay = 0;
  }

  Future<void> _simulateDelay() async {
    if (_operationDelay > 0) {
      await Future.delayed(Duration(milliseconds: _operationDelay));
    }
  }

  Future<void> _checkFailure() async {
    if (_shouldFailOperations) {
      throw Exception('Mock operation failed');
    }
  }

  Future<String> generateTempUserId() async {
    await _simulateDelay();
    await _checkFailure();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final userId = 'local_user_temp_$timestamp';
    
    _mockPrefs['temp_user_id'] = userId;
    _mockPrefs['temp_user_created_at'] = timestamp;
    
    return userId;
  }

  Future<String?> getTempUserId() async {
    await _simulateDelay();
    return _mockPrefs['temp_user_id'] as String?;
  }

  Future<bool> isTempUserExpired() async {
    await _simulateDelay();
    
    final createdAt = _mockPrefs['temp_user_created_at'] as int?;
    if (createdAt == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final sevenDaysInMs = 7 * 24 * 60 * 60 * 1000;
    
    return (now - createdAt) > sevenDaysInMs;
  }

  Future<void> deleteTempUserData() async {
    await _simulateDelay();
    await _checkFailure();
    
    _mockPrefs.remove('temp_user_id');
    _mockPrefs.remove('temp_user_created_at');
    _mockPrefs.remove('temp_onboarding_step');
  }

  Future<void> updateOnboardingStep(int step) async {
    await _simulateDelay();
    await _checkFailure();
    
    _mockPrefs['temp_onboarding_step'] = step;
  }

  Future<int> getOnboardingStep() async {
    await _simulateDelay();
    return _mockPrefs['temp_onboarding_step'] as int? ?? 0;
  }

  /// Test helper to directly set mock data
  void setMockData(String key, dynamic value) {
    _mockPrefs[key] = value;
  }

  /// Test helper to get mock data
  dynamic getMockData(String key) {
    return _mockPrefs[key];
  }
}

/// Mock implementation of StartupLogicService for testing
class MockStartupLogicService {
  final MockTempUserService _tempUserService;
  bool _isAuthenticated = false;
  bool _shouldFailOperations = false;

  MockStartupLogicService(this._tempUserService);

  /// Configure authentication state
  void setAuthenticationState(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
  }

  /// Configure mock to simulate failures
  void setShouldFail(bool shouldFail) {
    _shouldFailOperations = shouldFail;
  }

  /// Reset mock state
  void reset() {
    _isAuthenticated = false;
    _shouldFailOperations = false;
  }

  Future<void> _checkFailure() async {
    if (_shouldFailOperations) {
      throw Exception('Mock startup logic failed');
    }
  }

  Future<String> determineInitialRoute() async {
    await _checkFailure();

    if (_isAuthenticated) {
      return '/home';
    }

    final tempUserId = await _tempUserService.getTempUserId();
    if (tempUserId == null) {
      return '/onboarding/goal-creation';
    }

    final isExpired = await _tempUserService.isTempUserExpired();
    if (isExpired) {
      await cleanupExpiredTempData();
      return '/onboarding/goal-creation';
    }

    final step = await _tempUserService.getOnboardingStep();
    if (step >= 3) {
      return '/home';
    }

    switch (step) {
      case 0:
        return '/onboarding/goal-creation';
      case 1:
        return '/onboarding/demo-timer';
      case 2:
        return '/onboarding/account-creation';
      default:
        return '/onboarding/goal-creation';
    }
  }

  Future<bool> shouldShowOnboarding() async {
    await _checkFailure();

    if (_isAuthenticated) return false;

    final tempUserId = await _tempUserService.getTempUserId();
    if (tempUserId == null) return true;

    final isExpired = await _tempUserService.isTempUserExpired();
    if (isExpired) return true;

    final step = await _tempUserService.getOnboardingStep();
    return step < 3;
  }

  Future<double> getOnboardingProgress() async {
    await _checkFailure();

    final step = await _tempUserService.getOnboardingStep();
    switch (step) {
      case 0:
        return 0.0;
      case 1:
        return 0.33;
      case 2:
        return 0.66;
      case 3:
        return 1.0;
      default:
        return 0.0;
    }
  }

  Future<void> cleanupExpiredTempData() async {
    await _checkFailure();

    final isExpired = await _tempUserService.isTempUserExpired();
    if (isExpired) {
      await _tempUserService.deleteTempUserData();
    }
  }
}

/// Mock implementation of DataMigrationService for testing
class MockDataMigrationService {
  bool _shouldFailMigration = false;
  int _failureCount = 0;
  int _maxRetries = 3;
  int _retryCount = 0;
  List<String> _migrationLog = [];

  /// Configure migration to fail
  void setShouldFailMigration(bool shouldFail) {
    _shouldFailMigration = shouldFail;
    _retryCount = 0;
  }

  /// Set maximum retry count
  void setMaxRetries(int maxRetries) {
    _maxRetries = maxRetries;
  }

  /// Get migration log for testing
  List<String> getMigrationLog() {
    return List.from(_migrationLog);
  }

  /// Reset mock state
  void reset() {
    _shouldFailMigration = false;
    _failureCount = 0;
    _retryCount = 0;
    _migrationLog.clear();
  }

  Future<bool> migrateTempUserData(String tempUserId, String realUserId) async {
    _migrationLog.add('Migration attempt ${_retryCount + 1} for $tempUserId -> $realUserId');

    if (_shouldFailMigration && _retryCount < _maxRetries) {
      _retryCount++;
      _failureCount++;
      _migrationLog.add('Migration failed (attempt $_retryCount)');
      throw Exception('Migration failed - attempt $_retryCount');
    }

    await Future.delayed(const Duration(milliseconds: 100)); // Simulate processing time
    
    _migrationLog.add('Migration successful');
    return true;
  }

  Future<bool> retryMigration(String tempUserId, String realUserId) async {
    if (_retryCount >= _maxRetries) {
      _migrationLog.add('Max retries exceeded');
      return false;
    }

    try {
      return await migrateTempUserData(tempUserId, realUserId);
    } catch (e) {
      return false;
    }
  }

  /// Check if max retries exceeded
  bool hasExceededMaxRetries() {
    return _retryCount >= _maxRetries;
  }

  /// Get current retry count
  int getRetryCount() {
    return _retryCount;
  }

  /// Get failure count
  int getFailureCount() {
    return _failureCount;
  }
}

/// Mock implementation of TimerRestrictionService for testing
class MockTimerRestrictionService {
  String _userPlan = 'guest'; // guest, free, premium
  
  /// Set user plan for testing
  void setUserPlan(String plan) {
    _userPlan = plan;
  }

  /// Reset mock state
  void reset() {
    _userPlan = 'guest';
  }

  bool canUseTimerMode(String mode) {
    switch (_userPlan) {
      case 'premium':
        return true; // Premium can use all modes
      case 'free':
      case 'guest':
        return ['normal', 'countdown', 'countup'].contains(mode);
      default:
        return false;
    }
  }

  List<String> getAvailableTimerModes() {
    switch (_userPlan) {
      case 'premium':
        return ['normal', 'countdown', 'countup', 'pomodoro'];
      case 'free':
      case 'guest':
        return ['normal', 'countdown', 'countup'];
      default:
        return [];
    }
  }

  List<String> getRestrictedTimerModes() {
    switch (_userPlan) {
      case 'premium':
        return [];
      case 'free':
      case 'guest':
        return ['pomodoro'];
      default:
        return ['normal', 'countdown', 'countup', 'pomodoro'];
    }
  }

  String getRestrictionMessage(String mode) {
    if (canUseTimerMode(mode)) {
      return '';
    }
    return 'プレミアムプランで利用可能';
  }

  String getCurrentPlan() {
    switch (_userPlan) {
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
}

/// Factory for creating mock services
class MockServiceFactory {
  static MockTempUserService createTempUserService() {
    return MockTempUserService();
  }

  static MockStartupLogicService createStartupLogicService(
    MockTempUserService tempUserService,
  ) {
    return MockStartupLogicService(tempUserService);
  }

  static MockDataMigrationService createDataMigrationService() {
    return MockDataMigrationService();
  }

  static MockTimerRestrictionService createTimerRestrictionService() {
    return MockTimerRestrictionService();
  }

  /// Create a complete set of mock services for testing
  static Map<String, dynamic> createMockServiceSet() {
    final tempUserService = createTempUserService();
    final startupLogicService = createStartupLogicService(tempUserService);
    final dataMigrationService = createDataMigrationService();
    final timerRestrictionService = createTimerRestrictionService();

    return {
      'tempUserService': tempUserService,
      'startupLogicService': startupLogicService,
      'dataMigrationService': dataMigrationService,
      'timerRestrictionService': timerRestrictionService,
    };
  }
}