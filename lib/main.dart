import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _profilePicture;
  File? _verificationPicture;
  String _responseMessage = '';
  bool? _isVerified;
  int? _responseStatusCode;

  final picker = ImagePicker();

  Future getImage(ImageSource source, String field) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (field == 'profile_picture') {
          _profilePicture = File(pickedFile.path);
        } else if (field == 'verification_picture') {
          _verificationPicture = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _uploadImages() async {
    const endpoint = 'https://demo-capstone-ml-2-muf7kziviq-as.a.run.app';
    final uri = Uri.parse('${endpoint}/verify');
    final request = http.MultipartRequest('POST', uri);

    // Add profile picture to the request
    if (_profilePicture != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          _profilePicture!.path,
        ),
      );
    }

    // Add verification picture to the request
    if (_verificationPicture != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'verification_picture',
          _verificationPicture!.path,
        ),
      );
    }

    final response = await request.send();
    final responseData = await response.stream.toBytes();

    setState(() {
      _responseStatusCode = response.statusCode;
      if (_responseStatusCode == 200) {
        final jsonResponse = json.decode(utf8.decode(responseData));
        final data = jsonResponse['data'];
        _responseMessage = jsonResponse['message'];
        _isVerified = jsonResponse['data']['verified'];
        // Handle data as needed (e.g., access 'data' to get detector_backend, distance, etc.)
      } else {
        _responseMessage = 'Failed to upload images';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Image Upload Example'),
        ),
        body: Center(
          child: ListView(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _profilePicture != null
                      ? Image.file(_profilePicture!)
                      : const Text('No Profile Picture selected'),
                  ElevatedButton(
                    onPressed: () =>
                        getImage(ImageSource.gallery, 'profile_picture'),
                    child: const Text('Select Profile Picture'),
                  ),
                  const SizedBox(height: 20),
                  _verificationPicture != null
                      ? Image.file(_verificationPicture!)
                      : const Text('No Verification Picture selected'),
                  ElevatedButton(
                    onPressed: () =>
                        getImage(ImageSource.gallery, 'verification_picture'),
                    child: const Text('Select Verification Picture'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _uploadImages,
                    child: const Text('Upload Images'),
                  ),
                  const SizedBox(height: 20),
                  Text('Response Status Code: $_responseStatusCode'),
                  Text(
                    'Response Message: $_responseMessage',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Verified Status: $_isVerified',
                    style: TextStyle(
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
