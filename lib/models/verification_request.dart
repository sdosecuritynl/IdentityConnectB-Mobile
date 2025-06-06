import 'dart:convert';

class VerificationRequest {
  final String sessionId;
  final String challengeNonce;
  final String from;
  final String to;
  final String requestTimestamp;
  final String? responseTimestamp;
  final String status;
  final String domain;
  final String expiresAt;

  VerificationRequest({
    required this.sessionId,
    required this.challengeNonce,
    required this.from,
    required this.to,
    required this.requestTimestamp,
    this.responseTimestamp,
    required this.status,
    required this.domain,
    required this.expiresAt,
  });

  factory VerificationRequest.fromJson(Map<String, dynamic> json) {
    // The response is already a Map, no need to parse the body string
    final record = json['record'] as Map<String, dynamic>;

    return VerificationRequest(
      sessionId: record['sessionId']?.toString() ?? '',
      challengeNonce: record['challengeNonce']?.toString() ?? '',
      from: record['from']?.toString() ?? '',
      to: record['to']?.toString() ?? '',
      requestTimestamp: record['requestTimestamp']?.toString() ?? '',
      responseTimestamp: record['responseTimestamp']?.toString(),
      status: record['status']?.toString() ?? '',
      domain: record['domain']?.toString() ?? '',
      expiresAt: record['expiresAt']?.toString() ?? '',
    );
  }

  String getFormattedTimestamp() {
    try {
      final dateTime = DateTime.parse(requestTimestamp);
      return '${dateTime.day.toString().padLeft(2, '0')}-'
          '${dateTime.month.toString().padLeft(2, '0')}-'
          '${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return requestTimestamp;
    }
  }

  String getDomainFromEmail() {
    try {
      return from.split('@')[1];
    } catch (e) {
      return domain;
    }
  }
} 