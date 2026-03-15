import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PortraitTrait extends Equatable {
  const PortraitTrait({required this.label, required this.score});

  final String label;
  final int score;

  @override
  List<Object?> get props => <Object?>[label, score];
}

class PortraitAspect extends Equatable {
  const PortraitAspect({
    required this.icon,
    required this.title,
    required this.traits,
    required this.summary,
  });

  final IconData icon;
  final String title;
  final List<PortraitTrait> traits;
  final String summary;

  @override
  List<Object?> get props => <Object?>[icon, title, traits, summary];
}

class PersonalPortraitState extends Equatable {
  const PersonalPortraitState({
    required this.aspects,
    required this.strengths,
    required this.growthAreas,
    required this.careerRecommendations,
    required this.quote,
  });

  factory PersonalPortraitState.initial() {
    return const PersonalPortraitState(
      aspects: <PortraitAspect>[
        PortraitAspect(
          icon: Icons.person_rounded,
          title: 'Tính cách tổng quan',
          traits: <PortraitTrait>[
            PortraitTrait(label: 'Suy nghĩ sâu sắc', score: 9),
            PortraitTrait(label: 'Tìm kiếm ý nghĩa', score: 8),
            PortraitTrait(label: 'Thích không gian riêng', score: 9),
            PortraitTrait(label: 'Trực giác mạnh', score: 7),
          ],
          summary:
              'Bạn là người có nội tâm sâu sắc, luôn tìm kiếm ý nghĩa đằng sau mọi thứ. Tư duy phân tích là điểm mạnh nhưng đôi khi khiến bạn suy nghĩ quá nhiều.',
        ),
        PortraitAspect(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Giao tiếp & Biểu đạt',
          traits: <PortraitTrait>[
            PortraitTrait(label: 'Diễn đạt rõ ràng', score: 7),
            PortraitTrait(label: 'Sáng tạo trong ngôn từ', score: 8),
            PortraitTrait(label: 'Thích chia sẻ ý tưởng', score: 6),
            PortraitTrait(label: 'Lắng nghe chủ động', score: 8),
          ],
          summary:
              'Bạn giao tiếp có chiều sâu và ưu tiên những cuộc trò chuyện ý nghĩa. Khi chia sẻ, bạn thường mang đến góc nhìn độc đáo và tinh tế.',
        ),
        PortraitAspect(
          icon: Icons.favorite_rounded,
          title: 'Tình cảm & Quan hệ',
          traits: <PortraitTrait>[
            PortraitTrait(label: 'Trung thành sâu sắc', score: 9),
            PortraitTrait(label: 'Cần kết nối chất lượng', score: 8),
            PortraitTrait(label: 'Khó mở lòng ban đầu', score: 7),
            PortraitTrait(label: 'Đồng cảm cao', score: 7),
          ],
          summary:
              'Trong tình cảm, bạn ưu tiên kết nối chân thật và bền vững. Khi đã tin tưởng, bạn rất tận tâm và luôn muốn đồng hành đường dài.',
        ),
        PortraitAspect(
          icon: Icons.work_outline_rounded,
          title: 'Công việc & Sự nghiệp',
          traits: <PortraitTrait>[
            PortraitTrait(label: 'Làm việc độc lập tốt', score: 8),
            PortraitTrait(label: 'Cần mục đích rõ ràng', score: 9),
            PortraitTrait(label: 'Chuyên môn cao', score: 8),
            PortraitTrait(label: 'Tư duy chiến lược', score: 7),
          ],
          summary:
              'Bạn phù hợp với công việc cần chuyên môn sâu, phân tích rõ và mục tiêu có ý nghĩa. Môi trường yên tĩnh giúp bạn đạt hiệu suất cao nhất.',
        ),
      ],
      strengths: <String>[
        'Tư duy phân tích và logic mạnh mẽ',
        'Khả năng nhìn thấy điều người khác bỏ qua',
        'Kiên định trong việc tìm kiếm chân lý',
        'Trung thành và đáng tin cậy',
        'Độc lập và tự chủ cao',
      ],
      growthAreas: <String>[
        'Đôi khi quá suy nghĩ và do dự',
        'Có thể tách biệt khỏi thế giới bên ngoài',
        'Khó tin tưởng và mở lòng với người mới',
        'Đặt tiêu chuẩn cao khiến khó hài lòng',
        'Cần học cách cân bằng lý trí và cảm xúc',
      ],
      careerRecommendations: <String>[
        'Nghiên cứu viên',
        'Nhà phân tích',
        'Chuyên gia tâm lý',
        'Nhà văn/Biên tập',
        'Kỹ sư phần mềm',
        'Giáo viên/Giảng viên',
        'Chiến lược gia',
        'Nhà khoa học',
      ],
      quote:
          '"Sức mạnh của bạn nằm ở chiều sâu tư duy và khả năng nhìn thấy điều ẩn giấu"',
    );
  }

  final List<PortraitAspect> aspects;
  final List<String> strengths;
  final List<String> growthAreas;
  final List<String> careerRecommendations;
  final String quote;

  @override
  List<Object?> get props => <Object?>[
    aspects,
    strengths,
    growthAreas,
    careerRecommendations,
    quote,
  ];
}
