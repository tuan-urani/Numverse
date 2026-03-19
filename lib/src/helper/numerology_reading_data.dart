import 'package:test/src/core/model/numerology_reading_models.dart';

class NumerologyReadingData {
  NumerologyReadingData._();

  static const Map<int, CoreNumberContent> lifePath = <int, CoreNumberContent>{
    1: CoreNumberContent(
      title: 'Người tiên phong',
      description:
          'Con số định hướng cuộc đời của người lãnh đạo và khởi xướng.',
      interpretation:
          'Bạn có khuynh hướng độc lập, quyết đoán và muốn mở lối riêng. Bài học lớn là cân bằng giữa bản lĩnh cá nhân và khả năng hợp tác.',
      keywords: <String>['Lãnh đạo', 'Tiên phong', 'Độc lập', 'Can đảm'],
    ),
    2: CoreNumberContent(
      title: 'Người hòa giải',
      description: 'Con số của sự hợp tác, tinh tế và cân bằng.',
      interpretation:
          'Bạn mạnh về lắng nghe, kết nối và tạo hài hòa trong quan hệ. Bài học là giữ lập trường rõ ràng và tự tin hơn khi ra quyết định.',
      keywords: <String>['Hòa hợp', 'Hợp tác', 'Nhạy cảm', 'Ngoại giao'],
    ),
    3: CoreNumberContent(
      title: 'Người sáng tạo',
      description: 'Con số của biểu đạt, cảm hứng và niềm vui.',
      interpretation:
          'Bạn dễ truyền cảm hứng, giao tiếp tốt và có năng lượng sáng tạo mạnh. Bài học là tránh phân tán, tập trung hoàn thiện điều đã bắt đầu.',
      keywords: <String>['Sáng tạo', 'Giao tiếp', 'Lạc quan', 'Biểu đạt'],
    ),
    4: CoreNumberContent(
      title: 'Người xây dựng',
      description: 'Con số của nền tảng, kỷ luật và tính hệ thống.',
      interpretation:
          'Bạn thực tế, bền bỉ, có năng lực tổ chức tốt và thích sự rõ ràng. Bài học là linh hoạt hơn khi bối cảnh thay đổi.',
      keywords: <String>['Ổn định', 'Kỷ luật', 'Thực tế', 'Bền bỉ'],
    ),
    5: CoreNumberContent(
      title: 'Người tự do',
      description: 'Con số của thay đổi, trải nghiệm và khám phá.',
      interpretation:
          'Bạn linh hoạt, thích mới mẻ và dễ thích nghi với môi trường biến động. Bài học là cam kết với mục tiêu dài hạn thay vì chỉ tìm cảm giác mới.',
      keywords: <String>['Tự do', 'Phiêu lưu', 'Linh hoạt', 'Năng động'],
    ),
    6: CoreNumberContent(
      title: 'Người nuôi dưỡng',
      description: 'Con số của trách nhiệm, yêu thương và chăm sóc.',
      interpretation:
          'Bạn có xu hướng bảo bọc, chữa lành và tạo không gian hài hòa cho người khác. Bài học là cân bằng giữa cho đi và chăm sóc bản thân.',
      keywords: <String>['Yêu thương', 'Chăm sóc', 'Trách nhiệm', 'Hài hòa'],
    ),
    7: CoreNumberContent(
      title: 'Người tìm kiếm chân lý',
      description: 'Con số của trí tuệ, trực giác và chiều sâu nội tâm.',
      interpretation:
          'Bạn mạnh về phân tích, nghiên cứu và cần không gian riêng để nạp năng lượng. Bài học là kết nối với đời sống thực tế thay vì khép kín quá mức.',
      keywords: <String>['Trí tuệ', 'Tâm linh', 'Phân tích', 'Độc lập'],
    ),
    8: CoreNumberContent(
      title: 'Người thành đạt',
      description: 'Con số của thành tựu, quyền lực và quản trị.',
      interpretation:
          'Bạn có năng lực tạo kết quả lớn trong công việc và tài chính. Bài học là dùng quyền lực một cách có trách nhiệm, giữ cân bằng vật chất - tinh thần.',
      keywords: <String>['Thành công', 'Quyền lực', 'Tham vọng', 'Quản lý'],
    ),
    9: CoreNumberContent(
      title: 'Người nhân văn',
      description: 'Con số của từ bi, cho đi và hoàn thiện chu kỳ.',
      interpretation:
          'Bạn có tầm nhìn rộng, tinh thần phụng sự và mong muốn đóng góp cho cộng đồng. Bài học là buông bỏ quá khứ và giữ ranh giới năng lượng cá nhân.',
      keywords: <String>['Nhân văn', 'Từ bi', 'Rộng lượng', 'Hoàn thiện'],
    ),
  };

  static const Map<int, CoreNumberContent> soulUrge = <int, CoreNumberContent>{
    1: CoreNumberContent(
      title: 'Khát khao độc lập',
      description: 'Mong muốn tự chủ và làm chủ hướng đi của mình.',
      interpretation:
          'Bạn được thúc đẩy bởi nhu cầu tự quyết, tự do thể hiện và tạo dấu ấn cá nhân.',
      keywords: <String>['Độc lập', 'Tự do', 'Lãnh đạo', 'Khởi xướng'],
    ),
    2: CoreNumberContent(
      title: 'Khát khao kết nối',
      description: 'Mong muốn hòa hợp và có quan hệ ý nghĩa.',
      interpretation:
          'Bạn cần sự đồng điệu, cảm giác được thấu hiểu và môi trường quan hệ cân bằng.',
      keywords: <String>['Kết nối', 'Hài hòa', 'Yêu thương', 'Hỗ trợ'],
    ),
    3: CoreNumberContent(
      title: 'Khát khao biểu đạt',
      description: 'Mong muốn sáng tạo và truyền tải cảm xúc.',
      interpretation:
          'Bạn cảm thấy sống động nhất khi được nói, viết, sáng tạo và truyền cảm hứng.',
      keywords: <String>['Biểu đạt', 'Sáng tạo', 'Giao tiếp', 'Niềm vui'],
    ),
    4: CoreNumberContent(
      title: 'Khát khao ổn định',
      description: 'Mong muốn an toàn, rõ ràng và nền tảng vững chắc.',
      interpretation:
          'Bạn cần cấu trúc, kế hoạch và giá trị bền vững để thấy an tâm khi phát triển.',
      keywords: <String>['Ổn định', 'An ninh', 'Trật tự', 'Nền tảng'],
    ),
    5: CoreNumberContent(
      title: 'Khát khao tự do',
      description: 'Mong muốn trải nghiệm, khám phá và dịch chuyển.',
      interpretation:
          'Bạn được tiếp năng lượng bởi cái mới, sự đa dạng và không gian lựa chọn lớn.',
      keywords: <String>['Tự do', 'Khám phá', 'Phiêu lưu', 'Đa dạng'],
    ),
    6: CoreNumberContent(
      title: 'Khát khao chăm sóc',
      description: 'Mong muốn yêu thương, nuôi dưỡng và bảo vệ.',
      interpretation:
          'Bạn muốn xây môi trường ấm áp cho gia đình, người thân và cộng đồng gần gũi.',
      keywords: <String>['Yêu thương', 'Chăm sóc', 'Gia đình', 'Hài hòa'],
    ),
    7: CoreNumberContent(
      title: 'Khát khao hiểu biết',
      description: 'Mong muốn tìm chân lý và chiều sâu ý nghĩa sống.',
      interpretation:
          'Bạn được dẫn dắt bởi nhu cầu học sâu, nghiên cứu và kết nối nội tâm tinh tế.',
      keywords: <String>['Trí tuệ', 'Chân lý', 'Tâm linh', 'Hiểu biết'],
    ),
    8: CoreNumberContent(
      title: 'Khát khao thành đạt',
      description: 'Mong muốn tạo thành tựu và ảnh hưởng thực tế.',
      interpretation:
          'Bạn có động lực mạnh với mục tiêu lớn, giá trị vật chất và sức ảnh hưởng tích cực.',
      keywords: <String>['Thành công', 'Thịnh vượng', 'Ảnh hưởng', 'Thành tựu'],
    ),
    9: CoreNumberContent(
      title: 'Khát khao phục vụ',
      description: 'Mong muốn đóng góp cho cộng đồng và nhân loại.',
      interpretation:
          'Bạn cảm thấy có ý nghĩa nhất khi trao giá trị, chữa lành và phụng sự vô điều kiện.',
      keywords: <String>['Từ bi', 'Phục vụ', 'Nhân văn', 'Cho đi'],
    ),
  };

  static const Map<int, CoreNumberContent>
  personality = <int, CoreNumberContent>{
    1: CoreNumberContent(
      title: 'Ấn tượng mạnh mẽ',
      description: 'Người khác thấy bạn tự tin, chủ động và quyết đoán.',
      interpretation:
          'Bạn tạo cảm giác đáng tin trong các bối cảnh cần dẫn dắt và ra quyết định nhanh.',
      keywords: <String>['Tự tin', 'Mạnh mẽ', 'Quyết đoán', 'Lãnh đạo'],
    ),
    2: CoreNumberContent(
      title: 'Ấn tượng dịu dàng',
      description: 'Người khác thấy bạn dễ gần, tinh tế và hòa nhã.',
      interpretation:
          'Bạn tạo cảm giác an toàn, biết lắng nghe và khéo léo trong đối thoại.',
      keywords: <String>['Dịu dàng', 'Thân thiện', 'Khéo léo', 'Thấu hiểu'],
    ),
    3: CoreNumberContent(
      title: 'Ấn tượng sống động',
      description: 'Người khác thấy bạn sáng tạo, vui vẻ và có duyên.',
      interpretation:
          'Bạn dễ thu hút bằng năng lượng tích cực và khả năng diễn đạt giàu cảm hứng.',
      keywords: <String>['Vui vẻ', 'Sáng tạo', 'Thu hút', 'Biểu cảm'],
    ),
    4: CoreNumberContent(
      title: 'Ấn tượng đáng tin',
      description: 'Người khác thấy bạn thực tế, chắc chắn và có trách nhiệm.',
      interpretation:
          'Bạn tạo cảm giác chuyên nghiệp, có tổ chức và làm việc đến nơi đến chốn.',
      keywords: <String>['Đáng tin', 'Thực tế', 'Chăm chỉ', 'Có tổ chức'],
    ),
    5: CoreNumberContent(
      title: 'Ấn tượng năng động',
      description: 'Người khác thấy bạn linh hoạt, tò mò và yêu khám phá.',
      interpretation:
          'Bạn mang lại cảm giác đổi mới, tự do và tinh thần thử nghiệm.',
      keywords: <String>['Năng động', 'Linh hoạt', 'Tò mò', 'Phiêu lưu'],
    ),
    6: CoreNumberContent(
      title: 'Ấn tượng ấm áp',
      description: 'Người khác thấy bạn quan tâm, trưởng thành và trách nhiệm.',
      interpretation:
          'Bạn tạo môi trường giao tiếp hài hòa, đáng tin và có chiều sâu cảm xúc.',
      keywords: <String>['Ấm áp', 'Quan tâm', 'Hài hòa', 'Đáng tin'],
    ),
    7: CoreNumberContent(
      title: 'Ấn tượng bí ẩn',
      description: 'Người khác thấy bạn sâu sắc, trí tuệ và tinh tế.',
      interpretation:
          'Bạn tạo sức hút bằng chiều sâu tư duy và vẻ điềm tĩnh khác biệt.',
      keywords: <String>['Sâu sắc', 'Trí tuệ', 'Bí ẩn', 'Tinh tế'],
    ),
    8: CoreNumberContent(
      title: 'Ấn tượng quyền lực',
      description: 'Người khác thấy bạn bản lĩnh, có tầm và chuyên nghiệp.',
      interpretation:
          'Bạn toát lên tinh thần kết quả, năng lực quản trị và khí chất lãnh đạo.',
      keywords: <String>['Quyền lực', 'Thành đạt', 'Chuyên nghiệp', 'Uy lực'],
    ),
    9: CoreNumberContent(
      title: 'Ấn tượng rộng lượng',
      description: 'Người khác thấy bạn bao dung, nhân ái và chân thành.',
      interpretation:
          'Bạn tạo cảm giác được thấu hiểu, được nâng đỡ và được tôn trọng.',
      keywords: <String>['Rộng lượng', 'Từ bi', 'Khôn ngoan', 'Chân thành'],
    ),
  };

  static const Map<int, CoreNumberContent> mission = <int, CoreNumberContent>{
    1: CoreNumberContent(
      title: 'Sứ mệnh lãnh đạo',
      description: 'Bạn đến để khởi xướng và dẫn đường.',
      interpretation:
          'Sứ mệnh của bạn là mở lối, tạo chuẩn mới và kích hoạt tinh thần hành động ở người khác.',
      keywords: <String>['Lãnh đạo', 'Khởi xướng', 'Tiên phong', 'Độc lập'],
    ),
    2: CoreNumberContent(
      title: 'Sứ mệnh kết nối',
      description: 'Bạn đến để tạo cầu nối và hòa giải.',
      interpretation:
          'Sứ mệnh của bạn là làm dịu xung đột, tăng hợp tác và nuôi dưỡng sự đồng thuận.',
      keywords: <String>['Kết nối', 'Hòa giải', 'Hợp tác', 'Ngoại giao'],
    ),
    3: CoreNumberContent(
      title: 'Sứ mệnh truyền cảm hứng',
      description: 'Bạn đến để biểu đạt và lan tỏa năng lượng tích cực.',
      interpretation:
          'Sứ mệnh của bạn là dùng ngôn từ, sáng tạo và cảm hứng để mở rộng nhận thức cộng đồng.',
      keywords: <String>['Truyền cảm hứng', 'Sáng tạo', 'Biểu đạt', 'Niềm vui'],
    ),
    4: CoreNumberContent(
      title: 'Sứ mệnh xây dựng',
      description: 'Bạn đến để tạo hệ thống vững chắc, bền lâu.',
      interpretation:
          'Sứ mệnh của bạn là biến ý tưởng thành cấu trúc, quy trình và giá trị thực tế có thể duy trì.',
      keywords: <String>['Xây dựng', 'Nền tảng', 'Hệ thống', 'Bền vững'],
    ),
    5: CoreNumberContent(
      title: 'Sứ mệnh thay đổi',
      description: 'Bạn đến để mở rộng và tạo đột phá.',
      interpretation:
          'Sứ mệnh của bạn là thúc đẩy tiến bộ, giải phóng giới hạn và khơi dậy tư duy mới.',
      keywords: <String>['Thay đổi', 'Tự do', 'Tiến bộ', 'Khám phá'],
    ),
    6: CoreNumberContent(
      title: 'Sứ mệnh chữa lành',
      description: 'Bạn đến để nuôi dưỡng, bảo vệ và cân bằng.',
      interpretation:
          'Sứ mệnh của bạn là tạo không gian an toàn, hỗ trợ con người hồi phục và lớn lên trong yêu thương.',
      keywords: <String>['Chữa lành', 'Chăm sóc', 'Yêu thương', 'Hài hòa'],
    ),
    7: CoreNumberContent(
      title: 'Sứ mệnh khai sáng',
      description: 'Bạn đến để tìm hiểu bản chất và chia sẻ trí tuệ.',
      interpretation:
          'Sứ mệnh của bạn là nghiên cứu sâu, chắt lọc tri thức và truyền tải góc nhìn bản chất cho cộng đồng.',
      keywords: <String>['Khai sáng', 'Trí tuệ', 'Chân lý', 'Hiểu biết'],
    ),
    8: CoreNumberContent(
      title: 'Sứ mệnh trao quyền',
      description: 'Bạn đến để tạo thành tựu và trao cơ hội.',
      interpretation:
          'Sứ mệnh của bạn là xây thành công có hệ thống, đồng thời mở đường và nâng đỡ người khác cùng phát triển.',
      keywords: <String>['Trao quyền', 'Thành công', 'Lãnh đạo', 'Tạo giá trị'],
    ),
    9: CoreNumberContent(
      title: 'Sứ mệnh phục vụ',
      description: 'Bạn đến để phụng sự và lan tỏa từ bi.',
      interpretation:
          'Sứ mệnh của bạn là chữa lành tập thể qua tinh thần cống hiến, bao dung và hành động vì lợi ích cộng đồng.',
      keywords: <String>['Phục vụ', 'Từ bi', 'Nhân văn', 'Cho đi'],
    ),
  };

  static const BirthChartDataSet birthChart = BirthChartDataSet(
    numbers: <int, ChartNumberMeaning>{
      1: ChartNumberMeaning(
        strength:
            'Tự tin, độc lập, có khả năng dẫn dắt và khẳng định bản thân.',
        lesson:
            'Phát triển sự tự tin, học cách nói rõ nhu cầu và đưa ra quyết định riêng.',
      ),
      2: ChartNumberMeaning(
        strength: 'Nhạy cảm, kiên nhẫn, biết hợp tác và kết nối trong tập thể.',
        lesson:
            'Luyện khả năng lắng nghe, đồng cảm và giữ cân bằng trong quan hệ.',
      ),
      3: ChartNumberMeaning(
        strength:
            'Sáng tạo, diễn đạt tốt, có năng lượng truyền cảm hứng tích cực.',
        lesson:
            'Rèn khả năng biểu đạt, chia sẻ ý tưởng thay vì giữ trong lòng.',
      ),
      4: ChartNumberMeaning(
        strength:
            'Kỷ luật, thực tế, có năng lực tổ chức và xây nền tảng bền vững.',
        lesson:
            'Xây thói quen và cấu trúc làm việc ổn định hơn trong cuộc sống.',
      ),
      5: ChartNumberMeaning(
        strength: 'Linh hoạt, yêu trải nghiệm, thích ứng tốt trước biến động.',
        lesson:
            'Tăng khả năng thích nghi có định hướng thay vì thay đổi cảm tính.',
      ),
      6: ChartNumberMeaning(
        strength:
            'Quan tâm, có trách nhiệm, tạo sự hài hòa trong môi trường sống.',
        lesson: 'Học cân bằng giữa chăm sóc người khác và chăm sóc chính mình.',
      ),
      7: ChartNumberMeaning(
        strength:
            'Tư duy sâu, phân tích tốt, trực giác và năng lực chiêm nghiệm cao.',
        lesson:
            'Mở rộng học hỏi, kết nối thực tế để tránh khép kín nội tâm quá mức.',
      ),
      8: ChartNumberMeaning(
        strength:
            'Tham vọng, có năng lực quản trị và tư duy thành tựu rõ ràng.',
        lesson:
            'Phát triển cách dùng quyền lực và tài chính theo hướng bền vững.',
      ),
      9: ChartNumberMeaning(
        strength:
            'Nhân văn, rộng lượng, có tầm nhìn bao quát và tinh thần phụng sự.',
        lesson: 'Rèn lòng từ bi đi cùng ranh giới cá nhân rõ ràng.',
      ),
    },
    physicalAxis: ChartAxisMeaning(
      name: 'Trục Hành động',
      description: 'Cột 1-4-7 thể hiện thực thi và tính thực tế.',
      presentDescription:
          'Bạn có xu hướng biến ý tưởng thành hành động cụ thể và duy trì nhịp thực thi tốt.',
      missingDescription:
          'Bạn cần tăng tính kỷ luật, cấu trúc và bước hành động rõ để tránh trì hoãn.',
    ),
    mentalAxis: ChartAxisMeaning(
      name: 'Trục Tư duy',
      description: 'Cột 3-6-9 thể hiện tư duy, tầm nhìn và nhận thức.',
      presentDescription:
          'Bạn có khả năng tư duy chiến lược, liên kết ý tưởng và nhìn bức tranh tổng thể.',
      missingDescription:
          'Bạn cần rèn tư duy hệ thống và kỹ năng lập kế hoạch dài hạn.',
    ),
    emotionalAxis: ChartAxisMeaning(
      name: 'Trục Cảm xúc',
      description: 'Cột 2-5-8 thể hiện trực giác và cân bằng cảm xúc.',
      presentDescription:
          'Bạn có khả năng cảm nhận tinh tế, đồng cảm và kết nối sâu với người khác.',
      missingDescription:
          'Bạn cần luyện nhận biết cảm xúc, đặt ranh giới và phản hồi cân bằng hơn.',
    ),
  );

  static const Map<String, ChartArrowMeaning> nameChartArrows =
      <String, ChartArrowMeaning>{
        'determination': ChartArrowMeaning(
          key: 'determination',
          title: 'Quyết tâm',
          presentDescription:
              'Tên của bạn tạo cảm giác bền bỉ và theo đuổi mục tiêu đến cùng.',
          missingDescription:
              'Khi biểu đạt mục tiêu, hãy chốt rõ mốc thời gian và tiêu chí hoàn thành.',
          numbers: <int>[3, 5, 7],
        ),
        'planning': ChartArrowMeaning(
          key: 'planning',
          title: 'Kế hoạch',
          presentDescription:
              'Bạn có xu hướng trình bày ý tưởng có cấu trúc và lộ trình rõ ràng.',
          missingDescription:
              'Nên chia ý tưởng thành 3 phần: mục tiêu, bước làm, thời hạn.',
          numbers: <int>[1, 2, 3],
        ),
        'willpower': ChartArrowMeaning(
          key: 'willpower',
          title: 'Ý chí',
          presentDescription:
              'Cách bạn thể hiện cho thấy nội lực tốt và tinh thần cam kết ổn định.',
          missingDescription:
              'Giữ nhịp bằng thói quen nhỏ lặp lại mỗi ngày để tăng độ kiên định.',
          numbers: <int>[4, 5, 6],
        ),
        'activity': ChartArrowMeaning(
          key: 'activity',
          title: 'Năng động',
          presentDescription:
              'Năng lượng tên cho thấy bạn chủ động bắt đầu và xoay chuyển nhanh.',
          missingDescription:
              'Hãy ưu tiên hành động đầu tiên trong 24 giờ thay vì chờ hoàn hảo.',
          numbers: <int>[1, 5, 9],
        ),
        'sensitivity': ChartArrowMeaning(
          key: 'sensitivity',
          title: 'Nhạy cảm',
          presentDescription:
              'Bạn dễ bắt nhịp cảm xúc người đối diện và phản hồi tinh tế.',
          missingDescription:
              'Tăng chất lượng lắng nghe bằng cách nhắc lại ý chính trước khi phản hồi.',
          numbers: <int>[3, 6, 9],
        ),
        'frustration': ChartArrowMeaning(
          key: 'frustration',
          title: 'Bồn chồn',
          presentDescription:
              'Năng lượng bồn chồn có thể tăng khi áp lực cao, cần quản trị nhịp nghỉ.',
          missingDescription:
              'Bạn giữ nhịp khá ổn và ít bị cuốn vào trạng thái nôn nóng.',
          numbers: <int>[4, 5, 6],
        ),
        'success': ChartArrowMeaning(
          key: 'success',
          title: 'Thành tựu',
          presentDescription:
              'Tổ hợp này hỗ trợ tư duy kết quả và khả năng đi đường dài.',
          missingDescription:
              'Kết hợp kỷ luật và theo dõi tiến độ tuần để cải thiện hiệu quả.',
          numbers: <int>[7, 8, 9],
        ),
        'spirituality': ChartArrowMeaning(
          key: 'spirituality',
          title: 'Tâm thức',
          presentDescription:
              'Bạn có khả năng kết nối trực giác với hành động thực tế.',
          missingDescription:
              'Dành thời gian tĩnh để làm rõ giá trị cốt lõi trước các quyết định lớn.',
          numbers: <int>[1, 5, 9],
        ),
      };

  static const Map<int, LifeCycleContent> pinnacles = <int, LifeCycleContent>{
    1: LifeCycleContent(
      theme: 'Độc lập & Khởi đầu',
      description:
          'Giai đoạn phát triển bản lĩnh cá nhân, tự chủ và tinh thần dẫn dắt.',
      opportunities:
          'Khởi xướng dự án mới, xây vai trò lãnh đạo và tạo dấu ấn cá nhân.',
      advice:
          'Tin vào chính mình, quyết đoán hơn nhưng vẫn giữ khả năng lắng nghe.',
    ),
    2: LifeCycleContent(
      theme: 'Hợp tác & Cân bằng',
      description:
          'Giai đoạn trọng tâm quan hệ, đồng hành và điều phối hài hòa tập thể.',
      opportunities:
          'Xây quan hệ sâu, mở rộng hợp tác và tăng chất lượng giao tiếp.',
      advice:
          'Luyện kiên nhẫn, đặt ranh giới lành mạnh và giữ cân bằng cho - nhận.',
    ),
    3: LifeCycleContent(
      theme: 'Sáng tạo & Biểu đạt',
      description:
          'Giai đoạn nổi bật năng lực sáng tạo, giao tiếp và lan tỏa cảm hứng.',
      opportunities:
          'Mở rộng hiện diện cá nhân qua nội dung, nghệ thuật, truyền thông.',
      advice:
          'Tập trung hoàn thiện sản phẩm thay vì mở quá nhiều hướng cùng lúc.',
    ),
    4: LifeCycleContent(
      theme: 'Xây dựng & Kỷ luật',
      description:
          'Giai đoạn đặt nền tảng bền vững cho sự nghiệp và đời sống vật chất.',
      opportunities:
          'Tích lũy tài sản, nâng chuyên môn và thiết kế hệ thống làm việc hiệu quả.',
      advice: 'Đi từng bước chắc chắn, kiên trì với kế hoạch dài hạn.',
    ),
    5: LifeCycleContent(
      theme: 'Tự do & Thay đổi',
      description:
          'Giai đoạn mở rộng trải nghiệm, chuyển đổi môi trường và mô hình sống.',
      opportunities:
          'Du lịch, học kỹ năng mới, đổi nghề hoặc làm mới định hướng.',
      advice: 'Đón thay đổi với chủ động, nhưng vẫn giữ trục giá trị cốt lõi.',
    ),
    6: LifeCycleContent(
      theme: 'Yêu thương & Trách nhiệm',
      description:
          'Giai đoạn ưu tiên gia đình, quan hệ và vai trò chăm sóc cộng đồng gần.',
      opportunities:
          'Nuôi nền tảng tình cảm, xây tổ ấm và tạo ảnh hưởng chữa lành.',
      advice:
          'Quan tâm người khác nhưng đừng bỏ quên nhu cầu nghỉ ngơi của bản thân.',
    ),
    7: LifeCycleContent(
      theme: 'Trí tuệ & Tâm linh',
      description:
          'Giai đoạn học sâu, chiêm nghiệm và tái định nghĩa ý nghĩa cuộc sống.',
      opportunities:
          'Nghiên cứu, viết, giảng dạy, thiền định và phát triển trực giác.',
      advice:
          'Giữ thời gian tĩnh lặng đều đặn, đồng thời duy trì kết nối xã hội vừa đủ.',
    ),
    8: LifeCycleContent(
      theme: 'Thành công & Quyền lực',
      description:
          'Giai đoạn tối ưu năng lực quản trị, tài chính và ảnh hưởng thực tế.',
      opportunities: 'Thăng tiến, khởi nghiệp hoặc dẫn dắt dự án quy mô lớn.',
      advice:
          'Theo đuổi thành tựu đi kèm trách nhiệm, đạo đức và cân bằng cá nhân.',
    ),
    9: LifeCycleContent(
      theme: 'Nhân văn & Hoàn thiện',
      description:
          'Giai đoạn khép chu kỳ cũ, cho đi, chữa lành và mở rộng tầm nhìn cộng đồng.',
      opportunities:
          'Đóng góp xã hội, chia sẻ tri thức, kết thúc điều không còn phù hợp.',
      advice: 'Thực hành buông bỏ, tha thứ và chọn phụng sự có chủ đích.',
    ),
    11: LifeCycleContent(
      theme: 'Khai sáng & Truyền cảm hứng',
      description:
          'Giai đoạn tăng trực giác và ảnh hưởng tinh thần cho cộng đồng.',
      opportunities:
          'Làm người dẫn đường, mentor hoặc chia sẻ định hướng nhân văn sâu sắc.',
      advice:
          'Tin trực giác và giữ kỷ luật năng lượng để không bị quá tải cảm xúc.',
    ),
    22: LifeCycleContent(
      theme: 'Kiến tạo vĩ đại',
      description:
          'Giai đoạn biến tầm nhìn lớn thành hệ thống có tác động lâu dài.',
      opportunities:
          'Xây dự án quy mô lớn, tạo di sản tổ chức và giá trị cộng đồng bền vững.',
      advice: 'Kết hợp tầm nhìn xa với kế hoạch thực thi chi tiết, bền bỉ.',
    ),
    33: LifeCycleContent(
      theme: 'Phụng sự & Chữa lành',
      description:
          'Giai đoạn Master 33 nhấn mạnh phụng sự cộng đồng bằng tình thương, trí tuệ và trách nhiệm tinh thần.',
      opportunities:
          'Dẫn dắt các hoạt động giáo dục, chăm sóc, chữa lành hoặc xây nền tảng hỗ trợ dài hạn cho người khác.',
      advice:
          'Cho đi có ranh giới, giữ cân bằng năng lượng cá nhân và chuyển lý tưởng thành hành động thực tế từng bước.',
    ),
  };

  static const Map<int, LifeCycleContent> challenges = <int, LifeCycleContent>{
    0: LifeCycleContent(
      theme: 'Lựa chọn & Tiềm năng vô hạn',
      description:
          'Thử thách của sự tự do lớn: nhiều hướng đi nhưng dễ phân tán.',
      opportunities:
          'Bạn có thể chủ động thiết kế con đường sống riêng không bị khuôn mẫu giới hạn.',
      advice:
          'Xác định rõ ưu tiên cốt lõi để không bị choáng ngợp bởi quá nhiều lựa chọn.',
    ),
    1: LifeCycleContent(
      theme: 'Tự tin & Độc lập',
      description:
          'Bài học khẳng định bản thân và đứng vững trên quyết định của mình.',
      opportunities:
          'Mỗi lần bạn tự chủ hành động là một bước vượt qua thử thách này.',
      advice:
          'Luyện tiếng nói cá nhân rõ ràng, quyết đoán hơn trong các quyết định quan trọng.',
    ),
    2: LifeCycleContent(
      theme: 'Kiên nhẫn & Hợp tác',
      description:
          'Bài học cân bằng cảm xúc và khả năng làm việc cùng người khác.',
      opportunities:
          'Phát triển năng lực đồng cảm, lắng nghe và hợp tác bền vững.',
      advice: 'Đặt ranh giới lành mạnh để không bị cảm xúc bên ngoài kéo đi.',
    ),
    3: LifeCycleContent(
      theme: 'Biểu đạt & Tập trung',
      description:
          'Bài học vượt qua tự ti biểu đạt và khuynh hướng phân tán năng lượng.',
      opportunities:
          'Tỏa sáng qua giao tiếp, sáng tạo và truyền thông có chủ đích.',
      advice: 'Chọn ít mục tiêu hơn nhưng hoàn thành sâu hơn.',
    ),
    4: LifeCycleContent(
      theme: 'Kỷ luật & Nền tảng',
      description:
          'Bài học xây nhịp bền vững, làm việc hệ thống và giữ cam kết.',
      opportunities:
          'Tăng năng lực quản trị thời gian, tài chính và chất lượng công việc.',
      advice:
          'Tạo thói quen nhỏ đều đặn, ưu tiên tiến bộ ổn định thay vì bứt phá ngắn hạn.',
    ),
    5: LifeCycleContent(
      theme: 'Tự do & Cam kết',
      description:
          'Bài học cân bằng nhu cầu tự do với trách nhiệm và cam kết dài hạn.',
      opportunities:
          'Xây phong cách sống linh hoạt nhưng vẫn nhất quán với mục tiêu.',
      advice: 'Thay đổi có chiến lược, tránh chạy theo hưng phấn nhất thời.',
    ),
    6: LifeCycleContent(
      theme: 'Trách nhiệm & Ranh giới',
      description:
          'Bài học về cho đi đúng mức, tránh gánh thay hoặc hy sinh quá mức.',
      opportunities:
          'Học yêu thương trưởng thành: vừa chăm người khác vừa tự bảo toàn năng lượng.',
      advice: 'Dám nói không khi cần, ưu tiên cân bằng dài hạn trong quan hệ.',
    ),
    7: LifeCycleContent(
      theme: 'Niềm tin & Kết nối',
      description:
          'Bài học vượt cô lập nội tâm và phát triển niềm tin lành mạnh vào người khác.',
      opportunities:
          'Kết hợp chiều sâu trí tuệ với khả năng chia sẻ và hợp tác thực tế.',
      advice:
          'Giữ thời gian cho nội tâm, đồng thời duy trì kết nối xã hội chất lượng.',
    ),
    8: LifeCycleContent(
      theme: 'Quyền lực & Cân bằng',
      description:
          'Bài học dùng tham vọng và quyền lực đúng cách, không lệch giá trị.',
      opportunities:
          'Bạn có thể xây thành công lớn đi kèm ảnh hưởng tích cực cho tập thể.',
      advice: 'Đặt chuẩn đạo đức rõ ràng khi theo đuổi kết quả và tài chính.',
    ),
  };
}
