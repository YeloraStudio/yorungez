import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/api/yorungez_api.dart';

/// Non-personal, expiring public OMM packet. No location or account data.
final class IssElements {
  IssElements._(
    this.epoch,
    this.retrieved,
    this.expires,
    this.values,
    this.packet,
  );
  final DateTime epoch, retrieved, expires;
  final List<double> values;
  final Map<String, dynamic> packet;
  factory IssElements.decode(Map<String, dynamic> packet, DateTime now) {
    final raw = packet['rawOmm'];
    if (packet['schemaVersion'] != 1 ||
        packet['noradCatalogId'] != 25544 ||
        packet['referenceFrame'] != 'TEME' ||
        packet['timeSystem'] != 'UTC' ||
        packet['meanElementTheory'] != 'SGP4' ||
        packet['sourceUrl'] !=
            'https://celestrak.org/NORAD/elements/gp.php?CATNR=25544&FORMAT=JSON' ||
        raw is! String ||
        utf8.encode(raw).length > 16384 ||
        sha256.convert(utf8.encode(raw)).toString() != packet['sha256']) {
      throw const FormatException('Unsupported public orbital packet');
    }
    final list = jsonDecode(raw);
    if (list is! List || list.length != 1 || list[0] is! Map) {
      throw const FormatException('Invalid OMM count');
    }
    final row = (list[0] as Map).cast<String, dynamic>();
    if (row['NORAD_CAT_ID'] != 25544) {
      throw const FormatException('Invalid station identity');
    }
    for (final pair in [
      ('CENTER_NAME', 'EARTH'),
      ('REF_FRAME', 'TEME'),
      ('TIME_SYSTEM', 'UTC'),
      ('MEAN_ELEMENT_THEORY', 'SGP4'),
    ]) {
      if (row.containsKey(pair.$1) && row[pair.$1] != pair.$2) {
        throw const FormatException('Unsupported OMM convention');
      }
    }
    final stamp = row['EPOCH'] as String;
    final epoch = DateTime.parse(
      stamp.endsWith('Z') ? stamp : '${stamp}Z',
    ).toUtc();
    final retrieved = DateTime.parse(
      packet['retrievedAtUtc'] as String,
    ).toUtc();
    final expires = DateTime.parse(packet['expiresAtUtc'] as String).toUtc();
    if (epoch != DateTime.parse(packet['epochUtc'] as String).toUtc() ||
        expires != epoch.add(const Duration(hours: 72)) ||
        retrieved.isAfter(now.add(const Duration(minutes: 5))) ||
        epoch.isAfter(now.add(const Duration(minutes: 30)))) {
      throw const FormatException('Invalid orbital packet time');
    }
    double number(String name, double min, double max) {
      final value = row[name];
      if (value is! num || !value.isFinite || value < min || value > max) {
        throw const FormatException('Invalid orbital element');
      }
      return value.toDouble();
    }

    return IssElements._(
      epoch,
      retrieved,
      expires,
      List.unmodifiable([
        epoch.microsecondsSinceEpoch / 1e6,
        number('BSTAR', -1, 1),
        number('MEAN_MOTION_DOT', -1, 1),
        number('MEAN_MOTION_DDOT', -1, 1),
        number('ECCENTRICITY', 0, .1),
        number('ARG_OF_PERICENTER', 0, 360),
        number('INCLINATION', 0, 180),
        number('MEAN_ANOMALY', 0, 360),
        number('MEAN_MOTION', 10, 18),
        number('RA_OF_ASC_NODE', 0, 360),
      ]),
      Map.unmodifiable(packet),
    );
  }
  bool usable(DateTime instant) =>
      !instant.isBefore(epoch.subtract(const Duration(minutes: 30))) &&
      instant.isBefore(expires);
}

final class IssRepository {
  IssRepository(this.api);
  final YorungezApi api;
  Future<IssElements?> load(DateTime now) async {
    File? file;
    IssElements? cached;
    try {
      final directory = await getApplicationSupportDirectory();
      file = File('${directory.path}/public-catalogue/iss-v1.json');
      if (await file.exists() && await file.length() <= 32768) {
        cached = IssElements.decode(
          (jsonDecode(await file.readAsString()) as Map)
              .cast<String, dynamic>(),
          now,
        );
      }
    } catch (_) {
      /* Public optional cache, never a private inventory. */
    }
    if (cached != null &&
        cached.usable(now) &&
        now.difference(cached.retrieved) < const Duration(hours: 2)) {
      return cached;
    }
    try {
      final next = IssElements.decode(await api.issElements(), now);
      if (!next.usable(now)) throw const FormatException('Expired source');
      if (file != null) {
        try {
          await file.parent.create(recursive: true);
          final temp = File('${file.path}.tmp');
          await temp.writeAsString(jsonEncode(next.packet), flush: true);
          await temp.rename(file.path);
        } catch (_) {
          /* Network packet remains usable in memory. */
        }
      }
      return next;
    } catch (_) {
      return cached?.usable(now) == true ? cached : null;
    }
  }
}
