import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ChatPage extends StatefulWidget {
  final String chatId; // dışarıdan gelecek chatId'yi al
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

  // 📌 FOTOĞRAF SEÇME + YÜKLEME
  Future<void> _sendImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final File file = File(pickedFile.path);
    final currentId = FirebaseAuth.instance.currentUser!.uid;

    try {
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
            'imageUrl': imageUrl,
            'senderId': currentId,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print("Resim yükleme hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat ID: ${widget.otherUserEmail}')),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Sürekli değişen bir veriyi (stream) dinleyip UI’ı güncellemek için kullanılır.
                // chatId alıp o chatId'ye ait mesajları dinle
                stream: FirebaseFirestore.instance
                    .collection(
                      'chats',
                    ) // chats isimli koleksiyon (tüm sohbetler)
                    .doc(widget.chatId) // belirli bir sohbet seçiyoruz
                    .collection(
                      'messages',
                    ) // o sohbetin içindeki messages koleksiyonu
                    .orderBy(
                      'timestamp',
                      descending: true,
                    ) // mesajları zamanına göre sıralıyoruz
                    .snapshots(), // snapshots() → Firestore'daki verilerin gerçek zamanlı olarak dinlenmesini sağlar.
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Hata Oluştu');
                  } else {
                    final docs = snapshot
                        .data!
                        .docs; // dosyadaki veriyi aldık snapshot ile

                    // Mesajları listelemek için ListView kullandık
                    return ListView.builder(
                      reverse:
                          true, // listeyi ters çeviriyoruz ki en yeni mesaj en altta olsun
                      itemCount: docs.length, // mesaj sayısı
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final text = data['text'] ?? '';
                        final imageUrl = data['imageUrl']; // 📸 Fotoğraf URL'si
                        final senderId = data['senderId'] ?? '';
                        final timestamp = data['timestamp'];
                        final isMe =
                            senderId ==
                            FirebaseAuth
                                .instance
                                .currentUser!
                                .uid; // mesajı gönderen ben miyim?

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment
                                      .centerLeft, // kendi mesajım sağda diğerleri solda
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue[400]
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(isMe ? 12 : 0),
                                  topRight: Radius.circular(isMe ? 0 : 12),
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (text.isNotEmpty)
                                    Text(
                                      text, // firestore’daki mesajın text'i
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 16,
                                      ),
                                    ),
                                  if (imageUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Image.network(
                                        imageUrl,
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  SizedBox(height: 4),
                                  Text(
                                    timestamp != null
                                        ? (timestamp as Timestamp)
                                              .toDate()
                                              .toString()
                                        : '',
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
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
                  }
                },
              ),
            ),

            // 📌 MESAJ GÖNDERME KISMI
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.photo, color: Colors.green),
                    onPressed: _sendImage, // fotoğraf gönder
                  ),
                  Expanded(
                    child: TextField(
                      controller:
                          messageController, // mesaj girişini kontrol edecek controller
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        prefixIcon: Icon(Icons.message),
                        labelText: 'Mesajınızı girin',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: () async {
                      if (messageController.text.trim().isEmpty)
                        return; // boş mesaj gönderilmesin

                      final currentId = FirebaseAuth.instance.currentUser!.uid;

                      // Firestore’a mesaj kaydetme
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(widget.chatId)
                          .collection('messages')
                          .add({
                            'text': messageController.text,
                            'senderId': currentId,
                            'timestamp': FieldValue.serverTimestamp(),
                          });

                      messageController
                          .clear(); // gönderildikten sonra input temizlenir
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
