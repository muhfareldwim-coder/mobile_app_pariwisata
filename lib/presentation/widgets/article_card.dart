import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/article.dart';

class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5EAF0)),
            borderRadius: BorderRadius.circular(17),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A14304B),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 142,
                width: double.infinity,
                child: article.imageUrl == null
                    ? const _ArticleImageFallback()
                    : Image.network(
                        article.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const _ArticleImageFallback(),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.publishedDateLabel.isNotEmpty)
                      Text(
                        article.publishedDateLabel,
                        style: const TextStyle(
                          color: Color(0xFF8492A5),
                          fontSize: 10,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF132C49),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    if (article.summary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        article.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8492A5),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFE9EDF2)),
                    const SizedBox(height: 7),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Baca selengkapnya →',
                        maxLines: 1,
                        style: TextStyle(
                          color: AppColors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
        child: Icon(
          Icons.article_outlined,
          color: Color(0xFF0B294A),
          size: 42,
        ),
      ),
    );
  }
}
