import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kantin/Component/my_drawer.dart';
import 'package:kantin/Component/my_stall_tile.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/stall_schedule.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/pages/StudentState/Stalldetailpage.dart';
import 'package:kantin/utils/avatar_generator.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/widgets/home/featured_promos.dart';
import 'package:kantin/widgets/home/food_category_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Add this import
import 'package:kantin/widgets/search_bar_delegate.dart';
import 'package:kantin/widgets/shimmer/shimmer_loading.dart'; // Add this import
import 'package:intl/intl.dart'; // Add this for date formatting
import 'package:kantin/widgets/stall_status_indicator.dart';
import 'package:collection/collection.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<StudentPage>
    with SingleTickerProviderStateMixin {
  final StanService _stanService = StanService();
  final StudentService _studentService = StudentService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  List<Stan> _stalls = [];
  List<Stan> _popularStalls = [];
  // Add schedule information maps
  Map<int, Map<String, dynamic>> _stallSchedules = {};
  bool _isLoading = true;
  bool _isLoadingProfile = true;
  final TextEditingController _searchController = TextEditingController();
  final CarouselController _carouselController = CarouselController();
  final int _currentBannerIndex = 0;

  final int _bannerCount = 3;

  final List<String> _recentSearches = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Add new controller for tab view
  late TabController _tabController;

  // Add new state variables
  bool _isRefreshing = false;
  List<Stan> _filteredStalls = [];

  // Add missing state variables
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  StudentModel? _currentStudent;
  final _supabase = Supabase.instance.client;
  String _sortBy = 'rating';

  // New filtering states
  bool _isOpen = true;
  double _minRating = 0.0;
  bool _hasPromo = false;

  // New UI states
  bool _showScrollToTop = false;
  final int _selectedStallIndex = -1;

  // Add these new state variables
  final ValueNotifier<List<Stan>> _filteredStallsNotifier =
      ValueNotifier<List<Stan>>([]);
  Timer? _debounceTimer;

  // Add these new state variables for filter dialog
  late ValueNotifier<bool> _isOpenNotifier;
  late ValueNotifier<bool> _hasPromoNotifier;
  late ValueNotifier<double> _minRatingNotifier;

  // Add new state variables
  String _selectedCategory = 'All';

  bool _isDisposed = false; // Add this flag

  // Add error state variable
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Fix: Change length to 2 to match number of tabs
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    // Initialize notifiers with default values
    _isOpenNotifier = ValueNotifier(_isOpen);
    _hasPromoNotifier = ValueNotifier(_hasPromo);
    _minRatingNotifier = ValueNotifier(_minRating);

    // Add listener for filtered stalls
    _filteredStallsNotifier.addListener(() {
      if (mounted) {
        setState(() {
          _filteredStalls = _filteredStallsNotifier.value;
        });
      }
    });

    _loadStudentData();
    // Delay the data loading to ensure Scaffold is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });

    // Add scroll to top listener
    _scrollController.addListener(() {
      setState(() {
        _showScrollToTop = _scrollController.offset > 300;
      });
    });

    // Add a timer to refresh stall statuses every minute
    _stallStatusTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && !_isLoading) {
        _refreshStallStatuses();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.offset > 20 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 20 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  Future<void> _loadInitialData() async {
    await _loadStudentData();
    await _loadStalls();
  }

  Future<void> _loadStudentData() async {
    if (!mounted) return;
    try {
      setState(() => _isLoadingProfile = true);

      print('Debug: Starting to load student data');

      // Get the current user ID from AuthService
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get student data using the actual user ID from authentication
      final userData = await _userService.getUserByFirebaseUid(userId);
      if (userData == null) {
        throw Exception('User data not found');
      }

      final studentResponse = await _supabase
          .from('students')
          .select()
          .eq('id_user', userData.id!)
          .single();

      print('Debug: Student response - $studentResponse');

      if (mounted) {
        setState(() {
          _currentStudent = studentResponse != null
              ? StudentModel.fromMap(studentResponse)
              : null;
          _isLoadingProfile = false;
        });

        if (_currentStudent == null && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showCompleteProfileDialog();
          });
        }
      }
    } catch (e) {
      print('Debug: Error in _loadStudentData - $e');
      if (mounted) {
        setState(() => _isLoadingProfile = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        });
      }
    }
  }

  void _showCompleteProfileDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Your Profile'),
        content: const Text(
          'Please complete your profile to continue using the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile/setup')
                  .then((_) => _loadStudentData());
            },
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }

  // Update method to fetch stall schedules and apply defaults where missing
  Future<Map<int, Map<String, dynamic>>> _fetchStallSchedules() async {
    try {
      final now = DateTime.now();
      final currentTime = DateFormat('HH:mm:ss').format(now);
      final currentDay = now.weekday;
      final currentDate = now.toIso8601String().split('T')[0];

      // Query for stall schedules that are open now
      final response = await _supabase
          .from('stall_schedules')
          .select(
              'id, stall_id, day_of_week, specific_date, open_time, close_time, is_open')
          .or('day_of_week.eq.$currentDay,specific_date.eq.$currentDate');

      Map<int, Map<String, dynamic>> scheduleMap = {};

      // First, process all the returned schedules
      for (var schedule in response) {
        final stallId = schedule['stall_id'] as int;
        final openTime = schedule['open_time'] as String?;
        final closeTime = schedule['close_time'] as String?;
        final isOpen = schedule['is_open'] as bool? ?? false;

        // Check if the current time is within the open and close time
        bool isCurrentlyOpen = false;
        if (isOpen && openTime != null && closeTime != null) {
          isCurrentlyOpen = currentTime.compareTo(openTime) >= 0 &&
              currentTime.compareTo(closeTime) <= 0;
        }

        scheduleMap[stallId] = {
          'is_open': isCurrentlyOpen,
          'open_time': openTime,
          'close_time': closeTime,
          'has_custom_schedule': true,
        };
      }

      // Note: We don't need to add default schedules here
      // The Stan model will handle applying default schedules for stalls without custom schedules

      return scheduleMap;
    } catch (e) {
      print('Error fetching stall schedules: $e');
      // Return empty map on error
      return {};
    }
  }

  // Update the _loadStalls method to include schedule information and next opening times
  Future<void> _loadStalls() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // First get all stalls
      final stalls = await _stanService.getAllStans();
      
      // Create a map to store StallSchedule objects by stall ID
      Map<int, List<StallSchedule>> stallScheduleObjects = {};
      
      // Fetch schedule objects for all stalls in one batch
      for (var stall in stalls) {
        // Get actual StallSchedule objects instead of just schedule info
        final schedules = await _stanService.getStallScheduleObjects(stall.id);
        if (schedules.isNotEmpty) {
          stallScheduleObjects[stall.id] = schedules;
        }
      }

      // Store next opening times for stalls that are closed
      Map<int, String> nextOpeningTimes = {};

      // Update stalls with schedule information
      for (var stall in stalls) {
        if (stallScheduleObjects.containsKey(stall.id)) {
          // Important: Pass actual StallSchedule objects, not just a map
          stall.setScheduleInfo(null, schedules: stallScheduleObjects[stall.id]);
          
          // The isOpen property should now be correctly set by the setScheduleInfo method
          // We don't need to override it here
        } else {
          // Stall has no custom schedule - use default
          stall.setScheduleInfo(null);
        }

        // Print debug information
        print('Stall ${stall.stanName}: isOpen=${stall.isOpen}, isUsingDefault=${stall.isUsingDefaultSchedule}');

        // If stall is closed, get next opening time
        if (!stall.isOpen) {
          final nextOpeningInfo = await _stanService.getNextOpeningInfo(stall.id);
          nextOpeningTimes[stall.id] = nextOpeningInfo;
        }
      }

      // Sort stalls by rating to get popular stalls, handling null ratings
      final popularStalls = List<Stan>.from(stalls)
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      if (!_isDisposed) {
        setState(() {
          _stalls = stalls;
          _stallSchedules = {}; // Clear old schedule info since we're using StallSchedule objects now
          _popularStalls = popularStalls.take(5).toList();
          _isLoading = false;
          _nextOpeningTimes = nextOpeningTimes;
        });
      }

      // Apply filters to update UI
      _applyFilters();
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading stalls: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stalls: $e')),
        );
      }
    }
  }

  // Add this property to the class
  Map<int, String> _nextOpeningTimes = {};

  // Replace the current _isStallOpen method with this improved version
  bool _isStallOpen(Stan stall) {
    // First check if we have a custom schedule in our loaded data
    if (_stallSchedules.containsKey(stall.id)) {
      return _stallSchedules[stall.id]?['is_open'] ?? false;
    }

    // If no schedule is found in our loaded map, check the stall's own isOpen property
    // This is set in the setScheduleInfo method when stalls are loaded
    return stall.isOpen;
  }

  // Replace your existing getStallHours method with this new implementation
  String getStallHours(Stan stall) {
    print("Stall ${stall.stanName} isUsingDefault: ${stall.isUsingDefaultSchedule}");
    
    // First check if stall has custom schedules
    if (!stall.isUsingDefaultSchedule && stall.schedules != null && stall.schedules!.isNotEmpty) {
      // Get today's schedule
      final now = DateTime.now();
      final today = _getDayNameFromWeekday(now.weekday);
      
      // Check for specific date schedule first
      final specificSchedule = stall.schedules!.firstWhereOrNull(
        (s) => s.specificDate != null && s.specificDate!.day == now.day && 
               s.specificDate!.month == now.month && s.specificDate!.year == now.year
      );
      
      if (specificSchedule?.openTime != null && specificSchedule?.closeTime != null) {
        return '${_formatTimeOfDay(specificSchedule!.openTime!)} - ${_formatTimeOfDay(specificSchedule.closeTime!)}';
      }
      
      // Then check for day of week schedule
      final todaySchedule = stall.schedules!.firstWhereOrNull(
        (s) => s.dayOfWeek == today && s.specificDate == null
      );
      
      if (todaySchedule?.openTime != null && todaySchedule?.closeTime != null) {
        return '${_formatTimeOfDay(todaySchedule!.openTime!)} - ${_formatTimeOfDay(todaySchedule.closeTime!)}';
      }
    }
    
    // Fall back to using scheduleInfo for compatibility
    if (stall.scheduleInfo != null && 
        stall.scheduleInfo!['open_time'] != null && 
        stall.scheduleInfo!['close_time'] != null) {
        
      final openTime = stall.scheduleInfo!['open_time'] as String;
      final closeTime = stall.scheduleInfo!['close_time'] as String;
      
      return '${_formatTimeString(openTime)} - ${_formatTimeString(closeTime)}${stall.isUsingDefaultSchedule ? " (Default)" : ""}';
    }
    
    return 'Hours not set';
  }

  // Add the formatTimeString method here if it doesn't exist already
  String _formatTimeString(String time) {
    try {
      final parts = time.split(':');
      if (parts.length < 2) return time;

      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      String period = hour >= 12 ? 'PM' : 'AM';

      hour = hour > 12 ? hour - 12 : hour;
      hour = hour == 0 ? 12 : hour;

      return '$hour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  // Add these new helper methods after _formatTimeString
  String _getDayNameFromWeekday(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return 'Mon';
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    try {
      await Future.wait([
        _loadStudentData(),
        _loadStalls(),
      ]);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => _showSearch(),
          child: Hero(
            tag: 'searchBar',
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Search for food or restaurant...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  // Add a quick refresh button to the app bar
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: _isScrolled ? 4 : 0,
      backgroundColor: _isScrolled ? Colors.white : Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          color: _isScrolled ? Colors.black : Colors.white,
        ),
        onPressed: _openDrawer,
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Telkom Canteen',
          style: TextStyle(
            color: _isScrolled ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _handleRefresh,
          color: _isScrolled ? Colors.black : Colors.white,
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _showNotifications,
          color: _isScrolled ? Colors.black : Colors.white,
        ),
      ],
    );
  }

  void _showSearch() {
    showSearch(
      context: context,
      delegate: SearchBarDelegate(
        onSearch: _performSearch,
        recentSearches: _recentSearches,
      ),
    );
  }

  Future<List<dynamic>> _performSearch(String query) async {
    // Implement search functionality
    return [];
  }

  void _showNotifications() {
    // Handle notification tap
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.white),
            SizedBox(width: 8),
            Text('No new notifications'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Also update the AnimatedStallTile to use our new component
  Widget _buildStallsList() {
    if (_isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ShimmerLoading(
              width: double.infinity,
              height: 100,
            ),
          ),
          childCount: 5,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final stall = _filteredStalls[index];
          return Hero(
            tag: 'stall-${stall.id}',
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _navigateToStallDetail(stall),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Stall Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: Image.network(
                                stall.imageUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    AvatarGenerator.generateStallAvatar(
                                        stall.stanName),
                              ),
                            ),
                            // Add promo banner if applicable
                            if (stall.hasActivePromotions())
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'PROMO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stall.stanName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Show status with our new component
                            StallStatusIndicator(
                                stall: stall, isDetailed: true),

                            // Next opening info if closed
                            if (!stall.isOpen &&
                                _nextOpeningTimes.containsKey(stall.id))
                              StallStatusIndicator.nextOpeningInfo(
                                  stall, _nextOpeningTimes[stall.id] ?? ''),

                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    getStallHours(stall),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Show rating
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.star, size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  stall.rating?.toStringAsFixed(1) ??
                                      'Not rated',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                if (stall.hasActivePromotions())
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      'PROMO',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
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
              ),
            ),
          );
        },
        childCount: _filteredStalls.length,
      ),
    );
  }

  void _navigateToStallDetail(Stan stall) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StallDetailPage(
          stall: stall,
          studentId: _currentStudent?.id ?? 0,
        ),
      ),
    ).then((_) => _loadStalls()); // Refresh after returning
  }

  // Add new sorting method
  void _sortStalls() {
    _applyFilters(); // Re-apply filters with new sort
  }

  // Update the _buildSortAndFilter method
  Widget _buildSortAndFilter() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            DropdownButton<String>(
              value: _sortBy,
              items: [
                DropdownMenuItem(value: 'rating', child: Text('Rating')),
                DropdownMenuItem(value: 'name', child: Text('Name')),
                DropdownMenuItem(
                    value: 'popularity', child: Text('Popularity')),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _sortStalls();
                });
              },
            ),
            Spacer(),
            // Add a toggle chip for quickly toggling open/all stalls
            FilterChip(
              label: Text(_isOpen ? 'Open Now' : 'All Stalls'),
              selected: _isOpen,
              onSelected: (value) {
                setState(() {
                  _isOpen = value;
                  _isOpenNotifier.value = value;
                  _applyFilters();
                });
              },
              avatar: Icon(
                _isOpen ? Icons.check_circle : Icons.access_time,
                size: 16,
              ),
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: 'More filters',
            ),
          ],
        ),
      ),
    );
  }

  // Update filter dialog
  void _showFilterDialog() {
    // Create temporary notifiers for the dialog
    final tempIsOpen = ValueNotifier(_isOpen);
    final tempHasPromo = ValueNotifier(_hasPromo);
    final tempMinRating = ValueNotifier(_minRating);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Stalls'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: tempIsOpen,
                builder: (context, isOpen, child) {
                  return SwitchListTile(
                    title: Row(
                      children: [
                        Text('Open Now'),
                        Tooltip(
                          message: 'Only show stalls that are currently open',
                          child: Icon(Icons.info_outline,
                              size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                    value: isOpen,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (value) {
                      tempIsOpen.value = value;
                      // Apply filter immediately
                      _applyTemporaryFilters(
                        isOpen: value,
                        hasPromo: tempHasPromo.value,
                        minRating: tempMinRating.value,
                      );
                    },
                  );
                },
              ),
              const Divider(),
              ValueListenableBuilder<bool>(
                valueListenable: tempHasPromo,
                builder: (context, hasPromo, child) {
                  return SwitchListTile(
                    title: const Text('Has Promotions'),
                    value: hasPromo,
                    onChanged: (value) {
                      tempHasPromo.value = value;
                      // Apply filter immediately
                      _applyTemporaryFilters(
                        isOpen: tempIsOpen.value,
                        hasPromo: value,
                        minRating: tempMinRating.value,
                      );
                    },
                  );
                },
              ),
              const Text('Minimum Rating'),
              ValueListenableBuilder<double>(
                valueListenable: tempMinRating,
                builder: (context, minRating, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Slider(
                        value: minRating,
                        min: 0,
                        max: 5,
                        divisions: 5,
                        label: minRating > 0 ? minRating.toString() : "Any",
                        onChanged: (value) {
                          tempMinRating.value = value;
                          // Apply filter immediately
                          _applyTemporaryFilters(
                            isOpen: tempIsOpen.value,
                            hasPromo: tempHasPromo.value,
                            minRating: value,
                          );
                        },
                      ),
                      Text(
                        minRating > 0
                            ? '${minRating.toString()} stars or higher'
                            : 'Any rating',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Reset to original values
                _applyTemporaryFilters(
                  isOpen: _isOpen,
                  hasPromo: _hasPromo,
                  minRating: _minRating,
                );
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Save the new values
                setState(() {
                  _isOpen = tempIsOpen.value;
                  _hasPromo = tempHasPromo.value;
                  _minRating = tempMinRating.value;
                });
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  // Add new method for temporary filtering
  void _applyTemporaryFilters({
    required bool isOpen,
    required bool hasPromo,
    required double minRating,
  }) {
    final filteredList = _stalls.where((stall) {
      if (minRating > 0 &&
          (stall.rating == null || stall.rating! < minRating)) {
        return false;
      }

      // Use schedule data for open check
      if (isOpen && !_isStallOpen(stall)) {
        return false;
      }

      if (hasPromo && !stall.hasActivePromotions()) {
        return false;
      }

      return true;
    }).toList();

    // Sort the filtered list
    switch (_sortBy) {
      case 'rating':
        filteredList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'name':
        filteredList.sort((a, b) => a.stanName.compareTo(b.stanName));
        break;
      case 'popularity':
        // Implement popularity logic here
        break;
    }

    // Update the notifier immediately
    _filteredStallsNotifier.value = filteredList;
  }

  // Add scroll to top button
  Widget _buildScrollToTopButton() {
    return AnimatedOpacity(
      opacity: _showScrollToTop ? 1.0 : 0.0,
      duration: Duration(milliseconds: 200),
      child: FloatingActionButton(
        mini: true,
        child: Icon(Icons.arrow_upward),
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  // Add this method after _loadStalls()
  void _applyFilters() {
    // Cancel any pending debounce timer
    _debounceTimer?.cancel();

    // Create a new debounce timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      // Debug: count how many stalls match each filter
      int totalStalls = _stalls.length;
      int ratingFiltered = 0;
      int openFiltered = 0;
      int promoFiltered = 0;
      int categoryFiltered = 0;

      final filteredList = _stalls.where((stall) {
        // Apply minimum rating filter
        if (_minRating > 0 &&
            (stall.rating == null || stall.rating! < _minRating)) {
          ratingFiltered++;
          return false;
        }

        // If "Open Now" filter is active, use our improved check
        if (_isOpen && !_isStallOpen(stall)) {
          openFiltered++;
          return false;
        }

        // Check for active promotions
        if (_hasPromo && !stall.hasActivePromotions()) {
          promoFiltered++;
          return false;
        }

        // Category filter
        if (_selectedCategory != 'All' && stall.category != _selectedCategory) {
          categoryFiltered++;
          return false;
        }

        return true;
      }).toList();

      // Sort the filtered list
      switch (_sortBy) {
        case 'rating':
          filteredList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
          break;
        case 'name':
          filteredList.sort((a, b) => a.stanName.compareTo(b.stanName));
          break;
        case 'popularity':
          // Implement your popularity logic here
          break;
      }

      // Print debug information
      print(
          'Filter results: $totalStalls total, ${filteredList.length} passed');
      print(
          'Filtered out: $ratingFiltered by rating, $openFiltered by open status, '
          '$promoFiltered by promo, $categoryFiltered by category');

      if (_isOpen) {
        print('Open stalls:');
        for (var stall in _stalls) {
          print('${stall.stanName}: isOpen=${_isStallOpen(stall)}, '
              'DB status=${_stallSchedules[stall.id]?["is_open"]}, '
              'stall.isOpen=${stall.isOpen}');
        }
      }

      // Update the notifier
      _filteredStallsNotifier.value = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawer: MyDrawer(studentId: _currentStudent?.id ?? 0),
        floatingActionButton: _buildScrollToTopButton(),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildSearchBar(),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    FoodCategoryBar(
                      selectedCategory: _selectedCategory,
                      onCategorySelected: (category) {
                        setState(() {
                          _selectedCategory = category;
                          // Apply category filter
                          _applyFilters();
                        });
                      },
                    ),
                    FeaturedPromos(stalls: _stalls),
                    _buildPopularSection(),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Divider(),
                    ),
                  ],
                ),
              ),
              _buildSortAndFilter(),
              _buildStallsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularSection() {
    if (_popularStalls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Popular Stalls ⭐',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tabController.index = 1; // Switch to Featured tab
                  });
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200, // Increased height to accommodate content
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _popularStalls.length,
            itemBuilder: (context, index) {
              final stall = _popularStalls[index];
              return _buildPopularStallCard(stall);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPopularStallCard(Stan stall) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToStallDetail(stall),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Stack(
                children: [
                  SizedBox(
                    height: 90, // Reduced image height
                    width: double.infinity,
                    child: Image.network(
                      stall.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          AvatarGenerator.generateStallAvatar(stall.stanName),
                    ),
                  ),
                  // Promo badge
                  if (stall.hasActivePromotions())
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Text(
                          'PROMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Content section - use constrainedBox to prevent overflow
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 95),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Stall name
                      Text(
                        stall.stanName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Rating and status
                      Row(
                        children: [
                          // Rating
                          Icon(Icons.star, size: 12, color: Colors.amber[700]),
                          const SizedBox(width: 2),
                          Text(
                            stall.rating?.toStringAsFixed(1) ?? 'N/A',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),

                          // Compact status badge
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: stall.isOpen
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: stall.isOpen
                                    ? Colors.green[300]!
                                    : Colors.red[300]!,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              stall.isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: stall.isOpen
                                    ? Colors.green[700]
                                    : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Hours - always show in compact form
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 10, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                getStallHours(stall),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: stall.isUsingDefaultSchedule ? Colors.orange[600] : Colors.grey[600],
                                  fontStyle: stall.isUsingDefaultSchedule ? FontStyle.italic : FontStyle.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Only show next opening if closed
                      if (!stall.isOpen &&
                          _nextOpeningTimes.containsKey(stall.id))
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              Icon(Icons.event_available,
                                  size: 10, color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Opens ${_nextOpeningTimes[stall.id] ?? ""}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.orange[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this method after _loadStalls()
  Widget _buildStallsGrid() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 50, color: Colors.red),
              SizedBox(height: 16),
              Text(_errorMessage!),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _handleRefresh,
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }

    // Replace the "No stalls available" section with this improved version
    if (_filteredStalls.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_mall_directory_outlined,
                  size: 70, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No stalls match your filters',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              if (_isOpen)
                Text(
                  'Try showing closed stalls as well',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              SizedBox(height: 16),

              // Show two separate buttons for more control
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Button to toggle just the Open Now filter
                  if (_isOpen)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isOpen = false;
                          _isOpenNotifier.value = false;
                        });
                        _applyFilters();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      icon: Icon(Icons.visibility_outlined),
                      label: Text('Show All Stalls'),
                    ),

                  // Add some spacing if both buttons are shown
                  if (_isOpen &&
                      (_hasPromo ||
                          _minRating > 0 ||
                          _selectedCategory != 'All'))
                    SizedBox(width: 12),

                  // Reset all filters button
                  if (_hasPromo || _minRating > 0 || _selectedCategory != 'All')
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _hasPromo = false;
                          _hasPromoNotifier.value = false;
                          _minRating = 0;
                          _minRatingNotifier.value = 0;
                          _selectedCategory = 'All';
                        });
                        _applyFilters();
                      },
                      icon: Icon(Icons.filter_alt_off),
                      label: Text('Reset Other Filters'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final stall = _filteredStalls[index];
          // Modify AnimatedStallTile to include schedule information
          return AnimatedStallTile(
            stall: stall,
            onTap: () => _navigateToStallDetail(stall),
            useHero: true,
            openingHours: getStallHours(stall),
            isCurrentlyOpenBySchedule: _isStallOpen(stall),
          );
        },
        childCount: _filteredStalls.length,
      ),
    );
  }

  // Add a new timer to periodically refresh stall statuses
  Timer? _stallStatusTimer;

  // Add this method to refresh stall statuses without full reload
  Future<void> _refreshStallStatuses() async {
    if (!mounted || _isLoading) return;

    try {
      // For each loaded stall, check if its status has changed
      for (final stall in _stalls) {
        final isCurrentlyOpen =
            await _stanService.checkIfStoreIsOpenNow(stall.id);

        // If the status changed, update it
        if (stall.isOpen != isCurrentlyOpen) {
          setState(() {
            stall.isOpen = isCurrentlyOpen;

            // If it's now closed, get the next opening time
            if (!isCurrentlyOpen) {
              _stanService.getNextOpeningInfo(stall.id).then((nextOpening) {
                if (mounted) {
                  setState(() {
                    _nextOpeningTimes[stall.id] = nextOpening;
                  });
                }
              });
            } else {
              // If now open, remove any next opening time
              _nextOpeningTimes.remove(stall.id);
            }
          });
        }
      }

      // Re-apply filters as status changes might affect filtered results
      _applyFilters();
    } catch (e) {
      print('Error refreshing stall statuses: $e');
      // Don't show UI errors for background updates
    }
  }

  @override
  void dispose() {
    _isOpenNotifier.dispose();
    _hasPromoNotifier.dispose();
    _minRatingNotifier.dispose();
    _debounceTimer?.cancel();
    _filteredStallsNotifier.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    _isDisposed = true; // Set flag when disposing
    _stallStatusTimer?.cancel();
    super.dispose();
  }
}
