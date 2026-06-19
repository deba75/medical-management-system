import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/health_article_service.dart';
import '../../../models/health_article_model.dart';

class DoctorArticlesScreen extends StatefulWidget {
  const DoctorArticlesScreen({super.key});

  @override
  State<DoctorArticlesScreen> createState() => _DoctorArticlesScreenState();
}

class _DoctorArticlesScreenState extends State<DoctorArticlesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HealthArticleService _articleService = HealthArticleService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Articles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Published'),
            Tab(text: 'Drafts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildArticlesList(isPublished: true),
          _buildArticlesList(isPublished: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(null),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Write Article',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildArticlesList({required bool isPublished}) {
    return StreamBuilder<List<HealthArticleModel>>(
      stream: _articleService.getArticlesByAuthor(_currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allArticles = snapshot.data ?? [];
        final articles = allArticles
            .where((a) => a.isPublished == isPublished)
            .toList();

        if (articles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPublished ? Icons.article_outlined : Icons.drafts_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isPublished ? 'No published articles yet' : 'No drafts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPublished
                      ? 'Write and publish articles to share health knowledge'
                      : 'Your unpublished drafts will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[500],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isPublished)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToEditor(null),
                    icon: const Icon(Icons.add),
                    label: const Text('Write Article'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            return _buildArticleCard(article);
          },
        );
      },
    );
  }

  Widget _buildArticleCard(HealthArticleModel article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToEditor(article),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(article.category).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getCategoryName(article.category),
                      style: TextStyle(
                        color: _getCategoryColor(article.category),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (article.isFeatured)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleArticleAction(value, article),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: article.isPublished ? 'unpublish' : 'publish',
                        child: Row(
                          children: [
                            Icon(
                              article.isPublished
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(article.isPublished ? 'Unpublish' : 'Publish'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                article.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                article.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: article.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${article.views} views',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(article.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(ArticleCategory category) {
    switch (category) {
      case ArticleCategory.generalHealth:
        return Colors.blue;
      case ArticleCategory.nutrition:
        return Colors.green;
      case ArticleCategory.mentalHealth:
        return Colors.purple;
      case ArticleCategory.fitness:
        return Colors.orange;
      case ArticleCategory.diseases:
        return Colors.red;
      case ArticleCategory.medications:
        return Colors.teal;
      case ArticleCategory.wellness:
        return Colors.pink;
      case ArticleCategory.pregnancy:
        return Colors.deepPurple;
      case ArticleCategory.childcare:
        return Colors.cyan;
      case ArticleCategory.eldercare:
        return Colors.brown;
      case ArticleCategory.other:
        return Colors.grey;
    }
  }

  String _getCategoryName(ArticleCategory category) {
    switch (category) {
      case ArticleCategory.generalHealth:
        return 'General Health';
      case ArticleCategory.nutrition:
        return 'Nutrition';
      case ArticleCategory.mentalHealth:
        return 'Mental Health';
      case ArticleCategory.fitness:
        return 'Fitness';
      case ArticleCategory.diseases:
        return 'Diseases';
      case ArticleCategory.medications:
        return 'Medications';
      case ArticleCategory.wellness:
        return 'Wellness';
      case ArticleCategory.pregnancy:
        return 'Pregnancy';
      case ArticleCategory.childcare:
        return 'Childcare';
      case ArticleCategory.eldercare:
        return 'Elder Care';
      case ArticleCategory.other:
        return 'Other';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleArticleAction(String action, HealthArticleModel article) async {
    switch (action) {
      case 'edit':
        _navigateToEditor(article);
        break;
      case 'publish':
        await _togglePublish(article, true);
        break;
      case 'unpublish':
        await _togglePublish(article, false);
        break;
      case 'delete':
        _confirmDelete(article);
        break;
    }
  }

  Future<void> _togglePublish(HealthArticleModel article, bool publish) async {
    try {
      await _articleService.updateArticle(article.id, {
        'isPublished': publish,
        if (publish) 'publishedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publish ? 'Article published!' : 'Article unpublished',
            ),
            backgroundColor: publish ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _confirmDelete(HealthArticleModel article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Are you sure you want to delete "${article.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _articleService.deleteArticle(article.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Article deleted'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor(HealthArticleModel? article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleEditorScreen(article: article),
      ),
    );
  }
}

// Article Editor Screen
class ArticleEditorScreen extends StatefulWidget {
  final HealthArticleModel? article;

  const ArticleEditorScreen({super.key, this.article});

  @override
  State<ArticleEditorScreen> createState() => _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends State<ArticleEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final HealthArticleService _articleService = HealthArticleService();

  ArticleCategory _selectedCategory = ArticleCategory.generalHealth;
  bool _isFeatured = false;
  bool _isLoading = false;
  String _authorName = 'Doctor';
  String _authorSpecialization = '';

  @override
  void initState() {
    super.initState();
    _loadAuthorInfo();
    if (widget.article != null) {
      _titleController.text = widget.article!.title;
      _summaryController.text = widget.article!.summary;
      _contentController.text = widget.article!.content;
      _tagsController.text = widget.article!.tags.join(', ');
      _selectedCategory = widget.article!.category;
      _isFeatured = widget.article!.isFeatured;
    }
  }

  Future<void> _loadAuthorInfo() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(userId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _authorName = 'Dr. ${doc.data()?['name'] ?? 'Doctor'}';
          _authorSpecialization = doc.data()?['specialization'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading author info: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.article != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Article' : 'Write Article'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : () => _saveArticle(asDraft: true),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Article Title',
                  hintText: 'Enter a compelling title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<ArticleCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: ArticleCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryNameStatic(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Summary
              TextFormField(
                controller: _summaryController,
                decoration: const InputDecoration(
                  labelText: 'Summary',
                  hintText: 'Brief description of the article',
                  prefixIcon: Icon(Icons.short_text),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a summary';
                  }
                  return null;
                },
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Content
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Write your article content here...\n\nYou can use markdown formatting.',
                  prefixIcon: Icon(Icons.article),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter content';
                  }
                  if (value.length < 100) {
                    return 'Content should be at least 100 characters';
                  }
                  return null;
                },
                maxLines: 15,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),

              // Tags
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  hintText: 'health, tips, wellness (comma separated)',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),

              // Featured checkbox
              CheckboxListTile(
                title: const Text('Mark as Featured'),
                subtitle: const Text('Featured articles appear at the top'),
                value: _isFeatured,
                onChanged: (value) {
                  setState(() => _isFeatured = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Publish Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : () => _saveArticle(asDraft: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.publish),
                  label: Text(
                    _isLoading
                        ? 'Publishing...'
                        : (isEditing ? 'Update & Publish' : 'Publish Article'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveArticle({required bool asDraft}) async {
    if (!asDraft && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Not logged in');

      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final contentLength = _contentController.text.split(' ').length;
      final readTime = (contentLength / 200).ceil(); // Average reading speed

      if (widget.article != null) {
        // Update existing article
        await _articleService.updateArticle(widget.article!.id, {
          'title': _titleController.text,
          'summary': _summaryController.text,
          'content': _contentController.text,
          'category': _selectedCategory.name,
          'tags': tags,
          'isFeatured': _isFeatured,
          'isPublished': !asDraft,
          'readTimeMinutes': readTime,
          if (!asDraft) 'publishedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // Create new article
        final now = DateTime.now();
        final article = HealthArticleModel(
          id: '',
          title: _titleController.text,
          summary: _summaryController.text,
          content: _contentController.text,
          authorId: userId,
          authorName: _authorName,
          authorSpecialization: _authorSpecialization,
          category: _selectedCategory,
          tags: tags,
          imageUrl: '',
          isPublished: !asDraft,
          isFeatured: _isFeatured,
          views: 0,
          likes: 0,
          likedBy: [],
          readTimeMinutes: readTime,
          createdAt: now,
          updatedAt: now,
          publishedAt: now,
        );

        await _articleService.createArticle(article);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              asDraft
                  ? 'Article saved as draft'
                  : (widget.article != null
                      ? 'Article updated and published!'
                      : 'Article published!'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCategoryNameStatic(ArticleCategory category) {
    switch (category) {
      case ArticleCategory.generalHealth:
        return 'General Health';
      case ArticleCategory.nutrition:
        return 'Nutrition';
      case ArticleCategory.mentalHealth:
        return 'Mental Health';
      case ArticleCategory.fitness:
        return 'Fitness';
      case ArticleCategory.diseases:
        return 'Diseases';
      case ArticleCategory.medications:
        return 'Medications';
      case ArticleCategory.wellness:
        return 'Wellness';
      case ArticleCategory.pregnancy:
        return 'Pregnancy';
      case ArticleCategory.childcare:
        return 'Childcare';
      case ArticleCategory.eldercare:
        return 'Elder Care';
      case ArticleCategory.other:
        return 'Other';
    }
  }
}
