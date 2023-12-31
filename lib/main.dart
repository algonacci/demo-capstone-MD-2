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
  String? _prediction;
  List<dynamic>? _predictionData;

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
    const endpoint = 'http://192.168.0.109:5050';
    final uri = Uri.parse('$endpoint/verify');
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
        _prediction = jsonResponse['prediction'];

        // Fetch data based on prediction value
        _fetchDataBasedOnPrediction(_prediction);
      } else {
        _responseMessage = 'Failed to upload images';
      }
    });
  }

  Future<void> _fetchDataBasedOnPrediction(String? prediction) async {
    if (prediction != null) {
      final endpoint2 = 'https://b306-103-163-240-34.ngrok-free.app/artist';
      final response = await http.get(Uri.parse('$endpoint2?name=$prediction'));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('====================');
        setState(() {
          _predictionData = jsonResponse;
        });
      }
    }
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
                    style: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Verified Status: $_isVerified',
                    style: const TextStyle(
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (_predictionData != null)
                    Column(
                      children: _predictionData!.map((data) {
                        return ListTile(
                          title: Text('Name: ${data['name']}'),
                          subtitle: Text('Age: ${data['umur']}'),
                        );
                      }).toList(),
                    )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
