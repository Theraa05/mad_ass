enum UserRole { reporter, management }

class AppUser {
  final String email;
  final UserRole role;
  const AppUser(this.email, this.role);

  String get displayName {
    final name = email.split('@').first;
    if (name.isEmpty) return 'there';
    return name[0].toUpperCase() + name.substring(1);
  }
}

/// Prototype sign-in: the ROLE is decided by the email address.
/// Add management/maintenance staff emails to [managementEmails].
///
/// TODO (real app): replace with Firebase Auth (or your university SSO) and
/// read the role from your backend (e.g. a `role` field or custom claim),
/// never from a list inside the app. Passwords are not checked here.
class AuthService {
  static const managementEmails = {
    'management@tarc.edu.my',
    'maintenance@tarc.edu.my',
  };

  static AppUser? current;

  static AppUser signIn(String email) {
    final e = email.trim().toLowerCase();
    final role = managementEmails.contains(e)
        ? UserRole.management
        : UserRole.reporter;
    return current = AppUser(e, role);
  }

  static void signOut() => current = null;
}
