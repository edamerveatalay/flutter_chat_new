import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
                    ) // mesajları zamanına göre sıralıyoruz en yeni en üstte olacak şekilde
                    .snapshots(), // snapshots() → Firestore'daki verilerin gerçek zamanlı olarak dinlenmesini sağlar.
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // bağlantı durumu kontrolü
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    // hata kontrolü
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
                                    : Colors
                                          .grey
                                          .shade200, // kendi mesajlarım mavi diğerleri gri
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
                                  Text(
                                    text, // firestore’daki mesajın text'i
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                      fontSize: 16,
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
                                          ? Colors
                                                .white70 // kendi mesajlarım
                                          : Colors.black54, // diğer mesajlar
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
                  Expanded(
                    child: TextField(
                      controller:
                          messageController, // mesaj girişini kontrol edecek controller
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        prefixIcon: Icon(Icons.message),
                        suffixIcon: Icon(Icons.photo),
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
