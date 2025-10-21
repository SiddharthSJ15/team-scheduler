import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  Future getImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = image;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 200,
                  width: 200,
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: _image == null
                      ? const Text('No image selected.')
                      : _buildImage(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter your name',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: getImage,
                  child: Text('Select Image from gallery'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(_image!.path, fit: BoxFit.cover);
    } else {
      return Image.file(File(_image!.path), fit: BoxFit.cover);
    }
  }
}
