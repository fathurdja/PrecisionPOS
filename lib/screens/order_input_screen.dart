import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../repositories/product_repository.dart';
import '../repositories/transaction_repository.dart';
import '../utils/helpers.dart';

class CartItem {
  final ProductModel product;
  int qty;

  CartItem({required this.product, this.qty = 1});

  double get subtotal => product.harga * qty;
}

class OrderInputScreen extends StatefulWidget {
  const OrderInputScreen({super.key});

  @override
  State<OrderInputScreen> createState() => _OrderInputScreenState();
}

class _OrderInputScreenState extends State<OrderInputScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();

  List<ProductModel> _availableProducts = [];
  List<CartItem> _cart = [];
  
  String _receiptNumber = '';
  String _issueDate = '';
  
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _initOrder();
    _loadProducts();
  }

  void _initOrder() {
    setState(() {
      _receiptNumber = Helpers.generateReceiptNumber();
      _issueDate = Helpers.getCurrentTimestamp();
      _cart.clear();
      _selectedProduct = null;
    });
  }

  Future<void> _loadProducts() async {
    final products = await _productRepo.getProducts();
    setState(() {
      _availableProducts = products;
    });
  }

  double get subtotal => _cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;

  Future<void> _processPayment() async {
    if (_cart.isEmpty) return;
    
    final transaction = TransactionModel(
      receiptId: _receiptNumber,
      tanggal: _issueDate,
      totalHarga: total,
      status: 'Completed',
    );
    
    final items = _cart.map((item) => OrderItemModel(
      receiptId: _receiptNumber,
      productId: item.product.id,
      qty: item.qty,
      subtotal: item.subtotal,
    )).toList();
    
    await _transactionRepo.saveTransaction(transaction, items);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primary),
              const SizedBox(width: 12),
              const Expanded(child: Text('Payment Processed Successfully!', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold))),
            ],
          ),
          backgroundColor: AppColors.surfaceContainerHigh,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      
      _initOrder();
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const AppTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReceiptMeta(),
                  const SizedBox(height: 32),
                  _buildOrderSection(),
                  const SizedBox(height: 32),
                  _buildBentoMetrics(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.secondaryContainer,
        child: Icon(Icons.add, color: AppColors.onSecondaryContainer),
      ),
      bottomSheet: _buildCheckoutPanel(),
    );
  }

  Widget _buildReceiptMeta() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECEIPT NUMBER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.outline,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _receiptNumber.isNotEmpty ? _receiptNumber : '#RCPT-PENDING',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ISSUE DATE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.outline,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _issueDate.isNotEmpty && _issueDate.length >= 16 
                  ? _issueDate.substring(0, 16).replaceFirst('T', ' ')
                  : 'Today',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CURRENT ORDER',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1,
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () {
                setState(() {
                  _cart.clear();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Product Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProductModel>(
              isExpanded: true,
              hint: Text('Select Product to Add'),
              value: _selectedProduct,
              items: _availableProducts.map((p) => DropdownMenuItem(
                value: p,
                child: Text('${p.nama} - Rp ${p.harga.toInt()} (Stock: ${p.stok})'),
              )).toList(),
              onChanged: (product) {
                if (product != null && product.stok > 0) {
                  setState(() {
                    _selectedProduct = null;
                    int existingIdx = _cart.indexWhere((c) => c.product.id == product.id);
                    if (existingIdx >= 0) {
                        if (_cart[existingIdx].qty < product.stok) {
                          _cart[existingIdx].qty++;
                        }
                    } else {
                        _cart.add(CartItem(product: product, qty: 1));
                    }
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        if (_cart.isEmpty) _buildEmptyState(),
        
        ..._cart.asMap().entries.map((entry) {
          int idx = entry.key;
          CartItem item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildItemCard(
              Icons.shopping_bag,
              item.product.nama,
              item.product.harga,
              item.qty,
              (newQty) {
                setState(() {
                  if (newQty <= 0) {
                    _cart.removeAt(idx);
                  } else if (newQty <= item.product.stok) {
                    item.qty = newQty;
                  }
                });
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildItemCard(
    IconData icon,
    String name,
    double unitPrice,
    int qty,
    ValueChanged<int> onQtyChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  'Unit: Rp ${unitPrice.toInt()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Quantity stepper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (qty > 0) onQtyChanged(qty - 1);
                  },
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  child: Center(
                    child: Text(
                      '$qty',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => onQtyChanged(qty + 1),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Rp ${(unitPrice * qty).toInt()}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 2,
          // Using Flutter's default dashed border simulation
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_shopping_cart,
            color: AppColors.outlineVariant,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to complete the order',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoMetrics() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.loyalty, color: AppColors.secondaryFixed, size: 24),
                const SizedBox(height: 8),
                Text(
                  'LOYALTY POINTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+14 pts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.inventory_2, color: AppColors.primary, size: 24),
                const SizedBox(height: 8),
                Text(
                  'STOCK ALERT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'In Stock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Rp ${subtotal.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax (8%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Rp ${tax.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Rp ${total.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cart.isEmpty ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  icon: const Icon(Icons.payments, size: 20),
                  label: Text(
                    'Process Payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
