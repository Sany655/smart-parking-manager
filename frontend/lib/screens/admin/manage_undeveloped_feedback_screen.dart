import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageUndevelopedFeedbackScreen extends StatefulWidget {
  const ManageUndevelopedFeedbackScreen({super.key});

  @override
  State<ManageUndevelopedFeedbackScreen> createState() =>
      _ManageUndevelopedFeedbackScreenState();
}

class _ManageUndevelopedFeedbackScreenState
    extends State<ManageUndevelopedFeedbackScreen> {
  late Future<List<dynamic>> _feedbackFuture;
  List<bool> _visibleFlags = [];

  @override
  void initState() {
    super.initState();
    _feedbackFuture = _fetchFeedback();
  }

  // Fetch all undeveloped feedback from API
  Future<List<dynamic>> _fetchFeedback() async {
    final url = Uri.parse('http://localhost:3000/undeveloped-feedback/all');
    try {
      final httpResponse = await http.get(url);

      if (httpResponse.statusCode == 200) {
        final List<dynamic> data = List.from(jsonDecode(httpResponse.body));

        // initialize visibility flags for staggered animation
        _visibleFlags = List<bool>.filled(data.length, false);
        // schedule reveal
        for (int i = 0; i < data.length; i++) {
          Future.delayed(Duration(milliseconds: 70 * i), () {
            if (!mounted) return;
            setState(() {
              _visibleFlags[i] = true;
            });
          });
        }

        return data;
      } else {
        throw Exception('Failed to load feedback');
      }
    } catch (e) {
      throw Exception('Failed to load feedback: $e');
    }
  }

  // Delete feedback by ID
  Future<void> _deleteFeedback(int feedbackId) async {
    final url =
        Uri.parse('http://localhost:3000/undeveloped-feedback/delete/$feedbackId');
    try {
      final httpResponse = await http.delete(url);

      if (httpResponse.statusCode == 200) {
        setState(() {
          _feedbackFuture = _fetchFeedback();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Feedback deleted successfully!')),
          );
        }
      } else {
        throw Exception('Failed to delete feedback');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting feedback: $e')),
        );
      }
    }
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmDialog(int feedbackId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Feedback'),
          content: Text('Are you sure you want to delete feedback from $userName?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteFeedback(feedbackId);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Build star rating widget
  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage User Feedback'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _feedbackFuture = _fetchFeedback();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _feedbackFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading feedback: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No feedback available.'));
          } else {
            final feedbackList = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: feedbackList.length,
              itemBuilder: (context, index) {
                final feedback = feedbackList[index];
                final userName = feedback['username'] ?? 'Anonymous';
                final rating = feedback['rating'] ?? 0;
                final comments = feedback['comments'] ?? '';
                final createdAt = feedback['created_at'] ?? 'Unknown';
                final updatedAt = feedback['updated_at'] ?? 'Unknown';
                final feedbackId = feedback['feedback_id'] ?? 0;

                final visible = index < _visibleFlags.length && _visibleFlags[index];

                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 380),
                  opacity: visible ? 1.0 : 0.0,
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    transform: Matrix4.translationValues(0, visible ? 0 : 12, 0),
                    child: VxBox(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with user name and rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      userName.text.xl.bold.white.make(),
                                      const SizedBox(height: 6),
                                      _buildStarRating(rating),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () {
                                    _showDeleteConfirmDialog(feedbackId, userName);
                                  },
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),

                            // Feedback comments
                            if (comments.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: comments.text.white.size(14).make(),
                              ),
                            const SizedBox(height: 12),

                            // Timestamps
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                'Submitted: $createdAt'.text.gray300.sm.make(),
                                if (updatedAt != createdAt && updatedAt != 'Unknown')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: 'Updated: $updatedAt'.text.orange400.sm.make(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).color(const Color(0xFF1F2937)).roundedLg.shadowXs.make().p16(),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
