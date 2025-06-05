import 'package:flutter/material.dart';
import '../services/menu_actions.dart';
import '../services/device_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UserInfoScreen extends StatefulWidget {
  final String email;
  const UserInfoScreen({super.key, required this.email});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final MenuActions _menuActions = MenuActions();
  final DeviceService _deviceService = DeviceService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _userInfo;
  String? _deviceName;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    try {
      // Get device info
      final deviceInfo = await _deviceService.getDeviceInfo();
      _deviceName = deviceInfo['deviceName'];
      _deviceId = deviceInfo['deviceId'];

      final userData = await _apiService.getUserInfo(context);
      
      if (mounted) {
        setState(() {
          if (userData != null) {
            print('[UserInfo] Received user data: $userData');
            _userInfo = userData;
            _error = null;
          } else {
            _error = 'Failed to fetch user information';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[UserInfo] Error fetching info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
             '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.85,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logged in as',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
              Divider(thickness: 1, color: AppTheme.textGrey.withOpacity(0.2)),
              ListTile(
                leading: Icon(Icons.home, color: AppTheme.primaryBlue),
                title: Text('Home', style: TextStyle(color: AppTheme.textDark)),
                onTap: () => _menuActions.goToHome(context, widget.email),
              ),
              ListTile(
                leading: Icon(Icons.security, color: AppTheme.primaryBlue),
                title: Text('Identity Center', style: TextStyle(color: AppTheme.textDark)),
                onTap: () => _menuActions.goToIdentityCenter(context, widget.email),
              ),
              ListTile(
                leading: Icon(Icons.person, color: AppTheme.primaryBlue),
                title: Text('My Information', style: TextStyle(color: AppTheme.textDark)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Icon(Icons.delete_forever, color: AppTheme.primaryBlue),
                title: Text('Delete Account', style: TextStyle(color: AppTheme.textDark)),
                onTap: () => _menuActions.showDeleteConfirmation(context),
              ),
              ListTile(
                leading: Icon(Icons.logout, color: AppTheme.primaryBlue),
                title: Text('Sign Out', style: TextStyle(color: AppTheme.textDark)),
                onTap: () => _menuActions.signOut(context),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: AppTheme.headerShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 40,
                        width: 40,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'IdentityConnect.io',
                        style: AppTheme.titleLarge,
                      ),
                    ],
                  ),
                  Builder(
                    builder: (context) => IconButton(
                      icon: Icon(Icons.menu, size: 28, color: AppTheme.primaryBlue),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: AppTheme.bodyText.copyWith(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Information',
                                style: AppTheme.titleMedium.copyWith(fontSize: 20),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                decoration: AppTheme.cardDecoration,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'User Details',
                                      style: AppTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Email', widget.email),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                decoration: AppTheme.cardDecoration,
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Device Information',
                                      style: AppTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInfoRow('Device Name', _deviceName ?? 'N/A'),
                                    _buildInfoRow('Device ID', _deviceId ?? 'N/A'),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 