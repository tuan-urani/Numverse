class SessionInteractionUpdate {
  const SessionInteractionUpdate({required this.page, required this.count});

  final String page;
  final int count;
}

class SessionPromptService {
  const SessionPromptService({this.interactionThreshold = 5});

  final int interactionThreshold;

  SessionInteractionUpdate trackInteraction({
    required String currentPage,
    required int interactionCount,
    required String nextPage,
  }) {
    if (currentPage != nextPage) {
      return SessionInteractionUpdate(page: nextPage, count: 1);
    }
    return SessionInteractionUpdate(
      page: nextPage,
      count: interactionCount + 1,
    );
  }

  SessionInteractionUpdate resetInteraction(String page) {
    return SessionInteractionUpdate(page: page, count: 0);
  }

  bool shouldShowProfilePrompt({
    required String page,
    required String currentPageInteraction,
    required int interactionCount,
    required bool hasAnyProfile,
  }) {
    return currentPageInteraction == page &&
        interactionCount >= interactionThreshold &&
        !hasAnyProfile;
  }
}
