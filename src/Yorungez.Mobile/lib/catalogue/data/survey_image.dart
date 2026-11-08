import 'dart:io';
import 'dart:typed_data';

import '../domain/sky_object.dart';

/// Only fixed, public catalogue positions can be submitted to the survey.
Uri? surveyImageUri(SkyObject object) {
  final ra = object.raHours;
  final dec = object.decDegrees;
  if ((object.kind != ObjectKind.star && object.kind != ObjectKind.deepSky) ||
      ra == null ||
      dec == null ||
      !ra.isFinite ||
      !dec.isFinite ||
      ra < 0 ||
      ra >= 24 ||
      dec.abs() > 90) {
    return null;
  }
  return Uri.https('skyview.gsfc.nasa.gov', '/current/cgi/runquery.pl', {
    'Position': '${(ra * 15).toStringAsFixed(6)},${dec.toStringAsFixed(6)}',
    'Coordinates': 'J2000',
    'Survey': '2MASS-K',
    'Pixels': '300',
    'Size': '0.3',
    'Return': 'JPEG',
  });
}

Future<Uint8List> loadSurveyImage(SkyObject object) async {
  final uri = surveyImageUri(object);
  if (uri == null) throw ArgumentError('No fixed catalogue coordinates');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
  try {
    return await _readPreview(client, uri).timeout(const Duration(seconds: 15));
  } finally {
    client.close(force: true);
  }
}

Future<Uint8List> _readPreview(HttpClient client, Uri uri) async {
  const maxBytes = 512 * 1024;
  final request = await client.getUrl(uri);
  request.followRedirects = false;
  request.headers.set(HttpHeaders.acceptHeader, 'image/jpeg');
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok ||
      response.headers.contentType?.mimeType != 'image/jpeg' ||
      response.contentLength > maxBytes) {
    throw const FormatException('Survey preview unavailable');
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in response) {
    if (bytes.length + chunk.length > maxBytes) {
      throw const FormatException('Survey preview exceeds size limit');
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}
