import 'package:flutter/material.dart';

class PromotionalCardBuilder {
  static Widget buildCategoryBasedCard({
    required String title,
    required String subtitle,
    required String actionText,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required double screenWidth,//double is a data type that represents a floating point number like 1.0, 2.0, 3.0, etc.
    String? category,
    String? businessType,
  }) {
    // Determine card style based on category or business type
    final cardStyle = _determineCardStyle(category, businessType);
    
    return Container(
      width: screenWidth * 0.85,
      height: 160, // Reduced height to leave space for page indicators
      margin: const EdgeInsets.only(right: 16),//margin is the space around the container
      padding: const EdgeInsets.all(16),//padding is the space inside the container
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardStyle.gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            color: color.withOpacity(0.3),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,//crossAxisAlignment is the alignment of the children of the column, 
        children: [
          // Header with icon and badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20), // Reduced icon size
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  cardStyle.badgeText,
                  style: TextStyle(
                    color: color,
                    fontSize: 9, // Reduced font size
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          
          // Title and subtitle
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16, // Reduced font size
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          Expanded( // Make subtitle expandable
            child: Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13, // Reduced font size
              ),
              maxLines: 2, // Limit to 2 lines
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12), // Fixed spacing instead of Spacer
          
          // Action button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                color: color,
                fontSize: 13, // Reduced font size
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static PromotionalCardStyle _determineCardStyle(String? category, String? businessType) {
    // Map categories to specific card styles
    if (category != null) {
      switch (category.toLowerCase()) {
        case 'finance':
        case 'banking':
          return PromotionalCardStyle(
            gradientColors: [Colors.blue[600]!, Colors.blue[400]!],
            badgeText: 'FINANCE',
          );
        case 'fuel':
        case 'energy':
          return PromotionalCardStyle(
            gradientColors: [Colors.red[600]!, Colors.red[400]!],
            badgeText: 'FUEL',
          );
        case 'insurance':
          return PromotionalCardStyle(
            gradientColors: [Colors.green[600]!, Colors.green[400]!],
            badgeText: 'INSURANCE',
          );
        case 'automotive':
        case 'repair':
        case 'maintenance':
          return PromotionalCardStyle(
            gradientColors: [Colors.orange[600]!, Colors.orange[400]!],
            badgeText: 'AUTO',
          );
        default:
          return PromotionalCardStyle(
            gradientColors: [Colors.purple[600]!, Colors.purple[400]!],
            badgeText: 'PARTNER',
          );
      }
    }
    
    // Default style
    return PromotionalCardStyle(
      gradientColors: [Colors.grey[600]!, Colors.grey[400]!],
      badgeText: 'SPONSORED',
    );
  }
}

class PromotionalCardStyle {
  final List<Color> gradientColors;
  final String badgeText;

  const PromotionalCardStyle({
    required this.gradientColors,
    required this.badgeText,
  });
}

class AutoRotatingPromotionalCarousel extends StatefulWidget {
  final List<PromotionalCardData> cards;
  final Duration rotationDuration;
  final VoidCallback? onCardTap;

  const AutoRotatingPromotionalCarousel({
    super.key,
    required this.cards,
    this.rotationDuration = const Duration(seconds: 4),
    this.onCardTap,
  });

  @override
  State<AutoRotatingPromotionalCarousel> createState() => _AutoRotatingPromotionalCarouselState();
}

class _AutoRotatingPromotionalCarouselState extends State<AutoRotatingPromotionalCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoRotation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoRotation() {
    Future.delayed(widget.rotationDuration, () {
      if (mounted && widget.cards.length > 1) {
        _nextCard();
        _startAutoRotation();
      }
    });
  }

  void _nextCard() {
    if (!mounted) return;
    
    _pageController.animateToPage(
      (_currentIndex + 1) % widget.cards.length,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    ).then((_) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.cards.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 194, // Height to accommodate the 160px card + margins + page indicators (reduced by 6px)
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemCount: widget.cards.length,
            itemBuilder: (context, index) {
              final card = widget.cards[index];
              return Center(
                child: GestureDetector(
                  onTap: () {
                    widget.onCardTap?.call();
                    card.onTap();
                  },
                  child: PromotionalCardBuilder.buildCategoryBasedCard(
                    title: card.title,
                    subtitle: card.subtitle,
                    actionText: card.actionText,
                    color: card.color,
                    icon: card.icon,
                    onTap: card.onTap,
                    screenWidth: MediaQuery.of(context).size.width,
                    category: card.category,
                    businessType: card.businessType,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12), // Spacing between cards and page indicators
        
        // Page indicators
        if (widget.cards.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.cards.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index 
                      ? widget.cards[_currentIndex].color 
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PromotionalCardData {
  final String title;
  final String subtitle;
  final String actionText;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  final String? category;
  final String? businessType;

  const PromotionalCardData({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.color,
    required this.icon,
    required this.onTap,
    this.category,
    this.businessType,
  });
}

class PromotionalCardDataProvider {
  static List<PromotionalCardData> getDefaultCards() {
    return [
      PromotionalCardData(
        title: "KCB Car Finance",
        subtitle: "Get up to 80% financing for your dream car",
        actionText: "Apply Now",
        color: Colors.blue,
        icon: Icons.account_balance,
        category: "finance",
        onTap: () {
          // Handle KCB tap
        },
      ),
      PromotionalCardData(
        title: "Total Energies",
        subtitle: "Fuel up & save 5% on every purchase",
        actionText: "Find Station",
        color: Colors.red,
        icon: Icons.local_gas_station,
        category: "fuel",
        onTap: () {
          // Handle Total tap
        },
      ),
      PromotionalCardData(
        title: "Jubilee Insurance",
        subtitle: "Comprehensive car cover with 24/7 support",
        actionText: "Get Quote",
        color: Colors.green,
        icon: Icons.security,
        category: "insurance",
        onTap: () {
          // Handle Jubilee tap
        },
      ),
      PromotionalCardData(
        title: "AutoCare Pro",
        subtitle: "Expert mechanics with warranty guarantee",
        actionText: "Book Service",
        color: Colors.orange,
        icon: Icons.build,
        category: "automotive",
        onTap: () {
          // Handle AutoCare tap
        },
      ),
    ];
  }
}
