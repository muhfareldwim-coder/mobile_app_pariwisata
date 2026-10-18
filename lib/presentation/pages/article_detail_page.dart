import 'package:flutter/material.dart';

import '../../data/models/article.dart';

const _articleNavy = Color(0xFF0B294A);
const _articleBackground = Color(0xFFFFFFFF);

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
                        article.title,
                        style: const TextStyle(
                          color: Color(0xFF202B45),
                          fontSize: 25,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (article.publishedDateLabel.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Dipublikasikan ${article.publishedDateLabel}',
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
                    article.content,
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
