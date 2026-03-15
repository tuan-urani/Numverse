import 'package:equatable/equatable.dart';

sealed class HelpEvent extends Equatable {
  const HelpEvent();
}

final class HelpFaqToggled extends HelpEvent {
  const HelpFaqToggled(this.id);

  final int id;

  @override
  List<Object?> get props => <Object?>[id];
}
