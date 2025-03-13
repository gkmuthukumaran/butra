import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/welcome.dart';
import 'screens/booking.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login App',
      theme: ThemeData(
          appBarTheme: const AppBarTheme(
        shadowColor: Colors.transparent,
        elevation: 0.0,
        centerTitle: true,
        color: Colors.green,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
          fontWeight: FontWeight.normal,
        ),
      )),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/welcome': (context) => WelcomeScreen(accessToken: 'dummy_token'),
        // '/booking': (context) => BookingsScreen(accessToken: 'accessToken'),
      },
    );
  }
}
