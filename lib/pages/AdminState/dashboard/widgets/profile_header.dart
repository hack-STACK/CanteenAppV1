import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final int? stallId;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onProfilePressed;

  const ProfileHeaderWidget({
    super.key,
    this.stallId,
    this.onMenuPressed,
    this.onProfilePressed,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  String _ownerName = '';
  String _stallName = '';
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(ProfileHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stallId != widget.stallId) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    if (widget.stallId == null) {
      setState(() {
        _isLoading = false;
        _ownerName = 'Unknown Owner';
        _stallName = 'Unknown Stall';
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _supabase
          .from('stalls')
          .select('nama_stalls, nama_pemilik, image_url')
          .eq('id', widget.stallId!)
          .single();

      setState(() {
        _isLoading = false;
        _stallName = response['nama_stalls'] ?? 'Unknown Stall';
        _ownerName = response['nama_pemilik'] ?? 'Unknown Owner';
        _imageUrl = response['image_url'];
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
        _ownerName = 'Error loading profile';
        _stallName = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                  image: _imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(_imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageUrl == null
                    ? Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white70),
                                ),
                              )
                            : Text(
                                _ownerName.isNotEmpty ? _ownerName[0] : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isLoading ? 'Loading...' : _stallName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    _isLoading ? '' : '@${_ownerName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Inter',
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: widget.onMenuPressed,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.menu, color: Colors.black),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: widget.onProfilePressed,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9D9D9),
                    shape: BoxShape.circle,
                    image: _imageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageUrl == null
                      ? Center(
                          child: Text(
                            _ownerName.isNotEmpty ? _ownerName[0] : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
