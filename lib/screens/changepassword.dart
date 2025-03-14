import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'session_manager.dart';
import 'config.dart';
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  final String accessToken;

  ChangePasswordScreen({required this.accessToken});

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isLoading = false;

  Future<void> _submitChangePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        var headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        };

        var request = http.Request(
          'POST',
          Uri.parse('${APIConfig.baseUrl}/change_password'),
        );

        request.body = json.encode({
          "old_password": _oldPasswordController.text,
          "new_password": _newPasswordController.text,
        });

        request.headers.addAll(headers);

        http.StreamedResponse response = await request.send();

        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          // var data = json.decode(responseBody);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password changed successfully')),
          );

          Navigator.pop(context); // Navigate back to the previous screen
        }else if (response.statusCode == 402 || response.statusCode == 401) {
          handleSessionExpiration(context, response.statusCode);
        }  else {
          var errorBody = await response.stream.bytesToString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.reasonPhrase}. $errorBody')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send request: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
        backgroundColor: Color(0xFF004E2B),
          iconTheme: IconThemeData(
          color: Colors.white, // Change this to your desired color
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Old Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your old password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm New Password'),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submitChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00843D),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text('Change Password',
                    style: TextStyle(
                      fontSize: 16,
                          fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
