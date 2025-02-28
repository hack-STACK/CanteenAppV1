import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/stall_schedule.dart';
import '../../services/stall_schedule_service.dart';

class ScheduleManagerWidget extends StatefulWidget {
  final int stallId;
  final Function() onScheduleUpdated;

  const ScheduleManagerWidget({
    super.key,
    required this.stallId,
    required this.onScheduleUpdated,
  });

  @override
  State<ScheduleManagerWidget> createState() => _ScheduleManagerWidgetState();
}

class _ScheduleManagerWidgetState extends State<ScheduleManagerWidget>
    with SingleTickerProviderStateMixin {
  final StallScheduleService _scheduleService = StallScheduleService();
  late TabController _tabController;
  final List<String> _tabs = ['Weekly Schedule', 'Special Days'];

  List<StallSchedule> _schedules = [];
  bool _isLoading = true;
  String? _error;

  // Map to store weekly schedules by day
  final Map<String, Map<String, dynamic>> _weeklySchedules = {
    'Mon': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 8, minute: 0),
      'closeTime': const TimeOfDay(hour: 17, minute: 0)
    },
    'Tue': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 8, minute: 0),
      'closeTime': const TimeOfDay(hour: 17, minute: 0)
    },
    'Wed': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 8, minute: 0),
      'closeTime': const TimeOfDay(hour: 17, minute: 0)
    },
    'Thu': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 8, minute: 0),
      'closeTime': const TimeOfDay(hour: 17, minute: 0)
    },
    'Fri': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 8, minute: 0),
      'closeTime': const TimeOfDay(hour: 17, minute: 0)
    },
    'Sat': {
      'isOpen': true,
      'openTime': const TimeOfDay(hour: 9, minute: 0),
      'closeTime': const TimeOfDay(hour: 15, minute: 0)
    },
    'Sun': {
      'isOpen': false,
      'openTime': const TimeOfDay(hour: 8, minute: 0),
      'closeTime': const TimeOfDay(hour: 17, minute: 0)
    },
  };

  // List to store special day schedules
  List<Map<String, dynamic>> _specialDays = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    try {
      setState(() => _isLoading = true);
      _schedules = await _scheduleService.getSchedulesForStall(widget.stallId);

      // Process schedules into weekly and special days
      _processSchedules();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _processSchedules() {
    // Reset defaults
    for (var day in _weeklySchedules.keys) {
      _weeklySchedules[day] = {
        'isOpen': true,
        'openTime': const TimeOfDay(hour: 8, minute: 0),
        'closeTime': const TimeOfDay(hour: 17, minute: 0)
      };
    }
    _specialDays = [];

    // Process regular weekly schedules
    for (var schedule in _schedules) {
      if (schedule.dayOfWeek != null && schedule.specificDate == null) {
        _weeklySchedules[schedule.dayOfWeek!] = {
          'isOpen': schedule.isOpen,
          'openTime': schedule.openTime ?? const TimeOfDay(hour: 8, minute: 0),
          'closeTime':
              schedule.closeTime ?? const TimeOfDay(hour: 17, minute: 0),
          'scheduleId': schedule.id
        };
      }
      // Process special day schedules
      else if (schedule.specificDate != null) {
        _specialDays.add({
          'date': schedule.specificDate!,
          'isOpen': schedule.isOpen,
          'openTime': schedule.openTime,
          'closeTime': schedule.closeTime,
          'scheduleId': schedule.id
        });
      }
    }

    // Sort special days by date
    _specialDays.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  Future<void> _saveWeeklySchedule(String day) async {
    try {
      final schedule = _weeklySchedules[day]!;
      final int scheduleId = schedule['scheduleId'] ?? 0;

      // Create a StallSchedule object
      final stallSchedule = StallSchedule(
        id: scheduleId,
        stallId: widget.stallId,
        dayOfWeek: day,
        openTime: schedule['openTime'] as TimeOfDay,
        closeTime: schedule['closeTime'] as TimeOfDay,
        isOpen: schedule['isOpen'] as bool,
        specificDate: null,
        createdAt: DateTime.now(),
      );

      // Save the schedule
      await _scheduleService.saveSchedule(stallSchedule);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Schedule for $day updated')));
      }

      // Reload schedules and notify parent
      await _loadSchedules();
      widget.onScheduleUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error updating schedule: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _saveSpecialDaySchedule(Map<String, dynamic> specialDay) async {
    try {
      final int scheduleId = specialDay['scheduleId'] ?? 0;

      // Create a StallSchedule object for special day
      final stallSchedule = StallSchedule(
        id: scheduleId,
        stallId: widget.stallId,
        dayOfWeek: null,
        openTime:
            specialDay['isOpen'] ? (specialDay['openTime'] as TimeOfDay) : null,
        closeTime: specialDay['isOpen']
            ? (specialDay['closeTime'] as TimeOfDay)
            : null,
        isOpen: specialDay['isOpen'] as bool,
        specificDate: specialDay['date'] as DateTime,
        createdAt: DateTime.now(),
      );

      // Save the schedule
      await _scheduleService.saveSchedule(stallSchedule);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Special day schedule updated')));
      }

      // Reload schedules and notify parent
      await _loadSchedules();
      widget.onScheduleUpdated();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error updating special day: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteSpecialDay(Map<String, dynamic> specialDay) async {
    try {
      final int scheduleId = specialDay['scheduleId'] ?? 0;

      // Only attempt to delete if we have a valid scheduleId
      if (scheduleId > 0) {
        await _scheduleService.deleteSchedule(scheduleId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Special day schedule deleted')));
        }

        // Reload schedules and notify parent
        await _loadSchedules();
        widget.onScheduleUpdated();
      } else {
        // If no scheduleId, just remove from local list without database operation
        setState(() {
          _specialDays.removeWhere((day) => (day['date'] as DateTime)
              .isAtSameMomentAs(specialDay['date'] as DateTime));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error deleting special day: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _addSpecialDay() async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = now.add(const Duration(days: 1));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );

    if (selectedDate == null) return;

    // Check if this date already exists
    if (_specialDays.any((day) =>
        day['date'].year == selectedDate.year &&
        day['date'].month == selectedDate.month &&
        day['date'].day == selectedDate.day)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('This date already has a special schedule')));
      }
      return;
    }

    setState(() {
      _specialDays.add({
        'date': selectedDate,
        'isOpen': false, // Default to closed for special days
        'openTime': const TimeOfDay(hour: 8, minute: 0),
        'closeTime': const TimeOfDay(hour: 17, minute: 0),
      });

      // Sort special days
      _specialDays.sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    });
  }

  // Format TimeOfDay to string
  String _formatTimeOfDay(TimeOfDay time) {
    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  Future<TimeOfDay?> _selectTime(
      BuildContext context, TimeOfDay initialTime) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
  }

  Widget _buildWeeklyScheduleTab() {
    final dayFullNames = {
      'Mon': 'Monday',
      'Tue': 'Tuesday',
      'Wed': 'Wednesday',
      'Thu': 'Thursday',
      'Fri': 'Friday',
      'Sat': 'Saturday',
      'Sun': 'Sunday',
    };

    // Return a widget for the weekly schedule tab
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Edit Weekly Schedule',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._weeklySchedules.entries.map((entry) {
          final day = entry.key;
          final schedule = entry.value;
          return _buildWeeklyScheduleItem(
              day, dayFullNames[day] ?? day, schedule);
        }),
      ],
    );
  }

  // Add a helper widget builder method
  Widget _buildWeeklyScheduleItem(
      String key, String dayName, Map<String, dynamic> schedule) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dayName, style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: Text(schedule['isOpen'] ? 'Open' : 'Closed'),
              value: schedule['isOpen'],
              onChanged: (value) {
                setState(() {
                  schedule['isOpen'] = value;
                });
              },
            ),
            // Time controls
            if (schedule['isOpen'])
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Open Time'),
                      subtitle: Text(_formatTimeOfDay(schedule['openTime'])),
                      trailing: IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () async {
                          final time =
                              await _selectTime(context, schedule['openTime']);
                          if (time != null) {
                            setState(() {
                              schedule['openTime'] = time;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('Close Time'),
                      subtitle: Text(_formatTimeOfDay(schedule['closeTime'])),
                      trailing: IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () async {
                          final time =
                              await _selectTime(context, schedule['closeTime']);
                          if (time != null) {
                            setState(() {
                              schedule['closeTime'] = time;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            // Save button
            ElevatedButton(
              onPressed: () => _saveWeeklySchedule(key),
              child: Text('Save'),
            )
          ],
        ),
      ),
    );
  }

  // Add the missing build method
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text('Error: $_error', style: TextStyle(color: Colors.red)),
      );
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWeeklyScheduleTab(),
              // Implementation of special days tab
              _buildSpecialDaysTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialDaysTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Special Day Schedules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Day'),
                onPressed: _addSpecialDay,
              ),
            ],
          ),
        ),
        Expanded(
          child: _specialDays.isEmpty
              ? Center(child: Text('No special days scheduled'))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _specialDays
                      .map((day) => _buildSpecialDayItem(day))
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildSpecialDayItem(Map<String, dynamic> day) {
    final date = day['date'] as DateTime;
    final dateString = DateFormat('EEE, MMM d, yyyy').format(date);

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateString, style: TextStyle(fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: Text(day['isOpen'] ? 'Open' : 'Closed'),
              value: day['isOpen'],
              onChanged: (value) {
                setState(() {
                  day['isOpen'] = value;
                });
              },
            ),
            if (day['isOpen'])
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Open Time'),
                      subtitle: Text(_formatTimeOfDay(day['openTime'])),
                      trailing: IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () async {
                          final time =
                              await _selectTime(context, day['openTime']);
                          if (time != null) {
                            setState(() {
                              day['openTime'] = time;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('Close Time'),
                      subtitle: Text(_formatTimeOfDay(day['closeTime'])),
                      trailing: IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () async {
                          final time =
                              await _selectTime(context, day['closeTime']);
                          if (time != null) {
                            setState(() {
                              day['closeTime'] = time;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () => _deleteSpecialDay(day),
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('Save'),
                  onPressed: () => _saveSpecialDaySchedule(day),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
