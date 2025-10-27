import 'package:flutter/material.dart';
import '../services/location_service.dart';

/// Widget for collecting coordinates in the app
class CoordinateCollectionWidget extends StatefulWidget {
  final String? suggestedAreaName;
  final Function(Map<String, dynamic>)? onCoordinateCollected;

  const CoordinateCollectionWidget({
    super.key,
    this.suggestedAreaName,
    this.onCoordinateCollected,
  });

  @override
  State<CoordinateCollectionWidget> createState() => _CoordinateCollectionWidgetState();
}

class _CoordinateCollectionWidgetState extends State<CoordinateCollectionWidget> {
  bool _isCollecting = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Improve Location Accuracy',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Help us improve location detection by collecting real coordinates for this area.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCollecting ? null : _collectCoordinate,
                icon: _isCollecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_location),
                label: Text(_isCollecting ? 'Collecting...' : 'Collect This Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _collectCoordinate() async {
    setState(() => _isCollecting = true);

    try {
      final coordinate = await LocationService.collectCurrentLocation(
        context: context,
        suggestedAreaName: widget.suggestedAreaName,
      );

      if (coordinate != null) {
        widget.onCoordinateCollected?.call(coordinate);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location "${coordinate['area_name']}" collected successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isCollecting = false);
      }
    }
  }
}
