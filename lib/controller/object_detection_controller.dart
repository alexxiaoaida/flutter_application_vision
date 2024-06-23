import 'dart:developer';

import 'package:flutter_application_vision/service/camera_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:camera/camera.dart';

class ObjectDetectionController extends GetxController {
  final CameraService _cameraService = Get.find<CameraService>();
  var detections = <Detection>[].obs; // List to hold detection results.
  RxBool isDetecting = false.obs;
  FlutterTts flutterTts = FlutterTts();
  String lastSpokenText = "";
  var isModelBusy = false.obs; // Flag to indicate model is processing.
  int frameSkipCount = 0;

  @override
  void onInit() {
    super.onInit();
    initializeTts();
  }

  void initializeTts() {
    flutterTts.setStartHandler(() {
      log("Text to Speech start");
    });

    flutterTts.setCompletionHandler(() {
      log("Text to Speech complete");
    });

    flutterTts.setErrorHandler((msg) {
      log("Text to Speech error: $msg");
    });

    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  void toggleObjectDetection() {
    if (isDetecting.value) {
      stopObjectDetection();
    } else {
      loadModelAndStartStream();
    }
    isDetecting.toggle();
  }

  void startObjectDetection() {
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
    return isDetecting.value && !isModelBusy.value;
  }

  Future<void> processImage(CameraImage image) async {
    try {
      var recognitionResults = await detectObjects(image);
      if (recognitionResults.isNotEmpty) {
        var filteredResults = filterResults(recognitionResults);
        updateDetections(filteredResults);
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
      threshold: 0.1,
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

  List<Detection> filterResults(List<Detection> recognitionResults) {
    return recognitionResults.where((result) => result.confidence > 0.6).toList();
  }

  void updateDetections(List<Detection> filteredResults) {
    detections.value = filteredResults;
    logDetections();
    if (detections.isNotEmpty) {
      speakIfNewLabel(detections.first.label);
    }
  }

  void logDetections() {
    print("${detections.length} found");
    if (detections.isNotEmpty) {
      print('speakkkk');
    }
  }

  void loadModelAndStartStream() async {
    try {
      await Tflite.loadModel(
        model: "assets/ssd_mobilenet.tflite",
        labels: "assets/ssd_mobilenet.txt",
        isAsset: true,
        numThreads: 1,
        useGpuDelegate: false,
      );
      log('Model loaded successfully');
      startObjectDetection();
    } catch (e) {
      log('Failed to load model: $e');
    }
  }

  void speakIfNewLabel(String text) {
    if (text != lastSpokenText) {
      lastSpokenText = text;
      flutterTts.speak(text).then((result) {
        print("TTS speak initiated with result: $result"); // Log the result of the TTS attempt
      }).catchError((error) {
        print("Error speaking text: $error"); // Log if there is an error in speaking
      });
    }
  }

  void stopObjectDetection() {
    _cameraService.cameraController.stopImageStream();
    detections.clear();
  }

  @override
  void onClose() {
    if (isDetecting.value) {
      stopObjectDetection();
    }
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
