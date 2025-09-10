import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_new/screens/chat_page.dart';
import 'package:flutter_chat_new/screens/users_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String formatTimestamp(Timestamp? ts) {
    if (ts == null) {
      return '...';
    } else {
      DateTime dt = ts.toDate();
      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(dt); //formatı dd/MM/yyyy HH:mm olarak ayarladık
      //sonra bu formatı dt'ye uyguladık ve string olarak döndürdük.
    }
  }

  final messageController = TextEditingController();
  final String _otherUidForTest =
      'DP7qX6JG4aP43eV2n2Kpb2KOb8Q2'; //test amaçlı başka bir kullanıcının uid'si

  String _getChatId(String currentUid, String otherUid) {
    //kullanıcı id'lerini alıp sohbet id'si oluşturma fonksiyonu
    //bir kere yazdık tekrar tekrar yazmamak için fonksiyon oluşturduk
    //uid'leri alıp sohbet id'si oluşturacak
    final ids = [currentUid, otherUid]..sort(); //uid'leri listeye attık
    return ids.join('_'); //uid'leri birleştirip sohbet id'si oluşturduk
  }

  _buildChat() async {
    //kullanıcılar arası sohbet oluşturma fonksiyonu
    final String currentUid =
        FirebaseAuth.instance.currentUser!.uid; //şu anki kullanıcının uid'si
    //şu anki kullanıcıyı alıyoruz ve uid'sini yani benzersiz kimliğini alıyoruz
    final String _otherUid = _otherUidForTest; //başka bir kullanıcının uid'si

    final chatId = _getChatId(currentUid, _otherUid); //sohbet id'si oluşturduk

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set(
      {
        'members': [currentUid, _otherUid], //sohbetin üyeleri,
        'createdAt': FieldValue.serverTimestamp(), //sohbetin oluşturulma zamanı
      },
      SetOptions(merge: true),
    ); // merge true ekledim, var ise üstüne yazmasın, eklesin

    print("chatId: $chatId");
  }

  void _signOut() async {
    //çıkkış için fonksiyon oluşturdum
    await FirebaseAuth.instance
        .signOut(); //bu fonksiyon firebase kullanıcı giriş çıkış kısmına erişiyor ve oturumu kapatıyor
    //fireBase auth'un çıkkış yapma fonksiyonunu kullanarak çıkış yapmayı sağlıyoruz yani szaten onda olan fonksiyonu kullandık biz burada
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    //currentUser → şu an oturum açmış kullanıcıyı verir
    /*Auth → "Bu kim?" (giriş yapan kullanıcı)

Firestore → "Bu kişiyle ilgili ne biliyoruz?" (e-posta, mesajlar, zaman bilgisi vb.) */

    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserPage()),
              );
            },
            icon: Icon(Icons.people),
          ),
        ],
      ),

      body: Center(
        child: Column(
          children: [
            // Sohbet listesi için StreamBuilder (chats koleksiyonu)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('members', arrayContains: currentUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Hata oluştu: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final chats = snapshot.data?.docs ?? [];

                  if (chats.isEmpty) {
                    return Center(child: Text('Henüz sohbet yok'));
                  }

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chatDoc = chats[index];
                      final data = chatDoc.data() as Map<String, dynamic>;
                      final members = List<String>.from(
                        data['members'] ?? [],
                      ); //members değişkeni, o sohbet odasına dahil olan kullanıcıların UID'lerinden oluşan bir listedir.
                      final otherUid = members.isNotEmpty
                          ? members.firstWhere(
                              (uid) => uid != currentUid,
                              orElse: () => 'Bilinmiyor',
                            )
                          : 'Bilinmiyor';
                      print("otherUid: $otherUid");

                      // Eğer otherUid bulunamadıysa (ör. tek kişilik veya veri hatası) göster
                      if (otherUid == 'Bilinmiyor') {
                        return ListTile(title: Text('Kullanıcı bulunamadı'));
                      }

                      // chat dokümanında eğer oluşturulurken kaydedilmiş fallback email varsa alalım
                      final fallbackEmail = (data['otherEmail'] as String?)
                          ?.trim();

                      // 🔹 Kullanıcı belgesini çek; yoksa fallbackEmail göster
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUid.trim())
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(title: Text('Yükleniyor...'));
                          } else if (userSnapshot.hasError) {
                            return ListTile(title: Text('Hata'));
                          }

                          String shownEmail;
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            // Eğer users koleksiyonunda belge yoksa chat içindeki fallbackEmail'i göster
                            shownEmail = fallbackEmail ?? 'Bilinmiyor';
                          } else {
                            final userData =
                                userSnapshot.data!.data()
                                    as Map<String, dynamic>?;
                            shownEmail =
                                (userData?['email'] as String?) ??
                                (fallbackEmail ?? 'Bilinmiyor');
                          }

                          // Her sohbet satırında son mesajı göstermek için messages koleksiyonunu dinle
                          return ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    chatId: chatDoc.id,
                                    otherUserEmail: shownEmail,
                                  ),
                                ),
                              );
                              print('ChatId: ${chatDoc.id}');
                            },
                            title: Text(shownEmail),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Oluşturulma zamanı: ${formatTimestamp(data['createdAt'])}",
                                ),
                                SizedBox(height: 4),

                                //her sohbet için Firestore’daki messages koleksiyonunu dinleyip, varsa son mesajı gösteriyor; yoksa “Henüz mesaj yok” yazıyor.
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(chatDoc.id)
                                      .collection('messages')
                                      .orderBy('timestamp', descending: true)
                                      .limit(1)
                                      .snapshots(), //Buradaki verileri sürekli dinleyen bir stream başlatıyoruz.
                                  builder: (context, msgSnapshot) {
                                    if (msgSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text("Yükleniyor...");
                                    }
                                    if (msgSnapshot.hasError) {
                                      return Text("Hata oluştu");
                                    }
                                    final messages =
                                        msgSnapshot.data?.docs ?? [];

                                    if (messages.isNotEmpty) {
                                      final lastMessage = messages.first;
                                      final messageData =
                                          lastMessage.data()
                                              as Map<String, dynamic>;
                                      return Text(
                                        "Son mesaj: ${messageData['text'] ?? ''}",
                                      );
                                    } else {
                                      return Text("Henüz mesaj yok");
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            SizedBox(height: 20),
            Column(
              children: [
                SizedBox(
                  width:
                      MediaQuery.of(context).size.width * 0.4, // aynı genişlik
                  //mediaQuery → ekran boyutlarına erişmek için kullanılır
                  //.size.width → ekranın genişliğini pixel cinsinden verir.
                  //* 0.4 → bu genişliğin %40’ını alır.
                  child: ElevatedButton(
                    onPressed: _signOut,
                    child: Text('Çıkış Yap'),
                  ),
                ),
                SizedBox(height: 10),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: ElevatedButton(
                    onPressed: _buildChat,
                    child: Text('Sohbet Oluştur'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//buildChat içinde kullanılan currentId ohbet odasını oluştururken kullanılıyor. Yani kimlerle sohbet odası açılacağını belirlem
//elevatedButton içinde kullanılan currentId ise, mesaj gönderirken kullanılıyor. Yani mesajın hangi kullanıcı tarafından gönderildiğini belirlemek için.
