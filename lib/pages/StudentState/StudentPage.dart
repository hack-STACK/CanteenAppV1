import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:kantin/Component/my_Description_Box.dart';
import 'package:kantin/Component/my_Silver_App_Bar.dart';
import 'package:kantin/Component/my_current_location.dart';
import 'package:kantin/Component/my_drawer.dart';
import 'package:kantin/Component/my_stall_tile.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/student_models.dart';
import 'package:kantin/Services/Database/Stan_service.dart';
import 'package:kantin/pages/StudentState/Stalldetailpage.dart';
import 'package:kantin/utils/avatar_generator.dart';
import 'package:kantin/utils/banner_generator.dart';
import 'package:kantin/Services/Database/studentService.dart';
import 'package:kantin/pages/StudentState/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin/pages/StudentState/OrderPage.dart'; // Add this import
import 'package:kantin/widgets/student/food_category_grid.dart';
import 'package:kantin/widgets/search_bar_delegate.dart';
import 'package:kantin/widgets/student/student_profile_header.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<StudentPage> {
  final StanService _stanService = StanService();
  List<Stan> _stalls = [];
  List<Stan> _popularStalls = [];
  bool _isLoading = true;
  bool _isLoadingProfile = true; // Add this variable
  final TextEditingController _searchController = TextEditingController();
  final CarouselController _carouselController = CarouselController();
  int _currentBannerIndex = 0;

  final int _bannerCount = 3;

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.fastfood, 'label': 'Food', 'color': Colors.orange},
    {'icon': Icons.local_drink, 'label': 'Drinks', 'color': Colors.blue},
    {'icon': Icons.icecream, 'label': 'Snacks', 'color': Colors.purple},
    {'icon': Icons.food_bank, 'label': 'Rice', 'color': Colors.green},
    {'icon': Icons.lunch_dining, 'label': 'Noodles', 'color': Colors.red},
    {'icon': Icons.cake, 'label': 'Dessert', 'color': Colors.pink},
  ];

  final StudentService _studentService = StudentService();
  StudentModel? _currentStudent;
  final _supabase = Supabase.instance.client;

  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  String _selectedCategory = 'All';
  final List<String> _recentSearches = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Add this

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadStudentData();
    // Delay the data loading to ensure Scaffold is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
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

      // Get the user data directly from shared preferences or your auth state
      final userId = 36; // This should come from your auth state management
      print('Debug: Using user ID - $userId');

      // Get student data using user_id directly;
      final studentResponse = await _supabase
          .from('students')
          .select()
          .eq('id_user', userId)
          .single();

      print('Debug: Student response - $studentResponse');

      if (mounted) {
        setState(() {
          _currentStudent = studentResponse != null
              ? StudentModel.fromMap(studentResponse)
              : null;
          _isLoadingProfile = false;
        });

        // Show complete profile dialog only if in the right context
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
        // Delay showing SnackBar to ensure Scaffold is ready
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

      setState(() {
        _stalls = stalls;
        _popularStalls = popularStalls.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stalls: $e')),
      );
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

  Widget _buildCategories() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Container(
            width: 72,
            margin: const EdgeInsets.only(right: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category['icon'],
                    color: category['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category['label'],
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
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
                        builder: (context) => StallDetailPage(stall: stall),
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
    return StudentProfileHeader(
      student: _currentStudent,
      isLoading: _isLoadingProfile,
      onProfileComplete: _navigateToProfileSetup,
      onRefresh: _loadStudentData,
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.grey[50],
        drawer: const MyDrawer(),
        body: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _loadStudentData(),
              _loadStalls(),
            ]);
          },
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildProfileSection()), // Add this line
              _buildSearchBar(),
              SliverToBoxAdapter(child: _buildCategories()),
              SliverToBoxAdapter(child: _buildBannerCarousel()),
              SliverToBoxAdapter(child: _buildPopularStalls()),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const Divider(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'All Stalls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStallsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStallsList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_stalls.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No stalls available')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => AnimatedStallTile(
            stall: _stalls[index],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StallDetailPage(stall: _stalls[index]),
              ),
            ),
          ),
          childCount: _stalls.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
