import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final Color primary = const Color(0xFFE85D4A);
  final Color background = const Color(0xFFFFF8F2);

  String selectedFilter = 'All';

  bool matchesFilter(Map<String, dynamic> data) {
    if (selectedFilter == 'All') return true;

    final role = data['role']?.toString().toLowerCase() ?? '';

    return role == selectedFilter.toLowerCase();
  }

  String roleText(dynamic role) {
    final value = role?.toString().trim() ?? '';

    if (value.isEmpty || value == 'null') {
      return 'No role';
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  Color roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'donor':
        return const Color(0xFFE85D4A);
      case 'ngo':
        return const Color(0xFF4F7CAC);
      case 'volunteer':
        return const Color(0xFF6C8E5E);
      case 'receiver':
        return const Color(0xFF8E6BBE);
      case 'admin':
        return const Color(0xFF333333);
      default:
        return Colors.grey;
    }
  }

  Future<void> deleteUserProfile(
    String userId,
    String userName,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (userId == currentUser?.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You cannot delete your own admin account here.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete User?'),
          content: Text(
            'Delete the Firestore profile for "$userName"?\n\n'
            'This deletes the user profile document only. '
            'The Firebase Authentication account is not deleted here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile deleted successfully.'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: ${e.message ?? e.code}',
          ),
        ),
      );
    }
  }

  Widget statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: primary,
                size: 23,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    final displayValue =
        value.isEmpty ? 'Not provided' : value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 9),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            displayValue,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget userCard(
    String userId,
    Map<String, dynamic> data,
  ) {
    final name = data['name']?.toString().trim() ?? '';
    final email = data['email']?.toString().trim() ?? '';
    final phone = data['phone']?.toString().trim() ?? '';
    final location =
        data['location']?.toString().trim() ?? '';

    final role = roleText(data['role']);

    final displayName =
        name.isEmpty ? 'Unnamed User' : name;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: primary.withOpacity(0.12),
                child: Icon(
                  Icons.person,
                  color: primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty
                          ? 'No email'
                          : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                  color: roleColor(role).withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    color: roleColor(role),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),
          const Divider(height: 1),
          const SizedBox(height: 12),

          detailRow(
            Icons.phone_outlined,
            'Phone',
            phone,
          ),

          const SizedBox(height: 9),

          detailRow(
            Icons.location_on_outlined,
            'Location',
            location,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AdminUserDetailsScreen(
                            userId: userId,
                            userData: data,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.manage_accounts_outlined,
                      size: 19,
                    ),
                    label: const Text(
                      'Manage Details',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    deleteUserProfile(
                      userId,
                      displayName,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(
                      color: primary.withOpacity(0.45),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              final prefs =
                  await SharedPreferences.getInstance();

              await prefs.clear();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFF222222),
            ),
          ),
        ],
      ),

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: usersStream,

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load users.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final users = docs.where((doc) {
            return matchesFilter(doc.data());
          }).toList();

          int donors = 0;
          int ngos = 0;
          int volunteers = 0;
          int receivers = 0;
          int admins = 0;

          for (final doc in docs) {
            final role = doc
                .data()['role']
                ?.toString()
                .toLowerCase();

            switch (role) {
              case 'donor':
                donors++;
                break;

              case 'ngo':
                ngos++;
                break;

              case 'volunteer':
                volunteers++;
                break;

              case 'receiver':
                receivers++;
                break;

              case 'admin':
                admins++;
                break;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});

              await Future<void>.delayed(
                const Duration(milliseconds: 300),
              );
            },

            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                30,
              ),

              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Welcome, Administrator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Manage SharePlate users and monitor the platform.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    statCard(
                      'Total Users',
                      '${docs.length}',
                      Icons.people_alt_outlined,
                    ),
                    const SizedBox(width: 12),
                    statCard(
                      'Donors',
                      '$donors',
                      Icons.volunteer_activism_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    statCard(
                      'NGOs',
                      '$ngos',
                      Icons.business_outlined,
                    ),
                    const SizedBox(width: 12),
                    statCard(
                      'Volunteers',
                      '$volunteers',
                      Icons.delivery_dining_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    statCard(
                      'Receivers',
                      '$receivers',
                      Icons.groups_outlined,
                    ),
                    const SizedBox(width: 12),
                    statCard(
                      'Admins',
                      '$admins',
                      Icons.admin_panel_settings_outlined,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'Manage Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'View profiles and complete activity history.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      'Donor',
                      'NGO',
                      'Volunteer',
                      'Receiver',
                      'Admin',
                    ].map((filter) {
                      final selected =
                          selectedFilter == filter;

                      return Padding(
                        padding:
                            const EdgeInsets.only(right: 8),

                        child: ChoiceChip(
                          label: Text(filter),
                          selected: selected,
                          selectedColor: primary,

                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF333333),
                            fontWeight:
                                FontWeight.w600,
                          ),

                          onSelected: (_) {
                            setState(() {
                              selectedFilter = filter;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 18),

                if (users.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No users found',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'There are no users in this category.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...users.map(
                    (doc) => userCard(
                      doc.id,
                      doc.data(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ============================================================
// ADMIN USER DETAILS SCREEN
// ============================================================

class AdminUserDetailsScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const AdminUserDetailsScreen({
    super.key,
    required this.userId,
    required this.userData,
  });

  @override
  State<AdminUserDetailsScreen> createState() =>
      _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState
    extends State<AdminUserDetailsScreen> {
  final Color primary = const Color(0xFFE85D4A);
  final Color background = const Color(0xFFFFF8F2);

  late Future<Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
      historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = loadHistory();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      getCollection(
    String collection,
    String field,
  ) async {
    final result = await FirebaseFirestore.instance
        .collection(collection)
        .where(
          field,
          isEqualTo: widget.userId,
        )
        .get();

    return result.docs;
  }

  Future<Map<String,
          List<QueryDocumentSnapshot<Map<String, dynamic>>>>>
      loadHistory() async {
    final role =
        widget.userData['role']
            ?.toString()
            .toLowerCase() ??
        '';

    final Map<String,
            List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        result = {};

    if (role == 'donor') {
      result['Donations'] =
          await getCollection(
        'donations',
        'donorId',
      );

      result['Allocations'] =
          await getCollection(
        'allocations',
        'donorId',
      );
    }

    if (role == 'volunteer') {
      result['Volunteer Tasks'] =
          await getCollection(
        'volunteer_tasks',
        'volunteerId',
      );

      result['Allocations'] =
          await getCollection(
        'allocations',
        'volunteerId',
      );

      result['Donations / Pickup Records'] =
          await getCollection(
        'donations',
        'volunteerId',
      );
    }

    if (role == 'ngo') {
      result['Allocations Created'] =
          await getCollection(
        'allocations',
        'ngoId',
      );

      result['Receiver Requests'] =
          await getCollection(
        'receiver_requests',
        'ngoId',
      );

      result['Accepted Donations'] =
          await getCollection(
        'donations',
        'acceptedBy',
      );
    }

    if (role == 'receiver') {
      result['Receiver Requests'] =
          await getCollection(
        'receiver_requests',
        'receiverId',
      );

      result['Allocations'] =
          await getCollection(
        'allocations',
        'receiverId',
      );
    }

    if (role == 'admin') {
      result['Admin Profile'] = [];
    }

    return result;
  }

  String formatValue(dynamic value) {
    if (value == null) {
      return 'Not available';
    }

    if (value is Timestamp) {
      final date = value.toDate();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year} '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }

    if (value is GeoPoint) {
      return '${value.latitude}, ${value.longitude}';
    }

    if (value is DocumentReference) {
      return value.path;
    }

    if (value is List) {
      return value.join(', ');
    }

    if (value is Map) {
      return value.toString();
    }

    return value.toString();
  }

  String prettyFieldName(String field) {
    final formatted = field
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) {
            return '${match.group(1)} ${match.group(2)}';
          },
        )
        .replaceAll('_', ' ');

    if (formatted.isEmpty) {
      return formatted;
    }

    return formatted[0].toUpperCase() +
        formatted.substring(1);
  }

  Widget infoCard(
    String title,
    dynamic value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatValue(value),
                  style: const TextStyle(
                    fontSize: 14,
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

  Widget recordCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    primary.withOpacity(0.10),
                child: Icon(
                  Icons.description_outlined,
                  color: primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Record',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                doc.id.length > 10
                    ? '${doc.id.substring(0, 10)}...'
                    : doc.id,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1),

          const SizedBox(height: 10),

          ...data.entries.map(
            (entry) {
              return Padding(
                padding:
                    const EdgeInsets.only(bottom: 9),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 105,
                      child: Text(
                        prettyFieldName(entry.key),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatValue(entry.value),
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget historySection(
    String title,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>
        records,
  ) {
    if (records.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 38,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No $title found',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                '${records.length}',
                style: TextStyle(
                  color: primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...records.map(
          (doc) => recordCard(doc),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.userData['name']?.toString() ?? '';

    final email =
        widget.userData['email']?.toString() ?? '';

    final phone =
        widget.userData['phone']?.toString() ?? '';

    final location =
        widget.userData['location']?.toString() ?? '';

    final role =
        widget.userData['role']?.toString() ?? '';

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Manage User',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: FutureBuilder<
          Map<String,
              List<QueryDocumentSnapshot<
                  Map<String, dynamic>>>> >(
        future: historyFuture,

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Unable to load user history.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final history =
              snapshot.data ?? {};

          return ListView(
            padding: const EdgeInsets.all(20),

            children: [
              // ==========================================
              // USER HEADER
              // ==========================================

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius:
                      BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor:
                          Colors.white,
                      child: Icon(
                        Icons.person,
                        color: primary,
                        size: 35,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty
                                ? 'Unnamed User'
                                : name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            role.isEmpty
                                ? 'No role'
                                : role
                                    .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // BASIC INFORMATION
              // ==========================================

              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              infoCard(
                'Email',
                email,
                Icons.email_outlined,
              ),

              infoCard(
                'Phone',
                phone,
                Icons.phone_outlined,
              ),

              infoCard(
                'Location',
                location,
                Icons.location_on_outlined,
              ),

              infoCard(
                'Role',
                role,
                Icons.badge_outlined,
              ),

              const SizedBox(height: 18),

              // ==========================================
              // ACTIVITY HISTORY
              // ==========================================

              const Text(
                'Activity History',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Previous records and activities performed by this user.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 18),

              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 45,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No activity records found.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...history.entries.map(
                  (entry) => historySection(
                    entry.key,
                    entry.value,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}