import 'package:equatable/equatable.dart';

enum TodayTab { universal, personal }

class TodayState extends Equatable {
  const TodayState({required this.tab});

  factory TodayState.initial() => const TodayState(tab: TodayTab.universal);

  final TodayTab tab;

  TodayState copyWith({TodayTab? tab}) {
    return TodayState(tab: tab ?? this.tab);
  }

  @override
  List<Object?> get props => <Object?>[tab];
}
