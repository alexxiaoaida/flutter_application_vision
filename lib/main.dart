import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'views/camera_view.dart';
import 'controller/money_detection_controller.dart';
import 'controller/mrz_scanner_controller.dart';
import 'controller/object_detection_controller.dart';
import 'controller/specific_detection_controller.dart';
import 'controller/text_detection_controller.dart';
import 'service/camera_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Vision Application',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: initApp(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraView();
          }
          return const CircularProgressIndicator();  // Display a loading indicator until initialization is complete
        },
      ),
    );
  }

  Future<void> initApp() async {
    await Get.putAsync(() => CameraService().init());
    Get.put(ObjectDetectionController());
    Get.put(TextDetectionController());
    Get.put(MrzScannerController());
    Get.put(SpecificDetectionController());
    Get.put(MoneyDetectionController());
  }
}
