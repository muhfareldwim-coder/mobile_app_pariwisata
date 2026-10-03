import 'package:flutter/material.dart';

const _articleNavy = Color(0xFF0B294A);
const _articleOrange = Color(0xFFE98600);
const _articleBackground = Color(0xFFF7F9FC);

class NewsArticle {
  const NewsArticle({
    required this.imageAsset,
    required this.category,
    required this.meta,
    required this.title,
    required this.summary,
    required this.sections,
  });

  final String imageAsset;
  final String category;
  final String meta;
  final String title;
  final String summary;
  final List<String> sections;
}

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({
    super.key,
    required this.article,
    required this.onCategorySelected,
  });

  final NewsArticle article;
  final ValueChanged<String> onCategorySelected;

  void _openCategory(BuildContext context, String category) {
    Navigator.pop(context);
    onCategorySelected(category);
  }

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
                      child: Image.asset(
                        article.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(
                              color: Color(0xFFE5EEF4),
                              child: Icon(
                                Icons.article_outlined,
                                color: _articleNavy,
                                size: 48,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0DB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          article.category,
                          style: const TextStyle(
                            color: Color(0xFF9C5B08),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            color: _articleOrange,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            article.meta,
                            style: const TextStyle(
                              color: Color(0xFF7A8492),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      Text(
                        article.summary,
                        style: const TextStyle(
                          color: Color(0xFF40536A),
                          fontSize: 15,
                          height: 1.55,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final section in article.sections) ...[
                        Text(
                          section,
                          style: const TextStyle(
                            color: Color(0xFF5F6D7D),
                            fontSize: 13,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 13),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE7ECF1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jelajahi wisata Jember',
                              style: TextStyle(
                                color: _articleNavy,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Pilih kategori untuk melihat destinasi yang sesuai.',
                              style: TextStyle(
                                color: Color(0xFF7A8492),
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 11),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _ExploreCategoryButton(
                                  label: 'Alam',
                                  icon: Icons.park_outlined,
                                  onPressed: () =>
                                      _openCategory(context, 'ALAM'),
                                ),
                                _ExploreCategoryButton(
                                  label: 'Bahari',
                                  icon: Icons.waves_rounded,
                                  onPressed: () =>
                                      _openCategory(context, 'BAHARI'),
                                ),
                                _ExploreCategoryButton(
                                  label: 'Buatan',
                                  icon: Icons.account_balance_outlined,
                                  onPressed: () =>
                                      _openCategory(context, 'BUATAN'),
                                ),
                              ],
                            ),
                          ],
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

class _ExploreCategoryButton extends StatelessWidget {
  const _ExploreCategoryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onPressed,
      avatar: Icon(icon, size: 15, color: _articleNavy),
      label: Text(label),
      labelStyle: const TextStyle(
        color: _articleNavy,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFFF3F5F8),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
