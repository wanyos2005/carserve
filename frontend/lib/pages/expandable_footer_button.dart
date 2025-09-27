import 'package:flutter/material.dart';

class ExpandableFooterButton extends StatefulWidget {
  const ExpandableFooterButton({super.key});

  @override
  State<ExpandableFooterButton> createState() => _ExpandableFooterButtonState();
}

class _ExpandableFooterButtonState extends State<ExpandableFooterButton>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _sizeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeAnimation);
  }

  void _toggleMenu() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _sizeAnimation,
        child: GestureDetector(
          onTap: () {
            onTap();
            _toggleMenu(); // close after tap
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.black87)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Expanded menu items
          if (_expanded)
            Positioned(
              bottom: 70,
              child: Column(
                children: [
                  _buildAction(
                    icon: Icons.calendar_today,
                    label: 'Book Service',
                    onTap: () {
                      // TODO: Hook into your real logic
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Book Service tapped")));
                    },
                  ),
                  _buildAction(
                    icon: Icons.build,
                    label: 'Log Service',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Log Service tapped")));
                    },
                  ),
                  _buildAction(
                    icon: Icons.local_gas_station,
                    label: 'Refuel',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Refuel tapped")));
                    },
                  ),
                  _buildAction(
                    icon: Icons.note_add,
                    label: 'Add Info',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Add Info tapped")));
                    },
                  ),
                  _buildAction(
                    icon: Icons.campaign,
                    label: 'Post Event',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Post Event tapped")));
                    },
                  ),
                ],
              ),
            ),

          // Main oval button
          GestureDetector(
            onTap: _toggleMenu,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_expanded ? Icons.close : Icons.add,
                      color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _expanded ? "Close Menu" : "Add New",
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
