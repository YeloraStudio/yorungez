import '../account/account_models.dart';

final class EventReminder {
  const EventReminder(
    this.id,
    this.revision,
    this.eventId,
    this.targetId,
    this.title,
    this.instant,
    this.zone,
    this.lead,
    this.status,
    this.due,
  );
  final String id, targetId, title, zone, status;
  final String? eventId;
  final int revision, lead;
  final DateTime instant, due;
  static EventReminder decode(dynamic value) {
    final m = objectMap(value);
    if (m['id'] is! String ||
        m['revision'] is! int ||
        m['targetId'] is! String ||
        m['title'] is! String ||
        m['timeZoneId'] is! String ||
        m['leadMinutes'] is! int ||
        m['channel'] != 'email' ||
        ![
          'scheduled',
          'sending',
          'sent',
          'failed',
          'expired',
          'cancelled',
          'suppressed',
        ].contains(m['status'])) {
      throw const AccountFailure(AccountFailureKind.protocol);
    }
    try {
      return EventReminder(
        m['id'],
        m['revision'],
        m['eventId'],
        m['targetId'],
        m['title'],
        DateTime.parse(m['instantUtc']).toUtc(),
        m['timeZoneId'],
        m['leadMinutes'],
        m['status'],
        DateTime.parse(m['dueAtUtc']).toUtc(),
      );
    } catch (_) {
      throw const AccountFailure(AccountFailureKind.protocol);
    }
  }

  Map<String, dynamic> cancelInput() => {
    'id': id,
    'expectedRevision': revision,
    'eventId': eventId,
    'targetId': targetId,
    'instantUtc': instant.toIso8601String(),
    'timeZoneId': zone,
    'leadMinutes': lead,
    'cancelled': true,
  };
}
