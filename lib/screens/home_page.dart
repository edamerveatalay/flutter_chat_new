import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'members': [currentUid, _otherUid], //sohbetin üyeleri,
      'createdAt': FieldValue.serverTimestamp(), //sohbetin oluşturulma zamanı
    });

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
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),

      body: Center(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                //mesajları listelemek için streambuilder kullandık
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(
                      _getChatId(
                        FirebaseAuth.instance.currentUser!.uid,
                        _otherUidForTest,
                      ),
                    ) //sohbet id'si ile o sohbete ait mesajları alıyoruz
                    .collection('messages')
                    .orderBy(
                      'timestamp',
                      descending: true,
                    ) //mesajları zamanına göre sıralıyoruz en yeni en üstte olacak şekilde
                    .snapshots(), //snapshots() → Firestore'daki verilerin gerçek zamanlı olarak dinlenmesini sağlar. Yani verilerde bir değişiklik olduğunda otomatik olarak güncellenir.
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Hata oluştu: ${snapshot.error}');
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); //yükleniyor göstergesi
                  }
                  final messages = snapshot.data!.docs; //mesaj belgeleri

                  return ListView.builder(
                    reverse:
                        true, //listeyi ters çeviriyoruz ki en yeni mesaj en üstte olsun
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe =
                          message['senderId'] ==
                          FirebaseAuth
                              .instance
                              .currentUser!
                              .uid; //mesajı gönderen benim mi kontrolü

                      return ListTile(
                        title: Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message['text'],
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),

            TextField(
              //mesaj giriş alanı
              //textField → kullanıcıdan metin girişi almak için kullanılan bir widget'tır.
              controller:
                  messageController, //mesaj girişini kontrol edecek controller'ı bağladık
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText:
                    'Mesajınızı girin', //labelText → TextField'ın içinde, kullanıcının ne yapması gerektiğini belirten bir etiket (label) metni gösterir.
                //labetText ve hintText arasındaki fark: labelText, TextField'ın içinde kalıcı olarak gösterilir ve kullanıcının ne yapması gerektiğini belirtir. hintText ise, TextField boşken gösterilen ve kullanıcıya ipucu veren geçici bir metindir.
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final currentId = FirebaseAuth.instance.currentUser!.uid;
                final chatId = _getChatId(
                  currentId,
                  _otherUidForTest,
                ); //burada da bir daha oluşturduk çünkü mesaj gönderirken de kime göndereceğimi bilmek için gerekiyor

                //zaman alacak bir işlem yapacağımız için async yaptık
                //butona basılınca mesaj gönderme fonksiyonu
                //butona basılınca olacak şeyi onPressed ile belirtiyoruz

                await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .add({
                      //.instance → o anda kullanılan Firestore servisine erişiyoruz (singleton, yani tek bir kopya).
                      //Firestore’da messages adında bir koleksiyon (tablo gibi düşünebilirsin) seçiyoruz.
                      //add() ile bu koleksiyona yeni bir belge (document) ekliyoruz.
                      //Belge, bir harita (map) olarak tanımlanıyor. Burada sadece 'text' alanı var ve değeri 'Merhaba'.
                      'text': messageController
                          .text, //mesaj giriş alanındaki yazıyı alıp 'text' alanına atıyoruz
                      //text alanı → Firestore’da bu belgenin içinde bir alan (field) oluşturur ve mesajın içeriğini tutar.
                      'senderId': currentId, //mesajı gönderenin uid'si
                      'timestamp':
                          FieldValue.serverTimestamp(), //mesajın gönderilme zamanı (sunucu zamanı)
                    }); //Yani Firestore’da şu şekilde bir kayıt oluşur:
                messageController
                    .clear(); // mesajı gönderdikten sonra inputu temizle
              },
              child: Text('Mesaj gönder'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signOut, //fonksiyonu çağırmıyoruz referans veriyoruz
              child: Text('Çıkış Yap'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _buildChat,
              child: Text('Sohbet Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
//buildChat içinde kullanılan currentId ohbet odasını oluştururken kullanılıyor. Yani kimlerle sohbet odası açılacağını belirlemek için.
//elevatedButton içinde kullanılan currentId ise, mesaj gönderirken kullanılıyor. Yani mesajın hangi kullanıcı tarafından gönderildiğini belirlemek için.