import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_header.dart';
import '../theme/app_theme.dart';
import '../services/regula_service.dart';

class VerifiedIDsScreen extends StatefulWidget {
  const VerifiedIDsScreen({super.key});

  @override
  State<VerifiedIDsScreen> createState() => _VerifiedIDsScreenState();
}

class _VerifiedIDsScreenState extends State<VerifiedIDsScreen> {
  final RegulaService _regulaService = RegulaService();
  
  bool _isInitialized = false;
  bool _isScanning = false;
  String _status = "Ready";
  bool _canRfid = false;
  bool _doRfid = false;
  
  // Results
  String _extractedName = "";
  Uint8List? _documentImage;
  Uint8List? _portraitImage;

  @override
  void initState() {
    super.initState();
    _initializeRegula();
  }

  Future<void> _initializeRegula() async {
    setState(() {
      _status = "Initializing Regula SDK...";
    });

    try {
      print('Starting Regula SDK initialization...');
      final success = await RegulaService.initialize();
      
      if (success) {
        print('Regula SDK initialization successful, checking license status...');
        
        // Check license status and available scenarios
        final licenseStatus = await _regulaService.checkLicenseStatus();
        
        if (licenseStatus['isReady'] == true) {
          setState(() {
            _isInitialized = true;
            _status = "Ready - Connected to Docker container";
            _canRfid = licenseStatus['rfidAvailable'] ?? false;
          });
          
          // Log available scenarios for debugging
          final scenarios = licenseStatus['availableScenarios'] ?? [];
          print('✅ Regula SDK ready!');
          print('Available scenarios: $scenarios');
          print('RFID available: ${licenseStatus['rfidAvailable']}');
          print('SDK status: ${licenseStatus['status']}');
          
        } else {
          setState(() {
            _isInitialized = false;
            _status = "License check failed: ${licenseStatus['error'] ?? 'Unknown error'}";
          });
          
          print('❌ License check failed: ${licenseStatus['error'] ?? 'Unknown error'}');
          
          // Show error message to user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('License check failed: ${licenseStatus['error'] ?? 'Unknown error'}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } else {
        setState(() {
          _isInitialized = false;
          _status = "Failed to initialize Regula SDK";
        });
        print('❌ Regula SDK initialization failed');
      }
    } catch (e) {
      print('❌ Error initializing Regula: $e');
      setState(() {
        _isInitialized = false;
        _status = "Error initializing Regula SDK: $e";
      });
      
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Initialization error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _scanDocument() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document reader not ready'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _status = "Starting complete verification flow...";
      _clearResults();
    });

    try {
      // Check SDK status before scanning
      await _regulaService.checkSDKStatus();
      
      // Use the complete verification flow with server-side verification
      final results = await _regulaService.completeVerificationFlow();
      
      if (results != null && results['success'] == true) {
        setState(() {
          _isScanning = false;
          _status = "Verification completed successfully";
          _extractedName = results['documentData']?['surname'] ?? 
                          results['documentData']?['givenNames'] ?? "Unknown";
        });
        
        // Show success message with transaction ID
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification completed! Transaction ID: ${results['transactionId']}'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _isScanning = false;
          _status = "Verification failed";
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Verification failed'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in verification flow: $e');
      setState(() {
        _isScanning = false;
        _status = "Error in verification flow";
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _readRfid() async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document reader not ready'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _status = "Reading RFID chip with server verification...";
    });

    try {
      // Use RFID reading with server-side verification
      final results = await _regulaService.readRFID();
      
      if (results != null) {
        setState(() {
          _isScanning = false;
          _status = "RFID read successfully";
          _extractedName = results['surname'] ?? results['givenNames'] ?? "Unknown";
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('RFID read successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isScanning = false;
          _status = "RFID read failed";
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('RFID reading failed'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error reading RFID: $e');
      setState(() {
        _isScanning = false;
        _status = "Error reading RFID";
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearResults() {
    setState(() {
      _extractedName = "";
      _documentImage = null;
      _portraitImage = null;
    });
  }

  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scan Document',
              style: AppTheme.titleLarge.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            
            // RFID Checkbox
            if (_canRfid)
              CheckboxListTile(
                value: _doRfid,
                title: Text("Process RFID reading"),
                onChanged: (bool? value) {
                  setState(() => _doRfid = value ?? false);
                },
              ),
            
            // Scan with Camera
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
              title: Text('Scan with Camera'),
              subtitle: Text('Use camera to scan document'),
              onTap: () {
                Navigator.pop(context);
                _scanDocument();
              },
            ),
            
            // Read RFID
            if (_canRfid)
              ListTile(
                leading: Icon(Icons.nfc, color: AppTheme.primaryBlue),
                title: Text('Read RFID Chip'),
                subtitle: Text('Read passport chip data'),
                onTap: () {
                  Navigator.pop(context);
                  _readRfid();
                },
              ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Verified IDs'),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Status indicator
                  if (_status.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _status.contains("Error") 
                            ? Colors.red.withOpacity(0.1)
                            : _status.contains("Ready") 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _status.contains("Error") 
                              ? Colors.red.withOpacity(0.3)
                              : _status.contains("Ready") 
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _status.contains("Error") 
                                ? Icons.error_outline
                                : _status.contains("Ready") 
                                    ? Icons.check_circle_outline
                                    : Icons.info_outline,
                            color: _status.contains("Error") 
                                ? Colors.red
                                : _status.contains("Ready") 
                                    ? Colors.green
                                    : Colors.blue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _status,
                              style: TextStyle(
                                color: _status.contains("Error") 
                                    ? Colors.red
                                    : _status.contains("Ready") 
                                        ? Colors.green
                                        : Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Results display
                  if (_extractedName.isNotEmpty || _documentImage != null || _portraitImage != null)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (_extractedName.isNotEmpty)
                              Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Extracted Information',
                                        style: AppTheme.titleMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Name: $_extractedName',
                                        style: AppTheme.bodyText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            if (_documentImage != null)
                              Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Document Image',
                                        style: AppTheme.titleMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Image.memory(
                                        _documentImage!,
                                        height: 200,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            if (_portraitImage != null)
                              Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Portrait',
                                        style: AppTheme.titleMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Image.memory(
                                        _portraitImage!,
                                        height: 200,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Empty state
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/empty_ids.png',
                              width: 200,
                              height: 200,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Let's get started!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your verified IDs will appear here.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Add button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _isScanning ? null : _showScanOptions,
              backgroundColor: _isScanning ? Colors.grey : Colors.blue,
              foregroundColor: Colors.white,
              child: _isScanning 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
} 