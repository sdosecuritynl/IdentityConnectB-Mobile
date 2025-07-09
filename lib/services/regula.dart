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
      // Create scanner config with FULL_PROCESS scenario
      var config = ScannerConfig.withScenario(Scenario.FULL_PROCESS);
      print('Scanner config created with FULL_PROCESS scenario');
      
      // Start the document processing
      print('Starting document processing...');
      DocumentReader.instance.startScanner(config, (action, results, error) {
        print('Document processing action: $action');
        
        if (error != null) {
          print('Document processing error: ${error.message}');
          return;
        }
        
        if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
          // document processing was finished
          if (results != null) {
            print('Document processing completed successfully');
            print('Results: $results');
          } else {
            print('Document processing completed but no results received');
          }
        } else if (action == DocReaderAction.ERROR) {
          print('Document processing failed with error action');
        } else if (action == DocReaderAction.CANCEL) {
          print('Document processing was cancelled by user');
        } else {
          print('Document processing action: $action - continuing...');
        }
      });
      
      print('=== DOCUMENT PROCESSING STARTED ===');
    } catch (e) {
      print('Error starting document processing: $e');
    }
  }

  bool get isInitialized => _isInitialized;
} 