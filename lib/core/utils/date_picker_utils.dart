/// Keeps [DatePicker] / [showDatePicker] `initialDate` valid vs [firstDate] and [lastDate].
abstract final class DatePickerUtils {
  static DateTime clampInitial({
    required DateTime? preferred,
    required DateTime fallback,
    required DateTime first,
    required DateTime last,
  }) {
    final base = preferred ?? fallback;
    if (base.isBefore(first)) return first;
    if (base.isAfter(last)) return last;
    return base;
  }
}
