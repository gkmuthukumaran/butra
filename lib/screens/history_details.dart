import 'dart:async';
import 'package:fl_downloader/fl_downloader.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'config.dart';

class BookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final String accessToken;

  BookingDetailsScreen({required this.booking, required this.accessToken});

  @override
  _BookingDetailsScreenState createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  int progress = 0;
  late StreamSubscription progressStream;
  String pdfUrl = '';

  @override
  void initState() {
    super.initState();
    FlDownloader.initialize();
    progressStream = FlDownloader.progressStream.listen((event) {
      if (event.status == DownloadStatus.successful) {
        setState(() {
          progress = event.progress;
        });
        FlDownloader.openFile(filePath: event.filePath);
      } else if (event.status == DownloadStatus.running) {
        setState(() {
          progress = event.progress;
        });
      } else if (event.status == DownloadStatus.failed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed')),
        );
      }
    });
  }

  @override
  void dispose() {
    progressStream.cancel();
    super.dispose();
  }

  Future<bool> deleteBooking(int bookingId) async {
    try {
      final response = await http.put(
        Uri.parse('${APIConfig.baseUrl}/edit_booking/$bookingId'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': ""}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete booking: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting booking: $e');
      return false;
    }
  }

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    pdfUrl =
        'https://www.hmbweighbridge.com/static/pdf/order/order_${booking['id']}.pdf';
    // pdfUrl = 'http://13.214.131.66/static/pdf/booking_${booking['id']}.pdf';
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Details ...',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xFF004E2B),
        iconTheme: IconThemeData(
          color: Colors.white, // Change this to your desired color
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () async {
              var permission = await FlDownloader.requestPermission();
              if (permission == StoragePermissionStatus.granted) {
                await FlDownloader.download(pdfUrl);
              }
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.share, color: Colors.white),
          //   onPressed: () {
          //     print('Share Booking Details');
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.edit, color: Colors.white),
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => EditBookingScreen(
          //           bookingData: booking,
          //           accessToken: widget.accessToken,
          //         ),
          //       ),
          //     );
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.delete, color: Colors.white),
          //   onPressed: () async {
          //     bool isDeleted = await deleteBooking(booking['id']);
          //     if (isDeleted) {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('Booking deleted successfully')),
          //       );
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) =>
          //               BookingsScreen(accessToken: widget.accessToken),
          //         ),
          //       );
          //     } else {
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         const SnackBar(content: Text('Failed to delete booking')),
          //       );
          //     }
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Docket Number #${booking['docket_num']}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Image.network(
                    // 'http://192.168.1.2:5000/static/barcodes/booking_${booking['id']}.png',
                    'http://bwipjs-api.metafloor.com/?bcid=code128&text=${booking['QR_code']}&alttext=${booking['QR_code']}&scale=2',
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 50);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.blue),
              title: Text('Date: ${formatDate(booking['slot_date'])}'),
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.blue),
              title: Text('Time: ${booking['new_slot_time']}'),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.blue),
              title: Text('Product: ${booking['product_name'] ?? 'N/A'}'),
            ),
            ListTile(
              leading:
                  const Icon(Icons.format_list_bulleted, color: Colors.blue),
              title: Text('Product Type: ${booking['product_type'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: const Icon(Icons.delivery_dining, color: Colors.blue),
              title: Text(
                  'Delivery Location: ${booking['delivery_location'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: const Icon(Icons.production_quantity_limits,
                  color: Colors.blue),
              title: Text('Quantity: ${booking['quantity'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text('Driver: ${booking['driver_name'] ?? 'N/A'}'),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.blue),
              title: Text('Vehicle: ${booking['vehicle_num'] ?? 'N/A'}'),
            ),
            const Divider(),
            Text(
              booking['status'] != 'N/A'
                  ? 'Status: ${booking['status']}'
                  : 'Status: Unknown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: booking['status'] == 'completed' ||
                        booking['status'] == 'booked'
                    ? Colors.green
                    : booking['status'] == 'time mismatch'
                        ? Colors.orange
                        : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
