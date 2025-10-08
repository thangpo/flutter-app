enum VacationDurationType {
  oneDay('one_day'),
  untilChange('until_change'),
  custom('custom');

  final String value;
  const VacationDurationType(this.value);

  factory VacationDurationType.fromJson(String value) {
    return VacationDurationType.values.firstWhere((e) => e.value == value);
  }

  String toJson() => value;
}
