import 'package:flutter/foundation.dart';

import '../models/report.dart';

class EmailMessage {
  final String to;
  final String subject;
  final String body;
  const EmailMessage(
      {required this.to, required this.subject, required this.body});
}

/// MOCK email sender: it only waits a moment and prints the email to the
/// debug console, so no real email leaves the app.
///
/// A mobile app must NOT hold SMTP passwords or email API keys. To send real
/// emails, call your backend from [send] (for example a Firebase Cloud
/// Function using SendGrid, or the "Trigger Email" extension) and return
/// true only when the backend confirms it was sent.
class EmailService {
  static Future<bool> send(EmailMessage message) async {
    await Future.delayed(const Duration(milliseconds: 900));
    debugPrint('--- EMAIL (mock) ---\n'
        'To: ${message.to}\n'
        'Subject: ${message.subject}\n\n'
        '${message.body}\n'
        '--------------------');
    return true;
  }

  static EmailMessage resolvedNotice(Report r, {String? note}) {
    final name = r.reporterEmail.split('@').first;
    final extra = (note ?? r.managerNote ?? '').trim();
    return EmailMessage(
      to: r.reporterEmail,
      subject: '[MYREPAIR] ${r.id} has been resolved',
      body: 'Hi $name,\n\n'
          'Good news: your report ${r.id} (${r.category} at ${r.location}) '
          'has been marked as resolved.\n\n'
          '${extra.isEmpty ? '' : 'Note from maintenance: $extra\n\n'}'
          'Thank you for helping keep our campus running.\n\n'
          'MYREPAIR Maintenance Team',
    );
  }
}
