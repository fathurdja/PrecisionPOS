import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../data/database_helper.dart';
import '../utils/currency_format.dart';

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._internal();

  factory BluetoothPrinterService() {
    return _instance;
  }

  BluetoothPrinterService._internal();

  Future<bool> get isBluetoothEnabled async {
    return await PrintBluetoothThermal.bluetoothEnabled;
  }

  Future<List<BluetoothInfo>> getPairedDevices() async {
    return await PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> connect(String macAddress) async {
    return await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  Future<bool> disconnect() async {
    return await PrintBluetoothThermal.disconnect;
  }

  Future<bool> get isConnected async {
    return await PrintBluetoothThermal.connectionStatus;
  }

  Future<List<int>> _generateReceiptBytes(TransactionModel transaction, List<OrderItemModel> items) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('store_name') ?? 'PRECISION POS';

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> enrichedItems = [];
    
    for (var item in items) {
      final pList = await db.query('products', where: 'id = ?', whereArgs: [item.productId]);
      String productName = pList.isNotEmpty ? pList.first['nama'] as String : 'Item ${item.productId}';
      enrichedItems.add({
        'name': productName,
        'qty': item.qty,
        'subtotal': item.subtotal,
      });
    }

    // Header
    bytes += generator.text(storeName, styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2));
    bytes += generator.feed(1);
    bytes += generator.text('Invoice: ${transaction.receiptId}', styles: const PosStyles(align: PosAlign.center));
    
    String formattedDate = transaction.tanggal.length >= 16 ? transaction.tanggal.substring(0, 16).replaceFirst('T', ' ') : transaction.tanggal;
    bytes += generator.text('Waktu: $formattedDate', styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.feed(1);
    bytes += generator.hr();

    // Items
    for (var item in enrichedItems) {
      bytes += generator.row([
        PosColumn(
          text: '${item['qty']}x ${item['name']}',
          width: 8,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: formatCurrency.format(item['subtotal']),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.feed(1);
    bytes += generator.hr();

    // Total
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: formatCurrency.format(transaction.totalHarga), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    
    bytes += generator.feed(1);
    if (transaction.status == 'Bon' || transaction.status == 'Bon / Belum Lunas') {
      bytes += generator.text('PIUTANG / BON', styles: const PosStyles(align: PosAlign.center, bold: true));
    } else if (transaction.status == 'QRIS') {
      bytes += generator.text('QRIS PAID', styles: const PosStyles(align: PosAlign.center, bold: true));
    } else {
      bytes += generator.text('CASH PAID', styles: const PosStyles(align: PosAlign.center, bold: true));
    }

    bytes += generator.feed(1);
    bytes += generator.text('Terima Kasih!', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    
    return bytes;
  }

  Future<bool> printReceipt(TransactionModel transaction, List<OrderItemModel> items) async {
    bool connected = await isConnected;
    
    if (!connected) {
      final prefs = await SharedPreferences.getInstance();
      final savedMac = prefs.getString('printer_mac');
      if (savedMac != null && savedMac.isNotEmpty) {
        connected = await connect(savedMac);
      }
    }

    if (!connected) {
      throw Exception('Printer belum terhubung. Silakan atur di Settings.');
    }

    List<int> bytes = await _generateReceiptBytes(transaction, items);
    bool result = await PrintBluetoothThermal.writeBytes(bytes);
    return result;
  }
}
