import 'package:camera/camera.dart';
import 'package:flutter_application_vision/service/camera_service.dart';
import 'package:get/get.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextDetectionController extends GetxController {
  final CameraService _cameraService = Get.find<CameraService>();
  late final TextRecognizer textRecognizer;
  final FlutterTts flutterTts = FlutterTts();
  RxBool isFloatingButtonVisible = false.obs; // To manage FloatingActionButton visibility

  RxBool isProcessingText = false.obs;
  RxString recognizedText = ''.obs;
  String scanText = '';

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

  void toggleTextRecognition() {
    isProcessingText.value = !isProcessingText.value;
    isFloatingButtonVisible.value = isProcessingText.value; // Show or hide the FloatingActionButton
    if (!isProcessingText.value) {
      stopTextRecognition();
    }
  }

  void startTextRecognition() {
    captureAndProcessImage();
  }

  void stopTextRecognition() {
    isProcessingText.value = false;
    recognizedText.value = '';
    flutterTts.stop();
  }

  Future<void> captureAndProcessImage() async {
    if (!_cameraService.cameraController.value.isInitialized) {
      print("Camera is not initialized.");
      return;
    }

    final XFile image = await _cameraService.cameraController.takePicture();
    await getText(image.path);
  }

  Future<void> getText(String path) async {
  final inputImage = InputImage.fromFilePath(path);
  final RecognizedText recognizedTextResult = await textRecognizer.processImage(inputImage);
  String scanText = processRecognizedText(recognizedTextResult);
  updateRecognizedText(scanText);
}

String processRecognizedText(RecognizedText recognizedTextResult) {
  String scanText = '';
  for (TextBlock block in recognizedTextResult.blocks) {
    for (TextLine line in block.lines) {
      for (TextElement element in line.elements) {
        scanText += ' ${element.text}';
      }
      scanText += '\n';
    }
  }
  return scanText;
}

void updateRecognizedText(String scanText) {
  recognizedText.value = scanText;
  if (isProcessingText.value && recognizedText.value.isNotEmpty) {
    flutterTts.speak(recognizedText.value);
  }
}


  @override
  void onClose() {
    textRecognizer.close();
    flutterTts.stop();
    super.onClose();
  }
}
