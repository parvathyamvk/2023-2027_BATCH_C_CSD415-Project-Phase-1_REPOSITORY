import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'volunteer_task_details.dart';
import 'edit_profile.dart';
import 'login_screen.dart';

class VolunteerHomeScreen extends StatelessWidget {
  const VolunteerHomeScreen({super.key});

  Future<void> acceptAllocation(
    BuildContext context,
    String allocationId,
    Map<String, dynamic> allocation,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login again.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Accept Delivery?'),
          content: Text(
            'Accept ${allocation['allocatedQuantity'] ?? '-'} '
            '${allocation['unit'] ?? 'Meals'} for '
            '${allocation['receiverCommunityName'] ?? 'the receiver'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5B4D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final allocationRef =
          firestore.collection('allocations').doc(allocationId);

      final allocationSnapshot = await allocationRef.get();

      if (!allocationSnapshot.exists) {
        throw Exception('Allocation no longer exists.');
      }

      final currentAllocation = allocationSnapshot.data() ?? {};

      if (currentAllocation['volunteerId'] != null &&
          currentAllocation['volunteerId'].toString().isNotEmpty) {
        throw Exception('This delivery has already been assigned.');
      }

      final taskRef = firestore.collection('volunteer_tasks').doc();

      // Use the donor name already stored in the allocation.
      // We do not read the donor's private users/{id} document here.
      final donorName =
          currentAllocation['donorName']?.toString().trim().isNotEmpty == true
              ? currentAllocation['donorName'].toString().trim()
              : 'Donor';

      await firestore.runTransaction((transaction) async {
        final freshAllocation =
            await transaction.get(allocationRef);

        if (!freshAllocation.exists) {
          throw Exception('Allocation no longer exists.');
        }

        final freshData = freshAllocation.data() ?? {};

        if (freshData['volunteerId'] != null &&
            freshData['volunteerId'].toString().isNotEmpty) {
          throw Exception('This delivery has already been assigned.');
        }

        transaction.set(taskRef, {
          'allocationId': allocationId,
          'donationId': freshData['donationId'],
          'requestId': freshData['requestId'],
          'volunteerId': user.uid,

          'donorId': freshData['donorId'],
          'donorName': donorName,

          'receiverId': freshData['receiverId'],
          'receiverCommunityName':
              freshData['receiverCommunityName'] ?? '',
          'receiverContactPerson':
              freshData['receiverContactPerson'] ?? '',
          'receiverPhone':
              freshData['receiverPhone'] ?? '',
          'receiverAddress':
              freshData['receiverAddress'] ?? '',
          'receiverDistrict':
              freshData['receiverDistrict'] ?? '',
          'receiverLatitude':
              freshData['receiverLatitude'],
          'receiverLongitude':
              freshData['receiverLongitude'],

          'foodName': freshData['foodName'] ?? '',
          'foodType': freshData['foodType'] ?? '',
          'quantity': freshData['allocatedQuantity'] ?? 0,
          'unit': freshData['unit'] ?? 'Meals',

          'donorPickupAddress':
              freshData['donorPickupAddress'] ?? '',
          'donorPickupLatitude':
              freshData['donorPickupLatitude'],
          'donorPickupLongitude':
              freshData['donorPickupLongitude'],
          'pickupDate': freshData['pickupDate'] ?? '',
          'pickupTime': freshData['pickupTime'] ?? '',
          'expiryDate': freshData['expiryDate'] ?? '',
          'expiryTime': freshData['expiryTime'] ?? '',

          'pickupLocation':
              freshData['donorPickupAddress'] ?? '',
          'description':
              freshData['description'] ?? '',

          'pickupStatus': 'Assigned',
          'deliveryStatus': 'Not Started',
          'createdAt': FieldValue.serverTimestamp(),
          'pickedUpAt': null,
          'inTransitAt': null,
          'deliveredAt': null,
        });

        transaction.update(allocationRef, {
          'volunteerId': user.uid,
          'volunteerTaskId': taskRef.id,
          'status': 'Pickup Assigned',
          'assignedAt': FieldValue.serverTimestamp(),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Delivery accepted! Pickup and receiver details are now in My Pickup Tasks.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to accept delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void openTask(
    BuildContext context,
    String taskId,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VolunteerTaskDetailsScreen(
          taskId: taskId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),

      appBar: AppBar(
        title: const Text(
          'Volunteer Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFEF5B4D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 20,
                color: Color(0xFFEF5B4D),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VolunteerProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF7A6E),
                  Color(0xFFEF5B4D),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to make an impact? 🧡',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Pick up donated food and deliver it to the matched community.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'My Deliveries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (user != null)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('volunteer_tasks')
                  .where(
                    'volunteerId',
                    isEqualTo: user.uid,
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Color(0xFFEF5B4D),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _errorCard(snapshot.error.toString());
                }

                final tasks = snapshot.data?.docs ?? [];

                if (tasks.isEmpty) {
                  return _emptyTasksCard();
                }

                return Column(
                  children: tasks.map((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;

                    return _taskCard(
                      context,
                      doc.id,
                      data,
                    );
                  }).toList(),
                );
              },
            ),

          const SizedBox(height: 25),

          const Text(
            'Available Deliveries',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'These deliveries have already been matched by SharePlate.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('allocations')
                .where(
                  'status',
                  isEqualTo: 'Allocated',
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Color(0xFFEF5B4D),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return _errorCard(snapshot.error.toString());
              }

              final allocations = (snapshot.data?.docs ?? [])
                  .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final volunteerId = data['volunteerId']?.toString() ?? '';
                return volunteerId.isEmpty;
              }).toList();

              if (allocations.isEmpty) {
                return _emptyAvailableCard();
              }

              return Column(
                children: allocations.map((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  return _allocationCard(
                    context,
                    doc.id,
                    data,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================
  // MY TASK CARD
  // =========================

  Widget _taskCard(
    BuildContext context,
    String taskId,
    Map<String, dynamic> data,
  ) {
    final pickupStatus =
        data['pickupStatus']?.toString() ?? 'Assigned';
    final deliveryStatus =
        data['deliveryStatus']?.toString() ?? '';

    final status = deliveryStatus == 'Delivered'
        ? 'Delivered'
        : deliveryStatus == 'In Transit'
            ? 'In Transit'
            : pickupStatus;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF7A6E).withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping,
                  color: Color(0xFFEF5B4D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data['foodName']?.toString() ??
                      'Food Donation',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _statusChip(status),
            ],
          ),

          const SizedBox(height: 15),

          _routeBox(
            Icons.storefront_outlined,
            'PICKUP FROM DONOR',
            data['donorName']?.toString() ?? 'Donor',
            data['donorPickupAddress']?.toString() ??
                data['pickupLocation']?.toString() ??
                'Address unavailable',
          ),

          const SizedBox(height: 10),

          Center(
            child: Icon(
              Icons.arrow_downward_rounded,
              color: const Color(0xFFEF5B4D),
              size: 24,
            ),
          ),

          const SizedBox(height: 10),

          _routeBox(
            Icons.groups_outlined,
            'DELIVER TO RECEIVER',
            data['receiverCommunityName']?.toString() ??
                'Receiver',
            data['receiverAddress']?.toString() ??
                'Address unavailable',
          ),

          const SizedBox(height: 14),

          _infoRow(
            Icons.inventory_2_outlined,
            'Quantity',
            '${data['quantity'] ?? '-'} ${data['unit'] ?? 'Meals'}',
          ),

          const SizedBox(height: 10),

          _infoRow(
            Icons.person_outline,
            'Contact',
            data['receiverContactPerson']?.toString() ??
                '-',
          ),

          const SizedBox(height: 10),

          _infoRow(
            Icons.phone_outlined,
            'Phone',
            data['receiverPhone']?.toString() ?? '-',
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => openTask(context, taskId),
              icon: const Icon(Icons.location_on),
              label: const Text('Track Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5B4D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeBox(
    IconData icon,
    String label,
    String name,
    String address,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F5),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFEF5B4D),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _allocationCard(
    BuildContext context,
    String allocationId,
    Map<String, dynamic> data,
  ) {
    final quantity = data['allocatedQuantity']?.toString() ?? '0';
    final unit = data['unit']?.toString() ?? 'Meals';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: Color(0xFFEF5B4D),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['foodName']?.toString() ??
                          'Food Donation',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$quantity $unit',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'MATCHED',
                style: TextStyle(
                  color: Color(0xFFEF5B4D),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _routeBox(
            Icons.storefront_outlined,
            'PICKUP FROM DONOR',
            'Donor',
            data['donorPickupAddress']?.toString() ??
                'Address unavailable',
          ),

          const SizedBox(height: 10),

          Center(
            child: Icon(
              Icons.arrow_downward_rounded,
              color: const Color(0xFFEF5B4D),
              size: 24,
            ),
          ),

          const SizedBox(height: 10),

          _routeBox(
            Icons.groups_outlined,
            'DELIVER TO RECEIVER',
            data['receiverCommunityName']?.toString() ??
                'Receiver',
            data['receiverAddress']?.toString() ??
                'Address unavailable',
          ),

          const SizedBox(height: 10),

          _infoRow(
            Icons.person_outline,
            'Contact',
            data['receiverContactPerson']?.toString() ??
                '-',
          ),

          const SizedBox(height: 10),

          _infoRow(
            Icons.phone_outlined,
            'Phone',
            data['receiverPhone']?.toString() ?? '-',
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => acceptAllocation(
                context,
                allocationId,
                data,
              ),
              icon: const Icon(Icons.local_shipping),
              label: const Text('Accept Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5B4D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // STATUS CHIP
  // =========================

  Widget _statusChip(String status) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
            const Color(0xFFFFE9E5),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status,
        style: const TextStyle(
          color:
              Color(0xFFEF5B4D),
          fontWeight:
              FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // =========================
  // EMPTY TASKS
  // =========================

  Widget _emptyTasksCard() {
    return Container(
      padding:
          const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 45,
            color: Colors.grey,
          ),

          SizedBox(height: 10),

          Text(
            'No active deliveries',
            style: TextStyle(
              fontWeight:
                  FontWeight.w600,
              fontSize: 16,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Accept a delivery to start helping.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // EMPTY AVAILABLE
  // =========================

  Widget _emptyAvailableCard() {
    return Container(
      padding:
          const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 50,
            color: Colors.grey,
          ),

          SizedBox(height: 10),

          Text(
            'No deliveries available right now.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'New delivery tasks will appear here.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // ERROR CARD
  // =========================

  Widget _errorCard(String error) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Text(
        'Unable to load.\n\n$error',
        textAlign:
            TextAlign.center,
      ),
    );
  }

  // =========================
  // INFO ROW
  // =========================

  Widget _infoRow(
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
          size: 20,
          color:
              const Color(0xFFEF5B4D),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color:
                    Colors.black87,
              ),

              children: [
                TextSpan(
                  text: '$title: ',
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                TextSpan(
                  text: value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VolunteerProfileScreen extends StatelessWidget {
  const VolunteerProfileScreen({super.key});

  static const Color sharePlateCoral = Color(0xFFEF5B4D);
  static const Color sharePlateLightCoral = Color(0xFFFFF8F5);

  Future<void> logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('userRole');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
    await prefs.remove('userLocation');

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void openEditProfile(
    BuildContext context,
    Map<String, dynamic> data,
    User user,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          currentName: data['name']?.toString() ?? '',
          currentEmail: data['email']?.toString() ?? user.email ?? '',
          currentPhone: data['phone']?.toString() ?? '',
          currentLocation: data['location']?.toString() ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login again.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: sharePlateLightCoral,
      appBar: AppBar(
        title: const Text(
          'Volunteer Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: sharePlateCoral,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final name = data['name']?.toString() ?? '';
          final email = data['email']?.toString() ?? user.email ?? '';
          final phone = data['phone']?.toString() ?? '';
          final location = data['location']?.toString() ?? '';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF7A6E),
                      Color(0xFFEF5B4D),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.volunteer_activism,
                        size: 42,
                        color: sharePlateCoral,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name.isEmpty ? 'Volunteer' : name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _profileInfoCard(
                icon: Icons.person_outline,
                title: 'Name',
                value: name.isEmpty ? 'Not added' : name,
              ),
              _profileInfoCard(
                icon: Icons.email_outlined,
                title: 'Email',
                value: email.isEmpty ? 'Not added' : email,
              ),
              _profileInfoCard(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: phone.isEmpty ? 'Not added' : phone,
              ),
              _profileInfoCard(
                icon: Icons.location_on_outlined,
                title: 'Location',
                value: location.isEmpty ? 'Not added' : location,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => openEditProfile(context, data, user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sharePlateCoral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: sharePlateCoral,
                    side: const BorderSide(color: sharePlateCoral),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _profileInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sharePlateCoral.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sharePlateCoral.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: sharePlateCoral),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
