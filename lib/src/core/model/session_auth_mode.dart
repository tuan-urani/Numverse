enum SessionAuthMode {
  anonymous('anonymous'),
  registered('registered');

  const SessionAuthMode(this.value);

  final String value;

  static SessionAuthMode fromValue(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'anonymous':
        return SessionAuthMode.anonymous;
      case 'registered':
        return SessionAuthMode.registered;
      case 'local_guest':
        // Legacy value from older local snapshots.
        return SessionAuthMode.anonymous;
      default:
        return SessionAuthMode.anonymous;
    }
  }
}
