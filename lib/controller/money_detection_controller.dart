import 'package:camera/camera.dart';
import 'package:flutter_application_vision/service/camera_service.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MoneyDetectionController extends GetxController {
  final CameraService _cameraService = Get.find<CameraService>();
  final FlutterTts flutterTts = FlutterTts();
  late final TextRecognizer textRecognizer;

  RxBool isDetectingMoney = false.obs;
  RxBool isFloatingButtonVisible = false.obs; // To manage FloatingActionButton visibility
  RxString detectedMoney = ''.obs;

  @override
  void onInit() {
    super.onInit();
    textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    initializeTts();
  }

  void initializeTts() {
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  void toggleMoneyDetection() {
    isDetectingMoney.value = !isDetectingMoney.value;
    isFloatingButtonVisible.value = isDetectingMoney.value; // Show or hide the FloatingActionButton
    if (!isDetectingMoney.value) {
      stopMoneyDetection();
    }
  }

  void startMoneyDetection() {
    captureAndProcessImage();
  }

  void stopMoneyDetection() {
    isDetectingMoney.value = false;
    detectedMoney.value = '';
    flutterTts.stop();
  }

  Future<void> captureAndProcessImage() async {
    if (!_cameraService.cameraController.value.isInitialized) {
      print("Camera is not initialized.");
      return;
    }

    final XFile image = await _cameraService.cameraController.takePicture();
    await detectMoney(image.path);
  }

Future<void> detectMoney(String imagePath) async {
  try {
    final InputImage inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    String moneyValue = extractMoneyValue(recognizedText);
    updateMoneyDetection(moneyValue);
  } catch (e) {
    print("Error during money detection: $e");
  }
}

String extractMoneyValue(RecognizedText recognizedText) {
  final patterns = definePatterns();
  return detectMoneyValue(recognizedText, patterns);
}

Map<String, List<String>> definePatterns() {
  return {
    "500": ["cinci sute", "CINCI SUTE", "cinci sut", "CINCI SUT"],
    "200": ["două sute", "DOUĂ SUTE", "doua sute", "DOUA SUTE", "doua sut", "DOUA SUT","DOUĂ SUT", "două sut"],
    "100": ["una sută", "UNA SUTĂ", "una suta", "UNA SUTA", "una sut", "UNA SUT"],
    "50": ["cincizeci", "CINCIZECI", "cincizec", "CINCIZEC", "CINCIZE", "cincize", "CINCIZ", "cinciz"],
    "20": ["douazeci", "DOUAZECI", "douăzeci", "DOUĂZECI"],
    "10": ["ZECE", "zece", "ZEC", "zec"],
    "5": ["CINCI", "cinci"],
    "1": ["LEU", "leu"]
  };
}

String detectMoneyValue(RecognizedText recognizedText, Map<String, List<String>> patterns) {
  String moneyValue = "";
  for (TextBlock block in recognizedText.blocks) {
    for (TextLine line in block.lines) {
      for (var entry in patterns.entries) {
        if (entry.value.any((pattern) => line.text.toLowerCase().contains(pattern.toLowerCase()))) {
          moneyValue = entry.key;
          break;
        }
      }
      if (moneyValue.isNotEmpty) {
        break;
      }
    }
    if (moneyValue.isNotEmpty) {
      break;
    }
  }

  return moneyValue;
}

void updateMoneyDetection(String moneyValue) {
  if (moneyValue.isNotEmpty) {
    detectedMoney.value = "$moneyValue LEI";
    flutterTts.speak(detectedMoney.value);
    print("Detected: $moneyValue LEI");
  } else {
    detectedMoney.value = "No banknote detected";
    flutterTts.speak(detectedMoney.value);
  }
}



  @override
  void onClose() {
    textRecognizer.close();
    flutterTts.stop();
    super.onClose();
  }
}
