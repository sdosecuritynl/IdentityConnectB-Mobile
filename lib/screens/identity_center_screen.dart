import 'package:flutter/material.dart';
import '../services/menu_actions.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class IdentityCenterScreen extends StatefulWidget {
  final String email;
  const IdentityCenterScreen({super.key, required this.email});

  @override
  State<IdentityCenterScreen> createState() => _IdentityCenterScreenState();
}

class _IdentityCenterScreenState extends State<IdentityCenterScreen> {
  final MenuActions _menuActions = MenuActions();
  final ApiService _apiService = ApiService();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'Please enter an email address';
        _success = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final success = await _apiService.submitP2PRequest(context, email);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            _success = 'Verification request sent successfully';
            _error = null;
            _emailController.clear();
          } else {
            _error = 'Failed to send verification request. Please try again.';
            _success = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Error: $e';
          _success = null;
        });
      }
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
                onTap: () => Navigator.pop(context),
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
      endDrawer: null,
      drawerScrimColor: Colors.black54,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Identity Center',
                      style: AppTheme.titleMedium.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verify the identity of your colleagues and vendors in real-time.',
                      style: AppTheme.bodyText,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify Identity',
                            style: AppTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppTheme.primaryBlue,
                                secondary: AppTheme.primaryBlue,
                              ),
                              textSelectionTheme: TextSelectionThemeData(
                                cursorColor: AppTheme.primaryBlue,
                                selectionColor: AppTheme.primaryBlue.withOpacity(0.2),
                                selectionHandleColor: AppTheme.primaryBlue,
                              ),
                            ),
                            child: TextField(
                              controller: _emailController,
                              decoration: AppTheme.textFieldDecoration.copyWith(
                                labelText: 'Enter email to verify',
                                prefixIcon: Icon(Icons.email, color: AppTheme.primaryBlue),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryBlue),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: AppTheme.textDark),
                            ),
                          ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _error!,
                                style: AppTheme.bodyText.copyWith(color: Colors.red),
                              ),
                            ),
                          if (_success != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _success!,
                                style: AppTheme.bodyText.copyWith(color: Colors.green),
                              ),
                            ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: AppTheme.buttonDecoration,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleVerify,
                              style: AppTheme.primaryButtonStyle,
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.verified_user, size: 24),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Verify Now',
                                          style: AppTheme.buttonText.copyWith(color: Colors.white),
                                        ),
                                      ],
                                    ),
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
    );
  }
} 