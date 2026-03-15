import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:test/src/locale/locale_key.dart';

class PrivacyState extends Equatable {
  const PrivacyState({required this.documents});

  factory PrivacyState.initial() {
    return const PrivacyState(
      documents: <PrivacyDocumentItem>[
        PrivacyDocumentItem(
          id: 'privacy-policy',
          titleKey: LocaleKey.privacyDocPolicyTitle,
          icon: Icons.description_outlined,
        ),
        PrivacyDocumentItem(
          id: 'terms',
          titleKey: LocaleKey.privacyDocTermsTitle,
          icon: Icons.description_outlined,
        ),
        PrivacyDocumentItem(
          id: 'security-policy',
          titleKey: LocaleKey.privacyDocSecurityTitle,
          icon: Icons.lock_outline_rounded,
        ),
      ],
    );
  }

  final List<PrivacyDocumentItem> documents;

  @override
  List<Object?> get props => <Object?>[documents];
}

class PrivacyDocumentItem extends Equatable {
  const PrivacyDocumentItem({
    required this.id,
    required this.titleKey,
    required this.icon,
  });

  final String id;
  final String titleKey;
  final IconData icon;

  @override
  List<Object?> get props => <Object?>[id, titleKey, icon];
}
