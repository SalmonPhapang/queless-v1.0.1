import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: 'R',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatDate(date);
    }
  }

  static String formatPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'\D'), '');
    
    if (phone.length == 10 && phone.startsWith('0')) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    } else if (phone.length == 11 && phone.startsWith('27')) {
      return '+27 ${phone.substring(2, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    
    return phone;
  }
}
