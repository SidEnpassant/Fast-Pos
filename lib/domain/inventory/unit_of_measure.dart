
enum UnitOfMeasure {
  piece,
  kg,
  gram,
  litre,
  ml,
  dozen,
  box,
  meter,
  pack,
}

extension UnitOfMeasureX on UnitOfMeasure {
  String get symbol {
    switch (this) {
      case UnitOfMeasure.piece: return 'pc';
      case UnitOfMeasure.kg: return 'kg';
      case UnitOfMeasure.gram: return 'g';
      case UnitOfMeasure.litre: return 'L';
      case UnitOfMeasure.ml: return 'mL';
      case UnitOfMeasure.dozen: return 'dz';
      case UnitOfMeasure.box: return 'box';
      case UnitOfMeasure.meter: return 'm';
      case UnitOfMeasure.pack: return 'pk';
    }
  }

  String get pluralLabel {
    switch (this) {
      case UnitOfMeasure.piece: return 'pieces';
      case UnitOfMeasure.kg: return 'kilograms';
      case UnitOfMeasure.gram: return 'grams';
      case UnitOfMeasure.litre: return 'litres';
      case UnitOfMeasure.ml: return 'millilitres';
      case UnitOfMeasure.dozen: return 'dozens';
      case UnitOfMeasure.box: return 'boxes';
      case UnitOfMeasure.meter: return 'meters';
      case UnitOfMeasure.pack: return 'packs';
    }
  }

  int get decimalPlaces {
    switch (this) {
      case UnitOfMeasure.kg:
      case UnitOfMeasure.litre:
      case UnitOfMeasure.meter:
        return 3;
      default:
        return 0;
    }
  }

  bool get isDecimalUnit => decimalPlaces > 0;

  static UnitOfMeasure fromString(String uomStr) {
    return UnitOfMeasure.values.firstWhere(
      (e) => e.name == uomStr.toLowerCase().trim(),
      orElse: () => UnitOfMeasure.piece,
    );
  }
}

class UomConverter {
  static double convert(UnitOfMeasure from, UnitOfMeasure to, double value) {
    if (from == to) return value;
    if (from == UnitOfMeasure.kg && to == UnitOfMeasure.gram) return value * 1000;
    if (from == UnitOfMeasure.gram && to == UnitOfMeasure.kg) return value / 1000;
    if (from == UnitOfMeasure.litre && to == UnitOfMeasure.ml) return value * 1000;
    if (from == UnitOfMeasure.ml && to == UnitOfMeasure.litre) return value / 1000;
    if (from == UnitOfMeasure.dozen && to == UnitOfMeasure.piece) return value * 12;
    if (from == UnitOfMeasure.piece && to == UnitOfMeasure.dozen) return value / 12;
    // Default fallback
    return value;
  }
}
