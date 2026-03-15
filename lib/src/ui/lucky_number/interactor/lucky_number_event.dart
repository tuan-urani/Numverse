import 'package:equatable/equatable.dart';

sealed class LuckyNumberEvent extends Equatable {
  const LuckyNumberEvent();
}

final class LuckyNumberRefreshed extends LuckyNumberEvent {
  const LuckyNumberRefreshed();

  @override
  List<Object?> get props => <Object?>[];
}
