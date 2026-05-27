import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class StarRating extends StatelessWidget {
  final double initialRating;
  final ValueChanged<double>? onRatingUpdate;
  final bool readOnly;
  final double itemSize;

  const StarRating({
    super.key,
    this.initialRating = 0,
    this.onRatingUpdate,
    this.readOnly = false,
    this.itemSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return RatingBar.builder(
      initialRating: initialRating,
      minRating: 0.5,
      allowHalfRating: true,
      itemCount: 5,
      itemSize: itemSize,
      ignoreGestures: readOnly,
      itemBuilder: (_, __) => const Icon(Icons.star, color: Color(0xFFFFD700)),
      onRatingUpdate: onRatingUpdate ?? (_) {},
    );
  }
}
