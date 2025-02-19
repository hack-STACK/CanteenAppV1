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

  @override
  void initState() {
    super.initState();
    // Delay the data loading to ensure Scaffold is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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

      // Get student data using user_id directly
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
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for food or stalls...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                color: Theme.of(context).primaryColor.withOpacity(
                    _currentBannerIndex == index ? 0.9 : 0.4),
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    if (_isLoadingProfile) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 20,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _currentStudent != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProfilePage(student: _currentStudent!),
                ),
              ).then((_) => _loadStudentData()) // Reload data when returning from profile page
          : () {
              // Show message to complete profile if no student data
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please complete your profile'),
                  action: SnackBarAction(
                    label: 'Complete',
                    onPressed: () => _navigateToProfileSetup(),
                  ),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child: _currentStudent?.studentImage != null && 
                     _currentStudent!.studentImage!.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        _currentStudent!.studentImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return AvatarGenerator.generateStallAvatar(
                            _currentStudent?.studentName ?? 'Profile',
                            size: 60,
                          );
                        },
                      ),
                    )
                  : AvatarGenerator.generateStallAvatar(
                      _currentStudent?.studentName ?? 'Profile',
                      size: 60,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentStudent?.studentName ?? 'Complete Your Profile',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentStudent?.studentAddress != null)
                    Text(
                      _currentStudent!.studentAddress,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  void _navigateToProfileSetup() {
    // Navigate to profile setup/completion page
    Navigator.pushNamed(context, '/profile/setup').then((_) => _loadStudentData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadStudentData(),
            _loadStalls(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            MySilverAppBar(
              title: const Text('Food Court'),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildProfileSection(),
                  const MyCurrentLocation(),
                  _buildSearchBar(),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildBannerCarousel(),
                  _buildCategories(),
                  _buildPopularStalls(),
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
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _stalls.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(child: Text('No stalls available')),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => AnimatedStallTile(
                              stall: _stalls[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StallDetailPage(
                                      stall: _stalls[index],
                                    ),
                                  ),
                                );
                              },
                            ),
                            childCount: _stalls.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
