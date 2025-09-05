import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_chat_new/screens/auth_page.dart';
import 'package:flutter_chat_new/screens/home_page.dart';

import 'firebase_options.dart'; // FlutterFire CLI ile oluşturuldu

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Firebase öncesi gerekli
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //DefaultFirebaseOptions → firebase_options.dart dosyasından gelir ve platforma özgü Firebase yapılandırma seçeneklerini içerir.
  // currentPlatform → uygulamanın çalıştığı platforma (iOS, Android, web vb.) göre doğru yapılandırmayı seçer.
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<User?>(
        //kullanıcının giriş durumunu dinlemek için StreamBuilder kullandık
        //User? → Firebase Authentication'dan gelen kullanıcı nesnesi. '?' işareti, bu nesnenin null (boş) olabileceğini belirtir.
        //Yani kullanıcı giriş yapmamışsa null dönebilir.
        stream: FirebaseAuth.instance
            .authStateChanges(), //kullanıcının giriş durumunu sürekli dinleyecek instance ile firebase'den kullanıcı durumuna erişiyoruz
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomePage(); //eğer veri varsa ana sayfaya gönder
          } else {
            return AuthPage(); //eğer veri yani girş yoksa giriş sayfasında dur
          }
        },
      ),

      debugShowCheckedModeBanner:
          false, //sağ üstteki debug- çalıştırma işaretini logosunu kapatır
    );
  }
}
/* FirebaseAuth.instance.currentUser !=
              null //kullanıcı önceden giriş yaptıysa tekrar giriş yapma istemiyor
          ? HomePage() //oturum açmış kullanıcı boş değilse(!=) homepage'e
          : AuthPage(), //boşsa AuthPage'den devam. YANİ BİR IF ELSE işlemi yaptık
      //instance Firebase Authentication servisine erişim sağlar. currentUser şu an oturum açmış kullanıcıyı verir*/