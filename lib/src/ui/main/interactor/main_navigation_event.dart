import 'package:equatable/equatable.dart';

sealed class MainNavigationEvent extends Equatable {
  const MainNavigationEvent();
}

final class MainNavigationTabSelected extends MainNavigationEvent {
  const MainNavigationTabSelected(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}
