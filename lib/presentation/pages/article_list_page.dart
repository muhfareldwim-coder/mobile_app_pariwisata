import 'package:flutter/material.dart' hide Text;
import 'package:mobile_pariwisata/core/widgets/localized_text.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/article.dart';
import '../../data/services/article_service.dart';
import '../widgets/article_card.dart';
import 'article_detail_page.dart';

class ArticleListPage extends StatefulWidget {
  const ArticleListPage({
    super.key,
    required this.articles,
    this.articleService,
  });

  final List<Article> articles;
  final ArticleService? articleService;

  @override
  State<ArticleListPage> createState() => _ArticleListPageState();
}

class _ArticleListPageState extends State<ArticleListPage> {
  late final ArticleService _articleService;
  late List<Article> _articles;

  @override
  void initState() {
    super.initState();
    _articleService = widget.articleService ?? ArticleService();
    _articles = widget.articles;
  }

  Future<void> _refreshArticles() async {
    try {
      final articles = await _articleService.getArticles();
      if (mounted) setState(() => _articles = articles);
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
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Artikel Wisata'),
        backgroundColor: const Color(0xFFF6F8FB),
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshArticles,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _articles.isEmpty ? 1 : _articles.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (_articles.isEmpty) {
              return SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: const Center(
                  child: Text('Belum ada artikel yang dipublikasikan.'),
                ),
              );
            }
            final article = _articles[index];
            return ArticleCard(
              article: article,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ArticleDetailPage(
                    article: article,
                    articleService: _articleService,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
