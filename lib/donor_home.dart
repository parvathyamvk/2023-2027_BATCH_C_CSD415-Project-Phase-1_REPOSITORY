import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'donation_form.dart';
import 'my_donations.dart';
import 'login_screen.dart';
import 'edit_profile.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: Text(
          selectedIndex == 0 ? 'Donor Dashboard' : 'Profile',
          style: const TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: selectedIndex == 0
            ? [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF333333),
                  ),
                ),
              ]
            : null,
      ),

      body: selectedIndex == 0
          ? const DonorDashboardContent()
          : const DonorProfileScreen(),

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 5,
        selectedIndex: selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home,
              color: Color(0xFFE85D4A),
            ),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(
              Icons.person,
              color: Color(0xFFE85D4A),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DONOR DASHBOARD
// ============================================================

class DonorDashboardContent extends StatelessWidget {
  const DonorDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello, Donor 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your contribution can make a difference.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 25),

          // SHARE FOOD
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DonationFormScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE85D4A),
                    Color(0xFF9A6BFF),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.volunteer_activism,
                    color: Colors.white,
                    size: 38,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Have extra food?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Share it with someone who needs it.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DonationFormScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFE85D4A),
                    ),
                    child: const Text(
                      'Share Food',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            'Your Activity',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          // LIVE FIRESTORE COUNTS
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: user == null
                ? null
                : FirebaseFirestore.instance
                    .collection('donations')
                    .where('donorId', isEqualTo: user.uid)
                    .snapshots(),
            builder: (context, snapshot) {
              int donationCount = 0;
              int completedCount = 0;

              if (snapshot.hasData) {
                final donations = snapshot.data!.docs;
                donationCount = donations.length;

                completedCount = donations.where((doc) {
                  final status = doc.data()['status'];
                  return status == 'Delivered' || status == 'Completed';
                }).length;
              }

              return Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.volunteer_activism,
                      number: donationCount.toString(),
                      label: 'Donations',
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: StatCard(
                      icon: Icons.check_circle_outline,
                      number: completedCount.toString(),
                      label: 'Completed',
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          ActionCard(
            icon: Icons.add_circle_outline,
            title: 'New Donation',
            subtitle: 'Share food with someone in need.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DonationFormScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          ActionCard(
            icon: Icons.history,
            title: 'My Donations',
            subtitle: 'View your previous donations.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyDonationsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          ActionCard(
            icon: Icons.location_on_outlined,
            title: 'Track Donation',
            subtitle: 'See the status of your donation.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DonationTrackingScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE SCREEN - LOADS REAL USER DATA
// ============================================================

class DonorProfileScreen extends StatefulWidget {
  const DonorProfileScreen({super.key});

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please login again.'),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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
                  Icons.person,
                  size: 55,
                  color: Color(0xFFE85D4A),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                name.isEmpty ? 'Your Name' : name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                email.isEmpty ? 'Email not available' : email,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 30),

              ProfileOption(
                icon: Icons.person_outline,
                title: 'Personal Information',
                subtitle: 'View and edit your details.',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PersonalInformationScreen(
                        name: name,
                        email: email,
                        phone: phone,
                        location: location,
                      ),
                    ),
                  );

                  if (result == true && context.mounted) {
                    setState(() {});
                  }
                },
              ),

              const SizedBox(height: 12),

              ProfileOption(
                icon: Icons.history,
                title: 'My Donations',
                subtitle: 'View your donation history.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyDonationsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              ProfileOption(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Manage your account settings.',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DonorSettingsScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showLogoutDialog(context);
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: Color(0xFFE85D4A),
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Color(0xFFE85D4A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFE85D4A),
                    ),
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
    );
  }
}

// ============================================================
// PERSONAL INFORMATION
// ============================================================
class PersonalInformationScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String location;

  const PersonalInformationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
  });

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState
    extends State<PersonalInformationScreen> {
  Future<void> openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentName: widget.name,
          currentEmail: widget.email,
          currentPhone: widget.phone,
          currentLocation: widget.location,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Personal Information',
          style: TextStyle(
            color: Color(0xFF222222),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color(0xFF222222),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            infoTile(Icons.person_outline, 'Name', widget.name),
            const SizedBox(height: 12),
            infoTile(Icons.email_outlined, 'Email', widget.email),
            const SizedBox(height: 12),
            infoTile(Icons.phone_outlined, 'Phone', widget.phone),
            const SizedBox(height: 12),
            infoTile(
              Icons.location_on_outlined,
              'Location',
              widget.location,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: openEditProfile,
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Edit Information',
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
          ],
        ),
      ),
    );
  }

  Widget infoTile(
    IconData icon,
    String title,
    String value,
  ) {
    final displayValue = value.trim().isEmpty ? 'Not added' : value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
            child: Icon(
              icon,
              color: const Color(0xFFE85D4A),
            ),
          ),
          const SizedBox(width: 14),
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

// ============================================================
// PROFILE OPTION
// ============================================================

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ProfileOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(18),

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Row(
            children: [

              Container(
                width: 48,
                height: 48,

                decoration:
                    BoxDecoration(
                  color: const Color(
                    0xFFFFE9E5,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: Icon(
                  icon,
                  color:
                      const Color(0xFFE85D4A),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      title,
                      style:
                          const TextStyle(
                        fontSize: 15,
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
                        fontSize: 12,
                      ),
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
        ),
      ),
    );
  }
}

// ============================================================
// STAT CARD
// ============================================================

class StatCard extends StatelessWidget {
  final IconData icon;
  final String number;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.number,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Icon(
            icon,
            color:
                const Color(0xFFE85D4A),
            size: 28,
          ),

          const SizedBox(height: 12),

          Text(
            number,
            style:
                const TextStyle(
              color:
                  Color(0xFFE85D4A),
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTION CARD
// ============================================================

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,

        borderRadius:
            BorderRadius.circular(18),

        child: Padding(
          padding:
              const EdgeInsets.all(16),

          child: Row(
            children: [

              Container(
                width: 50,
                height: 50,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(0xFFFFE9E5),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: Icon(
                  icon,
                  color:
                      const Color(0xFFE85D4A),
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
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATIONS
// ============================================================

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        title: const Text(
          'Notifications',
        ),
        backgroundColor:
            Colors.white,
        elevation: 0,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.notifications_none_rounded,
              size: 70,
              color: Color(0xFFE85D4A),
            ),

            const SizedBox(height: 15),

            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'We will show important updates here.',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class DonorSettingsScreen
    extends StatelessWidget {
  const DonorSettingsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFFFF8F2),

      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor:
            Colors.white,
        elevation: 0,
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(20),

        children: [

          settingItem(
            context,
            Icons.notifications_outlined,
            'Notifications',
            'Manage notifications',
          ),

          settingItem(
            context,
            Icons.lock_outline,
            'Privacy',
            'Manage privacy settings',
          ),

          settingItem(
            context,
            Icons.info_outline,
            'About SharePlate',
            'Learn more about the app',
          ),
        ],
      ),
    );
  }

  Widget settingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: ListTile(
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                '$title will be available soon.',
              ),
            ),
          );
        },

        leading: Container(
          padding:
              const EdgeInsets.all(10),

          decoration:
              BoxDecoration(
            color:
                const Color(0xFFFFE9E5),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),

          child: Icon(
            icon,
            color:
                const Color(0xFFE85D4A),
          ),
        ),

        title: Text(
          title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        subtitle:
            Text(subtitle),

        trailing:
            const Icon(
          Icons.arrow_forward_ios,
          size: 15,
        ),
      ),
    );
  }
}

// ============================================================
// LOGOUT
// ============================================================

Future<void> showLogoutDialog(
  BuildContext context,
) async {
  final shouldLogout =
      await showDialog<bool>(
    context: context,

    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Logout?',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        content: const Text(
          'Are you sure you want to logout?',
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },

            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },

            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFFE85D4A),
              foregroundColor:
                  Colors.white,
            ),

            child: const Text(
              'Logout',
            ),
          ),
        ],
      );
    },
  );

  if (shouldLogout != true) {
    return;
  }

  final prefs =
      await SharedPreferences.getInstance();

  await prefs.setBool(
    'isLoggedIn',
    false,
  );

  if (!context.mounted) return;

  Navigator.pushAndRemoveUntil(
    context,

    MaterialPageRoute(
      builder: (context) =>
          const LoginScreen(),
    ),

    (route) => false,
  );
}

// ============================================================
// TRACK DONATION
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
        backgroundColor:
            Colors.white,
        elevation: 0,

        title: const Text(
          'Track Donation',
          style: TextStyle(
            color: Color(0xFF222222),
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
              icon:
                  Icons.check_circle,
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
              title:
                  'Picked Up',
              subtitle:
                  'Food collected from donor.',
              completed: false,
            ),

            trackingLine(),

            trackingStep(
              icon:
                  Icons.volunteer_activism,
              title:
                  'Delivered',
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