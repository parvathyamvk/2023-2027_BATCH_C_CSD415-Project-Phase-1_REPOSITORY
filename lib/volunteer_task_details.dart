import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VolunteerTaskDetailsScreen extends StatelessWidget {
  final String taskId;

  const VolunteerTaskDetailsScreen({
    super.key,
    required this.taskId,
  });

  Future<void> updatePickupStatus(
    BuildContext context,
    String newStatus,
    Map<String, dynamic> task,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final updateData = <String, dynamic>{
        'pickupStatus': newStatus,
      };

      if (newStatus == 'Picked Up') {
        updateData['pickedUpAt'] = FieldValue.serverTimestamp();
        updateData['deliveryStatus'] = 'Pickup Completed';
      }

      if (newStatus == 'In Transit') {
        updateData['inTransitAt'] = FieldValue.serverTimestamp();
        updateData['deliveryStatus'] = 'In Transit';
      }

      if (newStatus == 'Delivered') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
        updateData['deliveryStatus'] = 'Delivered';
      }

      // Update the volunteer task first.
      await firestore
          .collection('volunteer_tasks')
          .doc(taskId)
          .update(updateData);

      // -------------------------------------------------------
      // When delivered:
      // 1. Update the original donation.
      // 2. Update the allocation.
      //
      // We also write volunteerId to the donation so the
      // Firestore rule can verify that this volunteer owns
      // the delivery.
      // -------------------------------------------------------
      if (newStatus == 'Delivered') {
        final donationId = task['donationId']?.toString();
        final allocationId = task['allocationId']?.toString();
        final volunteerId = task['volunteerId']?.toString();

        if (donationId != null &&
            donationId.isNotEmpty &&
            volunteerId != null &&
            volunteerId.isNotEmpty) {
          await firestore
              .collection('donations')
              .doc(donationId)
              .update({
            'status': 'Delivered',
            'volunteerId': volunteerId,
            'deliveredAt': FieldValue.serverTimestamp(),
          });
        }

        if (allocationId != null && allocationId.isNotEmpty) {
          await firestore
              .collection('allocations')
              .doc(allocationId)
              .update({
            'status': 'Delivered',
            'volunteerId': volunteerId,
            'deliveredAt': FieldValue.serverTimestamp(),
          });
        }

        // Mark the receiver request as delivered only when the
        // request has been completely fulfilled.
        final requestId = task['requestId']?.toString();

        if (requestId != null && requestId.isNotEmpty) {
          final requestSnapshot = await firestore
              .collection('receiver_requests')
              .doc(requestId)
              .get();

          if (requestSnapshot.exists) {
            final requestData = requestSnapshot.data() ?? {};

            final remainingValue = requestData['remainingQuantity'];
            final requiredValue = requestData['quantityRequired'];
            final allocatedValue = requestData['allocatedQuantity'];

            final remaining = remainingValue is num
                ? remainingValue.toInt()
                : int.tryParse(remainingValue?.toString() ?? '');

            final required = requiredValue is num
                ? requiredValue.toInt()
                : int.tryParse(requiredValue?.toString() ?? '');

            final allocated = allocatedValue is num
                ? allocatedValue.toInt()
                : int.tryParse(allocatedValue?.toString() ?? '');

            // Older requests may not contain remainingQuantity.
            final fullyAllocated = remaining != null
                ? remaining <= 0
                : (required != null &&
                    allocated != null &&
                    allocated >= required);

            if (fullyAllocated) {
              await firestore
                  .collection('receiver_requests')
                  .doc(requestId)
                  .update({
                'status': 'Delivered',
                'deliveredAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to update status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text(
          'Pickup & Delivery',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFEF5B4D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: firestoreStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFEF5B4D),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load task.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Pickup task not found.'),
            );
          }

          final task =
              snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _routeHeader(task),
              const SizedBox(height: 22),
              const Text(
                'Donation Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _detailsCard(task),
              const SizedBox(height: 24),
              const Text(
                'Delivery Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              _trackingTimeline(task),
              const SizedBox(height: 24),
              _nextActionButton(context, task),
            ],
          );
        },
      ),
    );
  }

  Stream<DocumentSnapshot> firestoreStream() {
    return FirebaseFirestore.instance
        .collection('volunteer_tasks')
        .doc(taskId)
        .snapshots();
  }

  Widget _routeHeader(Map<String, dynamic> task) {
    final status = task['pickupStatus']?.toString() ?? 'Assigned';

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          const Text(
            'Donor → Receiver',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            status == 'Delivered'
                ? 'Delivery completed successfully.'
                : 'Follow each step until the food reaches the receiver.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(Map<String, dynamic> task) {
    final donorName = task['donorName']?.toString() ?? 'Donor';
    final donorAddress =
        task['donorPickupAddress']?.toString() ??
            task['pickupLocation']?.toString() ??
            '-';

    final receiverName =
        task['receiverCommunityName']?.toString() ?? 'Receiver';
    final receiverAddress =
        task['receiverAddress']?.toString() ?? '-';

    return Column(
      children: [
        _sectionCard(
          icon: Icons.storefront_outlined,
          title: 'PICKUP FROM DONOR',
          name: donorName,
          address: donorAddress,
          extraRows: [
            _detailRow(
              Icons.calendar_today_outlined,
              'Pickup Date',
              task['pickupDate']?.toString() ?? '-',
            ),
            _detailRow(
              Icons.access_time,
              'Pickup Time',
              task['pickupTime']?.toString() ?? '-',
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Center(
          child: Icon(
            Icons.arrow_downward_rounded,
            color: Color(0xFFEF5B4D),
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          icon: Icons.groups_outlined,
          title: 'DELIVER TO RECEIVER',
          name: receiverName,
          address: receiverAddress,
          extraRows: [
            _detailRow(
              Icons.person_outline,
              'Contact Person',
              task['receiverContactPerson']?.toString() ?? '-',
            ),
            _detailRow(
              Icons.phone_outlined,
              'Phone',
              task['receiverPhone']?.toString() ?? '-',
            ),
            _detailRow(
              Icons.location_city_outlined,
              'District',
              task['receiverDistrict']?.toString() ?? '-',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              _detailRow(
                Icons.restaurant,
                'Food',
                task['foodName']?.toString() ?? 'Food donation',
              ),
              _detailRow(
                Icons.category_outlined,
                'Food Type',
                task['foodType']?.toString() ?? '-',
              ),
              _detailRow(
                Icons.inventory_2_outlined,
                'Quantity',
                '${task['quantity'] ?? '-'} ${task['unit'] ?? 'Meals'}',
              ),
              _detailRow(
                Icons.event_busy_outlined,
                'Expiry',
                '${task['expiryDate'] ?? '-'} ${task['expiryTime'] ?? ''}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String name,
    required String address,
    required List<Widget> extraRows,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9E5),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFEF5B4D),
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      address,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...extraRows,
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 0),
          Icon(
            icon,
            color: const Color(0xFFEF5B4D),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackingTimeline(Map<String, dynamic> task) {
    final status = task['pickupStatus']?.toString() ?? 'Assigned';

    const statuses = [
      'Assigned',
      'Picked Up',
      'In Transit',
      'Delivered',
    ];

    int currentIndex = statuses.indexOf(status);

    if (currentIndex < 0) {
      currentIndex = 0;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: List.generate(
          statuses.length,
          (index) {
            final completed = index <= currentIndex;
            final isLast = index == statuses.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed
                            ? const Color(0xFFEF5B4D)
                            : Colors.grey.shade200,
                      ),
                      child: Icon(
                        completed
                            ? Icons.check
                            : Icons.circle_outlined,
                        size: 19,
                        color: completed
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 45,
                        color: index < currentIndex
                            ? const Color(0xFFEF5B4D)
                            : Colors.grey.shade300,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    statuses[index],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: index == currentIndex
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: completed
                          ? Colors.black87
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _nextActionButton(
    BuildContext context,
    Map<String, dynamic> task,
  ) {
    final status = task['pickupStatus']?.toString() ?? 'Assigned';

    String? nextStatus;
    String buttonText;
    IconData icon;

    if (status == 'Assigned') {
      nextStatus = 'Picked Up';
      buttonText = 'Mark as Picked Up';
      icon = Icons.inventory_2;
    } else if (status == 'Picked Up') {
      nextStatus = 'In Transit';
      buttonText = 'Start Delivery';
      icon = Icons.local_shipping;
    } else if (status == 'In Transit') {
      nextStatus = 'Delivered';
      buttonText = 'Mark as Delivered';
      icon = Icons.check_circle;
    } else {
      nextStatus = null;
      buttonText = 'Delivery Completed';
      icon = Icons.verified;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: nextStatus == null
            ? null
            : () {
                updatePickupStatus(
                  context,
                  nextStatus!,
                  task,
                );
              },
        icon: Icon(icon),
        label: Text(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF5B4D),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.green.shade100,
          disabledForegroundColor: Colors.green.shade700,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
