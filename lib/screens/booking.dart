import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'session_manager.dart';
import 'config.dart';
import 'dart:convert';
import 'creatbooking.dart';
import 'booking_details.dart';

class BookingsScreen extends StatefulWidget {
  final String accessToken;

  const BookingsScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List bookings = [];
  int start = 0;
  int end = 10; // number of items per page
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchBookings();
    isLoading = false;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Check if user has scrolled to the end of the list
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isLoading &&
        hasMore) {
      fetchBookings();
    }
  }

  Future<void> fetchBookings() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      };

      var request =
          http.Request('POST', Uri.parse('${APIConfig.baseUrl}/get_bookings'));
      request.body =
          json.encode({"start": start, "end": end, "status": "booked"});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      // Check for session expiration
      // handleSessionExpiration(context, response.statusCode);

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedData = json.decode(responseBody);

        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('booked')) {
          setState(() {
            final newBookings = decodedData['booked'] as List;
            if (newBookings.isNotEmpty) {
              bookings.addAll(newBookings);
              start += end; // Update start for the next batch
            } else {
              hasMore = false; // No more data to load
            }
          });
        }else {
          throw FormatException("Unexpected data format.");
        }
      } else if (response.statusCode == 402 || response.statusCode == 401) {
          handleSessionExpiration(context, response.statusCode);
        }  else {
        // Handle non-200 status codes
        var errorMessage = '';
        try {
          var responseBody = await response.stream.bytesToString();
          var errorData = json.decode(responseBody);
          errorMessage = errorData['message'] ?? 'Unexpected error occurred';
        } catch (e) {
          errorMessage = 'Failed to parse error response';
        }

        // Display the error in a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$errorMessage, e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  // void handleError(int statusCode) {
  //   final message = statusCode == 401
  //       ? 'Unauthorized access: Please check your credentials.'
  //       : 'Server error: $statusCode';
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(message)),
  //   );
  //   // Delay navigation until after the SnackBar is shown
  //   if (statusCode == 401) {
  //     Future.delayed(const Duration(seconds: 2), () {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => LoginScreen()),
  //       ); // Replace with your login route
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bookings',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0xFF004E2B), // Deep Green
        iconTheme: IconThemeData(
          color: Colors.white, // Change this to your desired color
        ),
      ),
      body: bookings.isEmpty && !isLoading
          ? Center(child: Text('No bookings found.'))
          : ListView.builder(
              controller: _scrollController,
              itemCount: bookings.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == bookings.length) {
                  return Center(child: CircularProgressIndicator());
                }

                final booking = bookings[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          15), // Rounded corners for a more modern look
                    ),
                    elevation: 8, // Subtle shadow effect
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '#${booking['id']} - ${booking['product_name']} (${booking['product_type']})',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow
                                  .ellipsis, // Ensure text doesn't overflow
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${booking['status']}',
                              style: TextStyle(
                                color: booking['status'] == 'booked' ||
                                        booking['status'] == 'completed'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text('Date: ${booking['slot_date'] ?? 'N/A'}'),
                            SizedBox(height: 5),
                            Text('Time: ${booking['new_slot_time'] ?? 'N/A'}'),
                          ],
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailsScreen(
                              booking: booking,
                              accessToken: widget.accessToken,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateBookingScreen(
                accessToken: widget.accessToken,
              ),
            ),
          );
          if (result == true) {
            fetchBookings(); // Refresh the list after booking creation
          }
        },
        backgroundColor: Color(0xFF00843D), // Mid Green
        foregroundColor: Colors.white, //
        child: const Icon(Icons.add),
      ),
    );
  }
}
