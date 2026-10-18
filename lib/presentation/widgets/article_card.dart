import 'package:flutter/material.dart';

import '../../data/models/article.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: article.imageUrl == null
                  ? const _ArticleImageFallback()
                  : Image.network(
                      article.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ArticleImageFallback(),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (article.publishedDateLabel.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    article.publishedDateLabel,
                    style: const TextStyle(
                      color: Color(0xFF8190A5),
                      fontSize: 12,
                    ),
                  ),
                ],
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
        child: Icon(Icons.article_outlined, color: Color(0xFF0B294A), size: 42),
      ),
    );
  }
}
