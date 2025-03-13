import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'session_manager.dart';
import 'dart:convert';

import 'booking.dart';
import 'booking_details.dart';

class EditBookingScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String accessToken;

  EditBookingScreen({required this.bookingData, required this.accessToken});

  @override
  _EditBookingScreenState createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController driverNameController = TextEditingController();
  final TextEditingController vehicleNumberController = TextEditingController();
  final TextEditingController slotDateController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController deliveryLocationController =
      TextEditingController();
  final TextEditingController remarksController =
      TextEditingController();

  // String? selectedClient;
  String? selectedProduct;
  String? selectedProductType;
  String? selectedProductName; // Bulk ~ for getting the name of product type
  int? selectedTimeSlot;
  String? selectedTime;
  int? bookingId;
  bool isLoading = false;

  // final List<String> clients = ["Client A", "Client B", "Client C"];
  DateTime selectedDate = DateTime.now();
  DateTime selectTime = DateTime.now();
  List<DateTime> allowedDates = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> productTypes = [];
  List<String> bookings = [];
  List<String> timeSlots = [];
  String timeSlotsMsg = 'Pick Date for Time Slot';
  // List<String> formattedSlots = [];
  int start = 0;
  int end = 10;
  @override
  void initState() {
    super.initState();
    fetchProductName();
    fetchAllowedDates();

    // Initialize the controllers with the existing booking data
    bookingId = widget.bookingData['id'];
    driverNameController.text = widget.bookingData['driver_name'];
    vehicleNumberController.text = widget.bookingData['vehicle_num'];
    // slotDateController.text = widget.bookingData['slot_date'];

    if (widget.bookingData['slot_date'] != null) {
      DateTime slotDate = DateTime.parse(widget.bookingData['slot_date']);
      slotDateController.text = DateFormat('dd-MM-yyyy').format(slotDate);
      print('slotDateController.text: $slotDateController.text');
      fetchTimeSlots(widget.bookingData['slot_date']);
    }

    selectedDate = DateFormat('dd-MM-yyyy').parse(slotDateController.text);
    print('selectedDate: $selectedDate');
    selectedTime = widget.bookingData['new_slot_time'];
    print('selectedTime: $selectedTime');
    selectedProduct = widget.bookingData['products_id'].toString();
    fetchProductType(selectedProduct!);
    selectedProductType = widget.bookingData['product_typeid'].toString();
    quantityController.text = widget.bookingData['quantity'].toString();
    print(widget.bookingData['quantity'].runtimeType);
    deliveryLocationController.text = widget.bookingData['delivery_location'];
    remarksController.text = widget.bookingData['remarks'];
  }

  // Fetch data for parent dropdown
  Future<void> fetchProductName() async {
    setState(() => isLoading = true);
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${widget.accessToken}', // Assuming accessToken is passed to this widget
      };

      var url = Uri.parse('${APIConfig.baseUrl}/get_products');
      var body = json.encode({"start": 0, "draw": 1});

      var response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        var decodedData = json.decode(response.body);
        setState(() {
          products = (decodedData['data'] as List).map((item) {
            return {
              "id": item['id'],
              "name": item['productname']
            }; // Ensure the key matches your API response
          }).toList();
        });
      } else if (response.statusCode == 402 || response.statusCode == 401) {
        handleSessionExpiration(context, response.statusCode);
      } else {
        print('Failed to load parent items: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching parent items: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Fetch data for product type dropdown
  Future<void> fetchProductType(String prodId) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${widget.accessToken}', // Assuming accessToken is passed to this widget
      };

      var url = Uri.parse('${APIConfig.baseUrl}/get_products/$prodId');
      var body = json.encode({"start": 0, "draw": 1});

      var response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        var decodedData = json.decode(response.body);
        setState(() {
          productTypes = (decodedData['data'] as List).map((item) {
            return {
              "id": item['id'],
              "name": item['product_type']
            }; // Ensure the key matches your API response
          }).toList();
        });
      } else {
        print('Failed to load parent items: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error fetching parent items: $e');
    }
  }

  Future<void> fetchAllowedDates() async {
    try {
      var response = await http.post(
        Uri.parse('${APIConfig.baseUrl}/get_schedule'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "slot_date": "",
          "start": 0,
          "draw": 1,
        }),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        // print(data);
        setState(() {
          allowedDates = (data['data'] as List).map((slot) {
            return DateTime.parse(slot['slot_date']);
          }).toList();
          // print(allowedDates);
        });
      } else {
        print("Failed to fetch allowed dates: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching allowed dates: $e");
    }
  }

  // Fetch available time slots for a given date
  Future<void> fetchTimeSlots(String date) async {
    try {
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      };
      var request = http.Request(
        'POST',
        Uri.parse('${APIConfig.baseUrl}/get_schedule'),
      );
      request.body = json.encode({"slot_date": date, "start": 0, "draw": 1});
      request.headers.addAll(headers);

      http.StreamedResponse response = await request.send();
      // print(response.statusCode);
      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var decodedData = json.decode(responseBody);
        print(decodedData['data']['new_slot_time']);
        print(decodedData['data']['new_bookings']);
        setState(() {
          bookings = List<String>.from(decodedData['data']['new_bookings']);
          timeSlots = List<String>.from(decodedData['data']['new_slot_time']);
          // formattedSlots = parseTimeSlotsToDates(timeSlots);
        });
      } else {
        print('Failed to fetch time slots: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching time slots: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // Print the allowed dates (for debugging)
    // print(allowedDates);

    // Set the initial date to a valid date, if the initialDate is invalid.
    DateTime currentDate = DateTime.now();
    DateTime initialDate = DateTime.parse(widget.bookingData['slot_date']);
    // Ensure the initial date is valid (not a weekend and part of allowedDates)
    while (!isDateSelectable(initialDate)) {
      // If the current date is invalid, move to the next day.
      initialDate = initialDate.add(Duration(days: 1));
    }

    try {
      final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: initialDate, // Use the adjusted initial date
            firstDate: DateTime.now(),
            lastDate: DateTime(currentDate.year + 1),
            selectableDayPredicate: (DateTime date) {
              // Disable weekends
              // if (date.weekday == DateTime.saturday ||
              //     date.weekday == DateTime.sunday) {
              //   return false;
              // }

              // Allow only certain dates from the allowed list
              return allowedDates.any((allowedDate) =>
                  allowedDate.year == date.year &&
                  allowedDate.month == date.month &&
                  allowedDate.day == date.day);
            },
          ) ??
          selectedDate;

      if (pickedDate != null) {
        setState(() {
          slotDateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
          print(DateFormat('dd-MM-yyyy').format(pickedDate));
        });

        // Fetch time slots for the selected date
        String formattedDate = DateFormat('yyyy-MM-dd')
            .format(pickedDate); // Adjust to match the API's expected format
        await fetchTimeSlots(formattedDate);
      }
    } catch (e) {
      print("Error selecting date: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred while selecting a date")),
      );
    }
  }

// Helper method to check if a date is selectable
  bool isDateSelectable(DateTime date) {
    // Disable weekends
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return false;
    }

    // Allow only dates in the allowedDates list
    return allowedDates.any((allowedDate) =>
        allowedDate.year == date.year &&
        allowedDate.month == date.month &&
        allowedDate.day == date.day);
  }

  Future<void> _submitForm() async {
    setState(() => isLoading = true);
    if (_formKey.currentState!.validate()) {
      // Prepare data
      String slotDate = slotDateController.text;
      print('slotDate: $slotDate');
      DateTime parsedDate = DateFormat('dd-MM-yyyy').parse(slotDate);
      print('parsedDate: $parsedDate');
      String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

      final formData = {
        // "client_id": "client1",
        "driver_name": driverNameController.text,
        "vehicle_num": vehicleNumberController.text,
        "slot_date": formattedDate,
        "slot_time": selectedTime,
        "products_id": selectedProduct,
        "product_typeid": selectedProductType,
        // "quantity": int.parse(quantityController.text),
        // "quantity": quantityController.text.isNotEmpty ? quantityController.text : '',
        "delivery_location": deliveryLocationController.text,
        "remarks": remarksController.text,
      };
      if (quantityController.text != 'N/A') {
        formData["quantity"] = quantityController.text;
      }
      print(formData);
      try {
        final response = await http.put(
          Uri.parse('${APIConfig.baseUrl}/edit_booking/$bookingId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer ${widget.accessToken}', // Replace with actual token
          },
          body: json.encode(formData),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking updated successfully!')),
          );

          // Reset the form and mark the slot as booked
          // setState(() {
          //   bookings[selectedBookingIndex] = '1'; // Mark the selected slot as booked
          //   selectedBookingIndex = -1;
          //   selectedTimeSlot = null;
          // });

          // Navigate to Bookings Page after booking
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => BookingsScreen(
                    accessToken:
                        '${widget.accessToken}')), // Replace 'BookingsPage' with your bookings page widget
          );
        } else if (response.statusCode == 402 || response.statusCode == 401) {
          handleSessionExpiration(context, response.statusCode);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to edit booking: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Booking',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Driver Name Input Field
              TextFormField(
                controller: driverNameController,
                decoration: InputDecoration(labelText: 'Driver Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter driver name' : null,
              ),
              SizedBox(height: 20),

              // Vehicle Number Input Field
              TextFormField(
                controller: vehicleNumberController,
                decoration: InputDecoration(labelText: 'Vehicle Number'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter vehicle number' : null,
              ),
              SizedBox(height: 20),

              // Slot Date Picker (Read-Only)
              TextFormField(
                controller: slotDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Slot Date',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () =>
                        _selectDate(context), // Date picker logic here
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please select a date' : null,
              ),
              SizedBox(height: 20),

              // Time Slot Grid Section
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      _getGridColumnCount(context), // 3 slots in a row
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio:
                      2.5, // Adjust the height-to-width ratio of tiles
                ),
                itemCount: timeSlots.length,
                itemBuilder: (context, index) {
                  // Determine if the slot is available
                  bool isAvailable = bookings[index].startsWith("0");
                  bool isSelected = selectedTimeSlot == index;

                  return GestureDetector(
                    onTap: () {
                      if (isAvailable) {
                        setState(() {
                          selectedTimeSlot =
                              index; // Set the selected time slot index
                          selectedTime = "${timeSlots[index]}";
                        });
                        print("Slot Selected: ${timeSlots[index]}");
                      } else {
                        print("Slot is booked: ${timeSlots[index]}");
                      }
                    },
                    child: Card(
                      color: isAvailable
                          ? (isSelected
                              ? const Color.fromARGB(198, 84, 140, 238)
                              : const Color.fromARGB(210, 132, 202, 139))
                          : const Color.fromARGB(
                              6, 159, 35, 4), // Red for booked slots
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.0, // Border width for selected slot
                        ),
                      ),
                      child: Center(
                        child: Text(
                          timeSlots[index],
                          style: TextStyle(
                            color: isAvailable
                                ? (isSelected ? Colors.white : Colors.black)
                                : Colors.white, // White text for booked slots
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 20),
              // Product Name Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Product Name'),
                value: selectedProduct,
                items: products.map((item) {
                  return DropdownMenuItem(
                    value: item['id'].toString(),
                    child: Text(item['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedProduct = value;
                    selectedProductType = null; // Reset child dropdown
                    productTypes = []; // Clear previous child items
                  });
                  fetchProductType(value!); // Fetch new child items
                },
                validator: (value) =>
                    value == null ? 'Please select a product' : null,
              ),
              SizedBox(height: 20),
              // Product Type Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Product Type'),
                value: selectedProductType,
                items: productTypes
                    .map((item) => DropdownMenuItem(
                          value: item['id'].toString(),
                          child: Text(item['name']),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedProductType = value;
                  });
                  // Find the name of the selected product type using the 'id'
                  selectedProductName = productTypes.firstWhere(
                    (item) => item['id'].toString() == selectedProductType,
                    orElse: () => {'id': '', 'name': ''},
                  )['name'];
                  print("selected ProductType:: $selectedProductName ");
                },
                validator: (value) =>
                    value == null ? 'Please select a product type' : null,
              ),
              SizedBox(height: 20),
              // Quantity Input Field
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(labelText: 'Quantity'),
                enabled: selectedProductName != 'Bulk',
                validator: (value) =>
                    value!.isEmpty && selectedProductName != 'Bulk'
                        ? 'Please enter quantity'
                        : null,
              ),
              SizedBox(height: 20),
              // Delivery Location Input Field
              TextFormField(
                controller: deliveryLocationController,
                decoration: InputDecoration(labelText: 'Delivery Location'),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter delivery location' : null,
              ),
              SizedBox(height: 20),
              // Delivery Location Input Field
              TextFormField(
                controller: remarksController,
                decoration: InputDecoration(labelText: 'Remarks'),
                maxLines: 3,
                // validator: (value) =>
                //     value!.isEmpty ? 'Please enter delivery location' : null,
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : _submitForm, // Disable button while loading
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                  backgroundColor: isLoading
                      ? Colors.grey // Greyed-out color when disabled
                      : Color(0xFF00843D), // Main theme color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: isLoading ? 0 : 4, // No elevation while disabled
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Processing...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Adjust column count dynamically based on screen size
  int _getGridColumnCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 4; // 2 columns for smaller screens
    } else if (width < 900) {
      return 5; // 3 columns for medium screens
    } else {
      return 6; // 4 columns for larger screens
    }
  }
}
