import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../models/email_transaction_candidate.dart';

class EmailImportService {
  final GoogleSignIn _googleSignIn;

  EmailImportService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [
                'email',
                'https://www.googleapis.com/auth/gmail.readonly',
              ],
            );

  Future<List<EmailTransactionCandidate>> fetchCandidates({DateTime? since}) async {
    final account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Inicio de sesión cancelado');
    }

    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) {
      throw Exception('No se pudo obtener el token de acceso');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final query = _buildQuery(since);
    final listUri = Uri.https(
      'gmail.googleapis.com',
      '/gmail/v1/users/me/messages',
      {
        'q': query,
        'maxResults': '20',
      },
    );

    final listRes = await http.get(listUri, headers: headers);
    if (listRes.statusCode != 200) {
      throw Exception('Error al listar correos: ${listRes.statusCode}');
    }

    final listBody = json.decode(listRes.body) as Map<String, dynamic>;
    final messages = (listBody['messages'] as List?) ?? [];
    if (messages.isEmpty) {
      return [];
    }

    final candidates = <EmailTransactionCandidate>[];

    for (final m in messages) {
      final id = m['id'] as String?;
      if (id == null) {
        continue;
      }

      final msgUri = Uri.https(
        'gmail.googleapis.com',
        '/gmail/v1/users/me/messages/$id',
        {
          'format': 'metadata',
          'metadataHeaders': ['Subject', 'From', 'Date'].join(','),
        },
      );

      final msgRes = await http.get(msgUri, headers: headers);
      if (msgRes.statusCode != 200) {
        continue;
      }

      final msgBody = json.decode(msgRes.body) as Map<String, dynamic>;
      final payload = msgBody['payload'] as Map<String, dynamic>?;
      if (payload == null) {
        continue;
      }

      final headersList = (payload['headers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      String subject = '';
      String from = '';
      String dateStr = '';

      for (final h in headersList) {
        final name = (h['name'] as String?) ?? '';
        final value = (h['value'] as String?) ?? '';
        if (name.toLowerCase() == 'subject') {
          subject = value;
        } else if (name.toLowerCase() == 'from') {
          from = value;
        } else if (name.toLowerCase() == 'date') {
          dateStr = value;
        }
      }

      if (subject.isEmpty) {
        subject = msgBody['snippet'] as String? ?? '';
      }

      DateTime date = DateTime.now();
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {}

      final parsed = _parseAmountAndType(subject);
      if (parsed == null) {
        continue;
      }

      final amount = parsed.$1;
      final currency = parsed.$2;

      final bankName = _extractBankName(from);

      candidates.add(
        EmailTransactionCandidate(
          messageId: id,
          date: date,
          amount: amount,
          currency: currency,
          description: subject,
          bankName: bankName,
        ),
      );
    }

    return candidates;
  }

  String _buildQuery(DateTime? since) {
    if (since == null) {
      return 'subject:(compra OR pago OR débito OR credito OR movimiento)';
    }
    final now = DateTime.now();
    final days = now.difference(since).inDays;
    final clampedDays = days <= 0 ? 1 : days;
    return 'newer_than:${clampedDays}d subject:(compra OR pago OR débito OR credito OR movimiento)';
  }

  (double, String)? _parseAmountAndType(String text) {
    final pattern = RegExp(r'([-+]?\d[\d\.\,]*)\s*(PYG|Gs|₲)?', caseSensitive: false);
    final match = pattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    final rawNumber = match.group(1) ?? '';
    final currency = match.group(2) ?? 'PYG';

    final normalized = rawNumber.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) {
      return null;
    }

    double amount = value;
    final lower = text.toLowerCase();
    if (lower.contains('compra') ||
        lower.contains('pago') ||
        lower.contains('débito') ||
        lower.contains('debito') ||
        lower.contains('cargo')) {
      if (amount > 0) {
        amount = -amount;
      }
    }

    return (amount, currency);
  }

  String _extractBankName(String fromHeader) {
    final ltIndex = fromHeader.indexOf('<');
    if (ltIndex > 0) {
      return fromHeader.substring(0, ltIndex).trim();
    }
    return fromHeader.trim();
  }
}

