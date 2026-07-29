import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/health_article_model.dart';

class HealthArticleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'health_articles';

  // Get all published articles
  Stream<List<HealthArticleModel>> getPublishedArticles() {
    return _firestore
        .collection(_collection)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final articles = snapshot.docs
              .where((doc) => doc.data()['status'] != 'restricted')
              .map((doc) => HealthArticleModel.fromJson(doc.data(), doc.id))
              .toList();
          // Sort locally to avoid needing composite index
          articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          return articles;
        });
  }

  // Get featured articles
  Stream<List<HealthArticleModel>> getFeaturedArticles() {
    return _firestore
        .collection(_collection)
        .where('isPublished', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final articles = snapshot.docs
              .map((doc) => HealthArticleModel.fromJson(doc.data(), doc.id))
              .toList();
          // Sort locally and limit
          articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          return articles.take(5).toList();
        });
  }

  // Get articles by category
  Stream<List<HealthArticleModel>> getArticlesByCategory(ArticleCategory category) {
    return _firestore
        .collection(_collection)
        .where('isPublished', isEqualTo: true)
        .where('category', isEqualTo: category.name)
        .snapshots()
        .map((snapshot) {
          final articles = snapshot.docs
              .map((doc) => HealthArticleModel.fromJson(doc.data(), doc.id))
              .toList();
          // Sort locally to avoid needing composite index
          articles.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
          return articles;
        });
  }

  // Get article by ID
  Future<HealthArticleModel?> getArticleById(String articleId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(articleId).get();
      if (doc.exists) {
        return HealthArticleModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch article: $e');
    }
  }

  // Search articles
  Future<List<HealthArticleModel>> searchArticles(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isPublished', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => HealthArticleModel.fromJson(doc.data(), doc.id))
          .where((article) =>
              article.title.toLowerCase().contains(query.toLowerCase()) ||
              article.summary.toLowerCase().contains(query.toLowerCase()) ||
              article.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      throw Exception('Failed to search articles: $e');
    }
  }

  // Increment view count
  Future<void> incrementViews(String articleId) async {
    try {
      await _firestore.collection(_collection).doc(articleId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently fail for view count
    }
  }

  // Like/Unlike article
  Future<void> toggleLike(String articleId, String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(articleId).get();
      if (doc.exists) {
        final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
        
        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
          await _firestore.collection(_collection).doc(articleId).update({
            'likedBy': likedBy,
            'likes': FieldValue.increment(-1),
          });
        } else {
          likedBy.add(userId);
          await _firestore.collection(_collection).doc(articleId).update({
            'likedBy': likedBy,
            'likes': FieldValue.increment(1),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to toggle like: $e');
    }
  }

  // Check if user has liked article
  Future<bool> hasUserLiked(String articleId, String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(articleId).get();
      if (doc.exists) {
        final likedBy = List<String>.from(doc.data()?['likedBy'] ?? []);
        return likedBy.contains(userId);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get articles by doctor/author
  Stream<List<HealthArticleModel>> getArticlesByAuthor(String authorId) {
    return _firestore
        .collection(_collection)
        .where('authorId', isEqualTo: authorId)
        .snapshots()
        .map((snapshot) {
          final articles = snapshot.docs
              .map((doc) => HealthArticleModel.fromJson(doc.data(), doc.id))
              .toList();
          // Sort locally to avoid needing composite index
          articles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return articles;
        });
  }

  // Create article (for doctors)
  Future<String> createArticle(HealthArticleModel article) async {
    try {
      final docRef = await _firestore.collection(_collection).add(article.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create article: $e');
    }
  }

  // Update article
  Future<void> updateArticle(String articleId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection(_collection).doc(articleId).update(updates);
    } catch (e) {
      throw Exception('Failed to update article: $e');
    }
  }

  // Delete article
  Future<void> deleteArticle(String articleId) async {
    try {
      await _firestore.collection(_collection).doc(articleId).delete();
    } catch (e) {
      throw Exception('Failed to delete article: $e');
    }
  }

  // Seed sample articles
  Future<void> seedSampleArticles() async {
    final sampleArticles = [
      {
        'title': '10 Tips for Better Sleep',
        'summary': 'Discover simple strategies to improve your sleep quality and wake up refreshed.',
        'content': '''
Sleep is essential for physical and mental health. Here are 10 proven tips to help you sleep better:

1. **Stick to a Schedule**: Go to bed and wake up at the same time every day, even on weekends.

2. **Create a Restful Environment**: Keep your bedroom cool, dark, and quiet. Consider using earplugs or a white noise machine.

3. **Limit Screen Time**: Avoid phones, tablets, and computers for at least an hour before bed. The blue light can interfere with your sleep.

4. **Watch Your Diet**: Avoid large meals, caffeine, and alcohol close to bedtime.

5. **Exercise Regularly**: Physical activity can help you fall asleep faster, but avoid exercising too close to bedtime.

6. **Manage Stress**: Try relaxation techniques like deep breathing, meditation, or gentle yoga before bed.

7. **Limit Naps**: If you need to nap, keep it short (20-30 minutes) and avoid napping late in the day.

8. **Get Some Sunlight**: Exposure to natural light during the day helps regulate your sleep-wake cycle.

9. **Be Comfortable**: Invest in a comfortable mattress and pillows.

10. **Consult a Doctor**: If sleep problems persist, talk to your healthcare provider.

Remember, good sleep is a cornerstone of good health!
        ''',
        'authorId': 'system',
        'authorName': 'MediCare Health Team',
        'category': 'wellness',
        'tags': ['sleep', 'wellness', 'health tips', 'lifestyle'],
        'readTimeMinutes': 5,
        'views': 0,
        'likes': 0,
        'likedBy': [],
        'isPublished': true,
        'isFeatured': true,
        'publishedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Understanding Your Blood Pressure Numbers',
        'summary': 'Learn what your blood pressure readings mean and how to maintain healthy levels.',
        'content': '''
Blood pressure is a vital indicator of your cardiovascular health. Understanding your numbers is the first step to managing them.

## What Do the Numbers Mean?

Blood pressure is measured in millimeters of mercury (mmHg) and is given as two numbers:

- **Systolic (top number)**: Pressure when your heart beats
- **Diastolic (bottom number)**: Pressure when your heart rests between beats

## Blood Pressure Categories

- **Normal**: Less than 120/80 mmHg
- **Elevated**: 120-129 / less than 80 mmHg
- **High Blood Pressure Stage 1**: 130-139 / 80-89 mmHg
- **High Blood Pressure Stage 2**: 140+ / 90+ mmHg
- **Hypertensive Crisis**: Higher than 180/120 mmHg

## Tips for Healthy Blood Pressure

1. Maintain a healthy weight
2. Exercise regularly
3. Eat a balanced diet low in sodium
4. Limit alcohol consumption
5. Don't smoke
6. Manage stress
7. Take prescribed medications as directed

Regular monitoring is key. Consult your doctor if your readings are consistently high.
        ''',
        'authorId': 'system',
        'authorName': 'MediCare Health Team',
        'category': 'generalHealth',
        'tags': ['blood pressure', 'heart health', 'cardiovascular'],
        'readTimeMinutes': 4,
        'views': 0,
        'likes': 0,
        'likedBy': [],
        'isPublished': true,
        'isFeatured': true,
        'publishedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      {
        'title': 'Mental Health: Signs You Should Seek Help',
        'summary': 'Recognizing when professional mental health support might benefit you.',
        'content': '''
Mental health is just as important as physical health. Here are signs that indicate it might be time to seek professional support:

## Warning Signs

- Persistent sadness or hopelessness lasting more than two weeks
- Excessive worry or fear that interferes with daily activities
- Extreme mood changes
- Withdrawal from friends and activities
- Significant changes in eating or sleeping habits
- Difficulty concentrating
- Unexplained physical symptoms
- Thoughts of self-harm

## When to Seek Help

Don't wait for a crisis. Consider reaching out if:

- Your emotions feel overwhelming
- You're using substances to cope
- Your relationships are suffering
- Work or school performance has declined
- You feel unable to handle daily tasks

## Types of Support Available

- Counseling and therapy
- Psychiatric evaluation
- Support groups
- Online mental health services
- Crisis hotlines

Remember: Seeking help is a sign of strength, not weakness. Your mental health matters.

**If you're in crisis, please contact a mental health helpline immediately.**
        ''',
        'authorId': 'system',
        'authorName': 'MediCare Health Team',
        'category': 'mentalHealth',
        'tags': ['mental health', 'anxiety', 'depression', 'wellness'],
        'readTimeMinutes': 4,
        'views': 0,
        'likes': 0,
        'likedBy': [],
        'isPublished': true,
        'isFeatured': false,
        'publishedAt': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    ];

    for (var article in sampleArticles) {
      await _firestore.collection(_collection).add(article);
    }
  }
}
