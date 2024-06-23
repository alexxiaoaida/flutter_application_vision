import 'package:flutter_application_vision/service/camera_service.dart';
import 'package:flutter_ocr_sdk/flutter_ocr_sdk.dart';
import 'package:flutter_ocr_sdk/mrz_line.dart';
import 'package:flutter_ocr_sdk/mrz_parser.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MrzScannerController extends GetxController {
  final CameraService cameraService = Get.find<CameraService>();

  final FlutterTts flutterTts = FlutterTts();

  RxBool isScanningMrz = false.obs;

  late FlutterOcrSdk mrzDetector;

  RxString recognizedText = ''.obs;
  RxBool isSpeaking = false.obs;


  @override
  void onInit() {
    super.onInit();
    initializeTts();
    // Optionally start text recognition here or trigger by user action
    initializeMrzDetector();
  }

  void initializeTts() {
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);


  }

 Future<void> initializeMrzDetector() async {
    mrzDetector = FlutterOcrSdk();
    int? ret = await mrzDetector.init("DLS2eyJoYW5kc2hha2VDb2RlIjoiMTAyOTI1OTQyLVRYbE5iMkpwYkdWUWNtOXEiLCJtYWluU2VydmVyVVJMIjoiaHR0cHM6Ly9tZGxzLmR5bmFtc29mdG9ubGluZS5jb20iLCJvcmdhbml6YXRpb25JRCI6IjEwMjkyNTk0MiIsInN0YW5kYnlTZXJ2ZXJVUkwiOiJodHRwczovL3NkbHMuZHluYW1zb2Z0b25saW5lLmNvbSIsImNoZWNrQ29kZSI6MzYzMzk0MH0=");
    if (ret == 0) {
      // Inițializare reușită
      await mrzDetector.loadModel();
      print("MRZ Detector initialized successfully.");
    } else {
      // Handle error
      print("Failed to initialize MRZ Detector.");
    }
  }


void toggleMrzScan() {
    if (isScanningMrz.value) {
      stopMrzScan();
    } else {
      startMrzScan();
    }
  }

  void startMrzScan() {
     isScanningMrz.value = true;
    // Here, you could log or do additional setup if necessary
    print("MRZ scan started, ready to capture.");
  }

  void stopMrzScan() {
    isScanningMrz.value = false;
    if (isSpeaking.value) {
      flutterTts.stop();
      isSpeaking.value = false;
    }
    recognizedText.value = ''; // Clear the text when stopping the scan
  }



  void captureAndProcessImage() async {
    final image = await cameraService.cameraController.takePicture();
    List<List<MrzLine>>? results = await mrzDetector.recognizeByFile(image.path);
    if (results != null && results.isNotEmpty) {
      recognizedText.value = parseMrzResults(results);
      flutterTts.speak(recognizedText.value).then((_) => isSpeaking.value = false);
      isSpeaking.value = true;
    } else {
      recognizedText.value = "No Data found.";
      flutterTts.speak(recognizedText.value);
    }
  }


    String parseMrzResults(List<List<MrzLine>>? results) {
      String information = '';
      if (results != null && results.isNotEmpty) {
        for (List<MrzLine> area in results) {
          if (area.length == 2) {
            information = MRZ.parseTwoLines(area[0].text, area[1].text).toString();
          } else if (area.length == 3) {
            information = MRZ.parseThreeLines(area[0].text, area[1].text, area[2].text).toString();
          }
        }
      }
      return information;
  }


 void toggleSpeaking() {
    if (isSpeaking.value) {
      flutterTts.stop();
      isSpeaking.value = false;
    }
  }




  @override
  void onClose() {
    stopMrzScan(); // Ensure everything is stopped when the controller is being closed
    toggleSpeaking(); // Oprește TTS la închiderea controllerului
    flutterTts.stop();
    super.onClose();
  }
}
