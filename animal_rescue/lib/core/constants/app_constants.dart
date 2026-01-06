class AppConstants {
  AppConstants._();

  // API Configuration
  static const String apiVersion = '';
  static const Duration apiTimeout = Duration(seconds: 15);

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userRoleKey = 'user_role';
  static const String userProfileKey = 'user_profile';

  // App Info
  static const String appName = 'Pet Buddy';
  static const String appVersion = '1.0.0';

  // Case Severities
  static const List<String> caseSeverities = [
    'Critical',
    'Urgent',
    'Moderate',
    'Low',
  ];

  // Case Statuses
  static const List<String> caseStatuses = [
    'Reported',
    'In Progress',
    'Resolved',
    'Closed',
  ];

  // User Roles
  static const String citizenRole = 'Citizen';
  static const String ngoRole = 'NGO';

  // Routes
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String roleSelectionRoute = '/role-selection';
  static const String dashboardRoute = '/dashboard';
  static const String reportCaseRoute = '/report-case';
  static const String casesRoute = '/cases';
  static const String caseDetailRoute = '/case-detail';
  static const String adoptionRoute = '/adoption';
  static const String createAdoptionRoute = '/create-adoption';
}
