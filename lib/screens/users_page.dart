import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserPage extends StatelessWidget {
  const UserPage.UsersPage({super.key});

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
                //userDoc['email'] → Firestore’daki belgeden email alanını alır.
                //?? '-' → eğer email alanı yoksa hata vermesin, yerine '-' göstersin.

                final ts = data['createdAt'] as Timestamp?;
                // Firestore'dan alınan 'createdAt' alanını Timestamp türüne dönüştürür.
                //Timestamp → Firestore'da tarih ve saat bilgisini tutmak için kullanılan özel bir veri türüdür.
                // '?' işareti, bu alanın null (boş) olabileceğini belirtir.
                final created = ts == null
                    ? '-'
                    : DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
                //oluşturulma zamanını okunabilir hale getir”
                return ListTile(
                  //her kullanıcı için bir liste öğesi oluşturur
                  //Flutter’da liste içinde tek bir satırdır (başlık, alt başlık, ikon koyabilirsin).
                  title: Text(email),
                  subtitle: Text('Oluşturulma zamanı: $created'),
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
