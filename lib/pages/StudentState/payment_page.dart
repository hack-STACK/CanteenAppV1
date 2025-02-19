import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:kantin/Component/my_button.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
import 'package:kantin/pages/StudentState/delivery_page.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/pages/StudentState/payment_selection_page.dart';
import 'dart:async'; // Add this import for TimeoutException
import 'package:kantin/utils/error_handler.dart';
import 'package:kantin/widgets/loading_overlay.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool isLoading = false; // Loading state
  late AnimationController _controller;
  late Animation<double> _animation;

  final TransactionService _transactionService = TransactionService();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.e_wallet;
  bool _isProcessing = false;
  String? _errorMessage;

  // Add the missing controller
  final TextEditingController noteController = TextEditingController();

  final _supabase = Supabase.instance.client;

  // Add new properties for UI state
  bool _isLoadingStudentData = false;
  Map<String, dynamic>? _studentData;
  final _pageController = PageController();
  int _currentStep = 0;

  // Add this to track payment steps
  bool _isPaymentConfirmed = false;
  bool _isPaymentProcessing = false;

  OrderType _selectedOrderType = OrderType.delivery;

  // Update steps number and names
  final List<String> _steps = ['Order', 'Type', 'Payment', 'Confirm'];

  // Add timeout duration constant
  static const paymentTimeout = Duration(seconds: 30);

  // Add new properties
  bool _isSubmitting = false;
  String? _transactionId;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(_controller);

    // Initialize payment method
    _selectedPaymentMethod = PaymentMethod.e_wallet;

    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    setState(() => _isLoadingStudentData = true);

    try {
      // Use fixed student ID directly
      final data = await _supabase
          .from('students')
          .select()
          .eq('id', 1) // Replace with your actual student ID
          .single();

      setState(() {
        _studentData = data;
        _isLoadingStudentData = false;
      });
    } catch (e) {
      print('Error loading student data: $e');
      setState(() {
        _isLoadingStudentData = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    noteController.dispose(); // Add this
    _controller.dispose();
    super.dispose();
  }

  // Update payment method string conversion
  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.e_wallet:
        return 'e_wallet';
      case PaymentMethod.bank_transfer:
        return 'bank_transfer';
      case PaymentMethod.credit_card:
        return 'credit_card';
    }
  }

  // Simplified method - no need for authentication checks
  Future<int> _getCurrentStudentId() async {
    // Just return the fixed student ID since we're not using auth
    return 1; // Replace with your actual student ID
  }

  // Add method to get stall ID from cart
  int? _getStallId(Restaurant restaurant) {
    if (restaurant.cart.isEmpty) {
      print('Debug: Cart is empty');
      return null;
    }

    final firstItem = restaurant.cart.first;
    if (firstItem.menu.stallId == null) {
      print('Debug: Stall ID is null for menu item');
      return null;
    }

    return firstItem.menu.stallId;
  }

  // Add navigation methods
  void _nextStep() async {
    if (_currentStep == 0) {
      // Order summary validation
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      if (restaurant.cart.isEmpty) {
        _showErrorSnackbar('Your cart is empty');
        return;
      }
      _moveToNextStep();
    } else if (_currentStep == 1) {
      // Order type selection
      if (_selectedOrderType == null) {
        _showErrorSnackbar('Please select an order type');
        return;
      }
      _moveToNextStep();
    } else if (_currentStep == 2) {
      // Payment method selection
      if (_selectedPaymentMethod == null) {
        _showErrorSnackbar('Please select a payment method');
        return;
      }
      if (_selectedPaymentMethod == PaymentMethod.credit_card) {
        _moveToNextStep();
      } else {
        await _processPayment();
      }
    } else if (_currentStep == 3) {
      // Process payment
      await _processPayment();
    }
  }

  void _moveToNextStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
        // Use animateToPage instead of nextPage for better control
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  // Simplified processing payment without auth checks
  Future<void> _processPayment() async {
    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      final restaurant = Provider.of<Restaurant>(context, listen: false);

      // Validate order first
      if (!_validateOrder(restaurant)) return;

      final shouldProceed = await _showPaymentConfirmationDialog(restaurant);
      if (!shouldProceed || !mounted) return;

      // Show loading overlay
      _showProcessingOverlay();

      // Process with timeout
      bool isSuccess = false;
      try {
        isSuccess = await Future.any([
          _submitTransaction(restaurant),
          Future.delayed(paymentTimeout)
              .then((_) => throw TimeoutException('Payment process timed out')),
        ]);
      } on TimeoutException {
        throw Exception('Payment process timed out. Please try again.');
      }

      if (!mounted) return;

      if (isSuccess) {
        restaurant.clearCart();
        await _showPaymentSuccessDialog();

        if (mounted) {
          // Navigate with fade transition
          await Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const StudentPage(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isPaymentProcessing = false;
        });
        Navigator.of(context).pop(); // Remove loading overlay
      }
    }
  }

  bool _validateOrder(Restaurant restaurant) {
    if (restaurant.cart.isEmpty) {
      _showError('Your cart is empty');
      return false;
    }

    if (_selectedOrderType == OrderType.delivery &&
        restaurant.deliveryAddress.trim().isEmpty) {
      _showError('Please provide a delivery address');
      return false;
    }

    return true;
  }

  void _showProcessingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const LoadingOverlay(
          isLoading: true,
          message: 'Processing your payment...\nPlease wait',
          child: SizedBox.shrink(), // Add required child parameter
        ),
      ),
    );
  }

  void _handleError(dynamic error) {
    String message = ErrorHandler.getErrorMessage(error);
    _showError(message);

    // Log error for debugging
    print('Payment Error: $error');
  }

  void _showError(String message) {
    if (!mounted) return;

    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => _scaffoldKey.currentState?.hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // Improved transaction submission
  Future<bool> _submitTransaction(Restaurant restaurant) async {
    try {
      final stallId = _getStallId(restaurant);
      if (stallId == null) throw Exception('Invalid stall ID');

      final studentId = await _getCurrentStudentId();

      final transactionId = await _transactionService.createTransaction(
        studentId: studentId,
        stallId: stallId,
        totalAmount: restaurant.calculateSubtotal(),
        orderType: _selectedOrderType,
        deliveryAddress: _selectedOrderType == OrderType.delivery
            ? restaurant.deliveryAddress
            : null,
        notes: noteController.text,
        items: restaurant.cart,
      );

      // Update transaction payment (fix type by converting to String)
      await _transactionService.updateTransactionPayment(
        transactionId,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: _selectedPaymentMethod,
      );

      _transactionId =
          transactionId.toString(); // Convert to String when storing

      return true;
    } catch (e) {
      throw Exception('Failed to process payment: ${e.toString()}');
    }
  }

  // Add navigation methods
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        // Use animateToPage instead of previousPage for better control
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  // Add this method for showing errors
  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Add this method for showing success dialog
  Future<void> _showPaymentSuccessDialog() async {
    if (!mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Payment Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text('Your payment has been processed successfully.'),
              const Text('Your order is being prepared.'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method for payment confirmation
  Future<bool> _showPaymentConfirmationDialog(Restaurant restaurant) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to proceed with payment?'),
            const SizedBox(height: 16),
            Text(
              'Total: Rp ${restaurant.calculateSubtotal().toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Payment Method: ${_getPaymentTitle(_selectedPaymentMethod)}'),
            if (_selectedOrderType == OrderType.delivery) ...[
              const SizedBox(height: 8),
              Text('Delivery to: ${restaurant.deliveryAddress}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isPaymentProcessing) {
      return _buildProcessingScreen();
    }

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          elevation: 0,
        ),
        body: _isProcessing
            ? _buildProcessingState()
            : Column(
                children: [
                  _buildStepIndicator(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        // Keep step indicator in sync with page changes
                        setState(() => _currentStep = index);
                      },
                      children: [
                        _buildOrderSummaryPage(),
                        _buildOrderTypePage(),
                        _buildPaymentMethodPage(),
                        if (_selectedPaymentMethod == PaymentMethod.credit_card)
                          _buildPaymentDetailsPage(),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepIcon(0, 'Order'),
          _buildStepLine(),
          _buildStepIcon(1, 'Type'),
          _buildStepLine(),
          _buildStepIcon(2, 'Payment'),
          _buildStepLine(),
          _buildStepIcon(3, 'Confirm'),
        ],
      ),
    );
  }

  Widget _buildStepIcon(int step, String label) {
    final isActive = _currentStep >= step;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                isActive ? Theme.of(context).primaryColor : Colors.grey[300],
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  isActive ? Theme.of(context).primaryColor : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey[300],
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildOrderSummaryPage() {
    return Consumer<Restaurant>(
      builder: (context, restaurant, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Delivery To'),
          _buildDeliveryCard(restaurant),
          const SizedBox(height: 16),
          _buildSectionTitle('Order Summary'),
          ...restaurant.cart.map((item) => _buildOrderItem(item)),
          const SizedBox(height: 16),
          _buildPriceSummary(restaurant),
        ],
      ),
    );
  }

  Widget _buildOrderTypePage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Select Order Type'),
        const SizedBox(height: 16),
        Column(
          children: OrderType.values.map((type) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _getOrderTypeIcon(type),
                title: Text(_getOrderTypeTitle(type)),
                subtitle: Text(_getOrderTypeDescription(type)),
                trailing: _selectedOrderType == type
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).primaryColor)
                    : null,
                selected: _selectedOrderType == type,
                onTap: () {
                  setState(() => _selectedOrderType = type);
                  _moveToNextStep();
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _getOrderTypeIcon(OrderType type) {
    IconData icon;
    Color color;
    switch (type) {
      case OrderType.delivery:
        icon = Icons.delivery_dining;
        color = Colors.blue;
        break;
      case OrderType.pickup:
        icon = Icons.store;
        color = Colors.green;
        break;
      case OrderType.dine_in:
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  String _getOrderTypeTitle(OrderType type) {
    switch (type) {
      case OrderType.delivery:
        return 'Delivery';
      case OrderType.pickup:
        return 'Self Pickup';
      case OrderType.dine_in:
        return 'Dine In';
    }
  }

  String _getOrderTypeDescription(OrderType type) {
    switch (type) {
      case OrderType.delivery:
        return 'We\'ll deliver to your location';
      case OrderType.pickup:
        return 'Pick up your order at the counter';
      case OrderType.dine_in:
        return 'Eat at the canteen';
    }
  }

  Widget _buildPaymentMethodPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Select Payment Method'),
        const SizedBox(height: 16),
        Column(
          children: PaymentMethod.values.map((method) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: _getPaymentIcon(method),
                title: Text(_getPaymentTitle(method)),
                subtitle: Text(_getPaymentDescription(method)),
                trailing: _selectedPaymentMethod == method
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).primaryColor)
                    : null,
                selected: _selectedPaymentMethod == method,
                onTap: () {
                  setState(() => _selectedPaymentMethod = method);
                  // Only move to next step if credit card is not selected
                  // For credit card, user needs to fill in details
                  if (method != PaymentMethod.credit_card) {
                    _moveToNextStep();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getPaymentIcon(method),
        title: Text(_getPaymentTitle(method)),
        subtitle: Text(_getPaymentDescription(method)),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
            : null,
        selected: isSelected,
        onTap: () => setState(() => _selectedPaymentMethod = method),
      ),
    );
  }

  Widget _getPaymentIcon(PaymentMethod method) {
    IconData icon;
    Color color;
    switch (method) {
      case PaymentMethod.cash:
        icon = Icons.money;
        color = Colors.green;
        break;
      case PaymentMethod.e_wallet:
        icon = Icons.account_balance_wallet;
        color = Colors.blue;
        break;
      case PaymentMethod.bank_transfer:
        icon = Icons.account_balance;
        color = Colors.purple;
        break;
      case PaymentMethod.credit_card:
        icon = Icons.credit_card;
        color = Colors.red;
        break;
    }
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color),
    );
  }

  String _getPaymentTitle(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash Payment';
      case PaymentMethod.e_wallet:
        return 'E-Wallet';
      case PaymentMethod.bank_transfer:
        return 'Bank Transfer';
      case PaymentMethod.credit_card:
        return 'Credit Card';
    }
  }

  String _getPaymentDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Pay with cash on delivery';
      case PaymentMethod.e_wallet:
        return 'Pay using digital wallet';
      case PaymentMethod.bank_transfer:
        return 'Pay via bank transfer';
      case PaymentMethod.credit_card:
        return 'Pay with credit card';
    }
  }

  Widget _buildProcessingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Processing your payment...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Please do not close this page',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isProcessing) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<Restaurant>(
              builder: (context, restaurant, _) => Text(
                'Total: Rp ${restaurant.calculateSubtotal().toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _nextStep, // Changed from _processPayment to _nextStep
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(_currentStep == 3 ? 'Pay Now' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Information',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 20),
        ScaleTransition(
          scale: _animation,
          child: CreditCardWidget(
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            cardHolderName: cardHolderName,
            cvvCode: cvvCode,
            showBackView: isCvvFocused,
            onCreditCardWidgetChange: (p0) {},
          ),
        ),
        const SizedBox(height: 20),
        CreditCardForm(
          cardNumber: cardNumber,
          expiryDate: expiryDate,
          cardHolderName: cardHolderName,
          cvvCode: cvvCode,
          onCreditCardModelChange: (data) {
            setState(() {
              cardNumber = data.cardNumber;
              expiryDate = data.expiryDate;
              cardHolderName = data.cardHolderName;
              cvvCode = data.cvvCode;
            });
          },
          formKey: formKey,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPaymentDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Payment Details'),
          const SizedBox(height: 16),
          _buildCreditCardSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildDeliveryCard(Restaurant restaurant) {
    if (_selectedOrderType != OrderType.delivery) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    restaurant.deliveryAddress,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Show address picker modal
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      builder: (context) =>
                          _buildAddressPickerModal(restaurant),
                    );
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.menu.photo != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.menu.photo!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menu.foodName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (item.selectedAddons.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Add-ons: ${item.selectedAddons.map((a) => a.addonName).join(", ")}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.quantity}x',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Rp ${item.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(Restaurant restaurant) {
    final subtotal = restaurant.calculateSubtotal();
    final deliveryFee = 2000.0; // Example delivery fee
    final total = subtotal + deliveryFee;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', subtotal),
            _buildPriceRow('Delivery Fee', deliveryFee),
            const Divider(height: 16),
            _buildPriceRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressPickerModal(Restaurant restaurant) {
    final addressController =
        TextEditingController(text: restaurant.deliveryAddress);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Delivery Address',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: addressController,
            decoration: const InputDecoration(
              labelText: 'Enter delivery address',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  restaurant.updateDeliveryAddress(addressController.text);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isPaymentConfirmed) ...[
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Processing Payment...',
                style: TextStyle(fontSize: 20),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Please do not close this page',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
