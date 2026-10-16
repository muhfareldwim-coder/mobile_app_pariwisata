import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/article.dart';
import '../widgets/article_card.dart';
import 'article_detail_page.dart';

class ArticleListPage extends StatelessWidget {
  const ArticleListPage({super.key, required this.articles});

  final List<Article> articles;

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
      body: articles.isEmpty
          ? const Center(child: Text('Belum ada artikel yang dipublikasikan.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: articles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final article = articles[index];
                return ArticleCard(
                  article: article,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ArticleDetailPage(article: article),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
