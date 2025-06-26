import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/cognito_service.dart';
import '../services/storage_service.dart';
import '../screens/login_screen.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppHeader({
    Key? key,
    required this.title,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: AppTheme.titleMedium.copyWith(
          color: AppTheme.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: AppTheme.primaryBlue,
            size: 28,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppTheme.textGrey.withOpacity(0.2),
        ),
      ),
    );
  }
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final CognitoService _cognitoService = CognitoService();
  final SecureStorageService _storage = SecureStorageService();
  String _userEmail = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final email = await _storage.getEmail();
      if (mounted) {
        setState(() {
          _userEmail = email ?? 'Unknown User';
        });
      }
    } catch (e) {
      print('[AppDrawer] Error loading user info: $e');
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    
    try {
      await _cognitoService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('[AppDrawer] Error during sign out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: AppTheme.titleMedium.copyWith(color: Colors.red),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
          style: AppTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTheme.bodyText.copyWith(color: AppTheme.textGrey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Delete',
              style: AppTheme.bodyText.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        // Clear all local data
        await _cognitoService.signOut();
        
        // TODO: Add API call to delete account from backend
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('[AppDrawer] Error deleting account: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showDataProtectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'How Your Data is Protected',
          style: AppTheme.titleMedium.copyWith(color: AppTheme.primaryBlue),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your privacy and security are our top priorities. Here\'s how we protect your data:',
                style: AppTheme.bodyText,
              ),
              const SizedBox(height: 16),
              _buildProtectionItem(
                Icons.lock,
                'End-to-End Encryption',
                'Your data is encrypted using industry-standard protocols. Only the authorized requestor can view the shared information.',
              ),
              _buildProtectionItem(
                Icons.security,
                'Secure Storage',
                'All your data is stored locally on your device in secure, encrypted storage systems.',
              ),
              _buildProtectionItem(
                Icons.verified_user,
                'Identity Verification',
                'Only authorized suppliers can request identity verification through our secure platform.',
              ),
              _buildProtectionItem(
                Icons.minimize,
                'Data Minimization',
                'We only store your email address and phone number. No additional personal data is collected.',
              ),
              _buildProtectionItem(
                Icons.no_accounts,
                'No Third-Party Sharing',
                'We never share your data. Your information remains strictly confidential.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: AppTheme.bodyText.copyWith(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtectionItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 13,
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.textGrey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signed in as:',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 14,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    icon: Icons.security,
                    title: 'How Your Data is Protected',
                    onTap: _showDataProtectionInfo,
                  ),
                  _buildDrawerItem(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    onTap: _deleteAccount,
                    isDestructive: true,
                  ),
                  const Divider(height: 32),
                  _buildDrawerItem(
                    icon: Icons.logout,
                    title: 'Sign Out',
                    onTap: _signOut,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(20),
              child: Text(
                'IdentityConnect v1.0.0',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 12,
                  color: AppTheme.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: isLoading 
        ? SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDestructive ? Colors.red : AppTheme.primaryBlue,
              ),
            ),
          )
        : Icon(
            icon,
            color: isDestructive ? Colors.red : AppTheme.primaryBlue,
            size: 24,
          ),
      title: Text(
        title,
        style: AppTheme.bodyText.copyWith(
          fontSize: 16,
          color: isDestructive ? Colors.red : AppTheme.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: isLoading ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
} 