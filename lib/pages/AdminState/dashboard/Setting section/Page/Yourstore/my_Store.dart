import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/discount.dart';
import 'package:kantin/Models/menus.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/foodService.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kantin/pages/AdminState/dashboard/Addmenu.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Page/apply_discount_screen.dart';
import 'package:kantin/pages/AdminState/dashboard/Setting%20section/Page/profile_screen/edit_profile_screen.dart';
import 'package:kantin/pages/menu/menu_details_screen.dart';
import 'package:kantin/services/database/discountService.dart';
import 'package:kantin/widgets/add_discount_form.dart';
import 'package:kantin/widgets/edit_discount_dialog.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kantin/Models/menus_addon.dart';
import 'package:kantin/Services/store_service.dart';
import 'package:kantin/widgets/loading_overlay.dart';
import 'package:kantin/widgets/addon_dialog.dart';
import 'package:kantin/widgets/addon_card.dart';
import 'package:kantin/utils/menu_state_manager.dart';
import 'package:intl/intl.dart' as intl;
import 'dart:async';

class MyStorePage extends StatefulWidget {
  final int userId;

  const MyStorePage({super.key, required this.userId});

  @override
  State<MyStorePage> createState() => _MyStorePageState();
}

class _MyStorePageState extends State<MyStorePage>
    with TickerProviderStateMixin {
  late final StoreService _storeService;
  final StanService _stallService = StanService();
  final DiscountService _discountService = DiscountService();
  final FoodService _foodService = FoodService();
  Stan? _stall;
  List<Menu> _menus = [];
  List<Menu> _foodMenus = [];
  List<Menu> _drinkMenus = [];
  bool _isLoading = true;
  String? _error;
  final int _currentIndex = 0;

  // Add new properties for UI
  late TabController _menuTabController;
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;
  final List<String> _categories = ['All', 'food', 'drink', 'Snacks'];

  // Add theme colors
  final Color primaryColor = const Color(0xFFFF3D00);
  final Color secondaryColor = const Color(0xFF2979FF);
  final Color accentColor = const Color(0xFF00C853);
  final Color backgroundColor = const Color(0xFFF5F5F5);
  final Color textColor = const Color(0xFF263238);

  // Change from final to regular Map
  Map<int, List<FoodAddon>> _menuAddons = {};

  // Add these variables
  Map<String, dynamic>? userData;
  int? stallId;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isProcessing = false; // Add this property

  final MenuStateManager _menuStateManager = MenuStateManager();

  // Add these properties at the class level, near other state variables
  TimeOfDay? _openTime;
  TimeOfDay? _closeTime;
  bool _isManuallyOpen = false;

  // Add these variables near other state variables
  final Map<String, TimeOfDay> _openTimes = {};
  final Map<String, TimeOfDay> _closeTimes = {};
  final Map<String, bool> _isDayActive = {};
  final List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  // Add these properties for status indicator
  Timer? _statusUpdateTimer;
  String _nextOpeningTime = '';
  String _closingTime = '';
  String _todayDayName = '';

  Future<void> _handleRefresh() async {
    try {
      await _initializeStore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Page refreshed'),
            duration: Duration(seconds: 1),
          ),
        );
        _showStoreStatusNotification();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _storeService = StoreService(FoodService());
    _menuTabController = TabController(length: _categories.length, vsync: this);
    _initializeStore();

    _scrollController.addListener(() {
      setState(() {
        _isCollapsed =
            _scrollController.hasClients && _scrollController.offset > 200;
      });
    });

    // Add loading stream listener
    _storeService.loadingStream.listen((isLoading) {
      if (mounted) {
        setState(() => _isProcessing = isLoading);
      }
    });

    // Add optimized state management
    _storeService.menuStream.listen((menus) {
      if (mounted) {
        setState(() {
          _menus = menus;
          _menuStateManager.updateMenus(menus);
        });
      }
    });

    _storeService.addonStream.listen((addons) {
      if (mounted) {
        setState(() {
          _menuAddons = addons;
          _menuStateManager.updateAddons(addons);
        });
      }
    });

    // Set up timer to update status periodically
    _statusUpdateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_stall != null && mounted) {
        _updateStoreTimingInfo();
      }
    });
  }

  final ImagePicker _picker = ImagePicker();
  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Image quality optimization
      );

      if (image != null && mounted) {
        Navigator.pop(context); // Close bottom sheet
        // Navigate to add menu screen with the image
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddMenuScreen(
              standId: _stall?.id ?? 0,
              initialImage: image,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navigateToEdit(BuildContext context) async {
    if (_stall == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store data not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Ensure userData is not null by creating a new map if needed
    final Map<String, dynamic> editData = userData ??
        {
          'id': _stall!.id.toString(),
          'name': _stall!.ownerName,
          'stallName': _stall!.stanName,
          'phone': _stall!.phone ?? '',
          'description': _stall!.description ?? '',
          'slot': _stall!.slot ?? '',
          'imageUrl': _stall!.imageUrl ?? '',
          'bannerUrl': _stall!.Banner_img ?? '',
          'ownerName': _stall!.ownerName ?? '',
          'email': '', // Add default value if needed
          'address': _stall!.slot ?? '', // Using slot as address
          'role': 'owner', // Add default role
          'status': 'active', // Add default status
        };

    try {
      final result = await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => EditProfileScreen(
            initialData: editData,
            stallId: _stall!.id.toString(),
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          userData = result;
          // Update _stall object with new data
          _stall = _stall!.copyWith(
            ownerName: result['name'] as String? ?? _stall!.ownerName,
            stanName: result['stallName'] as String? ?? _stall!.stanName,
            phone: result['phone'] as String? ?? _stall!.phone,
            description:
                result['description'] as String? ?? _stall!.description,
            slot: result['slot'] as String? ?? _stall!.slot,
            imageUrl: result['imageUrl'] as String? ?? _stall!.imageUrl,
            Banner_img: result['bannerUrl'] as String? ?? _stall!.Banner_img,
          );
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error navigating to edit screen: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening edit screen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initializeStore() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null; // Reset any previous errors
      });

      // Load stall data with error handling
      final stall = await _stallService.getStallByUserId(widget.userId);
      if (!mounted) return;

      // Initialize store service streams
      _storeService.menuStream.listen((menus) {
        if (mounted) {
          setState(() {
            _menus = menus;
            _menuStateManager.updateMenus(menus);
            _foodMenus = menus.where((menu) => menu.type == 'food').toList();
            _drinkMenus = menus.where((menu) => menu.type == 'drink').toList();
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() => _error = error.toString());
        }
      });

      _storeService.addonStream.listen((addons) {
        if (mounted) {
          setState(() {
            _menuAddons = addons;
            _menuStateManager.updateAddons(addons);
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() => _error = error.toString());
        }
      });

      // Load initial data and update UI
      await _storeService.loadMenusForStore(stall.id);

      setState(() {
        _stall = stall;
        _isLoading = false;
      });

      // After loading the stall data, update timing info
      if (_stall != null && mounted) {
        await _updateStoreTimingInfo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showStoreStatusNotification() {
    if (_stall != null && mounted) {
      // This will be safe to call after the widget is built
      Future.delayed(Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _stall!.isOpen ? Icons.check_circle : Icons.schedule,
                  color: Colors.white,
                ),
                SizedBox(width: 12),
                Text(
                  _stall!.isOpen
                      ? 'Your store is open'
                      : 'Your store is currently closed',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: _stall!.isOpen ? Colors.green : Colors.redAccent,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // If we've loaded the stall data but haven't shown the notification yet
    if (_stall != null && !_isLoading && !_hasShownStatusNotification) {
      _showStoreStatusNotification();
      _hasShownStatusNotification = true;
    }
  }

  bool _hasShownStatusNotification = false;

  Map<String, List<Menu>> _sortMenusByType(List<Menu> menus) {
    final foodMenus = menus.where((menu) => menu.type == 'food').toList();
    final drinkMenus = menus.where((menu) => menu.type == 'drink').toList();
    return {
      'food': foodMenus,
      'drink': drinkMenus,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while initializing
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    // Show error screen if there's an error
    if (_error != null) {
      return _buildErrorScreen();
    }

    // Show create store prompt if no store data
    if (_stall == null) {
      return _buildCreateStorePrompt();
    }

    return LoadingOverlay(
      isLoading: _isProcessing,
      message: 'Please wait...', // Add the isLoading parameter
      child: Scaffold(
        // Add the child parameter
        extendBodyBehindAppBar: true,
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _handleRefresh,
          color: accentColor,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeader(),
              _buildStoreStatusIndicator(), // Add this new widget
              _buildQuickActions(),
              _buildStats(),
              _buildMenuSection(),
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ), // Optional message
    );
  }

  Widget _buildLoadingScreen() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 280,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 24,
                    width: 200,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 150,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (_stall == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      leading: IconButton(
        // Add the back button here with proper styling
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          // Banner Image
          _buildStoreImage(),
          // Gradient overlay moved to _buildHeaderContent
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _buildHeaderContent(),
            ),
          ),
        ]),
      ),
      bottom: _isCollapsed ? _buildCollapsedHeader() : null,
    );
  }

  Widget _buildHeaderContent() {
    if (_stall == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: _stall?.imageUrl != null
                    ? NetworkImage(_stall!.imageUrl!)
                    : null,
                child: _stall?.imageUrl == null
                    ? Text(
                        _stall?.ownerName[0].toUpperCase() ?? '',
                        style: const TextStyle(fontSize: 24),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stall?.stanName ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stall?.ownerName ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_stall?.description != null && _stall!.description.isNotEmpty)
            Text(
              _stall!.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _stall?.slot ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PreferredSize _buildCollapsedHeader() {
    if (_stall == null) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(),
      );
    }

    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _stall?.imageUrl != null
                  ? NetworkImage(_stall!.imageUrl!)
                  : null,
              child: _stall?.imageUrl == null
                  ? Text(_stall!.ownerName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _stall!.stanName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _stall!.slot,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.add_box,
                    label: 'Add Menu',
                    color: accentColor,
                    onTap: () {
                      // Show bottom sheet to choose image source
                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: const Icon(Icons.photo_camera),
                                  title: const Text('Take a photo'),
                                  onTap: () =>
                                      _pickImage(ImageSource.camera, context),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from gallery'),
                                  onTap: () =>
                                      _pickImage(ImageSource.gallery, context),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  _buildActionButton(
                    icon: Icons.local_offer,
                    label: 'Discounts',
                    color: Colors.purple,
                    onTap: () => _showDiscountManagement(),
                  ),
                  _buildActionButton(
                    icon: Icons.edit_note,
                    label: 'Edit Store',
                    color: secondaryColor,
                    onTap: () => _navigateToEdit(context),
                  ),
                  _buildActionButton(
                    icon: Icons.insights,
                    label: 'Analytics',
                    color: primaryColor,
                    onTap: () {/* TODO */},
                  ),
                  _buildActionButton(
                    icon: Icons.schedule,
                    label: 'Hours',
                    color: Colors.teal,
                    onTap: () => _showScheduleManagement(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscountManagement() {
    // Check for expired discounts first
    _discountService.checkAndDetachExpiredDiscounts().then((_) {
      // Now show the discount management sheet with updated data
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manage Discounts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
                        onPressed: () => _showAddDiscountDialog(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: FutureBuilder<List<Discount>>(
                      future: _stall != null
                          ? _discountService.getDiscountsByStallId(_stall!.id)
                          : Future.value([]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No discounts available'));
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final discount = snapshot.data![index];
                            return _buildDiscountCard(
                              discount,
                              () => setModalState(() {}),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }).catchError((e) {
      print('Error checking expired discounts: $e');
    });
  }

  Future<void> _applyDiscountToMenus(Discount discount) async {
    if (_stall == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplyDiscountScreen(
          discount: discount,
          stallId: _stall!.id,
        ),
      ),
    );

    if (result == true && mounted) {
      // Close the current bottom sheet
      Navigator.pop(context);
      // Reopen the discount management with fresh data
      _showDiscountManagement();
    }
  }

  Widget _buildDiscountCard(Discount discount, VoidCallback refresh) {
    final isWithinDateRange = discount.startDate.isBefore(DateTime.now()) &&
        discount.endDate.isAfter(DateTime.now());
    final isExpired = discount.isExpired;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isExpired)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'EXPIRED',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ListTile(
            title: Text(
              discount.discountName,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${discount.discountPercentage}% off',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpired
                        ? Colors.grey[600]
                        : Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  'Valid: ${DateFormat('MMM dd').format(discount.startDate)} - ${DateFormat('MMM dd').format(discount.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: Switch(
              value: discount.isActive,
              onChanged: isExpired
                  ? null // Disable switch if expired
                  : (value) async {
                      try {
                        await _discountService.toggleDiscountStatus(
                          discount.id,
                          value,
                        );
                        discount.isActive = value;
                        refresh();
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update status: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isExpired)
                  TextButton.icon(
                    icon: Icon(Icons.update, size: 18),
                    label: Text('Update Dates'),
                    onPressed: () => _editDiscount(discount),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  )
                else
                  TextButton.icon(
                    icon: Icon(Icons.link, size: 18),
                    label: Text('Apply to Menu'),
                    onPressed: () => _applyDiscountToMenus(discount),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(Icons.edit, size: 18),
                  label: Text('Edit'),
                  onPressed: () => _editDiscount(discount),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('Delete'),
                  onPressed: () => _deleteDiscount(discount),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editDiscount(Discount discount) {
    final bool isExpired = discount.isExpired;

    showDialog(
      context: context,
      builder: (context) => EditDiscountDialog(
        discount: discount,
        isExpiredUpdate: isExpired,
        onSave: (updatedDiscount) async {
          try {
            await _discountService.updateDiscount(updatedDiscount);

            // If the discount was expired but now has valid dates, reactivate
            if (isExpired && !updatedDiscount.isExpired) {
              await _reactivateExpiredDiscount(updatedDiscount.id);
            }

            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Close bottom sheet
            _showDiscountManagement(); // Reopen to refresh
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update discount: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

// Add this helper method for reactivating discount
  Future<void> _reactivateExpiredDiscount(int discountId) async {
    try {
      await _discountService.updateDiscountStatus(discountId, true);

      // Optional: Show a confirmation to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Discount reactivated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error reactivating discount: $e');
    }
  }

  void _showAddDiscountDialog() {
    if (_stall == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Discount'),
        content: AddDiscountForm(
          stallId: _stall!.id,
          onSave: (discount) async {
            try {
              await _discountService.addDiscount(discount);
              Navigator.pop(context);
              _showDiscountManagement();
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add discount: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteDiscount(Discount discount) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this discount?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _discountService.deleteDiscount(discount.id);
        Navigator.pop(context); // Close bottom sheet
        _showDiscountManagement(); // Reopen to refresh
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete discount: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildStatCard(
              'Today\'s Sales',
              'Rp120.000',
              Icons.payments,
              Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Total Orders',
              '15',
              Icons.shopping_bag,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          TabBar(
            controller: _menuTabController,
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryColor,
            tabs: _categories
                .map((category) => Tab(
                    text: category == 'food'
                        ? 'Food'
                        : category == 'drink'
                            ? 'Drink'
                            : category))
                .toList(),
          ),
          SizedBox(
            height: 400, // Adjust based on your needs
            child: TabBarView(
              controller: _menuTabController,
              children: _categories.map((category) {
                final menuItems = category == 'All'
                    ? _menus
                    : _menus
                        .where((menu) =>
                            menu.type == category) // Remove toLowerCase()
                        .toList();
                return _buildMenuGrid(menuItems);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreImage() {
    if (_stall?.Banner_img == null) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(
            Icons.store,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: _stall!.Banner_img!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.error),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage:
              _stall!.imageUrl != null ? NetworkImage(_stall!.imageUrl!) : null,
          child: _stall!.imageUrl == null
              ? AvatarGlow(
                  glowColor: Colors.blue,
                  endRadius: 60.0,
                  duration: Duration(milliseconds: 2000),
                  repeat: true,
                  showTwoGlows: true,
                  child: Material(
                    elevation: 8.0,
                    shape: CircleBorder(),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      radius: 50.0,
                      child: Text(
                        _stall!.ownerName[0].toUpperCase(),
                        style: TextStyle(fontSize: 40.0, color: Colors.blue),
                      ),
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          _stall!.ownerName,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildStoreImage(),
          _buildGradientOverlay(),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildProfileHeader(),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _editStoreBanner,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _stall!.stanName,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusIndicator(),
                const SizedBox(width: 8),
                Text(
                  _stall!.slot,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_stall == null) return const SizedBox.shrink();

    final bool isOpen = _stall!.isOpen;
    final String statusText = isOpen ? 'Open' : 'Closed';
    final Color statusColor = isOpen ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.check_circle : Icons.schedule,
            color: statusColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreOverview() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Store Details',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEditableField('Phone', _stall!.phone, Icons.phone),
            _buildEditableField('Address', _stall!.slot, Icons.location_on),
            _buildEditableField(
                'Description', _stall!.description, Icons.info_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _editField(label, value),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDashboard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDashboardItem('Today\'s Earnings', '\$120.00'),
                  const SizedBox(width: 16),
                  _buildDashboardItem('Total Orders', '15'),
                  const SizedBox(width: 16),
                  _buildDashboardItem('Pending Orders', '3'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 3),
                        const FlSpot(1, 1),
                        const FlSpot(2, 4),
                        const FlSpot(3, 2),
                        const FlSpot(4, 5),
                      ],
                      isCurved: true,
                      color: Theme.of(context).primaryColor,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Light grey background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE0E0E0), // Lighter grey border
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFF542D), // Primary color
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF757575), // Medium grey
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(List<Menu> menuItems) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: menuItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildMenuCard(menuItems[index]),
    );
  }

  Widget _buildMenuCard(Menu menu) {
    final addons = _menuAddons[menu.id] ?? [];
    final hasAddons = addons.isNotEmpty;
    final isAvailable =
        menu.isAvailable ?? true; // Add this field to Menu model

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Stack with Status Badge
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: menu.photo ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: Icon(
                              menu.type == 'food'
                                  ? Icons.restaurant
                                  : Icons.local_drink,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (!isAvailable)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'OUT OF\nSTOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),

                  // Details Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Menu Name and Type Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                menu.foodName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: isAvailable,
                              onChanged: (value) {
                                _toggleMenuAvailability(menu)
                                    .catchError((error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to update availability: $error'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                });
                              },
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),

                        // Category and Type Tags
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildTag(
                              menu.type.toUpperCase(),
                              color: menu.type == 'food'
                                  ? Colors.orange
                                  : Colors.blue,
                            ),
                            if (menu.category != null)
                              _buildTag(
                                menu.category!,
                                color: Colors.green,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Description
                        if (menu.description?.isNotEmpty ==
                            true) // Fix null check here
                          Text(
                            menu.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),

                        // Price and Quick Edit
                        Row(
                          children: [
                            Text(
                              'Rp ${menu.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF542D),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, size: 16),
                              onPressed: () => _quickEditPrice(context, menu),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints.tightFor(
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Modified Add-ons Section
            const Divider(height: 16),
            Row(
              children: [
                Icon(
                  hasAddons ? Icons.add_circle_outline : Icons.add_circle,
                  size: 16,
                  color: hasAddons
                      ? Colors.grey[600]
                      : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  hasAddons
                      ? '${addons.length} Add-ons Available'
                      : 'Add New Add-on',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasAddons
                        ? Colors.grey[600]
                        : Theme.of(context).primaryColor,
                    fontWeight: hasAddons ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => hasAddons
                      ? _showAddons(context, menu, addons)
                      : _showAddonDialog(context, menu, null),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(60, 30),
                  ),
                  child: Text(hasAddons ? 'Manage' : 'Add'),
                ),
              ],
            ),

            // Stats Section
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Today',
                    '12',
                    Icons.today,
                  ),
                  _buildStatItem(
                    'This Week',
                    '85',
                    Icons.calendar_today,
                  ),
                  _buildStatItem(
                    'Rating',
                    '4.8',
                    Icons.star,
                  ),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _navigateToMenuDetails(menu, addons),
                      icon: const Icon(Icons.edit_note),
                      label: Text(
                          _isProcessing ? 'Please wait...' : 'Edit Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showMenuOptions(context, menu),
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ], // Added closing bracket for the children list
    ); // Added closing parenthesis for the Column constructor
  }

  Future<void> _toggleMenuAvailability(Menu menu) async {
    try {
      setState(() => _isLoading = true);

      // Get the current availability status
      final bool newAvailability = !menu.isAvailable;

      // Update the menu availability
      await _foodService.toggleMenuAvailability(menu.id, newAvailability);

      // Update local state
      setState(() {
        final index = _menus.indexWhere((m) => m.id == menu.id);
        if (index != -1) {
          _menus[index] = menu.copyWith(isAvailable: newAvailability);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Menu ${newAvailability ? 'enabled' : 'disabled'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update menu availability: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _quickEditPrice(BuildContext context, Menu menu) {
    final priceController = TextEditingController(
      text: menu.price.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Price'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Price',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newPrice = double.parse(priceController.text);
                await _foodService.updateMenuPrice(menu.id, newPrice);

                // Update local state
                setState(() {
                  final index = _menus.indexWhere((m) => m.id == menu.id);
                  if (index != -1) {
                    _menus[index] = menu.copyWith(price: newPrice);
                  }
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Price updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update price: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showMenuOptions(BuildContext context, Menu menu) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.visibility),
            title: Text(menu.isAvailable ? 'Hide Menu' : 'Show Menu'),
            onTap: () {
              Navigator.pop(context);
              _toggleMenuAvailability(menu);
            },
          ),
          ListTile(
            leading: Icon(Icons.copy),
            title: Text('Duplicate Menu'),
            onTap: () async {
              try {
                Navigator.pop(context);
                setState(() => _isProcessing = true);

                await _foodService.duplicateMenu(menu.id);

                // Reload menus and addons
                if (_stall != null) {
                  final menus = await _foodService.getMenuByStanId(_stall!.id);
                  // Update menus state
                  setState(() {
                    _menus = menus;
                    _foodMenus =
                        menus.where((menu) => menu.type == 'food').toList();
                    _drinkMenus =
                        menus.where((menu) => menu.type == 'drink').toList();
                  });

                  // Load addons for all menus
                  final Map<int, List<FoodAddon>> newAddonMap = {};
                  for (final menu in menus) {
                    final addons = await _foodService.getAddonsForMenu(menu.id);
                    newAddonMap[menu.id] = addons;
                  }

                  // Update addons state
                  setState(() {
                    _menuAddons = newAddonMap;
                    _isProcessing = false;
                  });
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menu duplicated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  setState(() => _isProcessing = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to duplicate menu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red),
            title: Text('Delete Menu', style: TextStyle(color: Colors.red)),
            onTap: () async {
              try {
                // Show confirmation dialog
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete this menu?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm ?? false) {
                  Navigator.pop(context); // Close bottom sheet
                  setState(() => _isLoading = true);

                  await _foodService.deleteMenu(menu.id);

                  // Update local state
                  setState(() {
                    _menus.removeWhere((m) => m.id == menu.id);
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menu deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete menu: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddonDialog(
      BuildContext context, Menu menu, FoodAddon? addon) async {
    try {
      final addonData = await showDialog<FoodAddon?>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AddonDialog(
          addon: addon,
          menuId: menu.id,
        ),
      );

      if (addonData != null && mounted) {
        setState(() => _isProcessing = true);
        await _storeService.saveAddon(addonData);

        // Refresh the addons for this menu
        final updatedAddons = await _foodService.getAddonsForMenu(menu.id);

        setState(() {
          _menuAddons[menu.id] = updatedAddons;
          _isProcessing = false;
        });

        // Pop context for both new and edit cases
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(addon == null
                ? 'Add-on added successfully'
                : 'Add-on updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddons(BuildContext context, Menu menu, List<FoodAddon> addons) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildAddonHeader(
                  menu, context), // Changed from bottomSheetContext
              Expanded(
                child: ListView.builder(
                  itemCount: _menuAddons[menu.id]?.length ?? 0,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final addon = _menuAddons[menu.id]![index];
                    return AddonCard(
                      key: ValueKey('${addon.id}-${addon.addonName}'),
                      addon: addon,
                      onEdit: () => _showAddonDialog(context, menu, addon),
                      onDelete: () => _deleteAddon(context, menu.id, addon),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddonHeader(Menu menu, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add-ons Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${menu.foodName} - ${_menuAddons[menu.id]?.length ?? 0} Add-ons',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddonDialog(context, menu, null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Add-on'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddonCard(Menu menu, FoodAddon addon) {
    return AddonCard(
      addon: addon,
      onEdit: () => _showAddonDialog(context, menu, addon),
      onDelete: () => _deleteAddon(context, menu.id, addon),
    );
  }

  Future<void> _deleteAddon(
      BuildContext context, int menuId, FoodAddon addon) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete add-on "${addon.addonName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _storeService.deleteAddon(menuId, addon.id!);
        // Refresh addons list
        final newAddons = await _foodService.getAddonsForMenu(menuId);
        setState(() {
          _menuAddons[menuId] = newAddons;
        });
        Navigator.pop(context); // Close the bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add-on deleted'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting add-on: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addNewAddon(BuildContext context, Menu menu) {
    // TODO: Implement add new addon functionality
  }

  void _editMenu(BuildContext context, Menu menu, List<FoodAddon> addons) {
    // TODO: Implement edit menu functionality
  }

  void _editAddon(BuildContext context, Menu menu, FoodAddon addon) {
    // TODO: Implement edit addon functionality
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _initializeStore(); // Changed from _loadStallAndMenus
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateStorePrompt() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('You don\'t have a store yet'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Navigate to create store page
              },
              child: const Text('Create Store'),
            ),
          ],
        ),
      ),
    );
  }

  void _editStoreBanner() {
    // TODO: Implement edit store banner functionality
  }

  void _editField(String label, String value) {
    // TODO: Implement edit field functionality
  }

  Future<void> _navigateToMenuDetails(Menu menu, List<FoodAddon> addons) async {
    try {
      setState(() => _isProcessing = true);
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MenuDetailsScreen(
            menu: menu,
            addons: addons,
          ),
        ),
      );

      if (result == true && mounted) {
        await _initializeStore();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error navigating to menu details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

// Update the _showScheduleManagement method to use the correct approach with stalls table
  void _showScheduleManagement() {
    // Create local variables to store schedule data that will be shown in the UI
    Map<String, Map<String, dynamic>> scheduleDataMap = {};
    bool isManuallyOpen = false; // Local copy of manual override status
    bool manualOpenStatus =
        false; // The actual open/closed status when in manual mode

    // Show loading indicator while fetching data
    setState(() => _isProcessing = true);

    // Load the initial data then show the bottom sheet
    _stallService.getCompleteScheduleInfo(_stall!.id).then((completeInfo) {
      setState(() => _isProcessing = false);

      // Extract regular schedules
      final List<Map<String, dynamic>> schedules =
          completeInfo['regularSchedules'] as List<Map<String, dynamic>>;

      // Extract manual override info
      final Map<String, dynamic> manualOverride =
          completeInfo['manualOverride'] as Map<String, dynamic>;

      // Set manual override variables - now correctly from stalls table
      isManuallyOpen = manualOverride['isManuallyOpen'] as bool? ?? false;
      manualOpenStatus = manualOverride['isOpen'] as bool? ?? false;

      // Initialize scheduleDataMap with the data from the database
      for (String day in _weekdays) {
        // Find the schedule for this day
        final daySchedule = schedules.firstWhere(
          (s) => s['day_of_week'] == day,
          orElse: () => {
            'is_open': false,
            'open_time': '09:00:00',
            'close_time': '17:00:00',
          },
        );

        scheduleDataMap[day] = Map<String, dynamic>.from(daySchedule);
      }

      // Now show the bottom sheet with preloaded data
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store Hours',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Day schedule cards - no changes needed here
                  Expanded(
                    child: ListView.builder(
                      itemCount: _weekdays.length,
                      itemBuilder: (context, index) {
                        // ... existing day schedule builder code ...
                        final String day = _weekdays[index];
                        final daySchedule = scheduleDataMap[day]!;
                        final bool isOpen = daySchedule['is_open'] == true;

                        // Parse time strings to TimeOfDay objects
                        TimeOfDay parseTimeString(String timeStr) {
                          final parts = timeStr.split(':');
                          if (parts.length < 2) {
                            return TimeOfDay(hour: 9, minute: 0);
                          }
                          try {
                            return TimeOfDay(
                              hour: int.parse(parts[0]),
                              minute: int.parse(parts[1]),
                            );
                          } catch (e) {
                            return TimeOfDay(hour: 9, minute: 0);
                          }
                        }

                        TimeOfDay openTime = parseTimeString(
                            daySchedule['open_time'] ?? '09:00:00');
                        TimeOfDay closeTime = parseTimeString(
                            daySchedule['close_time'] ?? '17:00:00');

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getFullDayName(day),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          isOpen ? 'Open' : 'Closed',
                                          style: TextStyle(
                                            color: isOpen
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Switch(
                                      value: isOpen,
                                      activeColor: Colors.green,
                                      onChanged: (bool value) {
                                        setModalState(() {
                                          scheduleDataMap[day] = {
                                            ...scheduleDataMap[day]!,
                                            'is_open': value,
                                          };
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                // Time picker UI for open days
                                if (isOpen)
                                  Column(
                                    children: [
                                      const Divider(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () async {
                                                final TimeOfDay? selectedTime =
                                                    await showTimePicker(
                                                  context: context,
                                                  initialTime: openTime,
                                                );

                                                if (selectedTime != null) {
                                                  setModalState(() {
                                                    final String formattedHour =
                                                        selectedTime.hour
                                                            .toString()
                                                            .padLeft(2, '0');
                                                    final String
                                                        formattedMinute =
                                                        selectedTime.minute
                                                            .toString()
                                                            .padLeft(2, '0');

                                                    scheduleDataMap[day] = {
                                                      ...scheduleDataMap[day]!,
                                                      'open_time':
                                                          '$formattedHour:$formattedMinute:00',
                                                    };
                                                  });
                                                }
                                              },
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Opening Time',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                            color: Colors
                                                                .grey[300]!),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.access_time,
                                                            color: Colors
                                                                .grey[600]),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(openTime
                                                            .format(context)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () async {
                                                final TimeOfDay? selectedTime =
                                                    await showTimePicker(
                                                  context: context,
                                                  initialTime: closeTime,
                                                );

                                                if (selectedTime != null) {
                                                  setModalState(() {
                                                    final String formattedHour =
                                                        selectedTime.hour
                                                            .toString()
                                                            .padLeft(2, '0');
                                                    final String
                                                        formattedMinute =
                                                        selectedTime.minute
                                                            .toString()
                                                            .padLeft(2, '0');

                                                    scheduleDataMap[day] = {
                                                      ...scheduleDataMap[day]!,
                                                      'close_time':
                                                          '$formattedHour:$formattedMinute:00',
                                                    };
                                                  });
                                                }
                                              },
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Closing Time',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                            color: Colors
                                                                .grey[300]!),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.access_time,
                                                            color: Colors
                                                                .grey[600]),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(closeTime
                                                            .format(context)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Manual Override Section - Updated to use stalls table approach
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Store Status Override',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Manually Control Store Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Override scheduled hours',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: isManuallyOpen,
                            activeColor: accentColor,
                            onChanged: (bool value) {
                              setModalState(() {
                                isManuallyOpen = value;
                              });
                            },
                          ),
                          if (isManuallyOpen)
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Store is currently',
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: Text(
                                manualOpenStatus ? 'OPEN' : 'CLOSED',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: manualOpenStatus
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              value: manualOpenStatus,
                              activeColor: Colors.green,
                              inactiveTrackColor: Colors.red.withOpacity(0.5),
                              onChanged: (bool value) {
                                setModalState(() {
                                  manualOpenStatus = value;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          setState(() => _isProcessing = true);

                          // Update each day's schedule in the stall_schedules table
                          for (String day in scheduleDataMap.keys) {
                            final dayData = scheduleDataMap[day]!;
                            // Only update if the day already exists in the database or is explicitly marked as open
                            if (dayData.containsKey('id') ||
                                dayData['is_open'] == true) {
                              await _stallService.updateDaySchedule(
                                  _stall!.id, day, dayData);
                            }
                          }

                          // Update the manual override status in the stalls table
                          await _stallService.updateManualOpenStatus(
                              _stall!.id, isManuallyOpen);

                          // If manually open, update the current open status according to the switch
                          if (isManuallyOpen) {
                            await _stallService.updateStallStatus(
                                _stall!.id, manualOpenStatus);
                            setState(() {
                              _stall =
                                  _stall!.copyWith(isOpen: manualOpenStatus);
                            });
                          } else {
                            // Otherwise compute open status based on current time and schedule
                            final shouldBeOpen = await _stallService
                                .checkIfStoreIsOpenNow(_stall!.id);
                            await _stallService.updateStallStatus(
                                _stall!.id, shouldBeOpen);
                            setState(() {
                              _stall = _stall!.copyWith(isOpen: shouldBeOpen);
                            });
                          }

                          // Update local state
                          setState(() {
                            _isManuallyOpen = isManuallyOpen;
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Schedule saved successfully'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } catch (e) {
                          print('Error saving schedule: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error saving schedule: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Save Schedule',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }).catchError((error) {
      setState(() => _isProcessing = false);
      print('Error loading schedule data: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load schedule data: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

// Helper method to get full day name
  String _getFullDayName(String shortDay) {
    switch (shortDay) {
      case 'Mon':
        return 'Monday';
      case 'Tue':
        return 'Tuesday';
      case 'Wed':
        return 'Wednesday';
      case 'Thu':
        return 'Thursday';
      case 'Fri':
        return 'Friday';
      case 'Sat':
        return 'Saturday';
      case 'Sun':
        return 'Sunday';
      default:
        return shortDay;
    }
  }

  // Add this method to update store timing information
  Future<void> _updateStoreTimingInfo() async {
    if (_stall == null) return;

    try {
      // Get current day name
      final now = DateTime.now();
      _todayDayName = intl.DateFormat('EEEE').format(now);

      // Get today's schedule
      final scheduleInfo =
          await _stallService.getStallSchedulesByDay(_stall!.id);
      final today = _getDayOfWeek(now.weekday);

      if (scheduleInfo.containsKey(today)) {
        final todaySchedule = scheduleInfo[today];

        // Format the open and close times for display
        if (todaySchedule['is_open'] == true) {
          final openTimeStr =
              todaySchedule['open_time'] as String? ?? '09:00:00';
          final closeTimeStr =
              todaySchedule['close_time'] as String? ?? '17:00:00';

          // Format for display
          final openFormatted = _formatTimeString(openTimeStr);
          final closeFormatted = _formatTimeString(closeTimeStr);

          setState(() {
            _closingTime = closeFormatted;

            // Calculate time until closing
            final closeParts = closeTimeStr.split(':');
            if (closeParts.length >= 2) {
              final closeHour = int.tryParse(closeParts[0]) ?? 17;
              final closeMinute = int.tryParse(closeParts[1]) ?? 0;

              final closeDateTime = DateTime(
                  now.year, now.month, now.day, closeHour, closeMinute);

              if (now.isBefore(closeDateTime)) {
                final remaining = closeDateTime.difference(now);
                final hours = remaining.inHours;
                final minutes = remaining.inMinutes % 60;

                if (hours > 0) {
                  _closingTime =
                      '$closeFormatted (in $hours hr ${minutes > 0 ? '$minutes min' : ''})';
                } else {
                  _closingTime = '$closeFormatted (in $minutes min)';
                }
              }
            }
          });
        } else {
          setState(() {
            _closingTime = 'Closed today';
          });
        }
      }

      // Find next opening time if currently closed
      if (!(_stall!.isOpen)) {
        // Check if we're on manual override
        if (_stall!.isManuallyOpen) {
          setState(() {
            _nextOpeningTime = 'Manual control - schedule overridden';
          });
        } else {
          // Find the next day the store will be open
          String nextOpenDay = '';
          String nextOpenTime = '';

          // Check remaining of today first
          if (_todayDaySchedule(scheduleInfo, today) &&
              _canStillOpenToday(scheduleInfo[today]['open_time'])) {
            nextOpenDay = 'Today';
            nextOpenTime = _formatTimeString(scheduleInfo[today]['open_time']);
          } else {
            // Check upcoming days
            int checkDay = now.weekday;
            for (int i = 1; i <= 7; i++) {
              checkDay = (checkDay % 7) +
                  1; // Move to next day, wrap around after Sunday
              final dayKey = _getDayOfWeek(checkDay);

              if (_todayDaySchedule(scheduleInfo, dayKey)) {
                switch (i) {
                  case 1:
                    nextOpenDay = 'Tomorrow';
                    break;
                  default:
                    nextOpenDay = intl.DateFormat('EEEE')
                        .format(now.add(Duration(days: i)));
                }

                nextOpenTime =
                    _formatTimeString(scheduleInfo[dayKey]['open_time']);
                break;
              }
            }
          }

          setState(() {
            if (nextOpenDay.isNotEmpty) {
              _nextOpeningTime = '$nextOpenDay at $nextOpenTime';
            } else {
              _nextOpeningTime = 'No upcoming opening scheduled';
            }
          });
        }
      } else {
        setState(() {
          _nextOpeningTime = '';
        });
      }
    } catch (e) {
      print('Error updating store timing info: $e');
    }
  }

  // Helper method to check if a day is scheduled to be open
  bool _todayDaySchedule(Map<String, dynamic> scheduleInfo, String day) {
    return scheduleInfo.containsKey(day) &&
        scheduleInfo[day] != null &&
        scheduleInfo[day]['is_open'] == true;
  }

  // Check if store can still open later today
  bool _canStillOpenToday(String openTimeStr) {
    try {
      final now = DateTime.now();
      final parts = openTimeStr.split(':');
      if (parts.length >= 2) {
        final openHour = int.tryParse(parts[0]) ?? 9;
        final openMinute = int.tryParse(parts[1]) ?? 0;

        final openToday =
            DateTime(now.year, now.month, now.day, openHour, openMinute);
        return now.isBefore(openToday);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Add this method to format time string
  String _formatTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      String period = hour >= 12 ? 'PM' : 'AM';

      hour = hour % 12;
      hour = hour == 0 ? 12 : hour;

      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr;
    }
  }

  // Add between _buildHeader() and _buildQuickActions()
  Widget _buildStoreStatusIndicator() {
    if (_stall == null) return const SizedBox.shrink();

    final bool isOpen = _stall!.isOpen;
    final bool isManuallyControlled = _stall!.isManuallyOpen;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: isOpen
                                ? Colors.green.withOpacity(0.4)
                                : Colors.red.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isOpen ? 'OPEN NOW' : 'CURRENTLY CLOSED',
                      style: TextStyle(
                        color: isOpen
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (isManuallyControlled)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Tooltip(
                          message: 'Manual override is active',
                          child: Icon(
                            Icons.pan_tool,
                            size: 16,
                            color: isOpen
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Store hours info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Today's hours info
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          isOpen
                              ? 'Closing at $_closingTime'
                              : _nextOpeningTime.isNotEmpty
                                  ? 'Opening $_nextOpeningTime'
                                  : 'Closed for today',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Manual override indicator if active
                    if (isManuallyControlled)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.warning, size: 16, color: Colors.amber),
                            const SizedBox(width: 8),
                            Text(
                              'Manual override is active - scheduled hours ignored',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Quick action button
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _showScheduleManagement(),
                            icon: Icon(Icons.edit_calendar, size: 16),
                            label: Text('Manage Hours'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              foregroundColor: Theme.of(context).primaryColor,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _quickToggleStoreStatus(),
                            icon: Icon(
                              isOpen ? Icons.store_mall_directory : Icons.store,
                              size: 16,
                            ),
                            label: Text(isOpen ? 'Close Store' : 'Open Store'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              foregroundColor:
                                  isOpen ? Colors.red : Colors.green,
                              side: BorderSide(
                                color: isOpen ? Colors.red : Colors.green,
                                width: 1,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add method to quickly toggle store status
  Future<void> _quickToggleStoreStatus() async {
    if (_stall == null) return;

    try {
      setState(() => _isProcessing = true);

      final newStatus = !_stall!.isOpen;

      // Need to enable manual override and set the status
      await _stallService.updateManualOpenStatus(_stall!.id, true);
      await _stallService.updateStallStatus(_stall!.id, newStatus);

      setState(() {
        _stall = _stall!.copyWith(
          isOpen: newStatus,
          isManuallyOpen: true,
        );
        _isProcessing = false;
      });

      // Update timing info
      _updateStoreTimingInfo();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Store is now ${newStatus ? 'open' : 'closed'} (Manual override)'),
          backgroundColor: newStatus ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update store status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _statusUpdateTimer?.cancel();
    _storeService.dispose();
    _menuTabController.dispose();
    _scrollController.dispose();
    _menuStateManager.clear();
    super.dispose();
  }

  // Helper method to convert weekday number to day string
  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return 'Mon';
    }
  }
}
