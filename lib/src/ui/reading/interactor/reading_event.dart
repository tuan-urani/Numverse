import 'package:equatable/equatable.dart';

sealed class ReadingEvent extends Equatable {
  const ReadingEvent();
}

final class ReadingProfileDialogOpened extends ReadingEvent {
  const ReadingProfileDialogOpened();

  @override
  List<Object?> get props => <Object?>[];
}

final class ReadingProfileDialogClosed extends ReadingEvent {
  const ReadingProfileDialogClosed();

  @override
  List<Object?> get props => <Object?>[];
}
