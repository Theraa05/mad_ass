import 'package:flutter/material.dart';

import 'screens/assign_technician_screen.dart';
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

class AppRoutes {
  static const signIn = '/';

  // Reporter screens
  static const home = '/home';
  static const myReports = '/my-reports';
  static const scan = '/scan';
  static const details = '/details';
  static const impact = '/impact';
  static const submitted = '/submitted';
  static const contributions = '/contributions';

  // Coordinator screens
  static const management = '/manage';
  static const manageReport = '/manage/report';
  static const assignTechnician = '/manage/assign';
  static const repairSchedule = '/manage/schedule-preview';

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
    assignTechnician: (_) => const AssignTechnicianScreen(),
    repairSchedule: (_) => const RepairScheduleScreen(),

    settings: (_) => const SettingsScreen(),
  };
}