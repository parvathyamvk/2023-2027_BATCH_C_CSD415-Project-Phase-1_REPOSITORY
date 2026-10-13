import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class DonationFormScreen extends StatefulWidget {
  const DonationFormScreen({super.key});

  @override
  State<DonationFormScreen> createState() => _DonationFormScreenState();
}

class _DonationFormScreenState extends State<DonationFormScreen> {
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  String selectedFoodType = 'Cooked Food';
  String selectedQuantityUnit = 'Meals';

  DateTime? selectedPickupDate;
  TimeOfDay? selectedPickupTime;

  DateTime? selectedExpiryDate;
  TimeOfDay? selectedExpiryTime;

  double? pickupLatitude;
  double? pickupLongitude;

  bool isGettingLocation = false;
  bool isSubmitting = false;

  Uint8List? foodImageBytes;

  @override
  void dispose() {
    foodNameController.dispose();
    quantityController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  // ==========================================================
  // PICK FOOD IMAGE
  // ==========================================================

  Future<void> pickFoodImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 65,
      );

      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      // Keep the Firestore document safely below the 1 MiB limit.
      if (bytes.length > 700000) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This photo is still too large. Please choose another photo.',
            ),
          ),
        );
        return;
      }

      setState(() {
        foodImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not select the food photo.'),
        ),
      );
    }
  }

  // ==========================================================
  // PHOTO OPTIONS
  // ==========================================================

  Future<void> showPhotoOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add Food Photo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.camera_alt),
                  ),
                  title: const Text('Take a Photo'),
                  subtitle: const Text('Use your camera'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    pickFoodImage(ImageSource.camera);
                  },
                ),

                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.photo_library),
                  ),
                  title: const Text('Choose from Gallery'),
                  subtitle: const Text('Select an existing photo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    pickFoodImage(ImageSource.gallery);
                  },
                ),

                if (foodImageBytes != null)
                  ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.delete_outline),
                    ),
                    title: const Text('Remove Photo'),
                    onTap: () {
                      Navigator.pop(sheetContext);

                      setState(() {
                        foodImageBytes = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // PICKUP DATE
  // ==========================================================

  Future<void> selectPickupDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 30),
      ),
    );

    if (picked != null) {
      setState(() {
        selectedPickupDate = picked;

        // Reset expiry if it becomes invalid.
        if (selectedExpiryDate != null &&
            selectedExpiryDate!.isBefore(picked)) {
          selectedExpiryDate = null;
        }
      });
    }
  }

  // ==========================================================
  // PICKUP TIME
  // ==========================================================

  Future<void> selectPickupTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedPickupTime = picked;
      });
    }
  }

  // ==========================================================
  // EXPIRY DATE
  // ==========================================================

  Future<void> selectExpiryDate() async {
    final DateTime minimumDate =
        selectedPickupDate ?? DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedExpiryDate ?? minimumDate,
      firstDate: minimumDate,
      lastDate: DateTime.now().add(
        const Duration(days: 30),
      ),
    );

    if (picked != null) {
      setState(() {
        selectedExpiryDate = picked;
      });
    }
  }

  // ==========================================================
  // EXPIRY TIME
  // ==========================================================

  Future<void> selectExpiryTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedExpiryTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        selectedExpiryTime = picked;
      });
    }
  }

  // ==========================================================
  // GET CURRENT LOCATION
  // ==========================================================

  Future<void> getCurrentLocation() async {
    if (isGettingLocation) return;

    setState(() {
      isGettingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please turn on Location/GPS and try again.',
            ),
          ),
        );

        await Geolocator.openLocationSettings();
        return;
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is required.',
            ),
          ),
        );

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please allow location permission in app settings.',
            ),
          ),
        );

        await Geolocator.openAppSettings();
        return;
      }

      Position? position =
          await Geolocator.getLastKnownPosition();

      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;

      setState(() {
        pickupLatitude = position!.latitude;
        pickupLongitude = position.longitude;

        locationController.text =
            'Current location selected '
            '(${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)})';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pickup location selected successfully!',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not get your location. '
            'Please try again or check the emulator GPS.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  // ==========================================================
  // SAVE DONATION
  // ==========================================================

  Future<void> submitDonation() async {
    if (isSubmitting) return;

    // ------------------------------
    // VALIDATION
    // ------------------------------

    if (foodNameController.text.trim().isEmpty ||
        quantityController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty ||
        selectedPickupDate == null ||
        selectedPickupTime == null ||
        selectedExpiryDate == null ||
        selectedExpiryTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields and enter a pickup location.',
          ),
        ),
      );

      return;
    }

    final int? quantity =
        int.tryParse(quantityController.text.trim());

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid quantity greater than 0.',
          ),
        ),
      );

      return;
    }

    final pickupDateTime = DateTime(
      selectedPickupDate!.year,
      selectedPickupDate!.month,
      selectedPickupDate!.day,
      selectedPickupTime!.hour,
      selectedPickupTime!.minute,
    );

    final expiryDateTime = DateTime(
      selectedExpiryDate!.year,
      selectedExpiryDate!.month,
      selectedExpiryDate!.day,
      selectedExpiryTime!.hour,
      selectedExpiryTime!.minute,
    );

    if (!expiryDateTime.isAfter(pickupDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Expiry date and time must be after '
            'the pickup date and time.',
          ),
        ),
      );

      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please login before submitting a donation.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // ======================================================
      // IMAGE → BASE64
      // ======================================================

      String? foodImageBase64;

      if (foodImageBytes != null) {
        foodImageBase64 =
            base64Encode(foodImageBytes!);
      }

      // ======================================================
      // CREATE FIRESTORE DOCUMENT
      // ======================================================

      final donationRef = FirebaseFirestore.instance
          .collection('donations')
          .doc();

      final pickupDateText =
          '${selectedPickupDate!.day}/'
          '${selectedPickupDate!.month}/'
          '${selectedPickupDate!.year}';

      final pickupTimeText =
          selectedPickupTime!.format(context);

      final expiryDateText =
          '${selectedExpiryDate!.day}/'
          '${selectedExpiryDate!.month}/'
          '${selectedExpiryDate!.year}';

      final expiryTimeText =
          selectedExpiryTime!.format(context);

      await donationRef.set({
        'donorId': user.uid,

        'foodName':
            foodNameController.text.trim(),

        'foodType':
            selectedFoodType,

        'quantity':
            quantity,

        'unit':
            selectedQuantityUnit,

        'pickupAddress':
            locationController.text.trim(),

        'pickupLocation':
            locationController.text.trim(),

        'pickupLatitude':
            pickupLatitude,

        'pickupLongitude':
            pickupLongitude,

        'pickupDate':
            pickupDateText,

        'pickupTime':
            pickupTimeText,

        'expiryDate':
            expiryDateText,

        'expiryTime':
            expiryTimeText,

        'description':
            descriptionController.text.trim(),

        'allocatedQuantity':
            0,

        'remainingQuantity':
            quantity,

        'status':
            'Pending',

        'createdAt':
            FieldValue.serverTimestamp(),

        'acceptedBy':
            null,

        'volunteerId':
            null,

        'deliveredAt':
            null,

        // ====================================================
        // FOOD PHOTO
        // ====================================================

        'foodImage':
            foodImageBase64,

        'hasFoodImage':
            foodImageBase64 != null,
      });

      // ======================================================
      // KEEP EXISTING LOCAL DATA
      // ======================================================

      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        'donation_id',
        donationRef.id,
      );

      await prefs.setString(
        'donation_food',
        foodNameController.text.trim(),
      );

      await prefs.setString(
        'donation_type',
        selectedFoodType,
      );

      await prefs.setString(
        'donation_quantity',
        quantity.toString(),
      );

      await prefs.setString(
        'donation_unit',
        selectedQuantityUnit,
      );

      await prefs.setString(
        'donation_location',
        locationController.text.trim(),
      );

      await prefs.setString(
        'donation_date',
        pickupDateText,
      );

      await prefs.setString(
        'donation_time',
        pickupTimeText,
      );

      await prefs.setString(
        'donation_expiry_date',
        expiryDateText,
      );

      await prefs.setString(
        'donation_expiry_time',
        expiryTimeText,
      );

      await prefs.setString(
        'donation_description',
        descriptionController.text.trim(),
      );

      await prefs.setString(
        'donation_status',
        'Pending',
      );

      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      // ======================================================
      // SUCCESS DIALOG
      // ======================================================

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(20),
            ),

            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Color(0xFFE85D4A),
                  size: 30,
                ),

                SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Donation Submitted',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            content: Text(
              foodImageBytes != null
                  ? 'Your food donation and photo '
                      'have been saved successfully.'
                  : 'Your food donation has been '
                      'saved successfully.',
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },

                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Color(0xFFE85D4A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save donation: '
            '${e.message ?? 'Please try again.'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while saving the donation.',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // REUSABLE DATE/TIME BOX
  // ==========================================================

  Widget dateTimeBox({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon),

            const SizedBox(width: 12),

            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isSelected
                    ? const Color(0xFF222222)
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // TEXT FIELD
  // ==========================================================

  InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ==========================================================
  // FOOD PHOTO SECTION
  // ==========================================================

  Widget foodPhotoSection() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Food Photo',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        GestureDetector(
          onTap: showPhotoOptions,
          child: Container(
            width: double.infinity,
            height: 210,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE6E6E6),
              ),
            ),
            child: foodImageBytes == null
                ? Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF3ECFF,
                          ),
                          borderRadius:
                              BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons
                              .add_a_photo_outlined,
                          size: 32,
                          color:
                              Color(0xFF8F57D9),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Add a photo of the food',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'Tap to take a photo or choose from gallery',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius:
                        BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          foodImageBytes!,
                          fit: BoxFit.cover,
                        ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: Row(
                            children: [
                              _photoActionButton(
                                icon:
                                    Icons.edit,
                                onTap:
                                    showPhotoOptions,
                              ),

                              const SizedBox(
                                width: 8,
                              ),

                              _photoActionButton(
                                icon:
                                    Icons.delete_outline,
                                onTap: () {
                                  setState(() {
                                    foodImageBytes =
                                        null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),

        if (foodImageBytes != null) ...[
          const SizedBox(height: 7),

          const Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Color(0xFFE85D4A),
              ),

              SizedBox(width: 5),

              Text(
                'Food photo added',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _photoActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(30),
      elevation: 3,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF222222),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'New Donation',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Share Food',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Provide some details about the food you want to donate.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // FOOD NAME
            // ==================================================

            const Text(
              'Food Name *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  foodNameController,
              decoration:
                  fieldDecoration(
                hint:
                    'Eg. Vegetable Rice',
                icon:
                    Icons.fastfood_outlined,
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // FOOD PHOTO
            // ==================================================

            foodPhotoSection(),

            const SizedBox(height: 18),

            // ==================================================
            // FOOD TYPE
            // ==================================================

            const Text(
              'Food Type',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child:
                  DropdownButtonHideUnderline(
                child:
                    DropdownButton<String>(
                  value:
                      selectedFoodType,
                  isExpanded: true,

                  items: const [
                    DropdownMenuItem(
                      value:
                          'Cooked Food',
                      child:
                          Text('Cooked Food'),
                    ),
                    DropdownMenuItem(
                      value:
                          'Packed Food',
                      child:
                          Text('Packed Food'),
                    ),
                    DropdownMenuItem(
                      value:
                          'Fruits & Vegetables',
                      child:
                          Text(
                            'Fruits & Vegetables',
                          ),
                    ),
                    DropdownMenuItem(
                      value:
                          'Groceries',
                      child:
                          Text('Groceries'),
                    ),
                  ],

                  onChanged:
                      (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedFoodType =
                          value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // QUANTITY
            // ==================================================

            const Text(
              'Quantity *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  quantityController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  fieldDecoration(
                hint: 'Eg. 400',
                icon:
                    Icons.people_outline,
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // QUANTITY UNIT
            // ==================================================

            const Text(
              'Quantity Unit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
              ),

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(14),
              ),

              child:
                  DropdownButtonHideUnderline(
                child:
                    DropdownButton<String>(
                  value:
                      selectedQuantityUnit,
                  isExpanded: true,

                  items: const [
                    DropdownMenuItem(
                      value: 'Meals',
                      child:
                          Text('Meals'),
                    ),
                    DropdownMenuItem(
                      value: 'Kg',
                      child:
                          Text('Kg'),
                    ),
                    DropdownMenuItem(
                      value: 'Packets',
                      child:
                          Text('Packets'),
                    ),
                    DropdownMenuItem(
                      value: 'Items',
                      child:
                          Text('Items'),
                    ),
                  ],

                  onChanged:
                      (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedQuantityUnit =
                          value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ==================================================
            // PICKUP LOCATION
            // ==================================================

            const Text(
              'Pickup Address *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  locationController,
              maxLines: 2,

              onChanged: (_) {
                if (pickupLatitude != null ||
                    pickupLongitude != null) {
                  setState(() {
                    pickupLatitude =
                        null;
                    pickupLongitude =
                        null;
                  });
                }
              },

              decoration:
                  fieldDecoration(
                hint:
                    'Enter pickup address manually',
                icon:
                    Icons.location_on_outlined,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,

              child:
                  OutlinedButton.icon(
                onPressed:
                    isGettingLocation
                        ? null
                        : getCurrentLocation,

                icon:
                    isGettingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  Color(
                                0xFF8F57D9,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.my_location,
                          ),

                label:
                    Text(
                  isGettingLocation
                      ? 'Getting Location...'
                      : 'Use My Current Location',
                ),

                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(
                    0xFF8F57D9,
                  ),

                  side:
                      const BorderSide(
                    color:
                        Color(0xFF8F57D9),
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                ),
              ),
            ),

            if (pickupLatitude != null &&
                pickupLongitude != null) ...[
              const SizedBox(height: 8),

              Text(
                'GPS coordinates: '
                '${pickupLatitude!.toStringAsFixed(6)}, '
                '${pickupLongitude!.toStringAsFixed(6)}',

                style:
                    const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 18),

            // ==================================================
            // PICKUP DATE
            // ==================================================

            const Text(
              'Pickup Date *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            dateTimeBox(
              icon:
                  Icons.calendar_today_outlined,

              text:
                  selectedPickupDate ==
                          null
                      ? 'Select pickup date'
                      : '${selectedPickupDate!.day}/'
                          '${selectedPickupDate!.month}/'
                          '${selectedPickupDate!.year}',

              onTap:
                  selectPickupDate,

              isSelected:
                  selectedPickupDate !=
                      null,
            ),

            const SizedBox(height: 18),

            // ==================================================
            // PICKUP TIME
            // ==================================================

            const Text(
              'Pickup Time *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            dateTimeBox(
              icon:
                  Icons.access_time_outlined,

              text:
                  selectedPickupTime ==
                          null
                      ? 'Select pickup time'
                      : selectedPickupTime!
                          .format(context),

              onTap:
                  selectPickupTime,

              isSelected:
                  selectedPickupTime !=
                      null,
            ),

            const SizedBox(height: 18),

            // ==================================================
            // EXPIRY DATE
            // ==================================================

            const Text(
              'Expiry Date *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            dateTimeBox(
              icon:
                  Icons.event_available_outlined,

              text:
                  selectedExpiryDate ==
                          null
                      ? 'Select expiry date'
                      : '${selectedExpiryDate!.day}/'
                          '${selectedExpiryDate!.month}/'
                          '${selectedExpiryDate!.year}',

              onTap:
                  selectExpiryDate,

              isSelected:
                  selectedExpiryDate !=
                      null,
            ),

            const SizedBox(height: 18),

            // ==================================================
            // EXPIRY TIME
            // ==================================================

            const Text(
              'Expiry Time *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            dateTimeBox(
              icon:
                  Icons.timer_outlined,

              text:
                  selectedExpiryTime ==
                          null
                      ? 'Select expiry time'
                      : selectedExpiryTime!
                          .format(context),

              onTap:
                  selectExpiryTime,

              isSelected:
                  selectedExpiryTime !=
                      null,
            ),

            const SizedBox(height: 18),

            // ==================================================
            // DESCRIPTION
            // ==================================================

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  descriptionController,

              maxLines: 4,

              decoration:
                  fieldDecoration(
                hint:
                    'Add any additional information...',
                icon:
                    Icons.notes_outlined,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SUBMIT
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 55,

              child:
                  ElevatedButton(
                onPressed:
                    isSubmitting
                        ? null
                        : submitDonation,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF8F57D9,
                  ),

                  foregroundColor:
                      Colors.white,

                  elevation: 0,

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                ),

                child:
                    isSubmitting
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Donation',
                            style:
                                TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}