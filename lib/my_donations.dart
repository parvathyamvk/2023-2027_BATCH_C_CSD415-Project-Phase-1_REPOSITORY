import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  List<Map<String, String>> donations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDonation();
  }

  // ============================================================
  // LOAD DONATIONS
  // ============================================================

  Future<void> loadDonation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        donations = [];
        isLoading = false;
      });

      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('donations')
          .where('donorId', isEqualTo: user.uid)
          .get();

      final loadedDonations = snapshot.docs.map((doc) {
        final data = doc.data();

        return <String, String>{
          'id': doc.id,

          'food':
              data['foodName']?.toString() ?? '',

          'type':
              data['foodType']?.toString() ?? 'Cooked Food',

          'quantity':
              data['quantity']?.toString() ?? '',

          'unit':
              data['unit']?.toString() ?? '',

          'location':
              data['pickupLocation']?.toString() ??
                  data['pickupAddress']?.toString() ??
                  '',

          'date':
              data['pickupDate']?.toString() ?? '',

          'time':
              data['pickupTime']?.toString() ?? '',

          'expiryDate':
              data['expiryDate']?.toString() ?? '',

          'expiryTime':
              data['expiryTime']?.toString() ?? '',

          'status':
              data['status']?.toString() ?? 'Pending',

          'description':
              data['description']?.toString() ?? '',

          // FOOD PHOTO
          'foodImage':
              data['foodImage']?.toString() ?? '',
        };
      }).toList();

      // ========================================================
      // NEWEST DONATIONS FIRST
      // ========================================================

      loadedDonations.sort((a, b) {
        final aDoc = snapshot.docs.firstWhere(
          (doc) => doc.id == a['id'],
        );

        final bDoc = snapshot.docs.firstWhere(
          (doc) => doc.id == b['id'],
        );

        final aTime = aDoc.data()['createdAt'];
        final bTime = bDoc.data()['createdAt'];

        if (aTime is Timestamp && bTime is Timestamp) {
          return bTime.compareTo(aTime);
        }

        return 0;
      });

      if (!mounted) return;

      setState(() {
        donations = loadedDonations;
        isLoading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        donations = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load donations: '
            '${e.message ?? 'Please try again.'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        donations = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while loading donations.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),

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
          'My Donations',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE85D4A),
              ),
            )
          : donations.isEmpty
              ? const EmptyDonations()
              : RefreshIndicator(
                  color: const Color(0xFFE85D4A),

                  onRefresh: loadDonation,

                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),

                    itemCount: donations.length,

                    itemBuilder: (context, index) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 16),

                        child: DonationCard(
                          donation: donations[index],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ============================================================
// EMPTY DONATIONS
// ============================================================

class EmptyDonations extends StatelessWidget {
  const EmptyDonations({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 100,
              height: 100,

              decoration: const BoxDecoration(
                color: Color(0xFFFFE7E4),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.volunteer_activism_outlined,
                size: 55,
                color: Color(0xFFE85D4A),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No donations yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your food donations will appear here after you submit them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },

              icon: const Icon(Icons.add),

              label: const Text(
                'Make a Donation',
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFE85D4A),
                foregroundColor:
                    Colors.white,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DONATION CARD
// ============================================================

class DonationCard extends StatelessWidget {
  final Map<String, String> donation;

  const DonationCard({
    super.key,
    required this.donation,
  });

  @override
  Widget build(BuildContext context) {
    final status =
        donation['status'] ?? 'Pending';

    final completed =
        status == 'Completed' ||
        status == 'Delivered';

    final image =
        donation['foodImage'] ?? '';

    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ==================================================
          // FOOD PHOTO
          // ==================================================

          if (image.isNotEmpty) ...[
            FoodImage(
              base64Image: image,
              height: 190,
              borderRadius: 16,
            ),

            const SizedBox(height: 16),
          ],

          // ==================================================
          // HEADER
          // ==================================================

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Container(
                width: 55,
                height: 55,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFFFE7E4),
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                ),

                child: const Icon(
                  Icons.restaurant,
                  color:
                      Color(0xFFE85D4A),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Text(
                      donation['food'] ?? '',
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      donation['type'] ?? '',
                      style:
                          const TextStyle(
                        fontSize: 13,
                        color:
                            Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration:
                    BoxDecoration(
                  color: completed
                      ? const Color(
                          0xFFE8F5E9,
                        )
                      : const Color(
                          0xFFFFF0D9,
                        ),

                  borderRadius:
                      BorderRadius.circular(
                    20,
                  ),
                ),

                child: Text(
                  status,

                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.bold,

                    color: completed
                        ? const Color(
                            0xFF43A047,
                          )
                        : const Color(
                            0xFFE58A00,
                          ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(
            color: Color(0xFFEEEEEE),
          ),

          const SizedBox(height: 14),

          // ==================================================
          // INFORMATION
          // ==================================================

          infoRow(
            Icons.people_outline,
            'Quantity',
            _quantityText(),
          ),

          const SizedBox(height: 10),

          infoRow(
            Icons.location_on_outlined,
            'Pickup Location',
            donation['location'] ?? '',
          ),

          const SizedBox(height: 10),

          infoRow(
            Icons.calendar_today_outlined,
            'Pickup Date',
            donation['date'] ?? '',
          ),

          const SizedBox(height: 10),

          infoRow(
            Icons.access_time_outlined,
            'Pickup Time',
            donation['time'] ?? '',
          ),

          const SizedBox(height: 18),

          // ==================================================
          // VIEW DETAILS
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 46,

            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (context) =>
                        DonationDetailsScreen(
                      donation: donation,
                    ),
                  ),
                );
              },

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    const Color(
                  0xFFE85D4A,
                ),

                side:
                    const BorderSide(
                  color:
                      Color(0xFFE85D4A),
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
              ),

              child: const Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(width: 8),

                  Icon(
                    Icons
                        .arrow_forward_rounded,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _quantityText() {
    final quantity =
        donation['quantity'] ?? '';

    final unit =
        donation['unit'] ?? '';

    if (unit.isEmpty) {
      return quantity;
    }

    return '$quantity $unit';
  }

  Widget infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Icon(
          icon,
          size: 19,
          color:
              const Color(0xFF888888),
        ),

        const SizedBox(width: 10),

        Text(
          '$title:',
          style: const TextStyle(
            fontSize: 13,
            color:
                Color(0xFF888888),
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value,

            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FOOD IMAGE
// ============================================================

class FoodImage extends StatelessWidget {
  final String base64Image;
  final double height;
  final double borderRadius;

  const FoodImage({
    super.key,
    required this.base64Image,
    this.height = 200,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final bytes =
          base64Decode(base64Image);

      return ClipRRect(
        borderRadius:
            BorderRadius.circular(
          borderRadius,
        ),

        child: Image.memory(
          bytes,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,

          errorBuilder:
              (context, error, stackTrace) {
            return _imageError();
          },
        ),
      );
    } catch (e) {
      return _imageError();
    }
  }

  Widget _imageError() {
    return Container(
      width: double.infinity,
      height: height,

      decoration: BoxDecoration(
        color:
            const Color(0xFFF5F5F5),
        borderRadius:
            BorderRadius.circular(
          borderRadius,
        ),
      ),

      child: const Column(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          Icon(
            Icons
                .image_not_supported_outlined,
            size: 40,
            color: Colors.grey,
          ),

          SizedBox(height: 8),

          Text(
            'Photo unavailable',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DONATION DETAILS
// ============================================================

class DonationDetailsScreen
    extends StatelessWidget {
  final Map<String, String> donation;

  const DonationDetailsScreen({
    super.key,
    required this.donation,
  });

  @override
  Widget build(BuildContext context) {
    final image =
        donation['foodImage'] ?? '';

    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Donation Details',
          style: TextStyle(
            color:
                Color(0xFF222222),
            fontWeight:
                FontWeight.bold,
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
            // ==================================================
            // FOOD PHOTO
            // ==================================================

            if (image.isNotEmpty) ...[
              FoodImage(
                base64Image: image,
                height: 230,
                borderRadius: 20,
              ),

              const SizedBox(height: 20),
            ],

            // ==================================================
            // HEADER CARD
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(22),

              decoration:
                  BoxDecoration(
                gradient:
                    const LinearGradient(
                  colors: [
                    Color(0xFFE85D4A),
                    Color(0xFF9A6BFF),
                  ],
                ),

                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Icon(
                    Icons.restaurant,
                    color: Colors.white,
                    size: 38,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    donation['food'] ?? '',
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    donation['type'] ?? '',
                    style:
                        const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Donation Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            detailTile(
              Icons.people_outline,
              'Quantity',
              _quantityText(),
            ),

            detailTile(
              Icons.location_on_outlined,
              'Pickup Location',
              donation['location'] ?? '',
            ),

            detailTile(
              Icons.calendar_today_outlined,
              'Pickup Date',
              donation['date'] ?? '',
            ),

            detailTile(
              Icons.access_time_outlined,
              'Pickup Time',
              donation['time'] ?? '',
            ),

            if ((donation['expiryDate'] ?? '')
                .isNotEmpty)
              detailTile(
                Icons.event_available_outlined,
                'Expiry Date',
                donation['expiryDate'] ?? '',
              ),

            if ((donation['expiryTime'] ?? '')
                .isNotEmpty)
              detailTile(
                Icons.timer_outlined,
                'Expiry Time',
                donation['expiryTime'] ?? '',
              ),

            detailTile(
              Icons.description_outlined,
              'Description',
              donation['description'] ??
                  'No description',
            ),

            const SizedBox(height: 15),

            // ==================================================
            // STATUS
            // ==================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions,
                    color:
                        Color(0xFFE58A00),
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Donation Status',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        donation['status'] ??
                            'Pending',

                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Color(0xFFE58A00),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // TRACK BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 52,

              child:
                  ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) =>
                          const DonationTrackingScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.location_searching,
                ),

                label: const Text(
                  'Track Donation',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

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
                      15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _quantityText() {
    final quantity =
        donation['quantity'] ?? '';

    final unit =
        donation['unit'] ?? '';

    if (unit.isEmpty) {
      return quantity;
    }

    return '$quantity $unit';
  }

  Widget detailTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,

      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(17),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            color:
                const Color(0xFFE85D4A),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TRACKING
// ============================================================

class DonationTrackingScreen
    extends StatelessWidget {
  const DonationTrackingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Track Donation',
          style: TextStyle(
            color:
                Color(0xFF222222),
            fontWeight:
                FontWeight.bold,
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
              'Donation Status',
              style: TextStyle(
                fontSize: 25,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Follow the progress of your donation.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(20),

              decoration:
                  BoxDecoration(
                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                  20,
                ),
              ),

              child: const Column(
                children: [
                  Icon(
                    Icons.pending_actions,
                    size: 55,
                    color:
                        Color(0xFFE58A00),
                  ),

                  SizedBox(height: 12),

                  Text(
                    'Pending Pickup',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Your donation is waiting to be picked up.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            trackingStep(
              icon: Icons.check_circle,
              title:
                  'Donation Submitted',
              subtitle:
                  'Donation details submitted.',
              completed: true,
            ),

            trackingLine(),

            trackingStep(
              icon:
                  Icons.pending_actions,
              title:
                  'Waiting for Pickup',
              subtitle:
                  'Waiting for a volunteer/NGO.',
              completed: false,
            ),

            trackingLine(),

            trackingStep(
              icon:
                  Icons.local_shipping_outlined,
              title: 'Picked Up',
              subtitle:
                  'Food collected from donor.',
              completed: false,
            ),

            trackingLine(),

            trackingStep(
              icon:
                  Icons.volunteer_activism,
              title: 'Delivered',
              subtitle:
                  'Food reaches people in need.',
              completed: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget trackingStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool completed,
  }) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Container(
          width: 45,
          height: 45,

          decoration:
              BoxDecoration(
            color: completed
                ? const Color(
                    0xFFE85D4A,
                  )
                : const Color(
                    0xFFE8E8E8,
                  ),

            shape:
                BoxShape.circle,
          ),

          child: Icon(
            icon,
            color: completed
                ? Colors.white
                : Colors.grey,
            size: 22,
          ),
        ),

        const SizedBox(width: 15),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style:
                    const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget trackingLine() {
    return Container(
      margin:
          const EdgeInsets.only(
        left: 21,
      ),

      height: 30,
      width: 2,

      color:
          const Color(0xFFE0E0E0),
    );
  }
}