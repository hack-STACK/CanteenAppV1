import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode; // Add this import
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:kantin/Models/menu_cart_item.dart';
import 'package:kantin/Models/payment_errors.dart' as payment_errors;
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/Services/Database/transaction_details_service.dart';
import 'package:kantin/pages/StudentState/StudentPage.dart';
// Hide ambiguous classes
import 'package:kantin/utils/logger.dart';
import 'package:provider/provider.dart';
import 'package:kantin/Models/Restaurant.dart';
import 'package:kantin/Services/Database/transaction_service.dart';
import 'package:kantin/models/enums/transaction_enums.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:kantin/utils/error_handler.dart' hide TransactionError;
import 'package:kantin/widgets/loading_overlay.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kantin/utils/image_helper.dart';
import 'package:kantin/models/enums/payment_method_extension.dart';
import 'package:kantin/models/enums/order_type_extension.dart';
import 'package:kantin/widgets/badges/discount_badge.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

class PaymentPage extends StatefulWidget {
  final int StudentId; // Make this non-nullable

  const PaymentPage({
    super.key,
    required this.StudentId, // Required parameter
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage>
    with SingleTickerProviderStateMixin {
  // Initialize controllers and animation properly
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late final PageController _pageController;

  // Initialize form-related variables
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  // Initialize state variables with default values
  bool isLoading = false;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.e_wallet;
  OrderType _selectedOrderType = OrderType.delivery;
  String? _errorMessage;
  bool _isLoadingStudentData = false;
  Map<String, dynamic>? _studentData;
  int _currentStep = 0;

  final TransactionService _transactionService = TransactionService();
  final bool _isProcessing = false;

  // Add the missing controller
  final TextEditingController noteController = TextEditingController();

  final _supabase = Supabase.instance.client;

  // Add new properties for UI state
  final bool _isPaymentConfirmed = false;
  bool _isPaymentProcessing = false;

  // Update steps number and names
  final List<String> _steps = ['Order', 'Type', 'Payment', 'Confirm'];

  // Add timeout duration constant
  static const paymentTimeout = Duration(seconds: 30);

  // Add new properties
  bool _isSubmitting = false;
  String? _transactionId;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  // Add logger
  final _logger = Logger();

  // Add retry mechanism
  int _retryAttempts = 0;
  static const maxRetryAttempts = 3;

  // Add transaction logging
  String? _transactionLog;

  // Add controller at class level
  late TextEditingController _addressController;

  final StudentService _studentService = StudentService();

  final TransactionDetailsService _detailsService = TransactionDetailsService();

  @override
  void initState() {
    super.initState();

    _logger
        .info('Initializing PaymentPage with StudentId: ${widget.StudentId}');

    // Initialize controllers
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(_controller);

    _pageController = PageController(initialPage: 0);

    _addressController = TextEditingController();

    // Load initial data
    _loadStudentData();
    _loadStudentAddress();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    _isSubmitting = false;
    _isPaymentProcessing = false;

    // Dispose controllers
    noteController.dispose();
    _controller.dispose();
    _pageController.dispose();
    _addressController.dispose();

    super.dispose();
  }

  // Update the _getStallId method
  int _getStallId(Restaurant restaurant) {
    _logger.debug('Getting stall ID from cart items');

    if (restaurant.cart.isEmpty) {
      _logger.error('Cannot get stall ID: Cart is empty');
      throw Exception('Your cart is empty');
    }

    // Get and validate the first item's stall ID
    final firstItem = restaurant.cart.first;

    final stallId = firstItem.menu.stallId;
    _logger.debug('First item stall ID: $stallId');

    // Validate stall ID
    if (stallId <= 0) {
      _logger.error('Invalid stall ID: $stallId');
      throw Exception('Invalid stall configuration. Please contact support.');
    }

    // Verify all items are from the same stall
    for (var item in restaurant.cart) {
      if (item.menu.stallId != stallId) {
        _logger.error(
            'Cart contains items from different stalls or invalid items');
        throw Exception('All items must be from the same stall');
      }
      _logger.debug('Checking item stall ID: ${item.menu.stallId}');
    }

    _logger.info('Successfully validated stall ID: $stallId');
    return stallId;
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
      // Order type selection and validation
      final restaurant = Provider.of<Restaurant>(context, listen: false);
      if (_selectedOrderType == OrderType.delivery &&
          (restaurant.deliveryAddress.isEmpty ||
              restaurant.deliveryAddress.trim().isEmpty)) {
        _showError('Please provide a delivery address');
        return;
      }
      _moveToNextStep();
    } else if (_currentStep == 2) {
      // Payment method selection
      if (_selectedPaymentMethod == PaymentMethod.credit_card) {
        _moveToNextStep();
      } else {
        await _processPayment();
      }
    } else if (_currentStep == 3) {
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
    if (!mounted) return;

    final navigationContext = context; // Capture context early
    final restaurant = Provider.of<Restaurant>(context, listen: false);

    // Show confirmation dialog first
    final shouldProceed = await _showPaymentConfirmationDialog(restaurant);
    if (!shouldProceed || !mounted) return;

    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      // Rest of the payment processing code...
      // Show loading overlay using captured context
      if (!mounted) return;
      _showProcessingOverlay(navigationContext);

      // Process with timeout
      bool isSuccess = false;
      try {
        isSuccess = await Future.any([
          _submitTransaction(restaurant),
          Future.delayed(paymentTimeout)
              .then((_) => throw TimeoutException('Payment process timed out')),
        ]);
      } on TimeoutException {
        if (mounted) {
          Navigator.of(navigationContext).pop(); // Remove overlay
        }
        throw Exception('Payment process timed out. Please try again.');
      }

      // Always check mounted state before UI updates
      if (!mounted) return;

      // Close loading overlay
      Navigator.of(navigationContext).pop();

      if (isSuccess) {
        restaurant.clearCart();

        if (!mounted) return;
        await _showPaymentSuccessDialog(navigationContext);

        if (!mounted) return;
        // Use captured context for final navigation
        await Navigator.pushReplacement(
          navigationContext,
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
    } catch (e) {
      if (mounted) {
        Navigator.of(navigationContext).pop(); // Remove overlay
        _handleError(e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isPaymentProcessing = false;
        });
      }
    }
  }

  bool _validateOrder(Restaurant restaurant) {
    if (restaurant.cart.isEmpty) {
      _showErrorSnackbar('Your cart is empty');
      return false;
    }

    if (_selectedOrderType == OrderType.delivery &&
        restaurant.deliveryAddress.trim().isEmpty) {
      _showError('Please provide a delivery address');
      return false;
    }

    return true;
  }

  // Update overlay show method to accept context
  void _showProcessingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: LoadingOverlay(
          isLoading: true,
          message: _transactionLog ?? 'Processing your payment...\nPlease wait',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator().animate().fadeIn().scale(),
              if (_transactionLog != null)
                Text(_transactionLog!).animate().fadeIn().slideY(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleError(dynamic error) {
    final message = ErrorHandler.getErrorMessage(error);
    _logger.error('Payment Error', error);

    String displayMessage;
    if (error is PostgrestException) {
      displayMessage = 'Database error: ${error.message}';
    } else if (error is payment_errors.PaymentError) {
      displayMessage = error.message;
    } else {
      displayMessage = message;
    }

    _showErrorDialog(
      title: 'Payment Failed',
      message: displayMessage,
      error: error,
      retryAction: error is! TimeoutException ? _retryPayment : null,
    );
  }

  Future<void> _retryPayment() async {
    if (_retryAttempts >= maxRetryAttempts) {
      _showError('Maximum retry attempts reached. Please try again later.');
      return;
    }

    _retryAttempts++;
    await _processPayment();
  }

  Future<bool> _submitTransaction(Restaurant restaurant) async {
    try {
      _logger.info('Starting transaction submission');
      setState(() => _transactionLog = 'Initializing transaction...');

      // Validate payment method
      if (_selectedPaymentMethod == null) {
        throw payment_errors.PaymentValidationError(
          message: 'Payment method must be selected',
        );
      }

      _logger.debug('Selected payment method: ${_selectedPaymentMethod.name}');

      // Calculate total amount
      final totalAmount = await _calculateFinalTotal(restaurant);

      // Validate total amount
      if (totalAmount <= 0) {
        throw payment_errors.PaymentValidationError(
          message: 'Invalid total amount',
        );
      }

      // Create transaction with payment method
      final response = await _supabase
          .from('transactions')
          .insert({
            'student_id': widget.StudentId,
            'stall_id': _getStallId(restaurant),
            'status': TransactionStatus.pending.name,
            'payment_status': PaymentStatus.unpaid.name,
            'payment_method': _selectedPaymentMethod.name
                .toLowerCase(), // Ensure lowercase for DB enum
            'total_amount': totalAmount,
            'order_type': _selectedOrderType.name
                .toLowerCase(), // Ensure lowercase for DB enum
            'delivery_address': _selectedOrderType == OrderType.delivery
                ? restaurant.deliveryAddress
                : null,
          })
          .select()
          .single();

      _logger.info('Transaction created successfully: ${response['id']}');

      // Create transaction details
      await _detailsService.createTransactionDetails(
        response['id'],
        _ensureValidMenuItems(restaurant.cart),
      );

      return true;
    } catch (e) {
      _logger.error('Transaction error:', e);
      if (e is PostgrestException) {
        _logger.error('Supabase error details:', {
          'message': e.message,
          'details': e.details,
        });
      }
      rethrow;
    }
  }

  // Add payment method validation
  bool _validatePaymentMethod(PaymentMethod method) {
    final validMethods = ['cash', 'e_wallet', 'bank_transfer', 'credit_card'];
    return validMethods.contains(method.name.toLowerCase());
  }

  // Update the payment method selection handler
  void _handlePaymentMethodSelection(PaymentMethod method) {
    if (!_validatePaymentMethod(method)) {
      _showError('Invalid payment method selected');
      return;
    }

    setState(() => _selectedPaymentMethod = method);
    _logger.debug('Payment method selected: ${method.name}');
  }

  Future<int> _createTransactionWithRetry(
    Restaurant restaurant,
    int stallId,
  ) async {
    int attempts = 0;
    late int transactionId;

    while (attempts < maxRetryAttempts) {
      try {
        setState(() => _transactionLog =
            'Creating transaction (Attempt ${attempts + 1})...');

        // Prepare transaction details with proper pricing
        final transactionDetails =
            await _prepareTransactionDetails(restaurant.cart);

        transactionId = await _transactionService.createTransaction(
          studentId: widget.StudentId,
          stallId: stallId,
          totalAmount: await _calculateFinalTotal(restaurant),
          orderType: _selectedOrderType, // This is correct, keep as enum
          deliveryAddress: _selectedOrderType == OrderType.delivery
              ? restaurant.deliveryAddress
              : null,
          notes: noteController.text,
          details: transactionDetails,
        );

        _logger.info('Transaction created successfully: $transactionId');
        return transactionId;
      } catch (e) {
        attempts++;
        _logger.warn('Transaction attempt $attempts failed: $e');

        if (attempts >= maxRetryAttempts) {
          throw payment_errors.TransactionError(
            message:
                'Failed to create transaction after $maxRetryAttempts attempts',
            originalError: e,
          );
        }

        await Future.delayed(Duration(seconds: attempts));
      }
    }

    throw payment_errors.TransactionError(
        message: 'Transaction creation failed');
  }

  Future<void> _updatePaymentStatus(int transactionId) async {
    try {
      setState(() => _transactionLog = 'Processing payment...');
      await _transactionService.updateTransactionPayment(
        transactionId,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: _selectedPaymentMethod,
      );
    } catch (e) {
      throw payment_errors.TransactionError(
        message: 'Failed to update payment status',
        originalError: e,
      );
    }
  }

  void _handlePaymentError(payment_errors.PaymentError error) {
    String userMessage;
    bool canRetry = true;

    switch (error.code) {
      case 'VALIDATION_ERROR':
        userMessage = error.message;
        canRetry = false;
        break;
      case 'STALL_ERROR':
        userMessage = 'There was a problem with the stall configuration. '
            'Please try again or contact support.';
        break;
      case 'TRANSACTION_ERROR':
        userMessage = 'Failed to process transaction. Please try again.';
        break;
      default:
        userMessage = 'An unexpected error occurred. Please try again.';
    }

    _showErrorDialog(
      title: 'Payment Failed',
      message: userMessage,
      error: error,
      retryAction: canRetry ? _retryPayment : null,
    );
  }

  // Remove duplicate _showErrorDialog and keep only one version
  void _showErrorDialog({
    required String title,
    required String message,
    dynamic error,
    VoidCallback? retryAction,
  }) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48)
                .animate()
                .shake(),
            const SizedBox(height: 16),
            Text(message),
            if (error != null && !kReleaseMode) ...[
              const SizedBox(height: 16),
              const Text(
                'Technical Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (error is payment_errors.PaymentError &&
              error.code == 'STALL_ERROR')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Add method to contact support
              },
              child: const Text('Contact Support'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (retryAction != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                retryAction();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  List<CartItem> _mapCartItems(List<CartItem> cart) {
    return cart
        .map((item) => CartItem(
              menu: item.menu,
              quantity: item.quantity,
              selectedAddons: item.selectedAddons,
              note: item.note,
              originalPrice: item.originalPrice,
              discountedPrice: item.discountedPrice,
            ))
        .toList();
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
  void _showError(String message) {
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
  Future<void> _showPaymentSuccessDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Payment Successful'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method for payment confirmation
  Future<bool> _showPaymentConfirmationDialog(Restaurant restaurant) async {
    double subtotal = 0;
    double totalDiscount = 0;

    for (var item in restaurant.cart) {
      double originalPrice = item.menu.price * item.quantity;
      double effectivePrice = item.discountedPrice ?? originalPrice;

      subtotal += originalPrice;
      if (effectivePrice < originalPrice) {
        totalDiscount += (originalPrice - effectivePrice);
      }
    }

    final deliveryFee = _selectedOrderType == OrderType.delivery ? 2000.0 : 0.0;
    final total = subtotal - totalDiscount + deliveryFee;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Confirm Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure you want to proceed with payment?'),
                const SizedBox(height: 16),
                _buildPriceRow('Subtotal', subtotal),
                if (totalDiscount > 0)
                  _buildPriceRow('Discounts', -totalDiscount,
                      textColor: Colors.green),
                if (_selectedOrderType == OrderType.delivery)
                  _buildPriceRow('Delivery Fee', deliveryFee),
                const Divider(height: 8),
                _buildPriceRow('Total', total, isTotal: true),
                const SizedBox(height: 8),
                Text('Payment Method: ${_selectedPaymentMethod.label}'),
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
        ) ??
        false;
  }

  // Ensure proper null checks in build method
  @override
  Widget build(BuildContext context) {
    // Optimize theme access
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        // Custom theme for payment page
        cardTheme: CardTheme(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: Colors.black26,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: colorScheme.surface,
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _isLoadingStudentData
            ? const LoadingOverlay(
                isLoading: true,
                child: Center(child: CircularProgressIndicator()),
              )
            : SafeArea(
                child: Column(
                  children: [
                    _buildStepIndicator().animate().slideY(
                          begin: -1,
                          end: 0,
                          curve: Curves.easeOutBack,
                          duration: const Duration(milliseconds: 600),
                        ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() => _currentStep = index);
                        },
                        children: [
                          _buildOrderSummaryPage(),
                          _buildOrderTypePage(),
                          _buildPaymentMethodPage(),
                          if (_selectedPaymentMethod ==
                              PaymentMethod.credit_card)
                            _buildPaymentDetailsPage(),
                        ].map((page) => _buildPageTransition(page)).toList(),
                      ),
                    ),
                  ],
                ),
              ),
        bottomNavigationBar: _buildBottomBar(),
      ),
    );
  }

  Widget _buildPageTransition(Widget page) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: page.animate().fadeIn(
              duration: const Duration(milliseconds: 400),
            ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'Checkout',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _steps[_currentStep],
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: () {
          if (_currentStep > 0) {
            _previousStep();
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: _currentStep >= i
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                ).animate().fadeIn(),
              ),
            _buildStepDot(i),
          ],
        ],
      ),
    ).animate().slideY(
          begin: -1,
          end: 0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
  }

  Widget _buildStepDot(int step) {
    final isCompleted = _currentStep > step;
    final isActive = _currentStep >= step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[300],
            border: Border.all(
              color:
                  isActive ? Theme.of(context).primaryColor : Colors.grey[400]!,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(
                    Icons.check,
                    size: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  )
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ).animate().scale(),
        const SizedBox(height: 4),
        Text(
          _steps[step],
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryPage() {
    return Consumer<Restaurant>(
      builder: (context, restaurant, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Order Summary', Icons.receipt_long),
          const SizedBox(height: 16),
          ...restaurant.cart.map((item) => _buildEnhancedOrderItem(item)),
          const SizedBox(height: 24),
          _buildSectionHeader('Delivery Details', Icons.location_on),
          const SizedBox(height: 16),
          _buildEnhancedDeliveryCard(restaurant),
          const SizedBox(height: 24),
          _buildEnhancedPriceSummary(restaurant),
        ],
      ),
    );
  }

  Widget _buildOrderTypePage() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Select Order Type', Icons.local_shipping),
          const SizedBox(height: 16),
          ...OrderType.values.map((type) {
            final isSelected = _selectedOrderType == type;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                elevation: isSelected ? 2 : 1,
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedOrderType = type);
                    _moveToNextStep();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: type.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            type.icon,
                            color: type.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodPage() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Select Payment Method', Icons.payment),
          const SizedBox(height: 16),
          ...PaymentMethod.values.map((method) {
            final isSelected = _selectedPaymentMethod == method;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                elevation: isSelected ? 2 : 1,
                child: InkWell(
                  onTap: () => _handlePaymentMethodSelection(method),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: method.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            method.icon,
                            color: method.color,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                method.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
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
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<Restaurant>(
              builder: (context, restaurant, _) {
                // Calculate the correct total including all components
                double subtotal = 0.0;
                double totalDiscount = 0.0;

                // Calculate per item
                for (var item in restaurant.cart) {
                  final originalTotal = item.originalPrice * item.quantity;
                  final discountedTotal = item.discountedPrice * item.quantity;

                  // Add addon costs
                  final addonTotal = item.selectedAddons.fold(
                      0.0, (sum, addon) => sum + (addon.price * item.quantity));

                  subtotal += discountedTotal +
                      addonTotal; // Include addons in subtotal
                  totalDiscount += originalTotal - discountedTotal;
                }

                // Add delivery fee if applicable
                final deliveryFee =
                    _selectedOrderType == OrderType.delivery ? 2000.0 : 0.0;
                final finalTotal = subtotal + deliveryFee;

                print('''
=== Bottom Bar Calculation Debug ===
Subtotal: $subtotal
Total Discount: $totalDiscount
Delivery Fee: $deliveryFee
Final Total: $finalTotal
===============================
''');

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Rp ${finalTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
            Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: _previousStep,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: Icon(_currentStep == 3
                        ? Icons.payment
                        : Icons.arrow_forward),
                    label: Text(_currentStep == 3 ? 'Pay Now' : 'Next'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                      .animate(target: _isProcessing ? 0 : 1)
                      .scaleXY(begin: 1, end: 1.05)
                      .shimmer(duration: const Duration(seconds: 2)),
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
                  onPressed: () => _showAddressPickerModal(restaurant),
                  child: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddressPickerModal(Restaurant restaurant) async {
    if (!mounted) return;

    // Set initial value
    _addressController.text = restaurant.deliveryAddress;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext modalContext) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Delivery Address',
                style: Theme.of(modalContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Enter delivery address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(modalContext),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final newAddress = _addressController.text.trim();
                      if (newAddress.isNotEmpty) {
                        // Update the address in provider
                        Provider.of<Restaurant>(context, listen: false)
                            .updateDeliveryAddress(newAddress);
                        Navigator.pop(modalContext);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    final hasDiscount = item.discountedPrice < item.originalPrice;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'food_${item.menu.id}',
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              image: DecorationImage(
                image: NetworkImage(item.menu.photo ?? ''),
                fit: BoxFit.cover,
                onError: (_, __) => Icon(
                  Icons.restaurant,
                  color: Colors.grey[400],
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          item.menu.foodName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildQuantityBadge(item.quantity),
                if (hasDiscount) ...[
                  const SizedBox(width: 8),
                  _buildDiscountBadge(item),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasDiscount)
              Text(
                'Rp ${item.originalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            Text(
              'Rp ${item.discountedPrice.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hasDiscount
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
            ),
          ],
        ),
        children: [
          if (item.selectedAddons.isNotEmpty) _buildAddonsSection(item),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildQuantityBadge(int quantity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$quantity',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountBadge(CartItem item) {
    final discount =
        ((item.originalPrice - item.discountedPrice) / item.originalPrice * 100)
            .round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            '$discount% OFF',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonsSection(CartItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Row(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Add-ons',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...item.selectedAddons.map((addon) {
          final addonTotal = addon.price * item.quantity;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        addon.addonName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Rp ${addon.price.toStringAsFixed(0)} × ${item.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rp ${addonTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPriceSummary(Restaurant restaurant) {
    double subtotal = 0;
    double totalDiscount = 0;

    // Calculate subtotal and discounts
    for (var item in restaurant.cart) {
      double originalPrice = item.menu.price * item.quantity;
      double effectivePrice = item.discountedPrice ?? originalPrice;

      subtotal += originalPrice;
      if (effectivePrice < originalPrice) {
        totalDiscount += (originalPrice - effectivePrice);
      }
    }

    final deliveryFee = _selectedOrderType == OrderType.delivery ? 2000.0 : 0.0;
    final total = subtotal - totalDiscount + deliveryFee;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', subtotal),
            if (totalDiscount > 0)
              _buildPriceRow('Discounts', -totalDiscount,
                  textColor: Colors.green),
            if (_selectedOrderType == OrderType.delivery)
              _buildPriceRow('Delivery Fee', deliveryFee),
            const Divider(height: 16),
            _buildPriceRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount,
      {bool isTotal = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: textColor,
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

  // Ensure safe state updates
  Future<void> _loadStudentData() async {
    if (!mounted) return;

    setState(() => _isLoadingStudentData = true);

    try {
      final data = await _supabase
          .from('students')
          .select('*, user:id_user (*)')
          .eq('id', widget.StudentId)
          .single();

      if (!mounted) return;

      setState(() {
        _studentData = data;
        _isLoadingStudentData = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load student data: ${e.toString()}';
        _isLoadingStudentData = false;
      });
    }
  }

  Future<void> _loadStudentAddress() async {
    try {
      final student = await _studentService.getStudentById(widget.StudentId);
      if (student != null && mounted) {
        final restaurant = Provider.of<Restaurant>(context, listen: false);
        if (restaurant.deliveryAddress.isEmpty) {
          restaurant.updateDeliveryAddress(student.studentAddress);
        }
      }
    } catch (e) {
      _logger.error('Error loading student address', e);
    }
  }

  Future<List<Map<String, dynamic>>> _prepareTransactionDetails(
      List<CartItem> cart) async {
    return _detailsService.prepareTransactionDetails(
      cart,
      enableDebug: !kReleaseMode,
    );
  }

  Widget _buildEnhancedOrderItem(CartItem item) {
    // Avoid unnecessary rebuilds by using const where possible
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          title: Row(
            children: [
              Stack(
                children: [
                  _buildFoodImage(item),
                  if (item.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: DiscountBadge(
                        discountPercentage: item.discountPercentage.toDouble(),
                        compact: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.menu.foodName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildPriceDisplay(item),
                    const SizedBox(height: 4),
                    _buildQuantityIndicator(item),
                  ],
                ),
              ),
            ],
          ),
          children: [
            if (item.selectedAddons.isNotEmpty)
              _buildEnhancedAddonsSection(item),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage(CartItem item) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageHelper.loadImage(
          item.menu.photo,
          width: 80,
          height: 80,
        ),
      ),
    );
  }

  Widget _buildEnhancedPriceSummary(Restaurant restaurant) {
    // Calculate correct totals
    double subtotal = 0.0;
    double totalDiscount = 0.0;

    print('\n=== Summary Calculation Debug ===');

    for (var item in restaurant.cart) {
      // Calculate per item
      final originalTotal = item.originalPrice * item.quantity;
      final discountedTotal = item.discountedPrice * item.quantity;

      // Add addon costs to discounted total
      final addonTotal = item.selectedAddons
          .fold(0.0, (sum, addon) => sum + (addon.price * item.quantity));

      subtotal += discountedTotal + addonTotal; // Include addons in subtotal
      totalDiscount += originalTotal - discountedTotal;

      print('Item: ${item.menu.foodName}');
      print('Original Total: $originalTotal');
      print('Discounted Total: $discountedTotal');
      print('Addon Total: $addonTotal');
      print('Item Savings: ${originalTotal - discountedTotal}');
    }

    final deliveryFee = _selectedOrderType == OrderType.delivery ? 2000.0 : 0.0;
    final finalTotal = subtotal + deliveryFee;

    print('Summary:');
    print('Subtotal (with addons): $subtotal');
    print('Total Discount: $totalDiscount');
    print('Delivery Fee: $deliveryFee');
    print('Final Total: $finalTotal');
    print('===========================\n');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal),
          if (totalDiscount > 0)
            _buildSummaryRow(
              'Discount',
              -totalDiscount,
              textColor: Colors.green,
            ),
          if (_selectedOrderType == OrderType.delivery)
            _buildSummaryRow('Delivery Fee', deliveryFee),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: DashedDivider(),
          ),
          _buildSummaryRow(
            'Total',
            finalTotal,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  // Add new widgets...
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildEnhancedDeliveryCard(Restaurant restaurant) {
    if (_selectedOrderType != OrderType.delivery) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restaurant.deliveryAddress.isEmpty
                      ? 'Add delivery address'
                      : restaurant.deliveryAddress,
                  style: TextStyle(
                    fontSize: 16,
                    color: restaurant.deliveryAddress.isEmpty
                        ? Colors.grey
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddressPickerModal(restaurant),
                icon: const Icon(Icons.edit),
                label: const Text('Change'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(CartItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.hasDiscount) ...[
          Row(
            children: [
              DiscountBadge(
                discountPercentage: item.discountPercentage.toDouble(),
                compact: true,
              ),
              const SizedBox(width: 8),
              Text(
                'Rp ${item.originalPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
        Text(
          'Rp ${item.discountedPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: item.hasDiscount
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityIndicator(CartItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '${item.quantity}x',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isTotal = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAddonsSection(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add-ons',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...item.selectedAddons.map((addon) {
            final addonTotal = addon.price * item.quantity;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon.addonName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rp ${addon.price.toStringAsFixed(0)} × ${item.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rp ${addonTotal.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (item.note?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Add this method inside the _PaymentPageState class
  Future<double> _calculateFinalTotal(Restaurant restaurant) async {
    double subtotal = 0.0;
    double totalDiscount = 0.0;

    if (kReleaseMode == false) {
      print('\n=== Final Total Calculation Debug ===');
    }

    // Calculate per item including addons and discounts
    for (var item in restaurant.cart) {
      final originalTotal = item.originalPrice * item.quantity;
      final discountedTotal = item.discountedPrice * item.quantity;

      // Calculate addon total for this item
      final addonTotal = item.selectedAddons.fold(
        0.0,
        (sum, addon) => sum + (addon.price * item.quantity),
      );

      subtotal += discountedTotal + addonTotal;
      totalDiscount += originalTotal - discountedTotal;

      if (kReleaseMode == false) {
        print('Item: ${item.menu.foodName}');
        print('Original Total: $originalTotal');
        print('Discounted Total: $discountedTotal');
        print('Addon Total: $addonTotal');
        print('Item Discount: ${originalTotal - discountedTotal}');
      }
    }

    // Add delivery fee if applicable
    final deliveryFee = _selectedOrderType == OrderType.delivery ? 2000.0 : 0.0;
    final finalTotal = subtotal + deliveryFee;

    if (kReleaseMode == false) {
      print('Summary:');
      print('Subtotal (with addons): $subtotal');
      print('Total Discount: $totalDiscount');
      print('Delivery Fee: $deliveryFee');
      print('Final Total: $finalTotal');
      print('===========================\n');
    }

    return finalTotal;
  }

  // Add this method before the build method
  List<CartItem> _ensureValidMenuItems(List<CartItem> items) {
    return items.map((item) {
      if (item.menu.foodName.trim().isEmpty) {
        throw payment_errors.PaymentValidationError(
          message: 'Menu name is required for all items',
        );
      }
      return item;
    }).toList();
  }
}

// Add new DashedDivider widget
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        final dashCount = (width / (dashWidth + dashSpace)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (index) => Container(
              width: dashWidth,
              height: 1,
              color: Colors.grey[300],
            ),
          ),
        );
      },
    );
  }
}
