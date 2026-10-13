import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile.dart';
import 'login_screen.dart';

class NgoHomeScreen extends StatefulWidget {
  const NgoHomeScreen({super.key});

  @override
  State<NgoHomeScreen> createState() => _NgoHomeScreenState();
}

class _NgoHomeScreenState extends State<NgoHomeScreen> {
  bool _allocationRunning = false;
  String _allocationMessage = '';

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout of SharePlate?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D4A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  double? _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  int _urgencyScore(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'critical':
        return 30;
      case 'urgent':
        return 20;
      default:
        return 10;
    }
  }

  Future<void> _runSmartAllocation(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> donations,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> requests,
  ) async {
    if (_allocationRunning) return;

    final availableDonations = donations.where((doc) {
      final d = doc.data();
      final status = d['status']?.toString() ?? '';
      final remaining =
          _num(d['remainingQuantity']) ?? _num(d['quantity']) ?? 0;
      return (status == 'Pending' || status == 'Partially Allocated') &&
          remaining > 0;
    }).toList();

    final pendingRequests = requests.where((doc) {
      final r = doc.data();
      final status = r['status']?.toString() ?? '';
      final remaining =
          _num(r['remainingQuantity']) ?? _num(r['quantityRequired']) ?? 0;
      return (status == 'Pending' || status == 'Partially Allocated') &&
          remaining > 0;
    }).toList();

    if (availableDonations.isEmpty || pendingRequests.isEmpty) {
      if (mounted) {
        setState(() {
          _allocationMessage =
              'Waiting for an available donation and receiver request.';
        });
      }
      return;
    }

    setState(() {
      _allocationRunning = true;
      _allocationMessage = 'Smart Allocation is finding the best matches...';
    });

    int created = 0;

    try {
      for (final requestDoc in pendingRequests) {
        final r = requestDoc.data();
        final requestFood = r['foodType']?.toString().toLowerCase() ?? '';
        final requestUrgency = r['urgency']?.toString() ?? 'Normal';
        final requestLat = _num(r['latitude']);
        final requestLon = _num(r['longitude']);

        QueryDocumentSnapshot<Map<String, dynamic>>? bestDonation;
        double bestScore = -1e9;

        for (final donationDoc in availableDonations) {
          final d = donationDoc.data();
          final status = d['status']?.toString() ?? '';
          final remaining =
              _num(d['remainingQuantity']) ?? _num(d['quantity']) ?? 0;

          if ((status != 'Pending' && status != 'Partially Allocated') ||
              remaining <= 0) {
            continue;
          }

          final donationFood = d['foodType']?.toString().toLowerCase() ?? '';

          double score = donationFood == requestFood ? 100 : 0;
          score += _urgencyScore(requestUrgency);

          // Prefer food approaching expiry.
          final expiryDate = d['expiryDate']?.toString() ?? '';
          final expiryTime = d['expiryTime']?.toString() ?? '';
          final expiry = DateTime.tryParse(
            '$expiryDate ${expiryTime.isEmpty ? '23:59' : expiryTime}',
          );

          if (expiry != null) {
            final hours = expiry.difference(DateTime.now()).inHours;
            if (hours >= 0 && hours <= 24) {
              score += 30;
            } else if (hours <= 48) {
              score += 15;
            }
          }

          // Prefer nearby donor/receiver locations when GPS exists.
          final donationLat = _num(d['pickupLatitude']);
          final donationLon = _num(d['pickupLongitude']);

          if (requestLat != null &&
              requestLon != null &&
              donationLat != null &&
              donationLon != null) {
            final distance = _distanceKm(
              requestLat,
              requestLon,
              donationLat,
              donationLon,
            );
            score += math.max(0, 30 - distance);
          }

          final required =
              _num(r['remainingQuantity']) ?? _num(r['quantityRequired']) ?? 0;

          if (remaining >= required) score += 20;

          if (score > bestScore) {
            bestScore = score;
            bestDonation = donationDoc;
          }
        }

        if (bestDonation == null) continue;

        final donationRef = FirebaseFirestore.instance
            .collection('donations')
            .doc(bestDonation.id);

        final requestRef = FirebaseFirestore.instance
            .collection('receiver_requests')
            .doc(requestDoc.id);

        final allocationRef = FirebaseFirestore.instance
            .collection('allocations')
            .doc();

        bool wasCreated = false;

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final donationSnapshot = await transaction.get(donationRef);
          final requestSnapshot = await transaction.get(requestRef);

          if (!donationSnapshot.exists || !requestSnapshot.exists) return;

          final d = donationSnapshot.data() ?? {};
          final currentRequest = requestSnapshot.data() ?? {};

          final donationRemaining =
              _num(d['remainingQuantity']) ?? _num(d['quantity']) ?? 0;
          final requestRemaining =
              _num(currentRequest['remainingQuantity']) ??
              _num(currentRequest['quantityRequired']) ??
              0;

          if (donationRemaining <= 0 || requestRemaining <= 0) return;

          // Partial allocation:
          // if donation = 400 and request = 300, amount = 300.
          final amount = math.min(donationRemaining, requestRemaining).toInt();

          if (amount <= 0) return;

          final newDonationRemaining = donationRemaining - amount;
          final newRequestRemaining = requestRemaining - amount;

          transaction.set(allocationRef, {
            'donationId': bestDonation!.id,
            'requestId': requestDoc.id,
            'donorId': d['donorId'],
            'donorName': d['donorName'] ?? d['donorOrganization'] ?? 'Donor',
            'receiverId': currentRequest['receiverId'],
            'ngoId': FirebaseAuth.instance.currentUser?.uid,

            'foodName': d['foodName'] ?? '',
            'foodType': d['foodType'] ?? '',
            'allocatedQuantity': amount,
            'unit': currentRequest['unit'] ?? d['unit'] ?? 'Meals',
            'urgency': currentRequest['urgency'] ?? 'Normal',

            // Volunteer pickup details.
            'donorPickupAddress':
                d['pickupAddress'] ?? d['pickupLocation'] ?? '',
            'donorPickupLatitude': d['pickupLatitude'],
            'donorPickupLongitude': d['pickupLongitude'],
            'pickupDate': d['pickupDate'] ?? '',
            'pickupTime': d['pickupTime'] ?? '',
            'expiryDate': d['expiryDate'] ?? '',
            'expiryTime': d['expiryTime'] ?? '',

            // Volunteer delivery details.
            'receiverCommunityName': currentRequest['communityName'] ?? '',
            'receiverContactPerson': currentRequest['contactPerson'] ?? '',
            'receiverPhone': currentRequest['phone'] ?? '',
            'receiverAddress': currentRequest['address'] ?? '',
            'receiverDistrict': currentRequest['district'] ?? '',
            'receiverLatitude': currentRequest['latitude'],
            'receiverLongitude': currentRequest['longitude'],

            'status': 'Allocated',
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.update(donationRef, {
            'allocatedQuantity': (_num(d['allocatedQuantity']) ?? 0) + amount,
            'remainingQuantity': newDonationRemaining,
            'status': newDonationRemaining <= 0
                ? 'Allocated'
                : 'Partially Allocated',
          });

          transaction.update(requestRef, {
            'allocatedQuantity':
                (_num(currentRequest['allocatedQuantity']) ?? 0) + amount,
            'remainingQuantity': newRequestRemaining,
            'status': newRequestRemaining <= 0
                ? 'Allocated'
                : 'Partially Allocated',
          });

          wasCreated = true;
        });

        if (wasCreated) created++;
      }

      if (mounted) {
        setState(() {
          _allocationMessage = created == 0
              ? 'No new allocation was created.'
              : '$created allocation(s) created automatically.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allocationMessage = 'Smart Allocation error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _allocationRunning = false;
        });
      }
    }
  }

  Widget _statCard(IconData icon, String value, String title) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE85D4A), size: 26),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _allocationCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final foodName = data['foodName']?.toString() ?? 'Food Donation';
    final foodType = data['foodType']?.toString() ?? '';
    final quantity = data['allocatedQuantity']?.toString() ?? '0';
    final unit = data['unit']?.toString() ?? 'Meals';

    final donorName = data['donorName']?.toString().trim().isNotEmpty == true
        ? data['donorName'].toString().trim()
        : (data['donorOrganization']?.toString().trim().isNotEmpty == true
              ? data['donorOrganization'].toString().trim()
              : 'Donor');

    final receiverName =
        data['receiverCommunityName']?.toString() ?? 'Receiver';

    final donorAddress = data['donorPickupAddress']?.toString() ?? '';
    final receiverAddress = data['receiverAddress']?.toString() ?? '';
    final receiverDistrict = data['receiverDistrict']?.toString() ?? '';

    final allocationStatus = data['status']?.toString() ?? 'Allocated';

    final volunteerId = data['volunteerId']?.toString() ?? '';
    final volunteerTaskId = data['volunteerTaskId']?.toString() ?? '';

    /*
     * IMPORTANT:
     * The allocation status can remain "Pickup Assigned" even after the
     * volunteer completes the delivery. The actual delivery progress is
     * stored in volunteer_tasks.
     *
     * For older allocations, volunteerTaskId may be empty, so we also find
     * the task using allocationId == this allocation document id.
     */
    final Stream<QuerySnapshot<Map<String, dynamic>>> taskQueryStream =
        volunteerTaskId.isNotEmpty
        ? FirebaseFirestore.instance
              .collection('volunteer_tasks')
              .where('allocationId', isEqualTo: doc.id)
              .snapshots()
        : FirebaseFirestore.instance
              .collection('volunteer_tasks')
              .where('allocationId', isEqualTo: doc.id)
              .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: taskQueryStream,
      builder: (context, taskSnapshot) {
        Map<String, dynamic>? taskData;

        if (taskSnapshot.hasData && taskSnapshot.data!.docs.isNotEmpty) {
          /*
           * Prefer the task referenced by volunteerTaskId when it exists.
           * Otherwise use the first task belonging to this allocation.
           */
          final matchingTasks = taskSnapshot.data!.docs;

          final matchingTask = volunteerTaskId.isNotEmpty
              ? matchingTasks.where((task) => task.id == volunteerTaskId)
              : matchingTasks;

          if (matchingTask.isNotEmpty) {
            taskData = matchingTask.first.data();
          } else {
            taskData = matchingTasks.first.data();
          }
        }

        /*
         * Some versions of the volunteer flow use pickupStatus and some
         * store the final delivery state in deliveryStatus. Check both.
         */
        final pickupStatus = taskData?['pickupStatus']?.toString().trim() ?? '';
        final deliveryStatus =
            taskData?['deliveryStatus']?.toString().trim() ?? '';

        String status = allocationStatus;

        if (pickupStatus == 'Delivered' || deliveryStatus == 'Delivered') {
          status = 'Delivered';
        } else if (pickupStatus == 'In Transit' ||
            deliveryStatus == 'In Transit') {
          status = 'In Transit';
        } else if (pickupStatus == 'Picked Up' ||
            deliveryStatus == 'Picked Up') {
          status = 'Picked Up';
        } else if (pickupStatus == 'Assigned' ||
            pickupStatus == 'Volunteer Assigned' ||
            deliveryStatus == 'Assigned') {
          status = 'Pickup Assigned';
        }

        final volunteerLabel = volunteerId.isEmpty
            ? 'Waiting for volunteer'
            : status == 'Delivered'
            ? 'Delivery completed'
            : (pickupStatus.isNotEmpty
                  ? pickupStatus
                  : (deliveryStatus.isNotEmpty
                        ? deliveryStatus
                        : 'Volunteer assigned'));

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE7E4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Color(0xFFE85D4A),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foodName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (foodType.isNotEmpty)
                          Text(
                            foodType,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'Delivered'
                          ? const Color(0xFFE7F7EC)
                          : const Color(0xFFFFEEE9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'Delivered'
                            ? const Color(0xFF2E8B57)
                            : const Color(0xFFE85D4A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(height: 1),
              const SizedBox(height: 14),
              _allocationPerson(
                Icons.storefront_outlined,
                'DONOR',
                donorName,
                donorAddress,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 5, bottom: 5),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 24,
                      color: const Color(0xFFE85D4A),
                    ),
                    const SizedBox(width: 15),
                    const Icon(
                      Icons.arrow_downward_rounded,
                      color: Color(0xFFE85D4A),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$quantity $unit allocated',
                      style: const TextStyle(
                        color: Color(0xFFE85D4A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              _allocationPerson(
                Icons.groups_outlined,
                'RECEIVER',
                receiverName,
                receiverAddress.isEmpty
                    ? receiverDistrict
                    : '$receiverAddress${receiverDistrict.isNotEmpty ? ', $receiverDistrict' : ''}',
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: status == 'Delivered'
                      ? const Color(0xFFE7F7EC)
                      : const Color(0xFFFFF8F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == 'Delivered'
                          ? Icons.check_circle_outline
                          : volunteerId.isEmpty
                          ? Icons.person_outline
                          : Icons.delivery_dining_outlined,
                      color: status == 'Delivered'
                          ? const Color(0xFF2E8B57)
                          : const Color(0xFFE85D4A),
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'VOLUNTEER: ',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        volunteerLabel,
                        style: TextStyle(
                          color: status == 'Delivered'
                              ? const Color(0xFF2E8B57)
                              : const Color(0xFF333333),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _allocationPerson(
    IconData icon,
    String label,
    String name,
    String address,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21, color: const Color(0xFF777777)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _matchingRow(IconData icon, String title, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE85D4A), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  text,
                  style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'NGO Dashboard',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Receiver Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NgoReceiverRequestsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.groups_outlined, color: Color(0xFF333333)),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF333333)),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NgoProfileScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Please login to continue.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('donations')
                  .where('status', whereIn: ['Pending', 'Partially Allocated'])
                  .snapshots(),
              builder: (context, donationSnapshot) {
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('receiver_requests')
                      .where(
                        'status',
                        whereIn: ['Pending', 'Partially Allocated'],
                      )
                      .snapshots(),
                  builder: (context, requestSnapshot) {
                    if (donationSnapshot.hasError || requestSnapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Unable to load donations or receiver requests.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (donationSnapshot.connectionState ==
                            ConnectionState.waiting ||
                        requestSnapshot.connectionState ==
                            ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE85D4A),
                        ),
                      );
                    }

                    final donations = donationSnapshot.data?.docs ?? [];
                    final requests = requestSnapshot.data?.docs ?? [];

                    // Count only donations that still have food available.
                    // A donation can remain in the Pending/Partially Allocated
                    // query even when its remaining quantity is already 0.
                    final availableDonationCount = donations.where((doc) {
                      final data = doc.data();
                      final status = data['status']?.toString() ?? '';
                      final remaining =
                          _num(data['remainingQuantity']) ??
                          _num(data['quantity']) ??
                          0;
                      return (status == 'Pending' ||
                              status == 'Partially Allocated') &&
                          remaining > 0;
                    }).length;

                    // Automatically attempt matching whenever the
                    // dashboard receives pending data.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted &&
                          !_allocationRunning &&
                          (donations.isNotEmpty && requests.isNotEmpty)) {
                        _runSmartAllocation(donations, requests);
                      }
                    });

                    return RefreshIndicator(
                      color: const Color(0xFFE85D4A),
                      onRefresh: () async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 400),
                        );
                        if (mounted) {
                          await _runSmartAllocation(donations, requests);
                        }
                      },
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text(
                            'Welcome to SharePlate 👋',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Smartly connect surplus food with communities that need it.',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          const SizedBox(height: 22),

                          Container(
                            padding: const EdgeInsets.all(21),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE85D4A), Color(0xFFEF5B4D)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Smart Allocation',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Automatic donor → receiver matching',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white24,
                                  child: Icon(
                                    _allocationRunning
                                        ? Icons.sync
                                        : Icons.auto_awesome,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_allocationMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _allocationMessage,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  Icons.restaurant_outlined,
                                  '$availableDonationCount',
                                  'Available Donations',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _statCard(
                                  Icons.groups_outlined,
                                  '${requests.length}',
                                  'Pending Requests',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'Matched Allocations',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('allocations')
                                .where(
                                  'ngoId',
                                  isEqualTo:
                                      FirebaseAuth.instance.currentUser?.uid,
                                )
                                .snapshots(),
                            builder: (context, allocationSnapshot) {
                              if (allocationSnapshot.hasError) {
                                return Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Text(
                                    'Unable to load matched allocations.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              if (allocationSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(15),
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFE85D4A),
                                    ),
                                  ),
                                );
                              }

                              final allocations =
                                  allocationSnapshot.data?.docs ?? [];

                              if (allocations.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.handshake_outlined,
                                        color: Color(0xFFE85D4A),
                                        size: 25,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'No donor → receiver matches yet. '
                                          'Matches will appear here automatically.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                children: allocations.map((doc) {
                                  return _allocationCard(doc);
                                }).toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 26),

                          const Text(
                            'How SharePlate Matches',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          _matchingRow(
                            Icons.category_outlined,
                            'Food Type',
                            'Prefer the same type of food.',
                          ),
                          _matchingRow(
                            Icons.timer_outlined,
                            'Freshness',
                            'Prioritize food that is nearing expiry.',
                          ),
                          _matchingRow(
                            Icons.location_on_outlined,
                            'Distance',
                            'Prefer nearby donor and receiver locations when GPS is available.',
                          ),
                          _matchingRow(
                            Icons.priority_high_rounded,
                            'Urgency',
                            'Urgent and critical receiver requests get higher priority.',
                          ),
                          _matchingRow(
                            Icons.pie_chart_outline,
                            'Partial Allocation',
                            'If 400 meals are donated and 300 are needed, only 300 are allocated and 100 remain available.',
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: _allocationRunning
                                  ? null
                                  : () => _runSmartAllocation(
                                      donations,
                                      requests,
                                    ),
                              icon: const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFE85D4A),
                              ),
                              label: const Text(
                                'Run Smart Allocation Again',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFE85D4A),
                                side: const BorderSide(
                                  color: Color(0xFFE85D4A),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class NgoReceiverRequestsScreen extends StatelessWidget {
  const NgoReceiverRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF222222),
        title: const Text(
          'Receiver Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('receiver_requests')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Text(
                  'Unable to load receiver requests.\n\n'
                  'If this is the first time opening this page, '
                  'make sure the updated Firestore rules are published.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE85D4A)),
            );
          }

          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return RefreshIndicator(
              color: const Color(0xFFE85D4A),
              onRefresh: () async {
                await Future<void>.delayed(const Duration(milliseconds: 400));
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const SizedBox(height: 80),
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.groups_outlined,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 15),
                        Text(
                          'No Pending Requests',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Food requests submitted by communities '
                          'will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFE85D4A),
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 400));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final doc = requests[index];

                return NgoReceiverRequestCard(
                  requestId: doc.id,
                  data: doc.data(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NgoReceiverRequestCard extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const NgoReceiverRequestCard({
    super.key,
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final communityName = data['communityName']?.toString() ?? 'Community';
    final contactPerson = data['contactPerson']?.toString() ?? '';
    final foodType = data['foodType']?.toString() ?? '';
    final quantity = data['quantityRequired']?.toString() ?? '';
    final unit = data['unit']?.toString() ?? 'Meals';
    final urgency = data['urgency']?.toString() ?? 'Normal';
    final address = data['address']?.toString() ?? '';
    final district = data['district']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFFE85D4A),
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      communityName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      foodType.isEmpty ? 'Food Request' : foodType,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _urgencyBadge(urgency),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          _info(
            Icons.people_outline,
            'Required',
            quantity.isEmpty ? '' : '$quantity $unit',
          ),
          const SizedBox(height: 9),
          _info(Icons.person_outline, 'Contact Person', contactPerson),
          const SizedBox(height: 9),
          _info(Icons.phone_outlined, 'Phone', phone),
          const SizedBox(height: 9),
          _info(
            Icons.location_on_outlined,
            'Address',
            address.isEmpty
                ? district
                : '$address${district.isNotEmpty ? ', $district' : ''}',
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 9),
            _info(Icons.notes_outlined, 'Description', description),
          ],
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFE85D4A), size: 19),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'This request is ready to be matched with an available donation.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _urgencyBadge(String urgency) {
    final isCritical = urgency == 'Critical';
    final isUrgent = urgency == 'Urgent';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isCritical
            ? const Color(0xFFFFE1DE)
            : isUrgent
            ? const Color(0xFFFFEEE9)
            : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        urgency,
        style: TextStyle(
          color: isCritical
              ? const Color(0xFFD93426)
              : isUrgent
              ? const Color(0xFFE85D4A)
              : Colors.grey.shade700,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF888888)),
        const SizedBox(width: 9),
        Text(
          '$title: ',
          style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}

class NgoDonationCard extends StatelessWidget {
  final String donationId;
  final Map<String, dynamic> data;

  const NgoDonationCard({
    super.key,
    required this.donationId,
    required this.data,
  });

  Future<void> acceptDonation(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login again.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Accept Donation?'),
          content: Text(
            'Do you want your NGO to accept this ${data['foodName']?.toString() ?? 'food'} donation?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D4A),
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
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(donationId)
          .update({
            'status': 'Accepted',
            'acceptedBy': user.uid,
            'acceptedAt': FieldValue.serverTimestamp(),
          });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation accepted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Permission denied. Firestore rules need to be updated.'
                : 'Could not accept donation: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not accept donation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foodName = data['foodName']?.toString() ?? 'Food Donation';
    final foodType = data['foodType']?.toString() ?? '';
    final quantity = data['quantity']?.toString() ?? '';
    final unit = data['unit']?.toString() ?? 'Meals';
    final location =
        data['pickupAddress']?.toString() ??
        data['pickupLocation']?.toString() ??
        '';
    final date = data['pickupDate']?.toString() ?? '';
    final time = data['pickupTime']?.toString() ?? '';
    final expiryDate = data['expiryDate']?.toString() ?? '';
    final expiryTime = data['expiryTime']?.toString() ?? '';
    final description = data['description']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7E4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Color(0xFFE85D4A),
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foodName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      foodType,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          _info(
            Icons.people_outline,
            'Quantity',
            quantity.isEmpty ? '' : '$quantity $unit',
          ),
          const SizedBox(height: 9),
          _info(Icons.location_on_outlined, 'Pickup Address', location),
          const SizedBox(height: 9),
          _info(Icons.calendar_today_outlined, 'Pickup Date', date),
          const SizedBox(height: 9),
          _info(Icons.access_time_outlined, 'Pickup Time', time),
          const SizedBox(height: 9),
          _info(Icons.event_available_outlined, 'Expiry Date', expiryDate),
          const SizedBox(height: 9),
          _info(Icons.timer_outlined, 'Expiry Time', expiryTime),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 9),
            _info(Icons.notes_outlined, 'Description', description),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => acceptDonation(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D4A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              child: const Text(
                'View & Accept',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF888888)),
        const SizedBox(width: 9),
        Text(
          '$title: ',
          style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// NGO PROFILE
// ============================================================

class NgoProfileScreen extends StatelessWidget {
  const NgoProfileScreen({super.key});

  Future<void> logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text('Are you sure you want to logout of SharePlate?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE85D4A),
                foregroundColor: Colors.white,
              ),
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
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please login again.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF222222),
        title: const Text(
          'NGO Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};

          final name = data['name']?.toString() ?? '';
          final email = data['email']?.toString() ?? user.email ?? '';
          final phone = data['phone']?.toString() ?? '';
          final location = data['location']?.toString() ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                Container(
                  width: 95,
                  height: 95,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE5E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 50,
                    color: Color(0xFFE85D4A),
                  ),
                ),

                const SizedBox(height: 15),

                Text(
                  name.isEmpty ? 'NGO Name' : name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email.isEmpty ? 'Email not available' : email,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),

                const SizedBox(height: 28),

                profileInfo(Icons.person_outline, 'Name', name),

                const SizedBox(height: 12),

                profileInfo(Icons.email_outlined, 'Email', email),

                const SizedBox(height: 12),

                profileInfo(Icons.phone_outlined, 'Phone', phone),

                const SizedBox(height: 12),

                profileInfo(Icons.location_on_outlined, 'Location', location),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            currentName: name,
                            currentEmail: email,
                            currentPhone: phone,
                            currentLocation: location,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85D4A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => logout(context),
                    icon: const Icon(Icons.logout, color: Color(0xFFE85D4A)),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Color(0xFFE85D4A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE85D4A)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget profileInfo(IconData icon, String title, String value) {
    final displayValue = value.trim().isEmpty ? 'Not added' : value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE9E5),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: const Color(0xFFE85D4A)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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
