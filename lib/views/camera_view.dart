import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_vision/controller/money_detection_controller.dart';
import 'package:flutter_application_vision/controller/mrz_scanner_controller.dart';
import 'package:flutter_application_vision/controller/object_detection_controller.dart';
import 'package:flutter_application_vision/controller/specific_detection_controller.dart';
import 'package:flutter_application_vision/controller/text_detection_controller.dart';
import 'package:flutter_application_vision/service/camera_service.dart';
import 'package:flutter_application_vision/widget/money_overlay_painter.dart';
import 'package:flutter_application_vision/widget/mrz_overlay.dart';
import 'package:flutter_application_vision/widget/object_overlay_painter.dart';
import 'package:flutter_application_vision/widget/text_overlay_painter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'report_page.dart';
import 'login_page.dart';

class CameraView extends StatelessWidget {
  final FlutterTts flutterTts = FlutterTts();

  CameraView({super.key}) {
    initializeTts();
  }

  void initializeTts() {
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speak(String text) async {
    await flutterTts.speak(text);
  }

  void _stopAllDetections(
      ObjectDetectionController objectDetectionController,
      TextDetectionController textDetectionController,
      MrzScannerController mrzScannerController,
      SpecificDetectionController specificDetectionController,
      MoneyDetectionController moneyDetectionController) {
    objectDetectionController.isDetecting.value = false;
    textDetectionController.isProcessingText.value = false;
    mrzScannerController.isScanningMrz.value = false;
    specificDetectionController.isDetectingSpecific.value = false;
    moneyDetectionController.isDetectingMoney.value = false;
  }

  void _onBottomNavButtonPressed(String label, RxBool isDetecting, VoidCallback action,
      ObjectDetectionController objectDetectionController,
      TextDetectionController textDetectionController,
      MrzScannerController mrzScannerController,
      SpecificDetectionController specificDetectionController,
      MoneyDetectionController moneyDetectionController) {
    if (isDetecting.value) {
      // If the current detection is active, stop it
      isDetecting.value = false;
      String state = 'stopped';
      HapticFeedback.vibrate();
      _speak('$state $label');
    } else {
      // Stop all other detections and start the selected one
      _stopAllDetections(objectDetectionController, textDetectionController, mrzScannerController, specificDetectionController, moneyDetectionController);
      action();
      String state = isDetecting.value ? 'started' : 'stopped';
      HapticFeedback.vibrate();
      _speak('$state $label');
    }
  }

  Widget _buildIconButton({
    required String label,
    required IconData icon,
    required RxBool controller,
    required VoidCallback action,
    required ObjectDetectionController objectDetectionController,
    required TextDetectionController textDetectionController,
    required MrzScannerController mrzScannerController,
    required SpecificDetectionController specificDetectionController,
    required MoneyDetectionController moneyDetectionController,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () => _onBottomNavButtonPressed(
            label,
            controller,
            action,
            objectDetectionController,
            textDetectionController,
            mrzScannerController,
            specificDetectionController,
            moneyDetectionController),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          backgroundColor: controller.value ? Colors.purple : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black, size: 24.0),
            Text(label, style: TextStyle(color: Colors.black, fontSize: 12.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required VoidCallback action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 48),
        onPressed: action,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CameraService cameraService = Get.find<CameraService>();
    final ObjectDetectionController objectDetectionController = Get.find<ObjectDetectionController>();
    final TextDetectionController textDetectionController = Get.find<TextDetectionController>();
    final MrzScannerController mrzScannerController = Get.find<MrzScannerController>();
    final SpecificDetectionController specificDetectionController = Get.find<SpecificDetectionController>();
    final MoneyDetectionController moneyDetectionController = Get.find<MoneyDetectionController>();

    return Scaffold(
      body: Obx(() {
        if (!cameraService.isCameraInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: CameraPreview(cameraService.cameraController),
            ),
            if (objectDetectionController.isDetecting.value)
              CustomPaint(
                painter: ObjectOverlayPainter(objectLabel: objectDetectionController.detections.isNotEmpty ? objectDetectionController.detections.first.label : ''),
                size: MediaQuery.of(context).size,
              ),
            if (textDetectionController.isProcessingText.value)
              CustomPaint(
                painter: TextOverlayPainter(recognizedText: textDetectionController.recognizedText.value),
                size: MediaQuery.of(context).size,
              ),
            if (textDetectionController.isFloatingButtonVisible.value)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: () => textDetectionController.captureAndProcessImage(),
                    backgroundColor: Colors.white,  
                    foregroundColor: Colors.black,  
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            if (mrzScannerController.isScanningMrz.value)
              CustomPaint(
                painter: MrzOverlay(recognizedText: mrzScannerController.recognizedText.value),
                size: MediaQuery.of(context).size,
              ),
            if (mrzScannerController.isScanningMrz.value)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: () => mrzScannerController.captureAndProcessImage(),
                    backgroundColor: Colors.white,  
                    foregroundColor: Colors.black,  
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),
            if (moneyDetectionController.isDetectingMoney.value)
              CustomPaint(
                painter: MoneyOverlayPainter(detectedMoney: moneyDetectionController.detectedMoney.value),
                size: MediaQuery.of(context).size,
              ),
            if(moneyDetectionController.isDetectingMoney.value)
            Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: () => moneyDetectionController.captureAndProcessImage(),
                    backgroundColor: Colors.white,  
                    foregroundColor: Colors.black,  
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),

            Positioned(
              top: 50.0,
              right: 16.0,
              child: _buildTopButton(
                icon: Icons.report,
                action: () {
                  Get.to(() => ReportPage());
                },
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: Container(
          height: 200, // Increased height of the bottom navigation bar to 200
          padding: const EdgeInsets.all(0), // Removed internal padding
          child: Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildIconButton(
                    label: 'Object Detection',
                    icon: Icons.search,
                    controller: objectDetectionController.isDetecting,
                    action: objectDetectionController.toggleObjectDetection,
                    objectDetectionController: objectDetectionController,
                    textDetectionController: textDetectionController,
                    mrzScannerController: mrzScannerController,
                    specificDetectionController: specificDetectionController,
                    moneyDetectionController: moneyDetectionController,
                  ),
                  _buildIconButton(
                    label: 'Text Recognition',
                    icon: Icons.text_fields,
                    controller: textDetectionController.isProcessingText,
                    action: textDetectionController.toggleTextRecognition,
                    objectDetectionController: objectDetectionController,
                    textDetectionController: textDetectionController,
                    mrzScannerController: mrzScannerController,
                    specificDetectionController: specificDetectionController,
                    moneyDetectionController: moneyDetectionController,
                  ),
                  _buildIconButton(
                    label: 'ID Scan',
                    icon: Icons.camera,
                    controller: mrzScannerController.isScanningMrz,
                    action: mrzScannerController.toggleMrzScan,
                    objectDetectionController: objectDetectionController,
                    textDetectionController: textDetectionController,
                    mrzScannerController: mrzScannerController,
                    specificDetectionController: specificDetectionController,
                    moneyDetectionController: moneyDetectionController,
                  ),
                  _buildIconButton(
                    label: 'Chair Detection',
                    icon: Icons.event_seat,
                    controller: specificDetectionController.isDetectingSpecific,
                    action: specificDetectionController.startOrStopDetection,
                    objectDetectionController: objectDetectionController,
                    textDetectionController: textDetectionController,
                    mrzScannerController: mrzScannerController,
                    specificDetectionController: specificDetectionController,
                    moneyDetectionController: moneyDetectionController,
                  ),
                  _buildIconButton(
                    label: 'Money Detection',
                    icon: Icons.attach_money,
                    controller: moneyDetectionController.isDetectingMoney,
                    action: moneyDetectionController.toggleMoneyDetection,
                    objectDetectionController: objectDetectionController,
                    textDetectionController: textDetectionController,
                    mrzScannerController: mrzScannerController,
                    specificDetectionController: specificDetectionController,
                    moneyDetectionController: moneyDetectionController,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => LoginPage());
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0), // Reduced padding
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, color: Colors.black, size: 24.0), // Reduced icon size
                          Text('Login', style: TextStyle(color: Colors.black, fontSize: 12.0)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
