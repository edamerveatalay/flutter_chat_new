import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart'; // ChatPage'i import ediyoruz

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  // iki kullanıcının uid'sinden benzersiz bir chatId üret
  String _getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kullanıcılar')),
      body: StreamBuilder<QuerySnapshot>(
        //Yani bir koleksiyondaki belgelerin (documents) toplu halidir.
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            //.connectionState → bu akışın şu anki durumunu verir.
            //"Eğer stream henüz veriyi getirmediyse (bekleme aşamasındaysa) ..." demek.
            return Center(child: CircularProgressIndicator());
            //"Veri gelene kadar ekranda ortalanmış bir yükleniyor animasyonu göster."
          }
          if (snapshot.hasError) {
            return Text('hata oluştu');
          } else {
            final users = snapshot
                .data!
                .docs; //users koleksiyonundaki belgelerdeki verileri alırız
            return ListView.builder(
              itemCount: users
                  .length, //aldığımız belgedeki verilerin uzunluğu kadar liste oluşturur
              itemBuilder: (context, index) {
                final userDoc = users[index]; //belge
                final data = //belge içindeki veriler
                    userDoc.data()
                        as Map<
                          String,
                          dynamic
                        >; //doğrudan okumuyoruz, önce map'e çeviriyoruz
                final email =
                    data['email'] ?? '-'; //eğer email yoksa '-' göster

                final ts = data['createdAt'] as Timestamp?;
                final created = ts == null
                    ? '-'
                    : DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());

                final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                final otherUserId = userDoc.id; // belge id = user id (uid)
                final chatId = _getChatId(currentUserId, otherUserId);

                return ListTile(
                  //her kullanıcı için bir liste öğesi oluşturur
                  title: Text(email),
                  subtitle: Text('Oluşturulma zamanı: $created'),
                  onTap: () async {
                    // kullanıcıya tıklanınca sohbet sayfasına git
                    // ⚠️ Burada chat belgesini yoksa oluşturuyoruz — böylece
                    // HomePage'de kullanıcı belgesi eksik olsa bile otherEmail'den gösterir.
                    final chatRef = FirebaseFirestore.instance
                        .collection('chats')
                        .doc(chatId);
                    final chatSnapshot = await chatRef.get();
                    if (!chatSnapshot.exists) {
                      await chatRef.set({
                        'members': [currentUserId, otherUserId],
                        'createdAt': FieldValue.serverTimestamp(),
                        'otherEmail':
                            email, // fallback için chat içinde email saklıyoruz
                      }, SetOptions(merge: true));
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatPage(chatId: chatId, otherUserEmail: email),
                      ),
                    );
                  },
                ); //created stringe çevir
                //lisTile kullanıcıyı listeye ekle
              },
            );
          }
        },
      ),
    );
  }
}
