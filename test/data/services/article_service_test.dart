import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pariwisata/data/models/article.dart';
import 'package:mobile_pariwisata/data/services/api_service.dart';
import 'package:mobile_pariwisata/data/services/article_service.dart';

void main() {
  test('articles use the current website API content and image URL', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/artikel');
      expect(request.url.queryParameters['per_page'], '50');
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 8,
              'judul': 'Festival Wisata Jember',
              'isi': 'Berita terbaru.\n\nInformasi lengkap acara.',
              'gambar': '/api/v1/media/articles/festival.jpg',
              'tanggal_publikasi': '2026-10-15T09:30:00+07:00',
            },
          ],
        }),
        200,
      );
    });
    final service = ArticleService(
      api: ApiService(baseUrl: 'http://localhost:8000/api/v1', client: client),
    );

    final articles = await service.getArticles();

    expect(articles, hasLength(1));
    expect(articles.single.id, '8');
    expect(articles.single.title, 'Festival Wisata Jember');
    expect(
      articles.single.content,
      'Berita terbaru.\n\nInformasi lengkap acara.',
    );
    expect(
      articles.single.imageUrl,
      'http://localhost:8000/api/v1/media/articles/festival.jpg',
    );
    expect(articles.single.publishedDateLabel, '15 Oktober 2026');
    expect(articles.single.summary, 'Berita terbaru. Informasi lengkap acara.');
  });

  test('articles without an image keep the image empty', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {
              'id': 9,
              'judul': 'Cerita Jember',
              'isi': 'Isi artikel.',
              'gambar': null,
              'tanggal_publikasi': null,
            },
          ],
        }),
        200,
      );
    });
    final service = ArticleService(
      api: ApiService(baseUrl: 'http://localhost/api/v1', client: client),
    );

    final articles = await service.getArticles();

    expect(articles.single.imageUrl, isNull);
    expect(articles.single.publishedAt, isNull);
  });

  test('article summaries are shortened without altering article content', () {
    final article = Article(
      id: '1',
      title: 'Artikel',
      content: List.filled(30, 'Jember').join(' '),
      imageUrl: null,
      publishedAt: null,
    );

    expect(article.summary, endsWith('...'));
    expect(article.summary.length, lessThanOrEqualTo(180));
    expect(article.content, hasLength(greaterThan(article.summary.length)));
  });
}
