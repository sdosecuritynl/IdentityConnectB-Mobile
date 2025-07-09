// Regula Document Reader Service
// This service will handle document scanning and RFID reading functionality

import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';
import 'package:flutter/services.dart';

class RegulaService {
  bool _isInitialized = false;
  
  // TODO: Implement Regula SDK integration
  
  Future<void> printAllScenarios() async {
    print('=== AVAILABLE REGULA SCENARIOS ===');
    for (var scenario in DocumentReader.instance.availableScenarios) {
      print(scenario.name);
    }
    print('=== END SCENARIOS ===');
  }

  Future<bool> initializeLicense() async {
    print('=== INITIALIZING REGULA LICENSE ===');
    
    try {
      // Download and prepare database first
      print('Downloading and preparing database...');
      var (dbSuccess, dbError) = await DocumentReader.instance.prepareDatabase("Full", (progress) {
        print('Database download progress: $progress%');
      });
      
      if (!dbSuccess) {
        print('Database preparation failed: ${dbError?.message}');
        return false;
      }
      
      print('Database preparation completed successfully');
      
      // Load license file from assets
      print('Loading license file...');
      var initConfig = InitConfig(await rootBundle.load("assets/regula.license"));
      
      // Initialize the document reader
      print('Initializing document reader...');
      var (success, error) = await DocumentReader.instance.initializeReader(initConfig);
      
      if (success) {
        print('Regula license initialization successful');
        _isInitialized = true;
        return true;
      } else {
        print('Regula license initialization failed: ${error?.message}');
        return false;
      }
    } catch (e) {
      print('Error initializing license: $e');
      return false;
    }
  }

  Future<void> prepareAndDownloadDatabase() async {
    print('=== PREPARING REGULA DATABASE ===');
    
    try {
      // Prepare database
      print('Preparing database...');
      var (success, error) = await DocumentReader.instance.prepareDatabase("Full", print);
      
      if (success) {
        print('Database preparation successful');
      } else {
        print('Database preparation failed: ${error?.message}');
        return;
      }

      // Run auto update
      print('Running auto update...');
      var (updateSuccess, updateError) = await DocumentReader.instance.runAutoUpdate("Full", print);
      
      if (updateSuccess) {
        print('Auto update successful');
      } else {
        print('Auto update failed: ${updateError?.message}');
      }

      // Check database update
      print('Checking database update...');
      var database = await DocumentReader.instance.checkDatabaseUpdate("Full");
      print('Database date: ${database?.date ?? "no update"}');
      
      print('=== DATABASE PREPARATION COMPLETE ===');
    } catch (e) {
      print('Error preparing database: $e');
    }
  }

  Future<void> startDocumentProcessing() async {
    print('=== STARTING DOCUMENT PROCESSING ===');
    
    if (!_isInitialized) {
      print('Regula SDK not initialized. Please initialize first.');
      return;
    }

    try {
      // Print available scenarios for debugging
      print('Available scenarios:');
      for (var scenario in DocumentReader.instance.availableScenarios) {
        print('- ${scenario.name}');
      }
      
      // Try different scenarios in order of preference
      var scenarios = [
        Scenario.FULL_PROCESS,
        Scenario.MRZ,
        Scenario.OCR,
        Scenario.BARCODE,
      ];
      
      for (var scenario in scenarios) {
        print('Trying scenario: ${scenario.name}');
        
        // Create scanner config with current scenario
        var config = ScannerConfig.withScenario(scenario);
        print('Scanner config created with ${scenario.name} scenario');
        
        // Start the document processing
        print('Starting document processing with ${scenario.name}...');
        DocumentReader.instance.startScanner(config, (action, results, error) {
          print('Document processing action: $action');
          
          if (error != null) {
            print('Document processing error: ${error.message}');
            return;
          }
          
          if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
            // document processing was finished
            if (results != null) {
              print('Document processing completed successfully with ${scenario.name}');
              _processDocumentResults(results);
            } else {
              print('Document processing completed but no results received with ${scenario.name}');
            }
          } else if (action == DocReaderAction.ERROR) {
            print('Document processing failed with error action');
          } else if (action == DocReaderAction.CANCEL) {
            print('Document processing was cancelled by user');
          } else {
            print('Document processing action: $action - continuing...');
          }
        });
        
        // Wait a bit before trying next scenario
        await Future.delayed(Duration(seconds: 2));
        break; // For now, just try the first scenario
      }
      
      print('=== DOCUMENT PROCESSING STARTED ===');
    } catch (e) {
      print('Error starting document processing: $e');
    }
  }

  void _processDocumentResults(dynamic results) {
    print('=== PROCESSING DOCUMENT RESULTS ===');
    
    try {
      // Get document type
      var documentType = results.documentType;
      print('Document type: $documentType');
      
      // Get text fields
      var textFields = results.textResult?.fields;
      if (textFields != null) {
        print('=== TEXT FIELDS ===');
        for (var field in textFields) {
          print('Field: ${field.fieldName} = ${field.value}');
        }
      }
      
      // Get graphic fields (images)
      var graphicFields = results.graphicResult?.fields;
      if (graphicFields != null) {
        print('=== GRAPHIC FIELDS ===');
        for (var field in graphicFields) {
          print('Graphic field: ${field.fieldName}');
        }
      }
      
      // Get authenticity checks
      var authenticityChecks = results.authenticityResult?.checks;
      if (authenticityChecks != null) {
        print('=== AUTHENTICITY CHECKS ===');
        for (var check in authenticityChecks) {
          print('Check: ${check.checkName} - Result: ${check.result}');
        }
      }
      
      // Get RFID data if available - using correct property name
      var rfidData = results.rfid;
      if (rfidData != null) {
        print('=== RFID DATA ===');
        print('RFID data available: ${rfidData.data != null}');
        
        // Access RFID properties according to documentation
        if (rfidData.data != null) {
          print('RFID overall status: ${rfidData.overallStatus}');
          print('RFID process time: ${rfidData.processTime}ms');
          print('RFID total bytes received: ${rfidData.totalBytesReceived}');
          print('RFID total bytes sent: ${rfidData.totalBytesSent}');
        }
      }
      
      // Get barcode data if available
      var barcodeData = results.barcode;
      if (barcodeData != null) {
        print('=== BARCODE DATA ===');
        print('Barcode type: ${barcodeData.type}');
        print('Barcode data: ${barcodeData.data}');
      }
      
      // Get transaction info if available
      var transactionInfo = results.transactionInfo;
      if (transactionInfo != null) {
        print('=== TRANSACTION INFO ===');
        print('Transaction ID: ${transactionInfo.transactionId}');
        print('Session log folder: ${transactionInfo.sessionLogFolder}');
      }
      
      print('=== DOCUMENT RESULTS PROCESSED ===');
    } catch (e) {
      print('Error processing document results: $e');
    }
  }

  bool get isInitialized => _isInitialized;
} 