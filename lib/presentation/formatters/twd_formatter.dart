String formatTwd(int amountMinor) {
  final sign = amountMinor < 0 ? '-' : '';
  final digits = amountMinor.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index += 1) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[index]);
  }
  return '${sign}NT\$${buffer.toString()}';
}
