import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
            ElevatedButton(
              onPressed: () async {
                //zaman alacak bir işlem yapacağımız için async yaptık
                //butona basılınca mesaj gönderme fonksiyonu
                //butona basılınca olacak şeyi onPressed ile belirtiyoruz
                await FirebaseFirestore.instance.collection('messages').add({
                  //.instance → o anda kullanılan Firestore servisine erişiyoruz (singleton, yani tek bir kopya).
                  //Firestore’da messages adında bir koleksiyon (tablo gibi düşünebilirsin) seçiyoruz.
                  //add() ile bu koleksiyona yeni bir belge (document) ekliyoruz.
                  //Belge, bir harita (map) olarak tanımlanıyor. Burada sadece 'text' alanı var ve değeri 'Merhaba'.
                  'text': 'Merhaba',
                }); //Yani Firestore’da şu şekilde bir kayıt oluşur:
              },
              child: Text('Mesaj gönder'),
            ),
            ElevatedButton(
              onPressed: _signOut, //fonksiyonu çağırmıyoruz referans veriyoruz
              child: Text('Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }
}
