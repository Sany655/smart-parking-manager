import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UndevelopedFeedbackScreen extends StatefulWidget {
  const UndevelopedFeedbackScreen({super.key});

  @override
  State<UndevelopedFeedbackScreen> createState() =>
      _UndevelopedFeedbackScreenState();
}

class _UndevelopedFeedbackScreenState extends State<UndevelopedFeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentsController = TextEditingController();
  double _rating = 3.0;
  bool _isLoading = false;
  int? _userId;
  List<Map<String, dynamic>> _userFeedbacks = [];
  int? _editingFeedbackId;
  double _editingRating = 3.0;
  List<bool> _visibleFlags = [];
  double _submitButtonScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      setState(() {
        _userId = userId;
      });
      if (userId != null) {
        _fetchUserFeedbacks(userId);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchUserFeedbacks(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/undeveloped-feedback/user/$userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _userFeedbacks = List<Map<String, dynamic>>.from(data);
          _visibleFlags = List<bool>.filled(_userFeedbacks.length, false);
        });

        // Staggered reveal animation
        for (int i = 0; i < _userFeedbacks.length; i++) {
          Future.delayed(Duration(milliseconds: 80 * i), () {
            if (!mounted) return;
            setState(() {
              _visibleFlags[i] = true;
            });
          });
        }
      }
    } catch (e) {
      print('Error fetching feedbacks: $e');
    }
  }

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User information not found. Please login again.'),
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/undeveloped-feedback/submit'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'user_id': _userId,
            'rating': _rating.toInt(),
            'comments': _commentsController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you! Your feedback has been submitted successfully.'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear form
          _commentsController.clear();
          setState(() {
            _rating = 3.0;
          });

          // Refresh feedbacks
          if (_userId != null) {
            _fetchUserFeedbacks(_userId!);
          }
        } else {
          final errorData = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${errorData['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateFeedback(int feedbackId, String comments, double rating) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/undeveloped-feedback/update/$feedbackId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': _userId,
          'rating': rating.toInt(),
          'comments': comments,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _editingFeedbackId = null;
        });
        if (_userId != null) {
          _fetchUserFeedbacks(_userId!);
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${errorData['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteFeedback(int feedbackId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/undeveloped-feedback/delete/$feedbackId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': _userId,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback deleted successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        if (_userId != null) {
          _fetchUserFeedbacks(_userId!);
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${errorData['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Share Feedback'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Submit Feedback'),
              Tab(text: 'Your Feedback'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Submit Feedback Form
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Rate your experience:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rating Widget
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 40,
                            ),
                            onPressed: () {
                              setState(() {
                                _rating = (index + 1).toDouble();
                              });
                            },
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Comments Input
                    const Text(
                      'Your Comments:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _commentsController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Share your feedback, suggestions, or concerns...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your feedback';
                        }
                        if (value.length < 5) {
                          return 'Feedback must be at least 5 characters';
                        }
                        return null;
                      },
                      maxLength: 500,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : GestureDetector(
                            onTapDown: (_) {
                              setState(() => _submitButtonScale = 0.98);
                            },
                            onTapUp: (_) {
                              setState(() => _submitButtonScale = 1.0);
                              _submitFeedback();
                            },
                            onTapCancel: () {
                              setState(() => _submitButtonScale = 1.0);
                            },
                            child: AnimatedScale(
                              scale: _submitButtonScale,
                              duration: const Duration(milliseconds: 120),
                              child: ElevatedButton(
                                onPressed: null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2575FC),
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Submit Feedback',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),

            // Tab 2: Your Feedback
            _userFeedbacks.isEmpty
                ? const Center(
                    child: Text('No feedback submitted yet.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _userFeedbacks.length,
                    itemBuilder: (context, index) {
                      final feedback = _userFeedbacks[index];
                      final feedbackId = feedback['feedback_id'];
                      final rating = feedback['rating'] ?? 0;
                      final comments = feedback['comments'] ?? '';
                      final createdAt = feedback['created_at'] ?? 'Unknown';
                      final isEditing = _editingFeedbackId == feedbackId;

                      final visible = index < _visibleFlags.length && _visibleFlags[index];

                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 400),
                        opacity: visible ? 1.0 : 0.0,
                        curve: Curves.easeOut,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          transform: Matrix4.translationValues(0, visible ? 0 : 16, 0),
                          child: VxBox(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: isEditing
                                  ? _buildEditForm(feedbackId, comments, rating.toDouble())
                                  : Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header with rating and action buttons
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(5, (i) {
                                                return Icon(
                                                  i < rating
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: Colors.amber,
                                                  size: 20,
                                                );
                                              }),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.indigo),
                                                  onPressed: () {
                                                    setState(() {
                                                      _editingFeedbackId =
                                                          feedbackId;
                                                      _editingRating =
                                                          rating.toDouble();
                                                    });
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.redAccent),
                                                  onPressed: () {
                                                    _deleteFeedback(feedbackId);
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const Divider(),

                                        // Comments
                                        comments.text.size(14).make(),
                                        const SizedBox(height: 12),

                                        // Submitted date
                                        'Submitted: $createdAt'
                                            .text
                                            .sm
                                            .gray600
                                            .make(),
                                      ],
                                    ),
                            ),
                          ).white.roundedLg.shadowLg.make(),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm(
      int feedbackId, String originalComments, double originalRating) {
    final editCommentsController =
        TextEditingController(text: originalComments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Edit Rating:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _editingRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 30,
                ),
                onPressed: () {
                  setState(() {
                    _editingRating = (index + 1).toDouble();
                  });
                },
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Edit Comments:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: editCommentsController,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLength: 500,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _editingFeedbackId = null;
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        _updateFeedback(
                          feedbackId,
                          editCommentsController.text,
                          _editingRating,
                        );
                      },
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }
}
