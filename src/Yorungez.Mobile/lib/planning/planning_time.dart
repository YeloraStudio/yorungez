import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

final class PlanningTime {
  static bool _ready = false;
  static void initialise() {
    if (!_ready) {
      data.initializeTimeZones();
      _ready = true;
    }
  }

  static tz.Location zone(String name) {
    initialise();
    return tz.getLocation(name);
  }

  static Future<String> deviceZone() async {
    try {
      final raw = await const MethodChannel(
        'yorungez/time',
      ).invokeMethod<String>('zone');
      if (raw != null) {
        final name = ['GMT', 'Etc/UTC', 'Etc/GMT'].contains(raw) ? 'UTC' : raw;
        zone(name);
        return name;
      }
    } catch (_) {
      /* Explicit UTC fallback; no invented geographic zone. */
    }
    return 'UTC';
  }

  static tz.TZDateTime local(DateTime instant, String name) =>
      tz.TZDateTime.from(instant.toUtc(), zone(name));
  static String offset(DateTime instant, String name) {
    final d = local(instant, name).timeZoneOffset, minutes = d.inMinutes.abs();
    return 'GMT${d.isNegative ? '-' : '+'}${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
  }

  static String label(
    DateTime instant,
    String name,
    String language, {
    bool seconds = false,
  }) =>
      '${DateFormat(seconds ? 'dd MMM yyyy · HH:mm:ss' : 'dd MMM yyyy · HH:mm', language).format(local(instant, name))} · ${offset(instant, name)}';
  static String utc(DateTime instant, String language) =>
      DateFormat("dd MMM yyyy · HH:mm 'UTC'", language).format(instant.toUtc());
  static ({DateTime start, DateTime end}) window(DateTime date, String name) {
    final z = zone(name);
    final start = tz.TZDateTime(z, date.year, date.month, date.day, 12).toUtc();
    final end = tz.TZDateTime(
      z,
      date.year,
      date.month,
      date.day + 1,
      12,
    ).toUtc();
    if (start.isBefore(DateTime.utc(2000)) || end.isAfter(DateTime.utc(2036))) {
      throw const FormatException('Unsupported planning window');
    }
    return (start: start, end: end);
  }

  static DateTime nightDate(DateTime instant, String name) {
    final d = local(instant, name);
    return DateTime.utc(d.year, d.month, d.day - (d.hour < 12 ? 1 : 0));
  }
}
