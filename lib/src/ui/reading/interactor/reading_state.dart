import 'package:equatable/equatable.dart';

class ReadingState extends Equatable {
  const ReadingState({required this.isProfileDialogOpen});

  factory ReadingState.initial() {
    return const ReadingState(isProfileDialogOpen: false);
  }

  final bool isProfileDialogOpen;

  ReadingState copyWith({bool? isProfileDialogOpen}) {
    return ReadingState(
      isProfileDialogOpen: isProfileDialogOpen ?? this.isProfileDialogOpen,
    );
  }

  @override
  List<Object?> get props => <Object?>[isProfileDialogOpen];
}
