import 'package:equatable/equatable.dart';

sealed class NumberLibraryEvent extends Equatable {
  const NumberLibraryEvent();
}

final class NumberLibraryBasicNumbersExpandedToggled
    extends NumberLibraryEvent {
  const NumberLibraryBasicNumbersExpandedToggled();

  @override
  List<Object?> get props => <Object?>[];
}

final class NumberLibraryMasterNumbersExpandedToggled
    extends NumberLibraryEvent {
  const NumberLibraryMasterNumbersExpandedToggled();

  @override
  List<Object?> get props => <Object?>[];
}

final class NumberLibraryNumberSelected extends NumberLibraryEvent {
  const NumberLibraryNumberSelected(this.number);

  final int number;

  @override
  List<Object?> get props => <Object?>[number];
}
