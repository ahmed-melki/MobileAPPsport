const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String formatShortDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]}';
}
