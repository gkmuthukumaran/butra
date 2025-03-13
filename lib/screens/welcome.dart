import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'session_manager.dart';
import 'config.dart';
import 'dart:convert';
import 'login.dart';
import 'booking.dart';
import 'history.dart';
import 'changepassword.dart';

class WelcomeScreen extends StatefulWidget {
  final String accessToken;

  WelcomeScreen({required this.accessToken});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int totalBookings = 0;
  int completedBookings = 0;
  int upcomingBookings = 0;
  int cancelledBookings = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookingData();
  }

  Future<void> fetchBookingData() async {
    try {
      final response = await http.post(
        Uri.parse('${APIConfig.baseUrl}/get_bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
        },
        body: json.encode(
            {"start": 0, "end": 10, "status": ''}), // Add your API parameters
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for session expiration
        handleSessionExpiration(context, response.statusCode);

        // Assuming the response contains counts for total, completed, and upcoming bookings
        setState(() {
          totalBookings = data['totalbookings'] ?? 0;
          completedBookings = data['pastbookings'] ?? 0;
          upcomingBookings = data['upcomingbookings'] ?? 0;
          cancelledBookings = data['cancelled'] ?? 0;
          isLoading = false;
        });
      }else if (response.statusCode == 402 || response.statusCode == 401) {
          handleSessionExpiration(context, response.statusCode);
        }  else {
        // Handle errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load booking data')),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF004E2B), // Deep Green
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        elevation: 4,
      ),
      drawer: _buildDrawer(context),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // Welcome Text
                    Text(
                      'Welcome to the BUTRA Booking App!',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Color(0xFF004E2B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    // Booking Tiles Section
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        children: [
                          _buildTile(
                            icon: Icons.calendar_today,
                            title: "Total Bookings",
                            count: totalBookings,
                            color: Colors.green,
                          ),
                          _buildTile(
                            icon: Icons.check_circle,
                            title: "Completed",
                            count: completedBookings,
                            color: Colors.blue,
                          ),
                          _buildTile(
                            icon: Icons.access_time,
                            title: "Upcoming",
                            count: upcomingBookings,
                            color: Colors.orange,
                          ),
                          _buildTile(
                            icon: Icons.cancel_outlined,
                            title: "Cancelled",
                            count: cancelledBookings,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004E2B), Color(0xFF00843D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.transparent),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'BUTRA Client',
                    style: TextStyle(
                      fontFamily: 'lexend',
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerTile(
              context,
              icon: Icons.book,
              title: 'Booking(s)',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookingsScreen(accessToken: widget.accessToken),
                ),
              ),
            ),
            _buildDrawerTile(
              context,
              icon: Icons.history,
              title: 'History',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BookingsHistoryScreen(accessToken: widget.accessToken),
                ),
              ),
            ),
            _buildDrawerTile(
              context,
              icon: Icons.password,
              title: 'Change Password',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChangePasswordScreen(accessToken: widget.accessToken),
                ),
              ),
            ),
            _buildDrawerTile(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildDrawerTile(BuildContext context,
      {required IconData icon,
      required String title,
      required Function() onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'lexend',
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }
}
