import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory('../../data/store/google-play/en-US/raw');
  await output.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      if (!RegExp(r'^0[1-8]-[a-z]+$').hasMatch(name)) {
        throw StateError('Unexpected capture name');
      }
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
