import 'package:flutter/material.dart';
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
                // Start Regula service when "+" button is pressed
                print('Starting Regula service...');
                
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
                
                // Print all available scenarios
                await _regulaService.printAllScenarios();
                
                // Prepare and download database
                await _regulaService.prepareAndDownloadDatabase();
                
                // Start document processing
                await _regulaService.startDocumentProcessing();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Regula initialized and document processing started!'),
                    duration: Duration(seconds: 2),
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