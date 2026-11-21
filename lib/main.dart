import 'package:flutter/material.dart';

import 'routes.dart';
import 'theme/app_theme.dart';

void main() => runApp(const MyRepairApp());

class MyRepairApp extends StatelessWidget {
  const MyRepairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MYREPAIR',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      initialRoute: AppRoutes.signIn,
      routes: AppRoutes.table,
    );
  }
}
