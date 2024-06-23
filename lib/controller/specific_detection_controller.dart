import 'package:camera/camera.dart';
import 'package:flutter_application_vision/service/camera_service.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'dart:developer';

class SpecificDetectionController extends GetxController {
  final CameraService _cameraService = Get.find<CameraService>();
  final FlutterTts flutterTts = FlutterTts();
  var isModelBusy = false.obs;
  var isDetectingSpecific = false.obs;
  var canSpeak = true.obs; // Controls if the TTS can speak
  int frameSkipCount = 0; // Added frameSkipCount for skipping frames

  @override
  void onInit() {
    super.onInit();
    initializeTts();
    loadModel();
  }

  void initializeTts() {
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false,
      );
      log('Model loaded successfully');
    } catch (e) {
      log('Failed to load model: $e');
    }
  }

  void startOrStopDetection() {
    if (isDetectingSpecific.value) {
      stopDetection();
    } else {
      startDetection();
    }
    isDetectingSpecific.toggle();
  }

  void startDetection() {
    _cameraService.cameraController.startImageStream((CameraImage image) async {
      if (shouldSkipFrame()) return;
      if (!shouldProcessFrame()) return;
      isModelBusy.value = true;
      await processImage(image);
    });
  }

  bool shouldSkipFrame() {
    frameSkipCount++;
    if (frameSkipCount < 5) return true;
    frameSkipCount = 0;
    return false;
  }

  bool shouldProcessFrame() {
    return isDetectingSpecific.value && !isModelBusy.value;
  }

  Future<void> processImage(CameraImage image) async {
    try {
      var recognitionResults = await detectObjects(image);
      if (recognitionResults.isNotEmpty) {
        handleDetections(recognitionResults);
      }
    } catch (e) {
      log('Error during object detection: $e');
    } finally {
      isModelBusy.value = false;
    }
  }

  Future<List<Detection>> detectObjects(CameraImage image) async {
    var recognitionResults = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      model: "SSDMobileNet",
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      rotation: 90,
      numResultsPerClass: 1,
      threshold: 0.5,
      asynch: true,
    );
    
    if (recognitionResults == null) return [];
    return recognitionResults.map((result) {
      var rect = result['rect'];
      return Detection(
        x: rect['x'] ?? 0.0,
        y: rect['y'] ?? 0.0,
        width: rect['w'] ?? 0.0,
        height: rect['h'] ?? 0.0,
        label: result['detectedClass'] ?? 'unknown',
        confidence: result['confidenceInClass']?.toDouble() ?? 0.0,
      );
    }).toList();
  }



  void handleDetections(List<Detection> recognitionResults) {
    for (var detection in recognitionResults) {
      if (detection.label == 'chair' && detection.confidence > 0.6) {
        if (canSpeak.value) {
          flutterTts.speak("DETECTED CHAIR");
          canSpeak.value = false; 
          Future.delayed(Duration(seconds: 5), () {
            canSpeak.value = true; 
          });
        }
        break;
      }
    }
  }

  void stopDetection() {
    _cameraService.cameraController.stopImageStream();
    isModelBusy.value = false; // Reset the busy state
  }

  @override
  void onClose() {
    Tflite.close();
    flutterTts.stop();
    super.onClose();
  }
}

// Detection class to hold detection results
class Detection {
  final double x;
  final double y;
  final double width;
  final double height;
  final String label;
  final double confidence;

  Detection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.confidence,
  });
}
