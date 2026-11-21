import 'package:flutter/material.dart';

import 'screens/contributions_screen.dart';
import 'screens/home_screen.dart';
import 'screens/impact_photos_screen.dart';
import 'screens/issue_details_screen.dart';
import 'screens/management_dashboard_screen.dart';
import 'screens/management_report_screen.dart';
import 'screens/my_reports_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/submitted_screen.dart';

/// Route names in one place so screens never use raw strings.
class AppRoutes {
  static const signIn = '/';

  // Reporter (students and anyone reporting an issue)
  static const home = '/home';
  static const myReports = '/my-reports';
  static const scan = '/scan';
  static const details = '/details';
  static const impact = '/impact';
  static const submitted = '/submitted';
  static const contributions = '/contributions';

  // Management
  static const management = '/manage';
  static const manageReport = '/manage/report'; // arguments: report id (String)

  static const settings = '/settings';

  static final Map<String, WidgetBuilder> table = {
    signIn: (_) => const SignInScreen(),
    home: (_) => const HomeScreen(),
    myReports: (_) => const MyReportsScreen(),
    scan: (_) => const ScanScreen(),
    details: (_) => const IssueDetailsScreen(),
    impact: (_) => const ImpactPhotosScreen(),
    submitted: (_) => const SubmittedScreen(),
    contributions: (_) => const ContributionsScreen(),
    management: (_) => const ManagementDashboardScreen(),
    manageReport: (_) => const ManagementReportScreen(),
    settings: (_) => const SettingsScreen(),
  };
}
