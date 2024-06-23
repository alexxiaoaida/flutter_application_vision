import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'dart:developer';

class CameraService extends GetxService {
  late CameraController cameraController;
  List<CameraDescription>? cameras;
  var isCameraInitialized = false.obs;

  Rxn<CameraImage> latestImage = Rxn<CameraImage>(); // Reactive variable to store the latest camera image

  Future<CameraService> init() async {
    await initializeCamera();
    return this;
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras![0], ResolutionPreset.max);

    try {
      await cameraController.initialize();
      
      isCameraInitialized.value = true;
    } catch (e) {
      log('Error initializing camera: $e');
    }
  }

  void startStreaming() {
    if (!cameraController.value.isStreamingImages) {
      cameraController.startImageStream((CameraImage image) {
        // Stream camera images
        latestImage.value = image;  // Store each frame in the reactive variable
      });
    }
  }

  void stopStreaming() {
    if (cameraController.value.isStreamingImages) {
      cameraController.stopImageStream();
    }
  }

  @override
  void onClose() {
    if (cameraController.value.isInitialized) {
      cameraController.dispose();
    }
    super.onClose();
  }
}
