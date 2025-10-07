// lib/reviews_feedback_progress/models/project_update.dart

// Yeh class ek photo aur uske item name ko represent karti hai
class UpdateImage {
  final int id;
  final String imageUrl;
  final String itemName;

  UpdateImage({required this.id, required this.imageUrl, required this.itemName});

  factory UpdateImage.fromJson(Map<String, dynamic> json) {
    return UpdateImage(
      id: json['id'],
      imageUrl: json['image'],
      itemName: json['item_name'],
    );
  }
}

// Yeh class poore project update ko represent karti hai
class ProjectUpdate {
  final int id;
  final String updateText;
  final int progressPercentage;
  final String createdAt;
  final List<UpdateImage> images;
  final Map<String, dynamic>? review;

  ProjectUpdate({
    required this.id,
    required this.updateText,
    required this.progressPercentage,
    required this.createdAt,
    required this.images,
    this.review,
  });

  factory ProjectUpdate.fromJson(Map<String, dynamic> json) {
    var imageList = json['images'] as List? ?? [];
    List<UpdateImage> images = imageList.map((i) => UpdateImage.fromJson(i)).toList();
    
    var reviews = json['reviews'] as List? ?? [];
    Map<String, dynamic>? firstReview = reviews.isNotEmpty ? reviews[0] : null;

    return ProjectUpdate(
      id: json['id'],
      updateText: json['update_text'] ?? '',
      progressPercentage: json['progress_percentage'] ?? 0,
      createdAt: json['created_at'] ?? '',
      images: images,
      review: firstReview,
    );
  }
}