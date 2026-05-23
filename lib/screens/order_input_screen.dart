import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../widgets/top_app_bar.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/order_item_model.dart';
import '../models/customer_model.dart';
import '../repositories/product_repository.dart';
import '../repositories/customer_repository.dart';
import '../utils/helpers.dart';
import 'payment_method_screen.dart';
import '../utils/currency_format.dart';

class CartItem {
  final ProductModel product;
  int qty;
  int bonusQty;

  CartItem({required this.product, this.qty = 1, this.bonusQty = 0});

  double get subtotal => product.harga * qty;
  int get totalQty => qty + bonusQty;
}

class OrderInputScreen extends StatefulWidget {
  const OrderInputScreen({super.key});

  @override
  State<OrderInputScreen> createState() => _OrderInputScreenState();
}

class _OrderInputScreenState extends State<OrderInputScreen> {
  final ProductRepository _productRepo = ProductRepository();
  final CustomerRepository _customerRepo = CustomerRepository();

  List<ProductModel> _availableProducts = [];
  List<CartItem> _cart = [];

  String _receiptNumber = '';
  String _issueDate = '';
  
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  ProductModel? _selectedProduct;
  CustomerModel? _selectedCustomer;

  double _taxRate = 8.0;
  double _serviceRate = 0.0;

  @override
  void initState() {
    super.initState();
    _initOrder();
    _loadProducts();
    _loadTaxServiceSettings();
  }

  Future<void> _loadTaxServiceSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _taxRate = prefs.getDouble('tax_rate') ?? 8.0;
      _serviceRate = prefs.getDouble('service_rate') ?? 0.0;
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  void _initOrder() {
    setState(() {
      _receiptNumber = Helpers.generateReceiptNumber();
      _issueDate = Helpers.getCurrentTimestamp();
      _cart.clear();
      _selectedProduct = null;
      _selectedCustomer = null;
      _customerNameController.clear();
      _customerPhoneController.clear();
    });
  }

  Future<void> _loadProducts() async {
    final products = await _productRepo.getProducts();
    setState(() {
      _availableProducts = products;
    });
  }

  double get subtotal => _cart.fold(0.0, (sum, item) => sum + item.subtotal);
  double get serviceCharge => subtotal * (_serviceRate / 100);
  double get tax => (subtotal + serviceCharge) * (_taxRate / 100);
  double get total => subtotal + serviceCharge + tax;

  void _processPayment() {
    if (_cart.isEmpty) return;

    final transaction = TransactionModel(
      receiptId: _receiptNumber,
      tanggal: _issueDate,
      totalHarga: total,
      status: 'Pending',
      customerName: _customerNameController.text.trim().isNotEmpty 
          ? _customerNameController.text.trim() 
          : null,
      customerPhone: _customerPhoneController.text.trim().isNotEmpty 
          ? _customerPhoneController.text.trim() 
          : null,
      taxAmount: tax,
      serviceAmount: serviceCharge,
    );

    if (_customerNameController.text.trim().isNotEmpty && _customerPhoneController.text.trim().isNotEmpty) {
      if (_selectedCustomer == null || _selectedCustomer!.phone != _customerPhoneController.text.trim()) {
        _customerRepo.addCustomer(CustomerModel(
          name: _customerNameController.text.trim(),
          phone: _customerPhoneController.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
        ));
      }
    }

    final items = _cart
        .expand((item) {
          final list = <OrderItemModel>[];
          if (item.qty > 0) {
            list.add(OrderItemModel(
              receiptId: _receiptNumber,
              productId: item.product.id,
              qty: item.qty,
              subtotal: item.subtotal,
            ));
          }
          if (item.bonusQty > 0) {
            list.add(OrderItemModel(
              receiptId: _receiptNumber,
              productId: item.product.id,
              qty: item.bonusQty,
              subtotal: 0,
            ));
          }
          return list;
        })
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentMethodScreen(transaction: transaction, items: items),
      ),
    ).then((_) {
      if (mounted) {
        _initOrder();
        _loadProducts();
        _loadTaxServiceSettings();
      }
    });
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
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReceiptMeta(),
                  const SizedBox(height: 24),
                  _buildCustomerInput(),
                  const SizedBox(height: 24),
                  _buildOrderSection(),
                  const SizedBox(height: 32),
                  _buildBentoMetrics(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildCheckoutPanel(),
    );
  }

  Widget _buildCustomerInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CUSTOMER INFO',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Autocomplete<CustomerModel>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 2) {
              return const Iterable<CustomerModel>.empty();
            }
            return await _customerRepo.searchCustomers(textEditingValue.text);
          },
          displayStringForOption: (CustomerModel option) => '${option.name} (${option.phone})',
          onSelected: (CustomerModel selection) {
            setState(() {
              _selectedCustomer = selection;
              _customerNameController.text = selection.name;
              _customerPhoneController.text = selection.phone;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                labelText: 'Search Customer (Name or Phone)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  _selectedCustomer = null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _customerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (val) {
                  _selectedCustomer = null;
                },
              ),
            ),
          ],
        ),
      ],
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

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ProductModel>(
              isExpanded: true,
              hint: Text('Select Product to Add'),
              value: _selectedProduct,
              items: _availableProducts
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.nama} - Rp ${p.harga.toInt()} (Stock: ${p.stok})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (product) {
                if (product != null && product.stok > 0) {
                  setState(() {
                    _selectedProduct = null;
                    int existingIdx = _cart.indexWhere(
                      (c) => c.product.id == product.id,
                    );
                    if (existingIdx >= 0) {
                      if (_cart[existingIdx].totalQty < product.stok) {
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
              item.bonusQty,
              (newQty) {
                setState(() {
                  if (newQty < 0) return;
                  if (newQty == 0 && item.bonusQty == 0) {
                    _cart.removeAt(idx);
                  } else {
                    int totalQtyForProduct = _cart
                        .where((c) => c.product.id == item.product.id && c != item)
                        .fold(0, (sum, c) => sum + c.totalQty);
                    if (newQty + item.bonusQty + totalQtyForProduct <= item.product.stok) {
                      item.qty = newQty;
                    }
                  }
                });
              },
              (newBonusQty) {
                setState(() {
                  if (newBonusQty < 0) return;
                  if (item.qty == 0 && newBonusQty == 0) {
                    _cart.removeAt(idx);
                  } else {
                    int totalQtyForProduct = _cart
                        .where((c) => c.product.id == item.product.id && c != item)
                        .fold(0, (sum, c) => sum + c.totalQty);
                    if (item.qty + newBonusQty + totalQtyForProduct <= item.product.stok) {
                      item.bonusQty = newBonusQty;
                    }
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
    int bonusQty,
    ValueChanged<int> onQtyChanged,
    ValueChanged<int> onBonusQtyChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Unit: Rp ${unitPrice.toInt()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Qty Reguler',
                          style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (qty > 0) onQtyChanged(qty - 1);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: Text(
                                      '-',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                child: Center(
                                  child: Text(
                                    '$qty',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => onQtyChanged(qty + 1),
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: Text(
                                      '+',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.card_giftcard, size: 10, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Qty Bonus',
                              style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => onBonusQtyChanged(bonusQty - 1),
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: Text('-', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 24,
                                child: Center(
                                  child: Text('$bonusQty', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => onBonusQtyChanged(bonusQty + 1),
                                behavior: HitTestBehavior.opaque,
                                child: SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Center(
                                    child: Text('+', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    CurrencyFormat.idr((unitPrice * qty)),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
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
                Icon(Icons.shopping_bag_outlined, color: Colors.white.withValues(alpha: 0.8), size: 24),
                const SizedBox(height: 8),
                Text(
                  'TOTAL ITEMS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_cart.fold(0, (sum, item) => sum + item.totalQty)} Items',
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
                    CurrencyFormat.idr(subtotal),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
              if (_serviceRate > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Charge (${_serviceRate.toStringAsFixed(_serviceRate % 1 == 0 ? 0 : 1)}%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      CurrencyFormat.idr(serviceCharge),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax (${_taxRate.toStringAsFixed(_taxRate % 1 == 0 ? 0 : 1)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    CurrencyFormat.idr(tax),
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
                    CurrencyFormat.idr(total),
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
                  label: const Text(
                    'Process Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
