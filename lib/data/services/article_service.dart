import '../models/article.dart';
import 'api_service.dart';

class ArticleService {
  ArticleService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<List<Article>> getArticles() async {
    final response = await _api.get(
      '/artikel',
      queryParameters: const {'per_page': '50'},
    );
    final data = response['data'];
    if (data is! List<dynamic>) {
      throw const FormatException('Daftar artikel dari server tidak valid.');
    }

    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Data artikel dari server tidak valid.');
      }

      final id = item['id'];
      final title = item['judul'];
      final content = item['isi'];
      final imageUrl = item['gambar'];
      final publishedAt = item['tanggal_publikasi'];
      if (id == null ||
          title is! String ||
          content is! String ||
          (imageUrl != null && imageUrl is! String) ||
          (publishedAt != null && publishedAt is! String)) {
        throw const FormatException('Informasi artikel dari server tidak lengkap.');
      }

      final publishedDate = publishedAt == null
          ? null
          : DateTime.tryParse(publishedAt);
      if (publishedAt != null && publishedDate == null) {
        throw const FormatException('Tanggal artikel dari server tidak valid.');
      }

      return Article(
        id: id.toString(),
        title: title,
        content: content,
        imageUrl: imageUrl is String && imageUrl.isNotEmpty
            ? _api.resolveUrl(imageUrl)
            : null,
        publishedAt: publishedDate,
      );
    }).toList();
  }
}
