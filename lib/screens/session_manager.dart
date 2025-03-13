// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'login_screen.dart'; // Replace with the path to your LoginScreen

// class SessionManager {
//   static Future<void> handleSessionExpiration(
//       BuildContext context, int statusCode) async {
//     if (statusCode == 401) { // Assuming 401 indicates session expiration
//       // Clear stored user data
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();

//       // Show a message to the user
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Session expired. Please log in again.')),
//       );

//       // Navigate to the login screen and clear navigation stack
//       Navigator.pushAndRemoveUntil(
//         context,
//         MaterialPageRoute(builder: (context) => LoginScreen()),
//         (route) => false, // Removes all previous routes
//       );
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'login.dart';

void handleSessionExpiration(BuildContext context, int statusCode) {
  if (statusCode == 402 || statusCode == 401) { // Assuming 401 indicates session expiration
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Session expired. Please log in again.'), backgroundColor: Colors.red,),
    );

    // Clear any stored session data (like tokens)
    // Example: SharedPreferences.clear();

    // Redirect to the login screen
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false, // Remove all routes from the stack
        ); // Replace with your login route
      });
  }
}
