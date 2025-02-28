import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Models/stall_detail_models.dart';
import 'package:kantin/Services/Database/Stan_service.dart';

class StallInfoSection extends StatefulWidget {
  final Stan stall;
  final List<StallMetric> metrics;
  final List<String> paymentMethods;
  final Map<String, String> scheduleByDay;
  final List<String> amenities;
  final double stallRating;

  const StallInfoSection({
    super.key,
    required this.stall,
    required this.metrics,
    required this.paymentMethods,
    required this.scheduleByDay,
    required this.amenities,
    this.stallRating = 0.0,
  });

  @override
  State<StallInfoSection> createState() => _StallInfoSectionState();
}

class _StallInfoSectionState extends State<StallInfoSection>
    with SingleTickerProviderStateMixin {
  final bool _showFullSchedule = false;
  bool _showFullDescription = false;
  late TabController _tabController;
  final List<String> _tabs = ['Info', 'Hours', 'Amenities', 'Payments'];
  bool _showFloatingHeader = false;
  final ScrollController _scrollController = ScrollController();

  final StanService _stallService = StanService();
  bool _isScheduleLoading = false;
  Map<String, dynamic>? _databaseSchedule;
  String? _nextOpeningTime;
  Timer? _scheduleRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _scrollController.addListener(_onScroll);

    _fetchStallSchedule();
    _scheduleRefreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        _fetchStallSchedule();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scheduleRefreshTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    final showHeader = _scrollController.offset > 50;
    if (showHeader != _showFloatingHeader) {
      setState(() => _showFloatingHeader = showHeader);
    }
  }

  Future<void> _fetchStallSchedule() async {
    if (!mounted) return;

    setState(() => _isScheduleLoading = true);

    try {
      final scheduleData =
          await _stallService.getStallSchedulesByDay(widget.stall.id);

      if (!widget.stall.isScheduleOpen()) {
        _nextOpeningTime =
            await _stallService.getNextOpeningInfo(widget.stall.id);
      } else {
        _nextOpeningTime = null;
      }

      if (mounted) {
        setState(() {
          _databaseSchedule = scheduleData;
          _isScheduleLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching stall schedule: $e');
      if (mounted) {
        setState(() => _isScheduleLoading = false);
      }
    }
  }

  String _getFormattedHoursForDay(String day) {
    if (_databaseSchedule != null && _databaseSchedule!.containsKey(day)) {
      final daySchedule = _databaseSchedule![day];

      if (daySchedule['is_open'] != true) {
        return 'Closed';
      }

      final openTime =
          _formatDatabaseTimeString(daySchedule['open_time'] ?? '09:00:00');
      final closeTime =
          _formatDatabaseTimeString(daySchedule['close_time'] ?? '17:00:00');

      return '$openTime - $closeTime';
    }

    final dayOfWeek = _getDayOfWeekFromName(day);
    return widget.scheduleByDay[dayOfWeek] ?? 'Hours not set';
  }

  String _formatDatabaseTimeString(String timeStr) {
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

  String _getDayOfWeekFromName(String shortName) {
    switch (shortName.toLowerCase()) {
      case 'mon':
        return 'Monday';
      case 'tue':
        return 'Tuesday';
      case 'wed':
        return 'Wednesday';
      case 'thu':
        return 'Thursday';
      case 'fri':
        return 'Friday';
      case 'sat':
        return 'Saturday';
      case 'sun':
        return 'Sunday';
      default:
        return shortName;
    }
  }

  bool _isOpenOnDay(String day) {
    if (_databaseSchedule != null && _databaseSchedule!.containsKey(day)) {
      return _databaseSchedule![day]['is_open'] == true;
    }

    final dayOfWeek = _getDayOfWeekFromName(day);
    return widget.scheduleByDay[dayOfWeek] != 'Closed';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
            ],
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _buildHeaderSection(colorScheme),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: colorScheme.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ),
              SizedBox(
                height: 350,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(),
                    _buildHoursTab(colorScheme),
                    _buildAmenitiesTab(),
                    _buildPaymentsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_showFloatingHeader)
          AnimatedOpacity(
            opacity: _showFloatingHeader ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              height: 60,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.stall.imageUrl != null
                        ? NetworkImage(widget.stall.imageUrl!)
                        : null,
                    backgroundColor: Colors.grey[200],
                    child: widget.stall.imageUrl == null
                        ? Icon(Icons.store, color: Colors.grey[500])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.stall.stanName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.stallRating > 0) ...[
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      widget.stallRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeaderSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.5),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: widget.stall.imageUrl != null
                      ? Image.network(
                          widget.stall.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.store,
                                size: 32,
                                color: Colors.grey[500],
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.store,
                            size: 32,
                            color: Colors.grey[500],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stall.stanName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildOpenStatusBadge(),
                    const SizedBox(height: 8),
                    if (widget.stallRating > 0)
                      Row(
                        children: [
                          _buildRatingStars(widget.stallRating),
                          const SizedBox(width: 8),
                          Text(
                            widget.stallRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.stall.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildDescription(),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _buildEnhancedMetricsRow(),
        ],
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    final int fullStars = rating.floor();
    final bool hasHalfStar = rating - fullStars >= 0.5;
    final int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          fullStars,
          (index) => const Icon(Icons.star, color: Colors.amber, size: 18),
        ),
        if (hasHalfStar)
          const Icon(Icons.star_half, color: Colors.amber, size: 18),
        ...List.generate(
          emptyStars,
          (index) => Icon(Icons.star_border, color: Colors.grey[400], size: 18),
        ),
      ],
    );
  }

  Widget _buildOpenStatusBadge() {
    final now = DateTime.now();
    final currentTime = TimeOfDay.fromDateTime(now);
    final currentDay = DateFormat('EEEE').format(now);

    final todaySchedule = widget.scheduleByDay[currentDay] ?? 'Closed';

    bool isOpen = false;
    if (todaySchedule != 'Closed') {
      try {
        final times = todaySchedule.split(' - ');
        if (times.length == 2) {
          final openTime = _parseTimeString(times[0]);
          final closeTime = _parseTimeString(times[1]);

          if (openTime != null && closeTime != null) {
            final currentMinutes = currentTime.hour * 60 + currentTime.minute;
            final openMinutes = openTime.hour * 60 + openTime.minute;
            final closeMinutes = closeTime.hour * 60 + closeTime.minute;

            isOpen =
                currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
          }
        }
      } catch (e) {
        print('Error parsing schedule time: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? Colors.green[300]! : Colors.red[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOpen ? Colors.green[500] : Colors.red[500],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isOpen ? Colors.green[500] : Colors.red[500])!
                      .withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOpen ? 'Open Now' : 'Closed',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isOpen ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final description = widget.stall.description ?? '';
    final displayText = _showFullDescription || description.length <= 100
        ? description
        : '${description.substring(0, 100)}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
            height: 1.6,
          ),
        ),
        if (description.length > 100)
          TextButton(
            onPressed: () {
              setState(() {
                _showFullDescription = !_showFullDescription;
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _showFullDescription ? 'Show less' : 'Read more',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showFullDescription
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 16,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEnhancedMetricsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: widget.metrics
            .map((metric) => _buildEnhancedMetricItem(metric))
            .toList(),
      ),
    );
  }

  Widget _buildEnhancedMetricItem(StallMetric metric) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: metric.color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: metric.color.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Icon(
            metric.icon,
            color: metric.color,
            size: 22,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          metric.value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          metric.label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            title: 'Stall Information',
            icon: Icons.info_outline,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                    'Category', widget.stall.stanName.split(' ').first),
                _buildInfoRow('Location', widget.stall.slot),
                _buildInfoRow('Vendor', widget.stall.ownerName),
                _buildInfoRow('Since', '2023'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Today\'s Schedule',
            icon: Icons.schedule,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTodaySchedule(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            title: 'Popular Items',
            icon: Icons.trending_up,
            content: Row(
              children: [
                _buildPopularItem(
                    'Nasi Goreng', '25K+', 'assets/icons/fried-rice.png'),
                const SizedBox(width: 16),
                _buildPopularItem(
                    'Es Teh', '18K+', 'assets/icons/iced-tea.png'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final now = DateTime.now();
    final today = DateFormat('EEEE').format(now);
    final shortToday = _getShortDayName(today);

    final String todaySchedule = _getFormattedHoursForDay(shortToday);
    final bool isOpen = _isOpenOnDay(shortToday);

    String remainingTime = '';
    String closeTimeStr = ''; // Declare closeTimeStr outside the try block

    if (isOpen && todaySchedule != 'Closed') {
      try {
        closeTimeStr =
            todaySchedule.split(' - ').last; // Assign value inside try
        final closeTime = _parseTimeString(closeTimeStr);
        if (closeTime != null) {
          final currentTime = TimeOfDay.now();

          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          final closeMinutes = closeTime.hour * 60 + closeTime.minute;

          if (closeMinutes > currentMinutes) {
            final remaining = closeMinutes - currentMinutes;
            final hours = remaining ~/ 60;
            final minutes = remaining % 60;

            if (hours > 0) {
              remainingTime = '$hours hr ${minutes > 0 ? '$minutes min' : ''}';
            } else {
              remainingTime = '$minutes min';
            }
          }
        }
      } catch (e) {
        print('Error calculating remaining time: $e');
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green[100] : Colors.red[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOpen ? Icons.check_circle : Icons.access_time,
                  color: isOpen ? Colors.green[700] : Colors.red[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOpen ? 'Open Now' : 'Closed Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isOpen ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                  Text(
                    isOpen
                        ? remainingTime.isNotEmpty
                            ? 'Closes in $remainingTime'
                            : closeTimeStr.isNotEmpty
                                ? 'Open until $closeTimeStr'
                                : 'Open today'
                        : _nextOpeningTime != null &&
                                _nextOpeningTime!.isNotEmpty
                            ? 'Opens $_nextOpeningTime'
                            : 'Closed for today',
                    style: TextStyle(
                      fontSize: 13,
                      color: isOpen ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'Today\'s Hours ($today)',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOpen ? Colors.green[200]! : Colors.red[200]!,
              ),
            ),
            child: Text(
              todaySchedule,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isOpen ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
          if (widget.stall.isManuallyOpen)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pan_tool, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Store hours are manually controlled',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopularItem(String name, String orders, String iconPath) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Icon(Icons.fastfood, color: Colors.orange[400]),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '$orders orders',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
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

  Widget _buildHoursTab(ColorScheme colorScheme) {
    final today = DateFormat('EEEE').format(DateTime.now());
    final shortToday = _getShortDayName(today);

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return _isScheduleLoading
        ? _buildLoadingHoursTab()
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildWeekVisualizerCard(days, shortToday),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 20,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Weekly Hours',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...days.map((shortDay) {
                      final dayName = _getDayOfWeekFromName(shortDay);
                      final isToday = dayName == today;
                      final hours = _getFormattedHoursForDay(shortDay);

                      return Container(
                        decoration: BoxDecoration(
                          color: isToday
                              ? colorScheme.primary.withOpacity(0.04)
                              : null,
                          border: !isToday
                              ? Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                )
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Row(
                                children: [
                                  if (isToday)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  Text(
                                    shortDay,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isToday
                                          ? colorScheme.primary
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                hours,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isToday
                                      ? colorScheme.primary
                                      : Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (widget.stall.isManuallyOpen)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This store is manually controlled by the owner and may open or close regardless of scheduled hours.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildLoadingHoursTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Loading schedule...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getShortDayName(String fullDay) {
    switch (fullDay) {
      case 'Monday':
        return 'Mon';
      case 'Tuesday':
        return 'Tue';
      case 'Wednesday':
        return 'Wed';
      case 'Thursday':
        return 'Thu';
      case 'Friday':
        return 'Fri';
      case 'Saturday':
        return 'Sat';
      case 'Sunday':
        return 'Sun';
      default:
        return fullDay.substring(0, 3);
    }
  }

  Widget _buildWeekVisualizerCard(List<String> days, String today) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Theme.of(context).primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Week at a Glance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.refresh, size: 16),
                  onPressed: _fetchStallSchedule,
                  tooltip: 'Refresh schedule',
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(width: 24, height: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: days.map((day) {
                final isToday = day == today;
                final isOpen = _isOpenOnDay(day);
                final hours = _getFormattedHoursForDay(day);

                return Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isToday
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? Theme.of(context).primaryColor.withOpacity(0.5)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isToday
                              ? Theme.of(context).primaryColor
                              : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(11),
                          ),
                        ),
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          day,
                          style: TextStyle(
                            color: isToday ? Colors.white : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOpen
                                    ? Colors.green[500]
                                    : Colors.red[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isOpen ? 'Open' : 'Closed',
                              style: TextStyle(
                                color: isOpen
                                    ? Colors.green[700]
                                    : Colors.red[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isOpen ? hours.split(' - ').join('\n') : '',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Available Amenities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: widget.amenities.length,
          itemBuilder: (context, index) {
            final amenity = widget.amenities[index];

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getAmenityIcon(amenity),
                      color: Colors.blue[600],
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      amenity,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Amenities Information',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'These amenities are provided to enhance your dining experience. If you need any special accommodations, please speak with our staff.',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.paymentMethods
            .map((method) => _buildPaymentMethodCard(method)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cash payments require exact change. For QRIS payments, scan the code at the counter.',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: _getPaymentColor(method).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPaymentIcon(method),
              color: _getPaymentColor(method),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getPaymentDescription(method),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(
            Icons.check_circle,
            color: Colors.green[700],
            size: 20,
          ),
        ],
      ),
    );
  }

  String _getPaymentDescription(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Pay with physical money';
      case 'qris':
        return 'Scan QR code to pay';
      case 'e-wallet':
        return 'Use digital wallet apps';
      case 'credit card':
        return 'Major cards accepted';
      case 'debit card':
        return 'Direct from bank account';
      default:
        return 'Payment option';
    }
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      print('Error parsing time string: $e');
      return null;
    }
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'air conditioning':
        return Icons.ac_unit;
      case 'seating available':
        return Icons.event_seat;
      case 'takeaway':
        return Icons.takeout_dining;
      case 'halal certified':
        return Icons.check_circle;
      case 'vegetarian options':
        return Icons.spa;
      case 'wifi':
        return Icons.wifi;
      case 'bathroom':
        return Icons.wc;
      case 'delivery':
        return Icons.delivery_dining;
      default:
        return Icons.check;
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'qris':
        return Icons.qr_code;
      case 'e-wallet':
        return Icons.account_balance_wallet;
      case 'credit card':
        return Icons.credit_card;
      case 'debit card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'qris':
        return Colors.blue;
      case 'e-wallet':
        return Colors.purple;
      case 'credit card':
        return Colors.orange;
      case 'debit card':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
