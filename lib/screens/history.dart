import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'login.dart';
import 'session_manager.dart';
import 'history_details.dart';
import 'dart:convert';

class BookingsHistoryScreen extends StatefulWidget {
  final String accessToken;

  const BookingsHistoryScreen({Key? key, required this.accessToken})
      : super(key: key);

  @override
  _BookingsHistoryScreenState createState() => _BookingsHistoryScreenState();
}

class _BookingsHistoryScreenState extends State<BookingsHistoryScreen> {
  List bookings = [];
  int start = 0;
  int end = 10; // Number of items per page
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    fetchBookingsHistory();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !isLoading &&
        hasMore) {
      fetchBookingsHistory(); // Fetch more data when scrolled to the bottom
    }
  }

  /// Fetch booking history from the API
  Future<void> fetchBookingsHistory() async {
    if (isLoading || !hasMore)
      return; // Prevent new request if already loading or no more data

    setState(() => isLoading = true); // Set loading state to true

    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      };

      var request = http.Request(
        'POST',
        Uri.parse('${APIConfig.baseUrl}/get_bookings'),
      );
      request.body =
          json.encode({"start": start, "end": end, "status": "others"});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedData = json.decode(responseBody);

        // Check if the response contains 'history'
        if (decodedData is Map<String, dynamic> &&
            decodedData.containsKey('history')) {
          setState(() {
            final newBookings = decodedData['history'] as List;
            if (newBookings.isNotEmpty) {
              bookings.addAll(newBookings);
              start += end;
            } else {
              hasMore = false; // Stop loading if no more bookings
            }
          });
        } else {
          throw FormatException("Unexpected data format.");
        }
      }else if (response.statusCode == 402 || response.statusCode == 401) {
          handleSessionExpiration(context, response.statusCode);
        }  else {
        // Handle error from API response
        var errorMessage = '';
        try {
          var responseBody = await response.stream.bytesToString();
          var errorData = json.decode(responseBody);
          errorMessage = errorData['message'] ?? 'Unexpected error occurred';
        } catch (e) {
          errorMessage = 'Failed to parse error response';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(' $errorMessage ' ),
              backgroundColor: Colors.red,
            ),
            );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false); // Reset loading state
    }
  }

  /// Handle API errors based on the status code
  // void handleError(int statusCode) {
  //   final message = statusCode == 401
  //       ? 'Unauthorized access: Please check your credentials.'
  //       : 'Server error: $statusCode';
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(content: Text(message)),
  //   );
  //     // Delay navigation until after the SnackBar is shown
  //   if (statusCode == 401) {
  //     Future.delayed(const Duration(seconds: 2), () {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (context) => LoginScreen()),
  //       ); // Replace with your login route
  //     });
  //   }
  // }

  /// Get color for the booking status
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'time mismatch':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'History',
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
          ? Center(child: Text('No bookings history found.'))
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
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 8,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              color: getStatusColor(booking['status'])),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '#${booking['id']} - ${booking['product_name']} (${booking['product_type']})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
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
                                color: getStatusColor(booking['status']),
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
                      onTap: () {
                        // Navigate to booking details screen
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {},
      //   backgroundColor: Color(0xFF00843D),
      //   foregroundColor: Colors.white, //
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
