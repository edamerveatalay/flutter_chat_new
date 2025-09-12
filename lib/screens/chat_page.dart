import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserEmail;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserEmail,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false; // yükleniyor mu kontrolü

  // 📌 FOTOĞRAF SEÇME + YÜKLEME
  Future<void> _sendImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final File file = File(pickedFile.path);
    final currentId = FirebaseAuth.instance.currentUser!.uid;

    try {
      setState(() => _isUploading = true);

      // Firebase Storage’a yükleme
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // Firestore’a imageUrl kaydetme
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
            'text': '', // text boş olsa da ekleyelim
            'imageUrl': imageUrl,
            'senderId': currentId,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print("Resim yükleme hatası: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserEmail)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Hata Oluştu');
                }
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final text = data['text'] ?? '';
                    final imageUrl = data['imageUrl'];
                    final senderId = data['senderId'] ?? '';
                    final timestamp = data['timestamp'];
                    final isMe =
                        senderId == FirebaseAuth.instance.currentUser!.uid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[400] : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isMe ? 12 : 0),
                              topRight: Radius.circular(isMe ? 0 : 12),
                              bottomLeft: const Radius.circular(12),
                              bottomRight: const Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (text.isNotEmpty)
                                Text(
                                  text,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              if (imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      imageUrl,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                timestamp != null
                                    ? (timestamp as Timestamp)
                                          .toDate()
                                          .toString()
                                    : '',
                                style: TextStyle(
                                  color: isMe ? Colors.white70 : Colors.black54,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 📌 MESAJ GÖNDERME KISMI
          if (_isUploading)
            LinearProgressIndicator(minHeight: 3, color: Colors.green),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo, color: Colors.green),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      prefixIcon: const Icon(Icons.message),
                      labelText: 'Mesajınızı girin',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: () async {
                    if (messageController.text.trim().isEmpty) return;

                    final currentId = FirebaseAuth.instance.currentUser!.uid;

                    await FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('messages')
                        .add({
                          'text': messageController.text,
                          'imageUrl': null,
                          'senderId': currentId,
                          'timestamp': FieldValue.serverTimestamp(),
                        });

                    messageController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
