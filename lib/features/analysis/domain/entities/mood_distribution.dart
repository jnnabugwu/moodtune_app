import 'package:equatable/equatable.dart';

class MoodDistribution extends Equatable {
  const MoodDistribution({
    required this.happy,
    required this.sad,
    required this.energetic,
    required this.calm,
    required this.danceable,
  });

  final double happy;
  final double sad;
  final double energetic;
  final double calm;
  final double danceable;

  @override
  List<Object?> get props => [
    happy,
    sad,
    energetic,
    calm,
    danceable,
  ];
}
