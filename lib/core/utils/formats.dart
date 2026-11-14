import 'package:intl/intl.dart';

abstract class Formats {
  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

  static const List<String> _bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _hari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String rupiah(num value) => _currency.format(value);

  static String number(num value) => _decimal.format(value);

  static String time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String timeWib(DateTime value) => '${time(value)} WIB';

  static String date(DateTime value) {
    return '${value.day} ${_bulan[value.month - 1]} ${value.year}';
  }

  static String dayName(DateTime value) => _hari[value.weekday - 1];

  static String pickupWindow(DateTime mulai, DateTime batas) {
    return '${time(mulai)} - ${time(batas)} WIB';
  }

  static String countdown(Duration duration) {
    if (duration.inMinutes <= 0) return 'Lewat batas';
    if (duration.inHours >= 1) {
      final jam = duration.inHours;
      final menit = duration.inMinutes.remainder(60);
      return menit == 0 ? '$jam jam' : '$jam jam $menit mnt';
    }
    return '${duration.inMinutes} mnt';
  }

  static String relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == -1) return 'Kemarin';
    return _hari[date.weekday - 1];
  }
}
