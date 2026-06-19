import 'package:flutter_test/flutter_test.dart';
import 'package:inventopos/domain/inventory/unit_of_measure.dart';

void main() {
  group('UomConverter', () {
    test('converts kg to grams', () {
      final result = UomConverter.convert(UnitOfMeasure.kg, UnitOfMeasure.gram, 2.5);
      expect(result, 2500.0);
    });

    test('converts grams to kg', () {
      final result = UomConverter.convert(UnitOfMeasure.gram, UnitOfMeasure.kg, 1500);
      expect(result, 1.5);
    });

    test('converts litre to ml', () {
      final result = UomConverter.convert(UnitOfMeasure.litre, UnitOfMeasure.ml, 1.2);
      expect(result, 1200.0);
    });

    test('converts dozen to piece', () {
      final result = UomConverter.convert(UnitOfMeasure.dozen, UnitOfMeasure.piece, 2);
      expect(result, 24.0);
    });

    test('returns same value if units are identical', () {
      final result = UomConverter.convert(UnitOfMeasure.piece, UnitOfMeasure.piece, 5);
      expect(result, 5.0);
    });

    test('returns same value for unsupported conversions', () {
      final result = UomConverter.convert(UnitOfMeasure.piece, UnitOfMeasure.kg, 5);
      expect(result, 5.0);
    });
  });

  group('UnitOfMeasureX', () {
    test('fromString parses correctly', () {
      expect(UnitOfMeasureX.fromString('kg'), UnitOfMeasure.kg);
      expect(UnitOfMeasureX.fromString('LITRE'), UnitOfMeasure.litre);
      expect(UnitOfMeasureX.fromString('unknown'), UnitOfMeasure.piece); // Default
    });

    test('isDecimalUnit returns correct value', () {
      expect(UnitOfMeasure.kg.isDecimalUnit, true);
      expect(UnitOfMeasure.piece.isDecimalUnit, false);
    });
  });
}
