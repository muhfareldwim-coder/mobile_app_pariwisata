import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

import '../../data/models/article.dart';
import '../../data/services/article_service.dart';

const _articleNavy = Color(0xFF0B294A);
const _articleBackground = Color(0xFFFFFFFF);

class ArticleDetailPage extends StatefulWidget {
  const ArticleDetailPage({
    super.key,
    required this.article,
    this.articleService,
  });

  final Article article;
  final ArticleService? articleService;

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late final ArticleService _articleService;
  late Article _article;

  @override
  void initState() {
    super.initState();
    _articleService = widget.articleService ?? ArticleService();
    _article = widget.article;
  }

  Future<void> _refreshArticle() async {
    try {
      final articles = await _articleService.getArticles();
      final refreshedArticles = articles
          .where((article) => article.id == _article.id)
          .toList();
      if (refreshedArticles.isEmpty) {
        throw const FormatException('Artikel ini sudah tidak tersedia.');
      }
      if (mounted) setState(() => _article = refreshedArticles.first);
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Artikel gagal diperbarui: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _articleBackground,
      body: RefreshIndicator(
        onRefresh: _refreshArticle,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: _articleBackground,
              foregroundColor: _articleNavy,
              surfaceTintColor: Colors.transparent,
              centerTitle: true,
              title: const Text(
                'Detail Artikel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _article.title,
                          style: const TextStyle(
                            color: Color(0xFF202B45),
                            fontSize: 25,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_article.publishedDateLabel.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Dipublikasikan ${_article.publishedDateLabel}',
                            style: const TextStyle(
                              color: Color(0xFF737B88),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    child: Text(
                      _article.content,
                      style: const TextStyle(
                        color: Color(0xFF252B33),
                        fontSize: 15,
                        height: 1.55,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1.7,
                        child: _article.imageUrl == null
                            ? const _ArticleImageFallback()
                            : Image.network(
                                _article.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const _ArticleImageFallback(),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleImageFallback extends StatelessWidget {
  const _ArticleImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE5EEF4),
      child: Center(
        child: Icon(Icons.article_outlined, color: _articleNavy, size: 48),
      ),
    );
  }
}
