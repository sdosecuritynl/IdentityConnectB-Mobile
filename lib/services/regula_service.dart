import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';
import 'package:url_launcher/url_launcher.dart';
// Core package is automatically included with the API package

class RegulaService {
  static final RegulaService _instance = RegulaService._internal();
  factory RegulaService() => _instance;
  RegulaService._internal();

  // Your Docker container URL
  static const String _baseUrl = 'http://54.210.48.17:8080';
  
  static bool _isInitialized = false;

  /// Initialize the Regula Document Reader SDK with server-side verification
  static Future<bool> initialize() async {
    try {
      if (!_isInitialized) {
        print('Loading Regula license file...');
        final ByteData licenseData = await rootBundle.load('assets/regula.license');
        print('License file loaded.');

        final initConfig = InitConfig(licenseData);

        // Download database online before SDK init (for both platforms)
        print('Preparing database online...');
        final (success, error) = await DocumentReader.instance.prepareDatabase(
          "Full",
          (progress) {
            print('Database download progress: $progress%');
          },
        );
        if (!success) {
          print('Database download failed: ${error?.message}');
          print('Error details: ${error?.toString()}');
          return false;
        }
        print('Database download completed successfully');
        
        // Wait a moment for database to be fully ready
        print('Waiting for database to be fully ready...');
        await Future.delayed(Duration(seconds: 2));

        print('Initializing Regula SDK...');
        final (initSuccess, initError) = await DocumentReader.instance.initialize(initConfig);
        if (initSuccess) {
          print('Regula SDK initialized successfully');
          await _configureBackendProcessing();
          _isInitialized = true;
          print('Regula SDK initialized successfully with server-side verification');
          return true;
        } else {
          print('Regula SDK initialization failed: ${initError?.message}');
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Failed to initialize Regula SDK: $e');
      return false;
    }
  }

  /// Configure backend processing for server-side verification
  static Future<void> _configureBackendProcessing() async {
    try {
      // Configure backend processing with your Regula Web Service URL
      final backendConfig = BackendProcessingConfig(
        _baseUrl,
        httpHeaders: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add any authentication headers if required
          // 'Authorization': 'Bearer your-token',
        },
      );
      // Set the backend processing configuration
      DocumentReader.instance.processParams.backendProcessingConfig = backendConfig;
      print('Backend processing configured successfully');
    } catch (e) {
      print('Failed to configure backend processing: $e');
    }
  }

  /// Check if the SDK is ready for use
  static bool get isReady => _isInitialized;

  /// Scan document using camera with server-side verification
  Future<Map<String, dynamic>?> scanDocument() async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('Starting document scan with server-side verification...');
      
      // Request camera permission first
      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        print('Camera permission not granted. Cannot scan documents.');
        return null;
      }
      
      // Check if we're on a simulator (camera won't work)
      if (Platform.isIOS) {
        print('Running on iOS - make sure you\'re on a real device, not simulator');
      }
      
      // Get available scenarios first
      final availableScenarios = await getAvailableScenarios();
      print('Available scenarios: $availableScenarios');
      
      // Use a basic scenario that should be available
      final scenario = Scenario.MRZ; // Use basic MRZ instead of MRZ_OR_OCR
      
      print('Attempting to start scanner with scenario: $scenario');
      
      // Use the real Regula camera scanner following official documentation
      final completer = Completer<Map<String, dynamic>?>();
      
      DocumentReader.instance.scan(
        ScannerConfig.withScenario(scenario),
        (DocReaderAction action, Results? results, DocReaderException? error) {
          print('Scanner action received: $action');
          
          if (error != null) {
            print('Document scanning error: ${error.message}');
            print('Error details: ${error.toString()}');
            completer.complete(null);
            return;
          }
          
          // Following official documentation: check for COMPLETE or TIMEOUT
          if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
            if (results != null) {
              print('Document scanning completed successfully');
              final extractedData = extractDocumentData(results);
              completer.complete(extractedData);
            } else {
              print('Document scanning completed but no results received');
              completer.complete(null);
            }
          } else if (action == DocReaderAction.ERROR) {
            print('Document scanning failed with error action');
            completer.complete(null);
          } else if (action == DocReaderAction.CANCEL) {
            print('Document scanning was cancelled by user');
            completer.complete(null);
          } else {
            print('Document scanning action: $action - continuing...');
            // Don't complete yet, wait for COMPLETE or TIMEOUT
          }
        },
      );
      
      return await completer.future;
    } catch (e) {
      print('Document scanning failed: $e');
      return null;
    }
  }

  /// Read RFID chip data with server-side verification
  Future<Map<String, dynamic>?> readRFID() async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('Starting RFID reading with server-side verification...');
      
      // Check if RFID is available first
      final rfidAvailable = await isRFIDAvailable();
      if (!rfidAvailable) {
        print('RFID not available on this device');
        return null;
      }
      
      // Use the real Regula RFID reader following official documentation
      final completer = Completer<Map<String, dynamic>?>();
      
      DocumentReader.instance.rfid(
        RFIDConfig((DocReaderAction action, Results? results, DocReaderException? error) {
          print('RFID action received: $action');
          
          if (error != null) {
            print('RFID reading error: ${error.message}');
            completer.complete(null);
            return;
          }
          
          // Following official documentation: check for COMPLETE or TIMEOUT
          if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
            if (results != null) {
              print('RFID reading completed successfully');
              final extractedData = extractRFIDData(results);
              completer.complete(extractedData);
            } else {
              print('RFID reading completed but no results received');
              completer.complete(null);
            }
          } else if (action == DocReaderAction.ERROR) {
            print('RFID reading failed with error action');
            completer.complete(null);
          } else if (action == DocReaderAction.CANCEL) {
            print('RFID reading was cancelled by user');
            completer.complete(null);
          } else {
            print('RFID reading action: $action - continuing...');
            // Don't complete yet, wait for COMPLETE or TIMEOUT
          }
        }),
      );
      
      return await completer.future;
    } catch (e) {
      print('RFID reading failed: $e');
      return null;
    }
  }

  /// Process image from gallery with server-side verification
  Future<Map<String, dynamic>?> processImage(List<Uint8List> imageBytes) async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('Processing ${imageBytes.length} images with server-side verification...');
      
      // Use the real Regula image processing following official documentation
      final completer = Completer<Map<String, dynamic>?>();
      
      DocumentReader.instance.recognize(
        RecognizeConfig.withScenario(
          Scenario.MRZ,
          images: imageBytes,
        ),
        (DocReaderAction action, Results? results, DocReaderException? error) {
          print('Image processing action received: $action');
          
          if (error != null) {
            print('Image processing error: ${error.message}');
            completer.complete(null);
            return;
          }
          
          // Following official documentation: check for COMPLETE or TIMEOUT
          if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
            if (results != null) {
              print('Image processing completed successfully');
              final extractedData = extractDocumentData(results);
              completer.complete(extractedData);
            } else {
              print('Image processing completed but no results received');
              completer.complete(null);
            }
          } else if (action == DocReaderAction.ERROR) {
            print('Image processing failed with error action');
            completer.complete(null);
          } else if (action == DocReaderAction.CANCEL) {
            print('Image processing was cancelled by user');
            completer.complete(null);
          } else {
            print('Image processing action: $action - continuing...');
            // Don't complete yet, wait for COMPLETE or TIMEOUT
          }
        },
      );
      
      return await completer.future;
    } catch (e) {
      print('Error processing images: $e');
      return null;
    }
  }

  /// Finalize package for server-side verification
  /// This encrypts the results and sends them to the Regula Web Service
  Future<String?> finalizePackage() async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('Finalizing package for server-side verification...');
      
      final completer = Completer<String?>();
      
      final (action, info, error) = await DocumentReader.instance.finalizePackage();
      
      if (error != null) {
        print('Finalize failed. Error: ${error.message}');
        completer.complete(null);
      } else if (action == DocReaderAction.COMPLETE && info != null) {
        print('Finalize done. Transaction ID: ${info.transactionId}');
        completer.complete(info.transactionId);
      } else {
        print('Finalize failed. Action: $action');
        completer.complete(null);
      }
      
      return await completer.future;
    } catch (e) {
      print('Error finalizing package: $e');
      return null;
    }
  }

  /// Send transaction ID to your backend for server-side verification
  Future<bool> sendTransactionToBackend(String transactionId) async {
    try {
      print('Sending transaction ID to backend: $transactionId');
      
      // This is where you would send the transaction ID to your backend
      // Your backend will then make a request to the Regula Web Service
      final response = await http.post(
        Uri.parse('$_baseUrl/api/transaction'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'transactionId': transactionId,
          'timestamp': DateTime.now().toIso8601String(),
          'deviceInfo': {
            'platform': 'flutter',
            'version': '1.0.0',
          },
        }),
      );
      
      if (response.statusCode == 200) {
        print('Transaction ID sent to backend successfully');
        return true;
      } else {
        print('Failed to send transaction ID to backend: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending transaction ID to backend: $e');
      return false;
    }
  }

  /// Complete server-side verification flow
  /// This combines document scanning, RFID reading, and server-side verification
  Future<Map<String, dynamic>?> completeVerificationFlow() async {
    try {
      print('Starting complete verification flow...');
      
      // Step 1: Optical Processing (Document Scanning) - Use FullProcess directly
      final documentResults = await scanDocumentWithFullProcess();
      if (documentResults == null) {
        print('Document scanning failed');
        return null;
      }
      
      // Step 2: RFID Chip Reading (Optional)
      Map<String, dynamic>? rfidResults;
      if (await isRFIDAvailable()) {
        print('RFID available, reading chip data...');
        rfidResults = await readRFID();
      }
      
      // Step 3: Finalize Package
      final transactionId = await finalizePackage();
      if (transactionId == null) {
        print('Failed to finalize package');
        return null;
      }
      
      // Step 4: Send Transaction ID to Backend
      final backendSuccess = await sendTransactionToBackend(transactionId);
      if (!backendSuccess) {
        print('Failed to send transaction ID to backend');
        return null;
      }
      
      // Combine results
      final combinedResults = {
        'success': true,
        'transactionId': transactionId,
        'documentData': documentResults,
        'rfidData': rfidResults,
        'verificationStatus': 'pending_server_verification',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('Complete verification flow finished successfully');
      return combinedResults;
      
    } catch (e) {
      print('Error in complete verification flow: $e');
      return null;
    }
  }

  /// Check license status and available scenarios
  Future<Map<String, dynamic>> checkLicenseStatus() async {
    if (!_isInitialized) {
      return {
        'isReady': false,
        'error': 'Regula service not initialized'
      };
    }

    try {
      final scenarios = await getAvailableScenarios();
      final rfidAvailable = await isRFIDAvailable();
      final isReady = await DocumentReader.instance.isReady;
      final status = await DocumentReader.instance.status;
      
      return {
        'isReady': isReady,
        'status': status,
        'availableScenarios': scenarios,
        'rfidAvailable': rfidAvailable,
        'scenarioCount': scenarios.length,
      };
    } catch (e) {
      return {
        'isReady': false,
        'error': 'Failed to check license status: $e'
      };
    }
  }

  /// Get available scenarios from the Regula SDK
  Future<List<String>> getAvailableScenarios() async {
    if (!_isInitialized) {
      return [];
    }

    try {
      // Get scenarios from Regula SDK
      final scenarios = DocumentReader.instance.availableScenarios;
      
      // Print scenario names for debugging (following official documentation)
      print('Available scenarios:');
      for (var scenario in scenarios) {
        print('  - ${scenario.name}');
      }
      
      return scenarios.map((s) => s.name).toList();
    } catch (e) {
      print('Error getting scenarios: $e');
      return [];
    }
  }

  /// Check if RFID is available
  Future<bool> isRFIDAvailable() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      // Check if device supports RFID
      final rfidAvailable = await DocumentReader.instance.isRFIDAvailableForUse();
      return rfidAvailable;
    } catch (e) {
      print('Error checking RFID availability: $e');
      return false;
    }
  }

  /// Extract document data from scan results
  static Map<String, dynamic>? extractDocumentData(Results results) {

    try {
      final documentData = <String, dynamic>{};
      
      // Extract document type
      documentData['documentType'] = results.documentType.toString();

      // Extract text fields
      final textResult = results.textResult;
      if (textResult != null) {
        final textFields = <String, dynamic>{};
        
        // Iterate through all text fields
        for (final field in textResult.fields) {
          textFields[field.fieldType.toString()] = field.value;
        }
        
        documentData['textFields'] = textFields;
        
        // Extract common fields
        documentData['surname'] = textFields['Surname'] ?? textFields['surname'] ?? '';
        documentData['givenNames'] = textFields['Given Names'] ?? textFields['givenNames'] ?? '';
        documentData['dateOfBirth'] = textFields['Date of Birth'] ?? textFields['dateOfBirth'] ?? '';
        documentData['dateOfExpiry'] = textFields['Date of Expiry'] ?? textFields['dateOfExpiry'] ?? '';
        documentData['documentNumber'] = textFields['Document Number'] ?? textFields['documentNumber'] ?? '';
      }

      // Extract graphic fields (images)
      final graphicResult = results.graphicResult;
      if (graphicResult != null) {
        final graphicFields = <String, dynamic>{};
        
        // Iterate through all graphic fields
        for (final field in graphicResult.fields) {
          graphicFields[field.fieldType.toString()] = field.value;
        }
        
        documentData['graphicFields'] = graphicFields;
        
        // Extract document and portrait images
        documentData['documentImage'] = graphicFields['Document Image'] ?? graphicFields['documentImage'];
        documentData['portraitImage'] = graphicFields['Portrait'] ?? graphicFields['portrait'];
      }

      // Extract authenticity results
      final authenticityResult = results.authenticityResult;
      if (authenticityResult != null) {
        final authenticityChecks = <Map<String, dynamic>>[];
        
        // Iterate through all authenticity checks
        for (final check in authenticityResult.checks) {
          authenticityChecks.add({
            'name': check.typeName,
            'type': check.type.toString(),
            'status': check.status.toString(),
          });
        }
        
        documentData['authenticityChecks'] = authenticityChecks;
      }

      return documentData;
    } catch (e) {
      print('Failed to extract document data: $e');
      return null;
    }
  }

  /// Extract RFID data from RFID results
  static Map<String, dynamic>? extractRFIDData(Results results) {

    try {
      final rfidData = <String, dynamic>{};
      
      // Extract RFID text fields
      final textResult = results.textResult;
      if (textResult != null) {
        final textFields = <String, dynamic>{};
        for (final field in textResult.fields) {
          textFields[field.fieldType.toString()] = field.value;
        }
        rfidData['textFields'] = textFields;
        
        // Extract common RFID fields
        rfidData['surname'] = textFields['Surname'] ?? textFields['surname'] ?? '';
        rfidData['givenNames'] = textFields['Given Names'] ?? textFields['givenNames'] ?? '';
        rfidData['dateOfBirth'] = textFields['Date of Birth'] ?? textFields['dateOfBirth'] ?? '';
        rfidData['nationality'] = textFields['Nationality'] ?? textFields['nationality'] ?? '';
        rfidData['documentNumber'] = textFields['Document Number'] ?? textFields['documentNumber'] ?? '';
      }

      // Extract RFID graphic fields
      final graphicResult = results.graphicResult;
      if (graphicResult != null) {
        final graphicFields = <String, dynamic>{};
        for (final field in graphicResult.fields) {
          graphicFields[field.fieldType.toString()] = field.value;
        }
        rfidData['graphicFields'] = graphicFields;
        
        // Extract RFID portrait
        rfidData['portraitImage'] = graphicFields['Portrait'] ?? graphicFields['portrait'];
      }

      return rfidData;
    } catch (e) {
      print('Failed to extract RFID data: $e');
      return null;
    }
  }

  /// Try scanning with different scenarios until one works
  Future<Map<String, dynamic>?> scanDocumentWithFallback() async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('Starting document scan with fallback scenarios...');
      
      // Get available scenarios first
      final availableScenarios = await getAvailableScenarios();
      print('Available scenarios: $availableScenarios');
      
      // Define scenario names to try in order of preference (based on your available scenarios)
      final scenarioNamesToTry = [
        'Mrz',                    // Basic MRZ - should be available
        'Ocr',                    // Basic OCR
        'Barcode',                // Basic barcode
        'Locate',                 // Basic locate
        'MrzOrOcr',              // Combined
        'FullProcess',            // Full process
        'Capture',                // Capture only as fallback
      ];
      
      // Try each scenario until one works
      for (final scenarioName in scenarioNamesToTry) {
        final scenarioEnum = getScenarioEnum(scenarioName);
        if (scenarioEnum == null) {
          print('Scenario $scenarioName not mapped, skipping...');
          continue;
        }
        try {
          print('Trying scenario: $scenarioName');
          
          final completer = Completer<Map<String, dynamic>?>();
          
          // Create scanner config with scenario enum
          final config = ScannerConfig.withScenario(scenarioEnum);
          
          DocumentReader.instance.startScanner(
            config,
            (DocReaderAction action, Results? results, DocReaderException? error) {
              print('Fallback scanner action received: $action for scenario: $scenarioName');
              
              if (error != null) {
                print('Scenario $scenarioName failed: ${error.message}');
                completer.complete(null);
                return;
              }
              
              // Following official documentation: check for COMPLETE or TIMEOUT
              if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
                if (results != null) {
                  print('Document scanning completed successfully with scenario: $scenarioName');
                  final extractedData = extractDocumentData(results);
                  completer.complete(extractedData);
                } else {
                  print('Scenario $scenarioName completed but no results received');
                  completer.complete(null);
                }
              } else if (action == DocReaderAction.ERROR) {
                print('Scenario $scenarioName failed with error action');
                completer.complete(null);
              } else if (action == DocReaderAction.CANCEL) {
                print('Scenario $scenarioName was cancelled by user');
                completer.complete(null);
              } else {
                print('Scenario $scenarioName action: $action - continuing...');
                // Don't complete yet, wait for COMPLETE or TIMEOUT
              }
            },
          );
          
          final result = await completer.future;
          if (result != null) {
            return result;
          }
        } catch (e) {
          print('Error with scenario $scenarioName: $e');
          continue;
        }
      }
      
      print('All scenarios failed');
      return null;
      
    } catch (e) {
      print('Document scanning failed: $e');
      return null;
    }
  }

  /// Process image from gallery with server-side verification (alternative method)
  /// This method uses RecognizeConfig with scenario for gallery images
  Future<Map<String, dynamic>?> processGalleryImage(List<Uint8List> imageBytes) async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('Processing ${imageBytes.length} gallery images with server-side verification...');
      
      // Create RecognizeConfig with scenario following official documentation
      final config = RecognizeConfig.withScenario(
        Scenario.FULL_PROCESS, // Use full process for gallery images
        images: imageBytes,
      );
      
      // Use the real Regula image processing following official documentation
      final completer = Completer<Map<String, dynamic>?>();
      
      DocumentReader.instance.recognize(
        config,
        (DocReaderAction action, Results? results, DocReaderException? error) {
          print('Gallery image processing action received: $action');
          
          if (error != null) {
            print('Gallery image processing error: ${error.message}');
            completer.complete(null);
            return;
          }
          
          // Following official documentation: check for COMPLETE or TIMEOUT
          if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
            if (results != null) {
              print('Gallery image processing completed successfully');
              final extractedData = extractDocumentData(results);
              completer.complete(extractedData);
            } else {
              print('Gallery image processing completed but no results received');
              completer.complete(null);
            }
          } else if (action == DocReaderAction.ERROR) {
            print('Gallery image processing failed with error action');
            completer.complete(null);
          } else if (action == DocReaderAction.CANCEL) {
            print('Gallery image processing was cancelled by user');
            completer.complete(null);
          } else {
            print('Gallery image processing action: $action - continuing...');
            // Don't complete yet, wait for COMPLETE or TIMEOUT
          }
        },
      );
      
      return await completer.future;
    } catch (e) {
      print('Error processing gallery images: $e');
      return null;
    }
  }

  /// Process binary image data with server-side verification
  /// This method can handle images in .pdf, .jpg, .png, or other formats
  Future<Map<String, dynamic>?> processBinaryImage(Uint8List imageData) async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('Processing binary image data with server-side verification...');
      
      // Create RecognizeConfig with binary data following official documentation
      final config = RecognizeConfig.withScenario(
        Scenario.FULL_PROCESS, // Use full process for binary data
        data: imageData,
      );
      
      // Use the real Regula image processing following official documentation
      final completer = Completer<Map<String, dynamic>?>();
      
      DocumentReader.instance.recognize(
        config,
        (DocReaderAction action, Results? results, DocReaderException? error) {
          print('Binary image processing action received: $action');
          
          if (error != null) {
            print('Binary image processing error: ${error.message}');
            completer.complete(null);
            return;
          }
          
          // Following official documentation: check for COMPLETE or TIMEOUT
          if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
            if (results != null) {
              print('Binary image processing completed successfully');
              final extractedData = extractDocumentData(results);
              completer.complete(extractedData);
            } else {
              print('Binary image processing completed but no results received');
              completer.complete(null);
            }
          } else if (action == DocReaderAction.ERROR) {
            print('Binary image processing failed with error action');
            completer.complete(null);
          } else if (action == DocReaderAction.CANCEL) {
            print('Binary image processing was cancelled by user');
            completer.complete(null);
          } else {
            print('Binary image processing action: $action - continuing...');
            // Don't complete yet, wait for COMPLETE or TIMEOUT
          }
        },
      );
      
      return await completer.future;
    } catch (e) {
      print('Error processing binary image: $e');
      return null;
    }
  }

  /// Get detailed SDK information and capabilities
  Future<Map<String, dynamic>> getSDKInfo() async {
    if (!_isInitialized) {
      return {
        'isReady': false,
        'error': 'Regula service not initialized'
      };
    }

    try {
      final scenarios = await getAvailableScenarios();
      final rfidAvailable = await isRFIDAvailable();
      final isReady = await DocumentReader.instance.isReady;
      final status = await DocumentReader.instance.status;
      
      // Get additional SDK information
      final sdkInfo = <String, dynamic>{
        'isReady': isReady,
        'status': status,
        'availableScenarios': scenarios,
        'rfidAvailable': rfidAvailable,
        'scenarioCount': scenarios.length,
        'platform': Platform.isIOS ? 'iOS' : 'Android',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Try to get version information if available
      try {
        // Note: Version info might not be directly available in Flutter API
        sdkInfo['sdkVersion'] = 'flutter_document_reader_api: 8.2.322-nightly';
        sdkInfo['coreVersion'] = 'flutter_document_reader_core_fullrfid: 8.1.427';
      } catch (e) {
        sdkInfo['versionError'] = 'Could not retrieve version info: $e';
      }
      
      return sdkInfo;
    } catch (e) {
      return {
        'isReady': false,
        'error': 'Failed to get SDK info: $e'
      };
    }
  }

  /// Map scenario name to Scenario enum
  Scenario? getScenarioEnum(String scenarioName) {
    switch (scenarioName) {
      case 'Mrz':
        return Scenario.MRZ;
      case 'Ocr':
        return Scenario.OCR;
      case 'Barcode':
        return Scenario.BARCODE;
      case 'Locate':
        return Scenario.LOCATE;
      case 'MrzOrOcr':
        return Scenario.MRZ_OR_OCR;
      case 'FullProcess':
        return Scenario.FULL_PROCESS;
      case 'Capture':
        return Scenario.CAPTURE;
      case 'MrzOrBarcode':
        return Scenario.MRZ_OR_BARCODE;
      case 'MrzOrLocate':
        return Scenario.MRZ_OR_LOCATE;
      case 'MrzAndLocate':
        return Scenario.MRZ_AND_LOCATE;
      case 'BarcodeAndLocate':
        return Scenario.BARCODE_AND_LOCATE;
      case 'CreditCard':
        return Scenario.CREDIT_CARD;
      case 'OcrFree':
        return Scenario.OCR_FREE;
      case 'DTC':
        return Scenario.DTC;
      case 'RFID':
        return Scenario.RFID;
      default:
        print('Unknown scenario name: $scenarioName');
        return null;
    }
  }

  /// Scan document using FullProcess scenario (following official documentation)
  Future<Map<String, dynamic>?> scanDocumentWithFullProcess() async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('Starting document scan with FullProcess scenario...');
      
      // TEMPORARILY SKIP PERMISSION CHECK FOR TESTING
      print('⚠️ TEMPORARILY SKIPPING PERMISSION CHECK FOR TESTING ⚠️');
      // final hasPermission = await requestCameraPermission();
      // if (!hasPermission) {
      //   print('Camera permission not granted. Cannot scan documents.');
      //   return null;
      // }
      
      // Create scanner config following official documentation
      final config = ScannerConfig.withScenario(Scenario.FULL_PROCESS);
      print('Scanner config created with FullProcess scenario');
      
      print('Starting scanner with FullProcess scenario...');
      
      // Use the real Regula camera scanner following official documentation
      final completer = Completer<Map<String, dynamic>?>();
      
      DocumentReader.instance.scan(config, (action, results, error) {
        print('Scanner action received: $action');
        
        if (error != null) {
          print('Document scanning error: ${error.message}');
          completer.complete(null);
          return;
        }
        
        if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
          if (results != null) {
            print('Document scanning completed successfully with FullProcess');
            final extractedData = extractDocumentData(results);
            completer.complete(extractedData);
          } else {
            print('Document scanning completed but no results received');
            completer.complete(null);
          }
        } else if (action == DocReaderAction.ERROR) {
          print('Document scanning failed with error action');
          completer.complete(null);
        } else if (action == DocReaderAction.CANCEL) {
          print('Document scanning was cancelled by user');
          completer.complete(null);
        } else {
          print('Document scanning action: $action - continuing...');
        }
      });
      
      return await completer.future;
    } catch (e) {
      print('Document scanning failed: $e');
      return null;
    }
  }

  /// Open app settings to allow user to enable camera permission
  Future<void> openAppSettings() async {
    try {
      final Uri settingsUri = Uri.parse('app-settings:');
      if (await canLaunchUrl(settingsUri)) {
        await launchUrl(settingsUri);
      } else {
        print('Could not open app settings');
      }
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }

  /// Check and request camera permission with better error handling
  Future<bool> checkCameraPermission() async {
    print('Checking camera permission...');
    var status = await Permission.camera.status;
    print('Camera permission status: $status');
    
    if (status.isGranted) {
      print('Camera permission already granted');
      return true;
    }
    
    if (status.isDenied) {
      print('Requesting camera permission...');
      status = await Permission.camera.request();
      print('Camera permission result: $status');
      
      if (status.isGranted) {
        print('Camera permission granted');
        return true;
      }
    }
    
    if (status.isPermanentlyDenied) {
      print('Camera permission is permanently denied. User must enable it in device settings.');
      // Return false so the UI can handle showing a dialog
      return false;
    }
    
    print('Camera permission denied');
    return false;
  }

  /// Request camera permission with user-friendly messaging
  Future<bool> requestCameraPermission() async {
    print('=== CAMERA PERMISSION DEBUG START ===');
    print('Requesting camera permission with user guidance...');
    
    // First check current status
    var status = await Permission.camera.status;
    print('Initial camera permission status: $status');
    
    if (status.isGranted) {
      print('✅ Camera permission already granted');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      print('❌ Camera permission is permanently denied - need to guide user to settings');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return false;
    }
    
    if (status.isRestricted) {
      print('❌ Camera permission is restricted');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return false;
    }
    
    if (status.isLimited) {
      print('⚠️ Camera permission is limited');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return false;
    }
    
    // Request permission (this will show the system dialog)
    print('📱 About to show camera permission request dialog...');
    print('This should show a system dialog asking for camera access');
    
    try {
      status = await Permission.camera.request();
      print('🔍 Permission request completed. New status: $status');
    } catch (e) {
      print('❌ Error during permission request: $e');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return false;
    }
    
    if (status.isGranted) {
      print('✅ Camera permission granted by user');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return true;
    } else if (status.isDenied) {
      print('❌ Camera permission denied by user');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return false;
    } else if (status.isPermanentlyDenied) {
      print('❌ Camera permission permanently denied by user');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return false;
    } else {
      print('❓ Unknown permission status: $status');
      print('=== CAMERA PERMISSION DEBUG END ===');
      return false;
    }
  }

  /// Handle permanently denied camera permission - call this from UI
  Future<void> handlePermanentlyDeniedCamera() async {
    print('Camera permission is permanently denied. Opening app settings...');
    await openAppSettings();
  }

  /// Check if camera permission is permanently denied
  Future<bool> isCameraPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  /// Complete camera permission flow for UI integration
  /// Call this from your UI when user wants to scan documents
  Future<bool> requestCameraAccessForScanning() async {
    print('Starting camera permission flow for document scanning...');
    
    // First try to request permission normally
    final hasPermission = await requestCameraPermission();
    
    if (hasPermission) {
      print('Camera permission granted - ready to scan');
      return true;
    }
    
    // If we get here, permission was denied or permanently denied
    final isPermanentlyDenied = await isCameraPermanentlyDenied();
    
    if (isPermanentlyDenied) {
      print('Camera permission is permanently denied - need to guide user to settings');
      // Return false so UI can show a dialog and then call handlePermanentlyDeniedCamera()
      return false;
    } else {
      print('Camera permission was denied by user');
      // Return false so UI can show a message about needing camera access
      return false;
    }
  }

  /// Simple test to check camera permission status
  Future<void> testCameraPermission() async {
    print('=== SIMPLE CAMERA PERMISSION TEST ===');
    
    // Check current status
    final currentStatus = await Permission.camera.status;
    print('Current camera permission status: $currentStatus');
    
    // Try to request permission
    print('About to request camera permission...');
    final newStatus = await Permission.camera.request();
    print('After request, status is: $newStatus');
    
    // Check if we can access camera
    final canAccess = await Permission.camera.isGranted;
    print('Can access camera: $canAccess');
    
    print('=== TEST COMPLETE ===');
  }

  /// Test scanning without permission checks (for debugging)
  Future<Map<String, dynamic>?> testScanWithoutPermissionCheck() async {
    if (!_isInitialized) {
      print('Regula service not initialized');
      return null;
    }

    try {
      print('=== TESTING SCAN WITHOUT PERMISSION CHECK ===');
      
      // Skip permission check and go straight to scanning
      print('Skipping permission check - going straight to scanner...');
      
      // Set the processing scenario (following official documentation)
      var config = ScannerConfig.withScenario(Scenario.FULL_PROCESS);
      
      print('Starting scanner with FullProcess scenario...');
      
      // Use the real Regula camera scanner following official documentation
      final completer = Completer<Map<String, dynamic>?>();
      
      DocumentReader.instance.scan(config, (action, results, error) {
        print('Scanner action received: $action');
        
        if (error != null) {
          print('Document scanning error: ${error.message}');
          completer.complete(null);
          return;
        }
        
        if (action == DocReaderAction.COMPLETE || action == DocReaderAction.TIMEOUT) {
          if (results != null) {
            print('Document scanning completed successfully with FullProcess');
            final extractedData = extractDocumentData(results);
            completer.complete(extractedData);
          } else {
            print('Document scanning completed but no results received');
            completer.complete(null);
          }
        } else if (action == DocReaderAction.ERROR) {
          print('Document scanning failed with error action');
          completer.complete(null);
        } else if (action == DocReaderAction.CANCEL) {
          print('Document scanning was cancelled by user');
          completer.complete(null);
        } else {
          print('Document scanning action: $action - continuing...');
        }
      });
      
      return await completer.future;
    } catch (e) {
      print('Document scanning failed: $e');
      return null;
    }
  }

  /// Check SDK status and database availability
  Future<void> checkSDKStatus() async {
    print('=== SDK STATUS CHECK ===');
    print('Is initialized: $_isInitialized');
    
    if (!_isInitialized) {
      print('SDK not initialized!');
      return;
    }
    
    try {
      // Check available scenarios
      final scenarios = await getAvailableScenarios();
      print('Available scenarios: $scenarios');
      
      // Check if FullProcess is available
      final hasFullProcess = scenarios.contains('FullProcess');
      print('FullProcess available: $hasFullProcess');
      
    } catch (e) {
      print('Error checking SDK status: $e');
    }
    
    print('=== STATUS CHECK COMPLETE ===');
  }
} 