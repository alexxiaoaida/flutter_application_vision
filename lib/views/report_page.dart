import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ReportPage extends StatefulWidget {
  ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final _formKey = GlobalKey<FormState>();
  bool _isListening = false;
  bool _anonymous = false;
  TextEditingController? _activeController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Submit as Anonymous'),
                value: _anonymous,
                onChanged: (bool value) async {
                  setState(() {
                    _anonymous = value;
                    if (_anonymous) {
                      emailController.text = 'Anonymous';
                    } else {
                      emailController.clear();
                    }
                  });
                  if (_anonymous) {
                    await _flutterTts.speak('Anonymous selected');
                  }
                },
              ),
              if (!_anonymous)
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    suffixIcon: IconButton(
                      icon: Icon(_isListening && _activeController == emailController ? Icons.mic : Icons.mic_none),
                      onPressed: () => _toggleListening(emailController, isEmail: true),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _formKey.currentState?.validate();
                  },
                ),
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  suffixIcon: IconButton(
                    icon: Icon(_isListening && _activeController == titleController ? Icons.mic : Icons.mic_none),
                    onPressed: () => _toggleListening(titleController),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onChanged: (value) {
                  _formKey.currentState?.validate();
                },
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Describe Problem',
                  suffixIcon: IconButton(
                    icon: Icon(_isListening && _activeController == descriptionController ? Icons.mic : Icons.mic_none),
                    onPressed: () => _toggleListening(descriptionController),
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe the problem';
                  }
                  return null;
                },
                onChanged: (value) {
                  _formKey.currentState?.validate();
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitReport,
                child: const Text('Submit'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

 void submitReport() async {
  if (_formKey.currentState?.validate() ?? false) {
    addReportToFirestore();
  } else {
    handleFormValidationError();
  }
}

Future<void> addReportToFirestore() async {
  CollectionReference colRef = FirebaseFirestore.instance.collection('reports');
  colRef.add({
    'email': emailController.text,
    'title': titleController.text,
    'description': descriptionController.text,
  }).then((value) async {
    await showSuccessDialogAndSpeak();
  }).catchError((error) async {
    await showErrorDialog();
  });
}


Future<void> showErrorDialog() async {
  await _flutterTts.speak("Failed to submit report, please try later");
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Submission Failed'),
      content: const Text('Failed to submit report, please try later.'),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}


Future<void> showSuccessDialogAndSpeak() async {
  await _flutterTts.speak("Thank you for your feedback");
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Thank You!'),
      content: const Text('Thank you for your feedback!'),
      actions: <Widget>[
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
            _clearTextFields();
          },
        ),
      ],
    ),
  );
  print('Report submitted successfully!');
}

Future<void> handleFormValidationError() async {
  print('Form validation failed');
  await _flutterTts.speak("Please fill all fields");
}

void _clearTextFields() {
  emailController.clear();
  titleController.clear();
  descriptionController.clear();
}


  void _toggleListening(TextEditingController controller, {bool isEmail = false}) async {
    if (_isListening && _activeController == controller) {
      setState(() {
        _isListening = false;
        _activeController = null;
      });
      _speech.stop();
      _playAudio('sounds/ding_stop.mp3');
    } else {
      if (!_isListening) {
        bool available = await _speech.initialize(
          onStatus: (status) => print('onStatus: $status'),
          onError: (errorNotification) => print('onError: $errorNotification'),
        );
        if (available) {
          setState(() {
            _isListening = true;
            _activeController = controller;
          });
          _speech.listen(
            onResult: (result) => setState(() {
              String recognizedText = result.recognizedWords;
              if (isEmail) {
                recognizedText = recognizedText.replaceAll(' ', '').toLowerCase();
                if (RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$').hasMatch(recognizedText)) {
                  controller.text = recognizedText;
                }
              } else {
                controller.text = recognizedText;
              }
            }),
          );
          _playAudio('button-pressed1.mp3');
        }
      } else {
        setState(() {
          _isListening = false;
          _activeController = null;
        });
        _speech.stop();
        _playAudio('button-pressed1.mp3');
      }
    }
  }

  void _playAudio(String filePath) async {
    await _audioPlayer.setSource(AssetSource(filePath));
    _audioPlayer.resume();
  }
}
