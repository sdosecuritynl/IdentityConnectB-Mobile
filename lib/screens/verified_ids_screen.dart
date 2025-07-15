import 'package:flutter/material.dart';
import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';
import '../widgets/app_header.dart';
import '../services/regula.dart';

class VerifiedIDsScreen extends StatefulWidget {
  const VerifiedIDsScreen({super.key});

  @override
  State<VerifiedIDsScreen> createState() => _VerifiedIDsScreenState();
}

class _VerifiedIDsScreenState extends State<VerifiedIDsScreen> {
  final RegulaService _regulaService = RegulaService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Verified IDs'),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Empty state
          Center(
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
          // Add button
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: () async {
                // Start full authentication flow when "+" button is pressed
                print('Starting full authentication flow...');
                
                // Initialize license first
                final licenseInitialized = await _regulaService.initializeLicense();
                if (!licenseInitialized) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to initialize Regula license'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                
                // Set completion callback
                _regulaService.setCompletionCallback((action, results, error) async {
                  if (error != null) {
                    print('Authentication error: $error');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Authentication failed: ${error.toString()}'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  } else if (action == DocReaderAction.COMPLETE) {
                    print('Document and RFID processing completed, starting selfie capture');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document verified! Now taking selfie...'),
                        backgroundColor: Colors.blue,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // Set selfie completion callback
                    _regulaService.setCompletionCallback((selfieAction, selfieResults, selfieError) {
                      if (selfieError != null) {
                        print('Selfie error: $selfieError');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selfie capture failed: ${selfieError.toString()}'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } else if (selfieAction == DocReaderAction.COMPLETE) {
                        print('Full authentication completed successfully!');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Full authentication completed! Document + RFID + Selfie verified.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 4),
                          ),
                        );
                        // TODO: Save verified ID to storage and update UI
                      } else if (selfieAction == DocReaderAction.CANCEL) {
                        print('Selfie capture cancelled');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selfie capture cancelled'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    });
                    
                    // Start selfie capture
                    await _regulaService.completeAuthenticationWithSelfie();
                  } else if (action == DocReaderAction.CANCEL) {
                    print('Authentication cancelled');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Authentication cancelled'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                });
                
                // Start full authentication flow
                await _regulaService.startFullAuthentication();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Starting full authentication: Document scan → RFID read → Selfie check'),
                    duration: Duration(seconds: 4),
                  ),
                );
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
} 