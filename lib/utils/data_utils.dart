import 'package:intl/intl.dart';

class DataUtils {
  static final NumberFormat _currencyFormatter = NumberFormat('#,###', 'ko_KR');

  static String calcStringToWon(String price) {
    if (price.isEmpty) {
      return '-';
    }
    if (price.toLowerCase() == 'free') {
      return 'Free';
    }

    return '${_currencyFormatter.format(int.parse(price))} won';
  }
}
