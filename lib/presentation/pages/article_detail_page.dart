import 'package:flutter/material.dart';

import '../../data/models/article.dart';

const _articleNavy = Color(0xFF0B294A);
const _articleOrange = Color(0xFFE98600);
const _articleBackground = Color(0xFFF7F9FC);

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _articleBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: _articleBackground,
            foregroundColor: _articleNavy,
            surfaceTintColor: Colors.transparent,
            title: const Text('Berita & Panduan'),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1.7,
                      child: article.imageUrl == null
                          ? const _ArticleImageFallback()
                          : Image.network(
                              article.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const _ArticleImageFallback(),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cerita perjalanan',
                        style: TextStyle(
                          color: _articleOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        article.title,
                        style: const TextStyle(
                          color: _articleNavy,
                          fontSize: 24,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      if (article.publishedDateLabel.isNotEmpty) ...[
                        Text(
                          article.publishedDateLabel,
                          style: const TextStyle(
                            color: Color(0xFF7A8492),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 17),
                      ],
                      Text(
                        article.content,
                        style: const TextStyle(
                          color: Color(0xFF40536A),
                          fontSize: 15,
                          height: 1.65,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
        child: Icon(
          Icons.article_outlined,
          color: _articleNavy,
          size: 48,
        ),
      ),
    );
  }
}
