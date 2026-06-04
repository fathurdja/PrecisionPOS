import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../services/pdf_receipt_service.dart';
import '../services/whatsapp_service.dart';
import '../services/bluetooth_printer_service.dart';
import '../utils/currency_format.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final TransactionModel transaction;
  final List<OrderItemModel> items;
  final String method;
  final double? receivedAmount;
  final double? changeAmount;
  final String? dueDate;

  const PaymentSuccessScreen({
    super.key,
    required this.transaction,
    required this.items,
    required this.method,
    this.receivedAmount,
    this.changeAmount,
    this.dueDate,
  });

  void _onNewTransaction(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Metode: $method',
                style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              _buildDigitalReceipt(),
              const SizedBox(height: 32),
              _buildActionButtons(context),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _onNewTransaction(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('+ Transaksi Baru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalReceipt() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'PRECISION POS',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Invoice:', style: TextStyle(color: AppColors.outline)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  transaction.receiptId, 
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Waktu:', style: TextStyle(color: AppColors.outline)),
              Text(
                transaction.tanggal.length >= 16 ? transaction.tanggal.substring(0, 16).replaceFirst('T', ' ') : transaction.tanggal,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1, color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 16),
          
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text('${item.qty}x Item ${item.productId}'),
                ),
                Text(CurrencyFormat.idr(item.subtotal)),
              ],
            ),
          )),
          
          const SizedBox(height: 16),
          const Divider(thickness: 1, color: AppColors.surfaceContainerHigh),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(CurrencyFormat.idr(transaction.totalHarga), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
            ],
          ),
          
          if (method == 'Cash' && receivedAmount != null && changeAmount != null)
            ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Cash Diterima', style: TextStyle(color: AppColors.outline)),
                  Text(CurrencyFormat.idr(receivedAmount!)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Kembalian', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  Text(CurrencyFormat.idr(changeAmount!), style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                ],
              ),
            ],

          if (method == 'QRIS')
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.secondary, size: 16),
                  SizedBox(width: 8),
                  Text('QRIS Paid', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
          if (method == 'Bon' && dueDate != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFFB07000), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Dicatat sebagai Bon · Jatuh Tempo: $dueDate', 
                      style: const TextStyle(color: Color(0xFFB07000), fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                final pdfFile = await PdfReceiptService().getPdfFile(transaction, items);
                await WhatsAppService().sharePdfFile(pdfFile, text: 'Receipt from Precision POS (\${transaction.receiptId})');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: \$e')));
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.share),
            label: const Text('WhatsApp'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mencetak struk via Bluetooth...')));
                }
                await BluetoothPrinterService().printReceipt(transaction, items);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Gagal mencetak: \$e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 4),
                  ));
                }
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.bluetooth),
            label: const Text('Cetak Struk'),
          ),
        ),
      ],
    );
  }
}
