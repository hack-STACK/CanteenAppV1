import 'dart:async';

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kantin/Component/my_drawer.dart';
import 'package:kantin/Component/my_stall_tile.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Services/Auth/auth_Service.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/Services/Database/UserService.dart';
import 'package:kantin/pages/StudentState/Stalldetailpage.dart';
import 'package:kantin/utils/avatar_generator.dart';
import 'package:kantin/utils/banner_generator.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/widgets/home/featured_promos.dart';
import 'package:kantin/widgets/home/food_category_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Add this import
import 'package:kantin/widgets/search_bar_delegate.dart';
import 'package:kantin/widgets/student/student_profile_header.dart';
import 'package:kantin/widgets/shimmer/shimmer_loading.dart'; // Add this import
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kantin/widgets/stall/stall_status_badge.dart';

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
  final UserService _userService = UserService(); // Add this line
  List<Stan> _stalls = [];
  List<Stan> _popularStalls = [];
  bool _isLoading = true;
  bool _isLoadingProfile = true; // Add this variable
  final TextEditingController _searchController = TextEditingController();
  final CarouselController _carouselController = CarouselController();
  int _currentBannerIndex = 0;

  final int _bannerCount = 3;

  final List<String> _recentSearches = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Add this

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
  String _sortBy = 'rating'; // New sorting state

  // New filtering states
  bool _isOpen = true;
  double _minRating = 0.0;
  bool _hasPromo = false;

  // New UI states
  bool _showScrollToTop = false;
  int _selectedStallIndex = -1;

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

  Future<void> _loadStalls() async {
    try {
      setState(() => _isLoading = true);
      final stalls = await _stanService.getAllStans();

      // Sort stalls by rating to get popular stalls, handling null ratings
      final popularStalls = List<Stan>.from(stalls)
        ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

      if (!_isDisposed) {
        // Check flag before setState
        setState(() {
          _stalls = stalls;
          _popularStalls = popularStalls.take(5).toList();
          _isLoading = false;
        });
      }

      // Apply initial filters
      _applyFilters();
    } catch (e) {
      if (!_isDisposed) {
        // Check flag before setState
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stalls: $e')),
        );
      }
    }
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

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _bannerCount,
          itemBuilder: (context, index, realIndex) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              child: BannerGenerator.generateBanner(index),
            );
          },
          options: CarouselOptions(
            height: 180.0,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            autoPlay: true,
            onPageChanged: (index, reason) {
              setState(() => _currentBannerIndex = index);
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_bannerCount, (index) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(
                vertical: 8.0,
                horizontal: 4.0,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .primaryColor
                    .withOpacity(_currentBannerIndex == index ? 0.9 : 0.4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPopularStalls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Popular Stalls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Show all popular stalls
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _popularStalls.length,
            itemBuilder: (context, index) {
              final stall = _popularStalls[index];
              return SizedBox(
                width: 160,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StallDetailPage(
                          stall: stall,
                          StudentId: _currentStudent?.id ??
                              0, // Add the StudentId parameter
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 120,
                          width: double.infinity,
                          child: stall.imageUrl != null
                              ? Image.network(
                                  stall.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return AvatarGenerator.generateStallAvatar(
                                      stall.stanName,
                                      size: 120,
                                    );
                                  },
                                )
                              : AvatarGenerator.generateStallAvatar(
                                  stall.stanName,
                                  size: 120,
                                ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stall.stanName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      size: 16, color: Colors.amber),
                                  Text(
                                    ' ${stall.rating?.toStringAsFixed(1) ?? "N/A"}',
                                    style: TextStyle(fontSize: 12),
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    return SliverToBoxAdapter(
      child: StudentProfileHeader(
        student: _currentStudent,
        isLoading: _isLoadingProfile,
        onProfileComplete: _navigateToProfileSetup,
        onRefresh: _loadStudentData,
      ),
    );
  }

  void _navigateToProfileSetup() {
    // Navigate to profile setup/completion page
    Navigator.pushNamed(context, '/profile/setup')
        .then((_) => _loadStudentData());
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: _isScrolled ? 4 : 0,
      backgroundColor: _isScrolled ? Colors.white : Colors.transparent,
      leading: IconButton(
        // Add this leading button to open drawer
        icon: Icon(
          Icons.menu,
          color: _isScrolled ? Colors.black : Colors.white,
        ),
        onPressed: _openDrawer, // Update this
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
            child: AnimatedStallTile(
              stall: stall,
              onTap: () => _navigateToStallDetail(stall),
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
          StudentId: _currentStudent?.id ?? 0,
        ),
      ),
    ).then((_) => _loadStalls()); // Refresh after returning
  }

  Widget _buildTabView() {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'All Stalls'),
                Tab(text: 'Featured'),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
            ),
          ),
          Container(
            height:
                MediaQuery.of(context).size.height * 0.6, // Increased height
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllStallsGrid(),
                _buildFeaturedStalls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllStallsGrid() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<List<Stan>>(
      valueListenable: _filteredStallsNotifier,
      builder: (context, filteredStalls, child) {
        if (filteredStalls.isEmpty) {
          return const Center(child: Text('No stalls found'));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: filteredStalls.length,
          itemBuilder: (context, index) =>
              _buildStallCard(filteredStalls[index]),
        );
      },
    );
  }

  Widget _buildStallCard(Stan stall) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToStallDetail(stall),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: stall.imageUrl != null
                        ? Image.network(
                            stall.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                AvatarGenerator.generateStallAvatar(
                                    stall.stanName),
                          )
                        : AvatarGenerator.generateStallAvatar(stall.stanName),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: StallStatusBadge(stall: stall),
                ),
                if (stall.hasActivePromotions())
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'PROMO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stall.stanName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(
                        ' ${stall.rating?.toStringAsFixed(1) ?? "N/A"}',
                        style: TextStyle(fontSize: 12),
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

  Widget _buildFeaturedStalls() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return _popularStalls.isEmpty
        ? Center(child: Text('No featured stalls'))
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _popularStalls.length,
            itemBuilder: (context, index) {
              final stall = _popularStalls[index];
              return _buildStallCard(stall);
            },
          );
  }

  // Add new sorting method
  void _sortStalls() {
    _applyFilters(); // Re-apply filters with new sort
  }

  // Add sort and filter UI
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
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
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
                    title: const Text('Open Now'),
                    value: isOpen,
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
                  return Slider(
                    value: minRating,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: minRating.toString(),
                    onChanged: (value) {
                      tempMinRating.value = value;
                      // Apply filter immediately
                      _applyTemporaryFilters(
                        isOpen: tempIsOpen.value,
                        hasPromo: tempHasPromo.value,
                        minRating: value,
                      );
                    },
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
              child: const Text('Save'),
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

      if (isOpen && !stall.isCurrentlyOpen()) {
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

      final filteredList = _stalls.where((stall) {
        // Apply minimum rating filter
        if (_minRating > 0 &&
            (stall.rating == null || stall.rating! < _minRating)) {
          return false;
        }

        // Only apply open/closed filter if the stall has this information
        if (_isOpen && !stall.isCurrentlyOpen()) {
          return false;
        }

        // Check for active promotions
        if (_hasPromo && !stall.hasActivePromotions()) {
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
          height: 200,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => _navigateToStallDetail(stall),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        stall.imageUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            AvatarGenerator.generateStallAvatar(stall.stanName),
                      ),
                      if (stall.hasActivePromotions())
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PROMO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stall.stanName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stall.rating?.toStringAsFixed(1) ?? 'N/A',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (stall.isCurrentlyOpen())
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Open',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
    );
  }

  // Add this method after _loadStalls()
  Widget _buildStallsGrid() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final stall = _filteredStalls[index];
          // Remove Hero wrapper since it's handled by AnimatedStallTile
          return AnimatedStallTile(
            stall: stall,
            onTap: () => _navigateToStallDetail(stall),
            useHero: true, // Enable Hero animation
          );
        },
        childCount: _filteredStalls.length,
      ),
    );
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
    super.dispose();
  }
}
