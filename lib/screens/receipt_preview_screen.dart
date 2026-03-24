import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';

import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../services/pdf_receipt_service.dart';
import '../services/whatsapp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptPreviewScreen extends StatelessWidget {
  final TransactionModel transaction;
  final List<OrderItemModel> items;
  final String method;

  const ReceiptPreviewScreen({
    super.key,
    required this.transaction,
    required this.items,
    required this.method,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const AppTopBar(trailingText: 'Preview Mode'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                  _buildReceiptCard(),
                  const SizedBox(height: 32),
                  Text(
                    'DIGITAL COPY • PAPERLESS CERTIFIED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.outline,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
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
          child: ElevatedButton.icon(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.share, size: 18),
            label: const Text(
              'Share WhatsApp',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await PdfReceiptService().printReceipt(transaction, items);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to print: \$e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryContainer,
              foregroundColor: AppColors.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text(
              'Export PDF',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildReceiptHeader(),
          _buildTransactionInfo(),
          _buildItemizedList(),
          _buildTotalsSection(),
          _buildFooterQR(),
        ],
      ),
    );
  }

  Widget _buildReceiptHeader() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        String storeName = 'PRECISION BREW';
        String storeAddress = 'Jl. Senopati No. 42, Jakarta Selatan';
        String storePhone = 'Tel: +62 21 555 0123';
        
        if (snapshot.hasData) {
           final prefs = snapshot.data!;
           final savedName = prefs.getString('store_name');
           final savedAddress = prefs.getString('store_address');
           final savedPhone = prefs.getString('store_phone');
           
           if (savedName != null && savedName.isNotEmpty) storeName = savedName;
           if (savedAddress != null && savedAddress.isNotEmpty) storeAddress = savedAddress;
           if (savedPhone != null && savedPhone.isNotEmpty) storePhone = savedPhone;
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.coffee,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                storeName.toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'ATELIER & ROASTERY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.outline,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                storeAddress,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                storePhone,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildTransactionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            transaction.receiptId,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.outline,
            ),
          ),
          Text(
            transaction.tanggal.length >= 16 ? transaction.tanggal.substring(0, 16).replaceFirst('T', ' ') : transaction.tanggal,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemizedList() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildReceiptItem('${item.qty}x Item ${item.productId}', '', 'Rp ${item.subtotal.toInt()}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReceiptItem(String name, String description, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection() {
    double subtotal = items.fold(0.0, (sum, item) => sum + item.subtotal);
    double tax = subtotal * 0.08;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
      color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', 'Rp ${subtotal.toInt()}'),
          const SizedBox(height: 8),
          _buildTotalRow('Tax (8%)', 'Rp ${tax.toInt()}'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onPrimaryFixedVariant,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Rp ${transaction.totalHarga.toInt()}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'PAYMENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.outline,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        method.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFooterQR() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.2),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.qr_code_2,
              size: 100,
              color: AppColors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SCAN TO DOWNLOAD E-INVOICE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.outline,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thank you for brewing with us!',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
