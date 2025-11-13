import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageFeedbackScreen extends StatefulWidget {
  const ManageFeedbackScreen({super.key});

  @override
  State<ManageFeedbackScreen> createState() => _ManageFeedbackScreenState();
}

class _ManageFeedbackScreenState extends State<ManageFeedbackScreen> {
  late Future<List<dynamic>> _feedbackFuture;

  @override
  void initState() {
    super.initState();
    _feedbackFuture = _fetchFeedback();
  }

  // Fetch all feedback from API
  Future<List<dynamic>> _fetchFeedback() async {
    final url = Uri.parse('http://localhost:3000/feedback/all');
    try {
      final httpResponse = await http.get(url);

      if (httpResponse.statusCode == 200) {
        final List<dynamic> data = List.from(jsonDecode(httpResponse.body));
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
    final url = Uri.parse('http://localhost:3000/feedback/delete/$feedbackId');
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
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Feedback'),
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
                final message = feedback['comments'] ?? feedback['message'] ?? '';
                final createdAt = feedback['created_at'] ?? 'Unknown';
                final feedbackId = feedback['feedback_id'] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
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
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildStarRating(rating),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmDialog(feedbackId, userName);
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        // Feedback message
                        if (message.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              message,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Created date
                        Text(
                          'Submitted: $createdAt',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
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
