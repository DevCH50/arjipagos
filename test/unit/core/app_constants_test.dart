/// Tests unitarios para [AppConstants.generarReferencia].
///
/// Verifica el formato de referencia para un solo ID (sufijo sep+0)
/// y para múltiples IDs (join con separador), en Android e iOS.
library;

import 'package:arjipagos/src/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConstants.generarReferencia', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    // -------------------------------------------------------------------------
    // Android
    // -------------------------------------------------------------------------
    group('Android — separador A', () {
      setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);

      test('un solo ID → "3399A0"', () {
        expect(AppConstants.generarReferencia([3399]), equals('3399A0'));
      });

      test('ID largo único → "99999999A0"', () {
        expect(AppConstants.generarReferencia([99999999]), equals('99999999A0'));
      });

      test('múltiples IDs → join con A', () {
        expect(
          AppConstants.generarReferencia([5358, 5359, 5360]),
          equals('5358A5359A5360'),
        );
      });
    });

    // -------------------------------------------------------------------------
    // iOS
    // -------------------------------------------------------------------------
    group('iOS — separador I', () {
      setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

      test('un solo ID → "3399I0"', () {
        expect(AppConstants.generarReferencia([3399]), equals('3399I0'));
      });

      test('ID largo único → "99999999I0"', () {
        expect(AppConstants.generarReferencia([99999999]), equals('99999999I0'));
      });

      test('múltiples IDs → join con I', () {
        expect(
          AppConstants.generarReferencia([5358, 5359, 5360]),
          equals('5358I5359I5360'),
        );
      });
    });
  });
}
