import 'package:flutter/material.dart';
import 'package:kantin/Component/my_Description_Box.dart';
import 'package:kantin/Component/my_Silver_App_Bar.dart';
import 'package:kantin/Component/my_current_location.dart';
import 'package:kantin/Component/my_drawer.dart';
import 'package:kantin/Component/my_stall_tile.dart';
import 'package:kantin/Models/Stan_model.dart';
import 'package:kantin/Services/Database/Stan_service.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<StudentPage> {
  final StanService _stanService = StanService();
  List<Stan> _stalls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStalls();
  }

  Future<void> _loadStalls() async {
    try {
      setState(() => _isLoading = true);
      final stalls = await _stanService.getAllStans();
      setState(() {
        _stalls = stalls;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stalls: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MyDrawer(),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          MySilverAppBar(
            title: const Text('Available Stalls'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Divider(
                  indent: 25,
                  endIndent: 25,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const MyCurrentLocation(),
                const MyDescriptionBox(),
              ],
            ),
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStalls,
                child: _stalls.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_mall_directory_rounded,
                              size: 64,
                              color: Theme.of(context).disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No stalls available',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _stalls.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          return AnimatedStallTile(
                            stall: _stalls[index],
                            onTap: () {
                              // TODO: Navigate to stall detail page
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => StallDetailPage(
                              //       stall: _stalls[index],
                              //     ),
                              //   ),
                              // );
                            },
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
