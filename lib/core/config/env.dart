class Env {
  // Read from String.fromEnvironment (passed via --dart-define) with fallback
  static const String projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'branchflow-production',
  );

  static const String projectNumber = String.fromEnvironment(
    'FIREBASE_PROJECT_NUMBER',
    defaultValue: '789746893835',
  );

  static const String defaultLibrarianEmail = String.fromEnvironment(
    'DEFAULT_LIBRARIAN_EMAIL',
    defaultValue: 'staff@branchflow.lib',
  );

  static const String defaultMemberEmail = String.fromEnvironment(
    'DEFAULT_MEMBER_EMAIL',
    defaultValue: 'member@branchflow.lib',
  );
}
