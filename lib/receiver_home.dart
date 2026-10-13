import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

const Color receiverCoral = Color(0xFFE85D4A);
const Color receiverLight = Color(0xFFFFF8F2);

class ReceiverHomeScreen extends StatelessWidget {
  const ReceiverHomeScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout?'),
          content: const Text(
            'Are you sure you want to logout of SharePlate?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: receiverCoral,
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
    await prefs.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please login to continue.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: receiverLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Receiver Dashboard',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReceiverProfileScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF333333),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() ?? {};
          final name = data['name']?.toString().trim() ?? '';
          final communityName =
              data['communityName']?.toString().trim() ?? '';
          final address = data['address']?.toString().trim() ?? '';
          final district = data['district']?.toString().trim() ?? '';

          final displayName = communityName.isNotEmpty
              ? communityName
              : (name.isNotEmpty ? name : 'Your Community');

          final profileComplete = communityName.isNotEmpty &&
              data['contactPerson']?.toString().trim().isNotEmpty == true &&
              data['phone']?.toString().trim().isNotEmpty == true &&
              address.isNotEmpty &&
              district.isNotEmpty;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('receiver_requests')
                .where('receiverId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, requestSnapshot) {
              final requests = requestSnapshot.data?.docs ?? [];
              final requestCount = requests.length;


              return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to SharePlate 👋',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  communityName.isEmpty
                      ? 'Set up your community profile to request food.'
                      : 'Hello $displayName, request food for your community.',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 22),

                // PROFILE STATUS
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: receiverCoral.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: receiverCoral.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: receiverCoral,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileComplete
                                  ? 'Community profile ready'
                                  : 'Complete your community profile',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profileComplete
                                  ? '$address${district.isNotEmpty ? ', $district' : ''}'
                                  : 'Add contact and location details before requesting food.',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12.5,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit profile',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ReceiverProfileScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: receiverCoral,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // MAIN CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        receiverCoral,
                        Color(0xFFFF8A78),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Food Requests',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Get food support for your community.',
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
                        child: Text(
                          '$requestCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Your Activity',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('allocations')
                      .where('receiverId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'Delivered')
                      .snapshots(),
                  builder: (context, allocationSnapshot) {
                    final receivedCount =
                        allocationSnapshot.data?.docs.length ?? 0;

                    return Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            Icons.restaurant_outlined,
                            'Food Requests',
                            '$requestCount',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            Icons.volunteer_activism_outlined,
                            'Food Received',
                            '$receivedCount',
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                const Text(
                  'Food Deliveries',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Food matched to your community will appear here with its delivery status.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),

                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('allocations')
                      .where('receiverId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (context, allocationSnapshot) {
                    if (allocationSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: receiverCoral,
                          ),
                        ),
                      );
                    }

                    if (allocationSnapshot.hasError) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Unable to load delivery information.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    final allocations = allocationSnapshot.data?.docs ?? [];

                    if (allocations.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 55,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'No matched food yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Food matched to your community by SharePlate will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: allocations.map((doc) {
                        final allocation = doc.data();
                        final foodName =
                            allocation['foodName']?.toString() ??
                                'Food Donation';
                        final quantity =
                            allocation['allocatedQuantity']?.toString() ??
                                '0';
                        final unit =
                            allocation['unit']?.toString() ?? 'Meals';
                        final donorName =
                            allocation['donorName']?.toString() ?? 'Donor';
                        final status =
                            allocation['status']?.toString() ?? 'Allocated';

                        final isDelivered = status == 'Delivered';

                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(17),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDelivered
                                  ? const Color(0xFFBFE8CC)
                                  : receiverCoral.withOpacity(0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isDelivered
                                          ? const Color(0xFFEAF8EE)
                                          : const Color(0xFFFFE9E5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isDelivered
                                          ? Icons.check_circle_outline
                                          : Icons.local_shipping_outlined,
                                      color: isDelivered
                                          ? const Color(0xFF2E8B57)
                                          : receiverCoral,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          foodName,
                                          style: const TextStyle(
                                            fontSize: 16,
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDelivered
                                          ? const Color(0xFFEAF8EE)
                                          : const Color(0xFFFFE9E5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        color: isDelivered
                                            ? const Color(0xFF2E8B57)
                                            : receiverCoral,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _deliveryInfoRow(
                                Icons.volunteer_activism_outlined,
                                'Donor',
                                donorName,
                              ),
                              if ((allocation['receiverAddress']
                                          ?.toString() ??
                                      '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _deliveryInfoRow(
                                  Icons.location_on_outlined,
                                  'Delivery Address',
                                  allocation['receiverAddress']
                                      .toString(),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (!profileComplete) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ReceiverProfileScreen(),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please complete your community profile first.',
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReceiverFoodRequestScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(
                      profileComplete
                          ? 'Request Food'
                          : 'Complete Profile',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: receiverCoral,
                      foregroundColor: Colors.white,
                      elevation: 0,
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

  static Widget _deliveryInfoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 19,
          color: receiverCoral,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _statCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.restaurant_outlined,
            color: receiverCoral,
            size: 26,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// RECEIVER PROFILE
// =====================================================

class ReceiverProfileScreen extends StatefulWidget {
  const ReceiverProfileScreen({super.key});

  @override
  State<ReceiverProfileScreen> createState() =>
      _ReceiverProfileScreenState();
}

class _ReceiverProfileScreenState extends State<ReceiverProfileScreen> {
  final communityNameController = TextEditingController();
  final contactPersonController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final districtController = TextEditingController();
  final peopleCountController = TextEditingController();

  String communityType = 'Community';
  double? latitude;
  double? longitude;

  bool loading = true;
  bool saving = false;
  bool gettingLocation = false;

  final List<String> communityTypes = [
    'Community',
    'Orphanage',
    'Old Age Home',
    'Shelter Home',
    'School',
    'College',
    'Hospital',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    communityNameController.dispose();
    contactPersonController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    districtController.dispose();
    peopleCountController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data() ?? {};

      communityNameController.text =
          data['communityName']?.toString() ?? '';
      contactPersonController.text =
          data['contactPerson']?.toString() ?? '';
      phoneController.text = data['phone']?.toString() ?? '';
      emailController.text =
          data['email']?.toString() ?? user.email ?? '';
      addressController.text = data['address']?.toString() ?? '';
      districtController.text = data['district']?.toString() ?? '';
      peopleCountController.text =
          data['peopleCount']?.toString() ?? '';

      final savedType = data['communityType']?.toString();
      if (savedType != null && communityTypes.contains(savedType)) {
        communityType = savedType;
      }

      latitude = _toDouble(data['latitude']);
      longitude = _toDouble(data['longitude']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load your profile.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> getCurrentLocation() async {
    setState(() {
      gettingLocation = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable GPS.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. Enable it from phone settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Current community location captured successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          gettingLocation = false;
        });
      }
    }
  }

  Future<void> saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final communityName = communityNameController.text.trim();
    final contactPerson = contactPersonController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final district = districtController.text.trim();
    final peopleCount = peopleCountController.text.trim();

    if (communityName.isEmpty ||
        contactPerson.isEmpty ||
        phone.isEmpty ||
        address.isEmpty ||
        district.isEmpty ||
        peopleCount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required community details.',
          ),
        ),
      );
      return;
    }

    if (int.tryParse(peopleCount) == null ||
        int.parse(peopleCount) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid number of people.',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'name': contactPerson,
          'email': emailController.text.trim().isEmpty
              ? (user.email ?? '')
              : emailController.text.trim(),
          'phone': phone,
          'location': address,
          'role': 'receiver',

          'communityName': communityName,
          'contactPerson': contactPerson,
          'communityType': communityType,
          'address': address,
          'district': district,
          'peopleCount': int.parse(peopleCount),
          'latitude': latitude,
          'longitude': longitude,

          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Community profile saved successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save profile. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: receiverLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF222222),
        title: const Text(
          'Community Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: receiverCoral,
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            receiverCoral,
                            Color(0xFFFF8A78),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            child: Icon(
                              Icons.groups_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Community Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'These details help SharePlate connect food to the right community. GPS location is optional.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    _sectionTitle('Community Information'),
                    const SizedBox(height: 12),

                    _field(
                      controller: communityNameController,
                      label: 'Community / Organization Name *',
                      hint: 'Eg. Hope Children Home',
                      icon: Icons.business_outlined,
                    ),

                    const SizedBox(height: 15),

                    _dropdown(),

                    const SizedBox(height: 15),

                    _field(
                      controller: peopleCountController,
                      label: 'Number of People *',
                      hint: 'Eg. 50',
                      icon: Icons.people_outline,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 25),

                    _sectionTitle('Contact Information'),
                    const SizedBox(height: 12),

                    _field(
                      controller: contactPersonController,
                      label: 'Contact Person *',
                      hint: 'Eg. Anitha Thomas',
                      icon: Icons.person_outline,
                    ),

                    const SizedBox(height: 15),

                    _field(
                      controller: phoneController,
                      label: 'Phone Number *',
                      hint: 'Eg. 9876543210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 15),

                    _field(
                      controller: emailController,
                      label: 'Email',
                      hint: 'Community email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 25),

                    _sectionTitle('Community Location'),
                    const SizedBox(height: 12),

                    _field(
                      controller: addressController,
                      label: 'Full Address *',
                      hint: 'House/building, street, town',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 15),

                    _field(
                      controller: districtController,
                      label: 'District *',
                      hint: 'Eg. Alappuzha',
                      icon: Icons.map_outlined,
                    ),

                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Location',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            latitude == null || longitude == null
                                ? 'Location not captured yet. You can add it now or later.'
                                : 'Latitude: ${latitude!.toStringAsFixed(6)}\nLongitude: ${longitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 13),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed:
                                  gettingLocation
                                      ? null
                                      : getCurrentLocation,
                              icon: gettingLocation
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: receiverCoral,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                      color: receiverCoral,
                                    ),
                              label: Text(
                                gettingLocation
                                    ? 'Getting Location...'
                                    : latitude == null
                                        ? 'Use Current Location'
                                        : 'Update Current Location',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: receiverCoral,
                                side: const BorderSide(
                                  color: receiverCoral,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: saving ? null : saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: receiverCoral,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: saving
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Save Community Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: receiverCoral,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Community Type *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: communityType,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
              ),
              items: communityTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  communityType = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}


// =====================================================
// RECEIVER FOOD REQUEST - STEP 2C
// =====================================================

class ReceiverFoodRequestScreen extends StatefulWidget {
  const ReceiverFoodRequestScreen({super.key});

  @override
  State<ReceiverFoodRequestScreen> createState() =>
      _ReceiverFoodRequestScreenState();
}

class _ReceiverFoodRequestScreenState
    extends State<ReceiverFoodRequestScreen> {
  final quantityController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedFoodType = 'Cooked Food';
  String selectedUnit = 'Meals';
  String selectedUrgency = 'Normal';

  bool saving = false;

  final List<String> foodTypes = [
    'Cooked Food',
    'Packaged Food',
    'Groceries',
    'Fruits',
    'Vegetables',
    'Bakery Items',
    'Other',
  ];

  final List<String> units = [
    'Meals',
    'Kg',
    'Packets',
    'Items',
  ];

  final List<String> urgencyLevels = [
    'Normal',
    'Urgent',
    'Critical',
  ];

  @override
  void dispose() {
    quantityController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    final quantityText = quantityController.text.trim();
    final description = descriptionController.text.trim();

    if (quantityText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the required quantity.'),
        ),
      );
      return;
    }

    final quantity = int.tryParse(quantityText);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid quantity greater than 0.'),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final profileSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final profile = profileSnapshot.data() ?? {};

      final communityName =
          profile['communityName']?.toString().trim() ?? '';
      final contactPerson =
          profile['contactPerson']?.toString().trim() ?? '';
      final phone = profile['phone']?.toString().trim() ?? '';
      final address = profile['address']?.toString().trim() ?? '';
      final district = profile['district']?.toString().trim() ?? '';

      if (communityName.isEmpty ||
          contactPerson.isEmpty ||
          phone.isEmpty ||
          address.isEmpty ||
          district.isEmpty) {
        if (!mounted) return;

        setState(() {
          saving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please complete your community profile before requesting food.',
            ),
          ),
        );
        return;
      }

      final requestRef = FirebaseFirestore.instance
          .collection('receiver_requests')
          .doc();

      await requestRef.set({
        'receiverId': user.uid,
        'communityName': communityName,
        'contactPerson': contactPerson,
        'phone': phone,
        'email': profile['email']?.toString() ?? user.email ?? '',
        'address': address,
        'district': district,

        'latitude': profile['latitude'],
        'longitude': profile['longitude'],

        'foodType': selectedFoodType,
        'quantityRequired': quantity,
        'unit': selectedUnit,
        'urgency': selectedUrgency,
        'description': description,

        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'Pending',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Food request submitted successfully.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not submit request: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: receiverLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF222222),
        title: const Text(
          'Request Food',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      receiverCoral,
                      Color(0xFFFF8A78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.restaurant_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Food Support Request',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Tell us what your community needs.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Food Requirement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _label('Food Type'),
              _dropdown(
                value: selectedFoodType,
                items: foodTypes,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedFoodType = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              _label('Quantity Required *'),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Eg. 300',
                  prefixIcon: const Icon(Icons.numbers_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: receiverCoral,
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _label('Unit'),
              _dropdown(
                value: selectedUnit,
                items: units,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedUnit = value;
                  });
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Urgency',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _dropdown(
                value: selectedUrgency,
                items: urgencyLevels,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedUrgency = value;
                  });
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _label('Description'),
              TextField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Eg. We need food for children attending our community programme.',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 65),
                    child: Icon(Icons.notes_outlined),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: receiverCoral,
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: receiverCoral,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your community address and contact details will automatically be attached to this request. If GPS was saved in your profile, it will also be included.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: saving ? null : submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: receiverCoral,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Food Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
