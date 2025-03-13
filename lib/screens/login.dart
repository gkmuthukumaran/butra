import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'forgotpassword.dart';
import 'welcome.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController =
      TextEditingController(text: '');
  final TextEditingController _passwordController =
      TextEditingController(text: '');
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Function to handle the login API call
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      var headers = {
        'Content-Type': 'application/json',
      };
      try {
        // Ensure the URL is correct and accessible
        var url = Uri.parse('${APIConfig.baseUrl}/client_login');
        print('Requesting URL: $url'); // Debugging: Log the URL

        var request = http.Request(
          'POST',
          url,
        );
        request.body = json.encode({
          "username": _usernameController.text,
          "password": _passwordController.text,
        });
        request.headers.addAll(headers);

        http.StreamedResponse response = await request.send();

        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          var data = json.decode(responseBody);
          String accessToken = data['access_token'];

          // Show success message and navigate to WelcomeScreen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login successful!',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF00843D), // Mid Green
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WelcomeScreen(accessToken: accessToken),
            ),
          );
        } else {
          var responseBody = await response.stream.bytesToString();
          var data = json.decode(responseBody);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login failed! ${data['message'] ?? 'Unknown error'}',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFF45D58), // Error Red
            ),
          );
        }
      } on SocketException catch (e) {
        // Handle connection issues
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Connection failed: ${e.message}. Please check your network.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFF45D58), // Error Red
          ),
        );
        print('SocketException: $e'); // Debugging: Print exception details
      } catch (e) {
        // Handle other exceptions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An unexpected error occurred: $e',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFF45D58), // Error Red
          ),
        );
        print('Error: $e'); // Debugging: Print error details
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
      resizeToAvoidBottomInset:
          true, // Allows screen adjustment when the keyboard appears
      body: Stack(
        children: [
          // Gradient Background
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade700,
                  Colors.green.shade500,
                  Colors.green.shade400,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    SizedBox(height: 90), // Space from top
                    // Logo
                    Image.asset(
                      'assets/images/HeidelbergMaterials.png',
                      height: 90.0,
                    ),
                    SizedBox(height: 50),
                    Text(
                      'Welcome to BUTRA !',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 50),
                    // Login Form Card
                    Card(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 8,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Username Field
                                  TextFormField(
                                    controller: _usernameController,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: TextStyle(
                                        fontFamily: 'Lexend',
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey[700],
                                      ),
                                      prefixIcon: Icon(Icons.email,
                                          color: Colors.green),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Color(0xFF00843D), width: 2),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email address';
                                      }
                                      // Regular expression for email validation
                                      final emailRegex =
                                          RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                      if (!emailRegex.hasMatch(value)) {
                                        return 'Please enter a valid email address';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(
                                        fontFamily: 'Lexend',
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey[700],
                                      ),
                                      prefixIcon:
                                          Icon(Icons.key, color: Colors.green),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                        horizontal: 16,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Color(0xFF00843D), width: 2),
                                      ),
                                    ),
                                    obscureText: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  // Login Button
                                  isLoading
                                      ? CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFF00843D),
                                          ),
                                        )
                                      : ElevatedButton(
                                          onPressed: _login,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 32,
                                            ),
                                            backgroundColor: Color(0xFF00843D),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            shadowColor: Color(0xFF004E2B),
                                            elevation: 4,
                                          ),
                                          child: Text(
                                            'Login',
                                            style: TextStyle(
                                              fontFamily: 'Lexend',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                  SizedBox(height: 10),
                                  // Forgot Password (Optional)
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                ForgotPasswordScreen()),
                                      );
                                    },
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF00843D),
                                        fontFamily: 'Lexend',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Notify Customer
                                  SizedBox(height: 10),
                                  Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                    color: Color.fromARGB(255, 224, 247, 202),
                                    child: Padding(
                                      padding: EdgeInsets.all(10),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.security,
                                            color: Color(0xFF00843D),
                                            size: 18,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Please keep your login password secure. HMB will not be responsible for any unauthorized access or misuse.',
                                              style: TextStyle(
                                                fontFamily: 'Lexend',
                                                fontSize: 8,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
