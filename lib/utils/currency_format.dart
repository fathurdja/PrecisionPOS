import 'package:intl/intl.dart';

class CurrencyFormat {
  static String idr(dynamic number) {
    if (number == null) return 'Rp 0';
    NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return currencyFormatter.format(number);
  }
}
