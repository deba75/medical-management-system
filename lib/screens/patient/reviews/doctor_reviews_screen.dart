import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/doctor_review_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/doctor_review_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorReviewsScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String doctorName;

  const DoctorReviewsScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
  });

  @override
  ConsumerState<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends ConsumerState<DoctorReviewsScreen> {
  final _reviewService = DoctorReviewService();
  final _patientId = FirebaseAuth.instance.currentUser?.uid ?? '';
  DoctorRatingSummary? _ratingSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRatingSummary();
  }

  void _loadRatingSummary() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _reviewService.getDoctorRatingSummary(widget.doctorId);
      setState(() {
        _ratingSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for Dr. ${widget.doctorName}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadRatingSummary(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildRatingSummaryCard()),
                  SliverToBoxAdapter(child: _buildWriteReviewButton()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Patient Reviews',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  _buildReviewsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildRatingSummaryCard() {
    if (_ratingSummary == null) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No reviews yet'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      _ratingSummary!.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    _buildStarRating(_ratingSummary!.averageRating),
                    const SizedBox(height: 4),
                    Text(
                      '${_ratingSummary!.totalReviews} reviews',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, _ratingSummary!.fiveStarCount),
                      _buildRatingBar(4, _ratingSummary!.fourStarCount),
                      _buildRatingBar(3, _ratingSummary!.threeStarCount),
                      _buildRatingBar(2, _ratingSummary!.twoStarCount),
                      _buildRatingBar(1, _ratingSummary!.oneStarCount),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'Would Recommend',
                  '${_ratingSummary!.recommendationPercentage.toInt()}%',
                  Icons.thumb_up_outlined,
                ),
                _buildStatColumn(
                  'Verified Reviews',
                  '${_ratingSummary!.verifiedReviewsCount}',
                  Icons.verified_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    final total = _ratingSummary!.totalReviews;
    final percentage = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars', style: const TextStyle(fontSize: 12)),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                color: AppTheme.primaryColor,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$count',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<bool> _canUserReviewDoctor() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUserId.isEmpty) return false;

    try {
      // 1. Check if patient has received a prescription from this doctor
      final prescriptionQuery = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('userId', isEqualTo: currentUserId)
          .where('doctorId', isEqualTo: widget.doctorId)
          .limit(1)
          .get();

      if (prescriptionQuery.docs.isNotEmpty) return true;

      // 2. Check if patient has a completed appointment with this doctor
      final appointmentQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('patientId', isEqualTo: currentUserId)
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('status', isEqualTo: 'completed')
          .limit(1)
          .get();

      if (appointmentQuery.docs.isNotEmpty) return true;

      // 3. Fallback check by doctor name in prescriptions
      final altPrescriptionQuery = await FirebaseFirestore.instance
          .collection('prescriptions')
          .where('userId', isEqualTo: currentUserId)
          .where('doctorName', isEqualTo: widget.doctorName)
          .limit(1)
          .get();

      if (altPrescriptionQuery.docs.isNotEmpty) return true;
    } catch (e) {
      debugPrint('Error verifying review permission: $e');
    }

    return false;
  }

  void _handleWriteReviewPressed() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final canReview = await _canUserReviewDoctor();
    if (mounted) Navigator.pop(context); // Close loading dialog

    if (!canReview) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.amber),
                SizedBox(width: 8),
                Text('Consultation Required'),
              ],
            ),
            content: Text(
              'You can only rate or review Dr. ${widget.doctorName} after you have completed a consultation and received a prescription from them.',
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    _showWriteReviewDialog();
  }

  Widget _buildWriteReviewButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _handleWriteReviewPressed,
        icon: const Icon(Icons.rate_review),
        label: const Text('Write a Review'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder<List<DoctorReviewModel>>(
      stream: _reviewService.getDoctorReviews(widget.doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Text('Be the first to write a review!'),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              return _buildReviewCard(snapshot.data![index]);
            },
            childCount: snapshot.data!.length,
          ),
        );
      },
    );
  }

  Widget _buildReviewCard(DoctorReviewModel review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    review.patientName.isNotEmpty
                        ? review.patientName[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.isAnonymous ? 'Anonymous' : review.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (review.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getRatingColor(review.rating).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: _getRatingColor(review.rating),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getRatingColor(review.rating),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.reviewText ?? ''),
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: review.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (review.doctorReply != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: AppTheme.primaryColor),
                        SizedBox(width: 4),
                        Text(
                          'Doctor\'s Response',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.doctorReply!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                InkWell(
                  onTap: () => _toggleHelpful(review),
                  child: Row(
                    children: [
                      Icon(
                        review.helpfulBy.contains(_patientId)
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        size: 18,
                        color: review.helpfulBy.contains(_patientId)
                            ? AppTheme.primaryColor
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Helpful (${review.helpfulCount})',
                        style: TextStyle(
                          fontSize: 12,
                          color: review.helpfulBy.contains(_patientId)
                              ? AppTheme.primaryColor
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showWriteReviewDialog() {
    int rating = 5;
    final titleController = TextEditingController();
    final reviewController = TextEditingController();
    bool wouldRecommend = true;
    bool isAnonymous = false;
    final selectedTags = <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Write a Review',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Your Rating'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setModalState(() => rating = index + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Review Title (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reviewController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Your Review',
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tags (select all that apply)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReviewTags.allTags.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Would you recommend this doctor?'),
                    value: wouldRecommend,
                    onChanged: (value) {
                      setModalState(() => wouldRecommend = value ?? true);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Post anonymously'),
                    value: isAnonymous,
                    onChanged: (value) {
                      setModalState(() => isAnonymous = value ?? false);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: reviewController.text.isNotEmpty
                          ? () => _submitReview(
                                rating,
                                titleController.text,
                                reviewController.text,
                                selectedTags,
                                wouldRecommend,
                                isAnonymous,
                              )
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitReview(
    int rating,
    String title,
    String reviewText,
    List<String> tags,
    bool wouldRecommend,
    bool isAnonymous,
  ) async {
    Navigator.pop(context);

    try {
      // Get patient name
      final userDoc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(_patientId)
          .get();
      final patientName = userDoc.data()?['name'] ?? 'Patient';

      final review = DoctorReviewModel(
        id: '',
        doctorId: widget.doctorId,
        patientId: _patientId,
        patientName: patientName,
        appointmentId: '', // Will be set by service if verified
        rating: rating.toDouble(),
        reviewText: reviewText.isNotEmpty ? reviewText : null,
        tags: tags,
        isAnonymous: isAnonymous,
        isVerified: false, // This would be checked against appointments
        helpfulCount: 0,
        helpfulBy: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _reviewService.submitReview(review);
      _loadRatingSummary();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleHelpful(DoctorReviewModel review) async {
    try {
      await _reviewService.toggleHelpful(review.id, _patientId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} weeks ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}
