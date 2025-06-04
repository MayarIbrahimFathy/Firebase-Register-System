import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    void _showPostDialog({String? docId, String? existingContent}) {
      final TextEditingController controller =
          TextEditingController(text: existingContent ?? '');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            docId == null ? 'Add Post' : 'Edit Post',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            maxLines: null,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter your post',
              hintStyle: TextStyle(color: Colors.white60),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = controller.text.trim();
                if (content.isNotEmpty) {
                  if (docId == null) {
                    await firestore.collection('posts').add({
                      'content': content,
                      'userEmail': user?.email ?? 'Anonymous',
                      'createdAt': FieldValue.serverTimestamp(),
                      'likes': 0,
                      'comments': [],
                    });
                  } else {
                    await firestore.collection('posts').doc(docId).update({
                      'content': content,
                    });
                  }
                }
                Navigator.pop(context);
              },
              child: Text(docId == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      );
    }

    Future<void> _deletePost(String docId) async {
      await firestore.collection('posts').doc(docId).delete();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Welcome'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color.fromARGB(255, 138, 15, 15)),
            onPressed: () => _showPostDialog(),
            tooltip: 'Add Post',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color.fromARGB(255, 138, 15, 15)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.email ?? "User"}!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Posts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Text(
                      'Error loading posts',
                      style: TextStyle(color: Color.fromARGB(255, 138, 15, 15)),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text(
                      'No posts available',
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  final posts = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final content =
                          post['content'] as String? ?? 'No content';
                      final userEmail =
                          post['userEmail'] as String? ?? 'Anonymous';

                      final likes = post['likes'] ?? 0;
                      final comments =
                          List<String>.from(post['comments'] ?? []);

                      Future<void> _incrementLike() async {
                        final postRef =
                            firestore.collection('posts').doc(post.id);
                        await postRef.update({
                          'likes': FieldValue.increment(1),
                        });
                      }

                      void _showCommentDialog() {
                        final TextEditingController commentController =
                            TextEditingController();

                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: const Text('Add Comment',
                                style: TextStyle(color: Colors.white)),
                            content: TextField(
                              controller: commentController,
                              maxLines: null,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Write your comment',
                                hintStyle: TextStyle(color: Colors.white60),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.white)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final commentText =
                                      commentController.text.trim();
                                  if (commentText.isNotEmpty) {
                                    await firestore
                                        .collection('posts')
                                        .doc(post.id)
                                        .update({
                                      'comments':
                                          FieldValue.arrayUnion([commentText])
                                    });
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userEmail,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                content,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.favorite,
                                        color:
                                            Color.fromARGB(255, 185, 36, 26)),
                                    onPressed: _incrementLike,
                                  ),
                                  Text('$likes',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                  const SizedBox(width: 20),
                                  IconButton(
                                    icon: const Icon(Icons.comment,
                                        color: Colors.blue),
                                    onPressed: _showCommentDialog,
                                  ),
                                  Text('${comments.length}',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ],
                              ),
                              if (comments.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Comments',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...comments.map((c) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Text(
                                        c,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    )),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _showPostDialog(
                                      docId: post.id,
                                      existingContent: content,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromARGB(255, 82, 78, 78),
                                    ),
                                    child: const Text('Edit',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color:
                                            Color.fromARGB(255, 138, 15, 15)),
                                    onPressed: () => _deletePost(post.id),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
