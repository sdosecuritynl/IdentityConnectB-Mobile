import 'package:flutter/material.dart';
import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';
import 'dart:convert';
import '../widgets/app_header.dart';
import '../services/regula.dart';
import '../models/verified_id.dart';
import '../services/storage_service.dart';

class VerifiedIDsScreen extends StatefulWidget {
  const VerifiedIDsScreen({super.key});

  @override
  State<VerifiedIDsScreen> createState() => _VerifiedIDsScreenState();
}

class _VerifiedIDsScreenState extends State<VerifiedIDsScreen> {
  final RegulaService _regulaService = RegulaService();
  final SecureStorageService _storageService = SecureStorageService();
  List<VerifiedID> _verifiedIDs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerifiedIDs();
  }

  Future<void> _loadVerifiedIDs() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final verifiedIDs = await _storageService.getVerifiedIDs();
      setState(() {
        _verifiedIDs = verifiedIDs;
        _isLoading = false;
      });
      

      
    } catch (e) {
      print('Error loading verified IDs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Clear all existing verified IDs
  Future<void> _clearAllVerifiedIDs() async {
    try {
      await _storageService.clearVerifiedIDs();
      print('All existing verified IDs cleared');
    } catch (e) {
      print('Error clearing verified IDs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Verified IDs'),
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _verifiedIDs.isEmpty
              ? _buildEmptyState()
              : _buildVerifiedIDsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Clear existing verified IDs first (allow only one identity)
          await _clearAllVerifiedIDs();
          
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
              _regulaService.setCompletionCallback((selfieAction, selfieResults, selfieError) async {
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
                  
                  // Reload verified IDs to show the new one
                  await _loadVerifiedIDs();
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'Your verified identity will appear here.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedIDsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _verifiedIDs.length,
      itemBuilder: (context, index) {
        final verifiedID = _verifiedIDs[index];
        return _buildVerifiedIDCard(verifiedID);
      },
    );
  }

  Widget _buildVerifiedIDCard(VerifiedID verifiedID) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with document photo
            Row(
              children: [
                if (verifiedID.documentPhotoBase64 != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(verifiedID.documentPhotoBase64!),
                      width: 80,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.credit_card, color: Colors.grey),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        verifiedID.extractedName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        verifiedID.documentType,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Document details
            _buildDetailRow('Document Number', verifiedID.documentNumber),
            _buildDetailRow('Date of Expiry', verifiedID.dateOfExpiry),
            _buildDetailRow('Date of Birth', verifiedID.dateOfBirth),
            _buildDetailRow('Personal Number', verifiedID.personalNumber),
            _buildDetailRow('Nationality', verifiedID.nationality),
            _buildDetailRow('Sex', verifiedID.sex),
            _buildDetailRow('Age', verifiedID.age),
            
            // MRZ (collapsible)
            ExpansionTile(
              title: const Text('MRZ Data', style: TextStyle(fontSize: 14)),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    verifiedID.mrz,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            // Verification date
            const SizedBox(height: 8),
            Text(
              'Verified on: ${_formatDate(verifiedID.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
} 