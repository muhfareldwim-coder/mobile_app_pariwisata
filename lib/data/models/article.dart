class Article {
  const Article({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.publishedAt,
  });

  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime? publishedAt;

  String get summary {
    final plainText = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (plainText.length <= 180) return plainText;
    return '${plainText.substring(0, 177).trimRight()}...';
  }

  String get publishedDateLabel {
    final date = publishedAt;
    if (date == null) return '';
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
}
