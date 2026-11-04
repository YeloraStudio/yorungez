import 'package:flutter_test/flutter_test.dart';
import 'package:yorungez/sky/domain/dwell_selection.dart';

void main() {
  test('selection fires once after one complete monotonic second', () {
    final dwell = DwellSelection();
    expect(dwell.update('jupiter', Duration.zero), isNull);
    expect(dwell.update('jupiter', const Duration(milliseconds: 999)), isNull);
    expect(dwell.update('jupiter', const Duration(seconds: 1)), 'jupiter');
    expect(dwell.update('jupiter', const Duration(seconds: 20)), isNull);
  });
  test(
    'target/context interruption and non-monotonic input restart the dwell',
    () {
      final dwell = DwellSelection();
      dwell.update('moon', Duration.zero);
      expect(dwell.update('moon', const Duration(milliseconds: 600)), isNull);
      dwell.update(null, const Duration(milliseconds: 700));
      dwell.update('mars', const Duration(milliseconds: 800));
      expect(dwell.update('mars', const Duration(milliseconds: 1799)), isNull);
      expect(dwell.update('mars', const Duration(milliseconds: 1800)), 'mars');
      dwell.reset();
      dwell.update('mars', const Duration(seconds: 2));
      expect(dwell.update('mars', const Duration(milliseconds: 2999)), isNull);
      expect(dwell.update('mars', const Duration(milliseconds: 2500)), isNull);
      expect(dwell.update('mars', const Duration(milliseconds: 3499)), isNull);
      expect(dwell.update('mars', const Duration(milliseconds: 3500)), 'mars');
    },
  );
}
