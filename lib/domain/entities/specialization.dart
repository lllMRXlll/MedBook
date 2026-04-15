import 'package:equatable/equatable.dart';

class Specialization extends Equatable {
  const Specialization({required this.id, required this.title});

  final String id;
  final String title;

  @override
  List<Object?> get props => [id, title];
}
