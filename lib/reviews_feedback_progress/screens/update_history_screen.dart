// lib/reviews_feedback_progress/screens/update_history_screen.dart
import 'package:flutter/material.dart';
import 'package:apna_thekedar_specialist/reviews_feedback_progress/models/project_update.dart';
import 'package:iconsax/iconsax.dart';
import 'package:apna_thekedar_specialist/core/widgets/full_screen_image_viewer.dart';

class UpdateHistoryScreen extends StatelessWidget {
  final List<ProjectUpdate> updates;
  const UpdateHistoryScreen({super.key, required this.updates});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update History')),
      body: updates.isEmpty
          ? const Center(child: Text('No updates have been sent yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: updates.length,
              itemBuilder: (context, index) {
                final update = updates[index];
                return _buildUpdateCard(context, update);
              },
            ),
    );
  }

  Widget _buildUpdateCard(BuildContext context, ProjectUpdate update) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(update.createdAt), // Yahan date format kar sakte hain
            const Divider(),
            Text(update.updateText, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            if (update.images.isNotEmpty) _buildImageRow(context, update.images),
            const Divider(),
            _buildRatingSection(context, update.review),
          ],
        ),
      ),
    );
  }

Widget _buildImageRow(BuildContext context, List<UpdateImage> images) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector( // Image ko GestureDetector se wrap karein
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImageViewer(imageUrl: image.imageUrl),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(image.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildRatingSection(BuildContext context, Map<String, dynamic>? review) {
    if (review == null) {
      return const ListTile(
        leading: Icon(Iconsax.clock, color: Colors.grey),
        title: Text("No score yet", style: TextStyle(color: Colors.grey)),
      );
    }

    final rating = double.tryParse(review['rating'].toString()) ?? 0.0;
    final comment = review['comment'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < rating.floor() ? Iconsax.star1 : Iconsax.star,
                color: Colors.amber,
              );
            }),
            const SizedBox(width: 8),
            Text(rating.toStringAsFixed(1), style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        if (comment.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Comment: $comment'),
          ),
      ],
    );
  }
}