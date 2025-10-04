import 'package:flutter/material.dart';
import 'package:car_platform/pages/ProviderPages/provider_log_service_page.dart';


class ProviderHomePage extends StatelessWidget {
  final String providerId;

  const ProviderHomePage({super.key, required this.providerId});

  @override
  Widget build(BuildContext context) {
    final quickActions = [
      {
        "title": "Bookings",
        "icon": Icons.calendar_month,
        "color": Colors.blueAccent,
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Bookings section coming soon...")),
          );
        },
      },
      {
        "title": "Service Logs",
        "icon": Icons.check_circle_outline,
        "color": Colors.green,
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderLogServicePage(providerId: providerId),
            ),
          );
        },
      },
      {
        "title": "Earnings",
        "icon": Icons.attach_money,
        "color": Colors.orange,
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Earnings view coming soon...")),
          );
        },
      },
      {
        "title": "History",
        "icon": Icons.history,
        "color": Colors.purple,
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("History view coming soon...")),
          );
        },
      },
      {
        "title": "Analytics",
        "icon": Icons.bar_chart_outlined,
        "color": Colors.indigo,
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Analytics dashboard coming soon...")),
          );
        },
      },
      {
        "title": "Settings",
        "icon": Icons.settings_outlined,
        "color": Colors.grey,
        "onTap": () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Settings coming soon...")),
          );
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Notifications feature coming soon")),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // In future: refresh provider stats
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider welcome section
              const Text(
                "Welcome Back 👋",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Manage your garage, bookings, and services all in one place.",
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Summary cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard("Today's Profit", "KES 12,400", Icons.trending_up, Colors.green),
                  _buildSummaryCard("Bookings", "8 Active", Icons.calendar_today, Colors.blue),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryCard("Pending Tasks", "3", Icons.list_alt_outlined, Colors.orange),
                  _buildSummaryCard("Customer Rating", "4.8 ★", Icons.star_rate_rounded, Colors.amber),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Grid for actions
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: quickActions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final action = quickActions[index];
                  return _buildActionCard(
                    title: action["title"] as String,
                    icon: action["icon"] as IconData,
                    color: action["color"] as Color,
                    onTap: action["onTap"] as VoidCallback,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
