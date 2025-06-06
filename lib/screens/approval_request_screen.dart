import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../models/verification_request.dart';
import '../services/verification_service.dart';

class ApprovalRequestScreen extends StatefulWidget {
  final String sessionId;

  const ApprovalRequestScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<ApprovalRequestScreen> createState() => _ApprovalRequestScreenState();
}

class _ApprovalRequestScreenState extends State<ApprovalRequestScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isRecognized = false;
  String? _error;
  VerificationRequest? _requestData;
  final _verificationService = VerificationService();

  @override
  void initState() {
    super.initState();
    _fetchRequestData();
  }

  Future<void> _fetchRequestData() async {
    try {
      final data = await _verificationService.getRequestData(widget.sessionId);
      if (mounted) {
        setState(() {
          _requestData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
        
        if (e.toString().contains('Authentication failed')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          });
        }
      }
    }
  }

  Future<void> _handleApproval(bool approved) async {
    if (!_isRecognized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that you recognize this request.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // TODO: Implement approval/rejection logic
      print('[Approval] Session ${widget.sessionId} - Approved: $approved');
      
      if (mounted) {
        Navigator.of(context).pop(); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildRequestDetails() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading request details',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _fetchRequestData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Identity Verification Request',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_requestData != null) ...[
            _buildInfoRow('From:', _requestData!.from),
            const SizedBox(height: 12),
            _buildInfoRow('To:', _requestData!.to),
            const SizedBox(height: 12),
            _buildInfoRow('Timestamp:', _requestData!.getFormattedTimestamp()),
            const SizedBox(height: 24),
            Text(
              'Identity approval request from ${_requestData!.getDomainFromEmail()}',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.textDark,
                height: 1.5,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _isRecognized,
                    onChanged: (value) {
                      setState(() {
                        _isRecognized = value ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I recognize this identity verification request.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textDark,
                      height: 1.5,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textGrey,
              height: 1.5,
              letterSpacing: -0.3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textDark,
              height: 1.5,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const AppHeader(showBackButton: true),
          Expanded(
            child: Stack(
              children: [
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRequestDetails(),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withOpacity(0.3),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : () => _handleApproval(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isProcessing)
                                        const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      else
                                        const Icon(Icons.check_circle, size: 24),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Approve',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isProcessing ? null : () => _handleApproval(false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: BorderSide(
                                    color: _isProcessing ? Colors.grey : Colors.red,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_isProcessing)
                                      const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.cancel, size: 24),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Reject',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
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
        ],
      ),
    );
  }
} 