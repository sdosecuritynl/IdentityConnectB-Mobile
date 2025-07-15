// Regula Document Reader Service
// This service will handle document scanning and RFID reading functionality

import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class RegulaService {
  bool _isInitialized = false;
  bool _canRfid = false;
  bool _doRfid = true; // Enable RFID by default for full auth
  bool _isReadingRfid = false;
  
  // Callback for completion handling
  Function(DocReaderAction, dynamic, dynamic)? _completionCallback;
  
  // Set completion callback
  void setCompletionCallback(Function(DocReaderAction, dynamic, dynamic) callback) {
    _completionCallback = callback;
  }

  Future<bool> initializeLicense() async {
    print('=== INITIALIZING REGULA LICENSE ===');
    
    try {
      // Load license file from assets
      print('Loading license file...');
      ByteData license = await rootBundle.load("assets/regula.license");
      var initConfig = InitConfig(license);
      initConfig.delayedNNLoad = true;
      
      // Initialize the document reader
      print('Initializing document reader...');
      var (success, error) = await DocumentReader.instance.initialize(initConfig);
      
      if (success) {
        print('Regula license initialization successful');
        _isInitialized = true;
        
        // Check RFID availability
        _canRfid = await DocumentReader.instance.isRFIDAvailableForUse();
        print('RFID available: $_canRfid');
        
        return true;
      } else {
        if (error == null) error = DocReaderException.unknown();
        print('Regula license initialization failed: ${error.message}');
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

  // Main completion handler for the full authentication flow
  void handleCompletion(DocReaderAction action, dynamic results, dynamic error) {
    print('=== HANDLING COMPLETION ===');
    print('Action: $action');
    
    if (error != null) {
      print('Error: ${error.message}');
      if (_completionCallback != null) {
        _completionCallback!(action, results, error);
      }
      return;
    }
    
    // If action is stopped and we shouldn't do RFID, display results
    if (action.stopped() && !shouldRfid(results)) {
      print('Document processing completed, displaying results');
      displayResults(results);
    } 
    // If action is finished and we should do RFID, start RFID reading
    else if (action.finished() && shouldRfid(results)) {
      print('Document processing finished, starting RFID reading');
      readRfid();
    }
    // Otherwise, continue processing
    else {
      print('Continuing processing...');
    }
  }

  // Check if we should do RFID reading (following example pattern)
  bool shouldRfid(dynamic results) {
    return _doRfid && !_isReadingRfid && results != null && results.chipPage != 0;
  }

  // Display results from document processing
  void displayResults(dynamic results) async {
    print('=== DISPLAYING RESULTS ===');
    _isReadingRfid = false;
    
    if (results == null) {
      print('No results to display');
      if (_completionCallback != null) {
        _completionCallback!(DocReaderAction.COMPLETE, results, null);
      }
      return;
    }

    try {
      // Extract text fields (following example pattern)
      var name = await results.textFieldValueByType(FieldType.SURNAME_AND_GIVEN_NAMES);
      print('Extracted name: $name');
      
      // Extract document image
      var docImage = await results.graphicFieldImageByType(GraphicFieldType.DOCUMENT_IMAGE);
      print('Document image extracted: ${docImage != null}');
      
      // Extract portrait
      var portrait = await results.graphicFieldImageByType(GraphicFieldType.PORTRAIT);
      print('Portrait extracted: ${portrait != null}');
      
      // Try to get RFID portrait if available (following example pattern)
      var rfidPortrait = await results.graphicFieldImageByTypeSource(
        GraphicFieldType.PORTRAIT,
        ResultType.RFID_IMAGE_DATA,
      );
      if (rfidPortrait != null) {
        portrait = rfidPortrait;
        print('RFID portrait used');
      }
      
      // Process results
      _processDocumentResults(results);
      
      // Call completion callback with results
      if (_completionCallback != null) {
        _completionCallback!(DocReaderAction.COMPLETE, results, null);
      }
      
    } catch (e) {
      print('Error displaying results: $e');
      if (_completionCallback != null) {
        _completionCallback!(DocReaderAction.ERROR, null, e);
      }
    }
  }

  // Start RFID reading (following example pattern)
  void readRfid() {
    print('=== STARTING RFID READING ===');
    _isReadingRfid = true;
    
    try {
      // Use basic RFID configuration (following example pattern)
      DocumentReader.instance.rfid(RFIDConfig(handleCompletion));
      print('RFID reading started');
      
    } catch (e) {
      print('Error starting RFID reading: $e');
      _isReadingRfid = false;
      if (_completionCallback != null) {
        _completionCallback!(DocReaderAction.ERROR, null, e);
      }
    }
  }

  // Start full authentication flow (document scan + RFID + selfie)
  Future<void> startFullAuthentication() async {
    print('=== STARTING FULL AUTHENTICATION FLOW ===');
    
    if (!_isInitialized) {
      print('Regula SDK not initialized. Please initialize first.');
      return;
    }

    try {
      // Clear any previous results
      _isReadingRfid = false;
      
      // Start document scanning with FULL_PROCESS scenario (following example pattern)
      print('Starting document scanning...');
      DocumentReader.instance.startScanner(
        ScannerConfig.withScenario(Scenario.FULL_PROCESS),
        handleCompletion,
      );
      print('Full authentication flow started');
      
    } catch (e) {
      print('Error starting full authentication: $e');
      if (_completionCallback != null) {
        _completionCallback!(DocReaderAction.ERROR, null, e);
      }
    }
  }

  // Capture selfie for authentication
  Future<Uint8List?> captureSelfie() async {
    print('=== CAPTURING SELFIE ===');
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      
      if (photo != null) {
        final Uint8List imageBytes = await photo.readAsBytes();
        print('Selfie captured successfully');
        return imageBytes;
      } else {
        print('Selfie capture cancelled');
        return null;
      }
    } catch (e) {
      print('Error capturing selfie: $e');
      return null;
    }
  }

  // Complete authentication flow with selfie
  Future<void> completeAuthenticationWithSelfie() async {
    print('=== COMPLETING AUTHENTICATION WITH SELFIE ===');
    
    try {
      // Capture selfie
      final selfieImage = await captureSelfie();
      
      if (selfieImage != null) {
        print('Selfie captured, authentication flow complete');
        // TODO: Compare selfie with document portrait
        // TODO: Send all data to backend for verification
        
        if (_completionCallback != null) {
          _completionCallback!(DocReaderAction.COMPLETE, {'selfie': selfieImage}, null);
        }
      } else {
        print('Selfie capture failed or cancelled');
        if (_completionCallback != null) {
          _completionCallback!(DocReaderAction.CANCEL, null, null);
        }
      }
    } catch (e) {
      print('Error completing authentication: $e');
      if (_completionCallback != null) {
        _completionCallback!(DocReaderAction.ERROR, null, e);
      }
    }
  }

  void _processDocumentResults(dynamic results) {
    print('=== PROCESSING DOCUMENT RESULTS ===');
    
    try {
      // Get document type
      var documentType = results.documentType;
      if (documentType != null && documentType.isNotEmpty) {
        print('Document type: ${documentType.first.name}');
      } else {
        print('Document type: Not detected');
      }
      
      // Get text fields
      var textFields = results.textResult?.fields;
      if (textFields != null) {
        print('=== TEXT FIELDS ===');
        for (var field in textFields) {
          print('Field: ${field.fieldName} = ${field.value}');
        }
      } else {
        print('=== TEXT FIELDS ===');
        print('No text fields available');
      }
      
      // Get graphic fields (images)
      var graphicFields = results.graphicResult?.fields;
      if (graphicFields != null) {
        print('=== GRAPHIC FIELDS ===');
        for (var field in graphicFields) {
          print('Graphic field: ${field.fieldName}');
        }
      } else {
        print('=== GRAPHIC FIELDS ===');
        print('No graphic fields available');
      }
      
      // Get authenticity checks
      var authenticityChecks = results.authenticityResult?.checks;
      if (authenticityChecks != null) {
        print('=== AUTHENTICITY CHECKS ===');
        for (var check in authenticityChecks) {
          print('Check: ${check.checkName} - Result: ${check.result}');
        }
      } else {
        print('=== AUTHENTICITY CHECKS ===');
        print('No authenticity checks available');
      }
      
      // Get RFID data if available - using correct property name
      var rfidData = results.rfidSessionData;
      if (rfidData != null) {
        print('=== RFID DATA ===');
        print('RFID session data available');
        // Note: RFID session data properties are accessed through specific methods
        // rather than direct property access to avoid compatibility issues
        print('RFID data extracted successfully');
      } else {
        print('=== RFID DATA ===');
        print('No RFID session data available (document may not have RFID chip)');
      }
      
      // Get barcode data if available
      var barcodeData = results.barcodeResult;
      if (barcodeData != null) {
        print('=== BARCODE DATA ===');
        print('Barcode data available');
        // Access barcode properties safely
        try {
          print('Barcode type: ${barcodeData.type}');
          print('Barcode data: ${barcodeData.data}');
        } catch (e) {
          print('Error accessing barcode properties: $e');
        }
      } else {
        print('=== BARCODE DATA ===');
        print('No barcode data available');
      }
      
      // Get transaction info if available
      var transactionInfo = results.transactionInfo;
      if (transactionInfo != null) {
        print('=== TRANSACTION INFO ===');
        print('Transaction ID: ${transactionInfo.transactionId}');
        print('Session log folder: ${transactionInfo.sessionLogFolder}');
      } else {
        print('=== TRANSACTION INFO ===');
        print('No transaction info available');
      }
      
      print('=== DOCUMENT RESULTS PROCESSED ===');
    } catch (e) {
      print('Error processing document results: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  // RFID Processing Methods
  Future<void> startRFIDProcessing() async {
    print('=== STARTING RFID PROCESSING ===');
    
    if (!_isInitialized) {
      print('Regula SDK not initialized. Please initialize first.');
      return;
    }

    try {
      // Set RFID scenario if not doing optical processing
      DocumentReader.instance.processParams.scenario = Scenario.RFID;
      print('RFID scenario set');
      
      // Start RFID reader
      print('Opening RFID reader...');
      DocumentReader.instance.rfid(RFIDConfig((action, results, error) {
        print('RFID processing action: $action');
        
        if (error != null) {
          print('RFID processing error: ${error.message}');
          return;
        }
        
        if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
          // RFID processing was finished
          if (results != null) {
            print('RFID processing completed successfully');
            _processRFIDResults(results);
          } else {
            print('RFID processing completed but no results received');
          }
        } else if (action == DocReaderAction.ERROR) {
          print('RFID processing failed with error action');
        } else if (action == DocReaderAction.CANCEL) {
          print('RFID processing was cancelled by user');
        } else {
          print('RFID processing action: $action - continuing...');
        }
      }));
      
      print('=== RFID PROCESSING STARTED ===');
    } catch (e) {
      print('Error starting RFID processing: $e');
    }
  }

  void _processRFIDResults(dynamic results) {
    print('=== PROCESSING RFID RESULTS ===');
    
    try {
      // Get RFID data
      var rfidData = results.rfidSessionData;
      if (rfidData != null) {
        print('=== RFID DATA ===');
        print('RFID session data available');
        // Note: RFID session data properties are accessed through specific methods
        // rather than direct property access to avoid compatibility issues
        print('RFID data extracted successfully');
      } else {
        print('=== RFID DATA ===');
        print('No RFID session data available');
      }
      
      print('=== RFID RESULTS PROCESSED ===');
    } catch (e) {
      print('Error processing RFID results: $e');
    }
  }

  Future<void> stopRFIDReader() async {
    print('=== STOPPING RFID READER ===');
    
    try {
      DocumentReader.instance.stopRFIDReader();
      print('RFID reader stopped successfully');
    } catch (e) {
      print('Error stopping RFID reader: $e');
    }
  }

  // Combined document processing with RFID
  Future<void> startFullDocumentProcessing() async {
    print('=== STARTING FULL DOCUMENT PROCESSING (OPTICAL + RFID) ===');
    
    if (!_isInitialized) {
      print('Regula SDK not initialized. Please initialize first.');
      return;
    }

    try {
      // Create scanner config with FULL_PROCESS scenario (includes RFID)
      var config = ScannerConfig.withScenario(Scenario.FULL_PROCESS);
      print('Scanner config created with FULL_PROCESS scenario (includes RFID)');
      
      // Start the document processing
      print('Starting full document processing...');
      DocumentReader.instance.startScanner(config, (action, results, error) {
        print('Full document processing action: $action');
        
        if (error != null) {
          print('Full document processing error: ${error.message}');
          return;
        }
        
        if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
          // document processing was finished
          if (results != null) {
            print('Full document processing completed successfully');
            _processDocumentResults(results);
          } else {
            print('Full document processing completed but no results received');
          }
        } else if (action == DocReaderAction.ERROR) {
          print('Full document processing failed with error action');
        } else if (action == DocReaderAction.CANCEL) {
          print('Full document processing was cancelled by user');
        } else {
          print('Full document processing action: $action - continuing...');
        }
      });
      
      print('=== FULL DOCUMENT PROCESSING STARTED ===');
    } catch (e) {
      print('Error starting full document processing: $e');
    }
  }
} 