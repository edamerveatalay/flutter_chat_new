import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_new/screens/home_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _signUp() async {
    String email = emailController.text;
    String password = passwordController.text;

    print('email: $email ');
    print('password: $password');

    print("Firestore’a yazılıyor...");

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      FirebaseFirestore.instance
          .collection(
            'users',
          ) // Firestore’da users adında bir koleksiyon oluşturduk
          .doc(
            FirebaseAuth
                .instance
                .currentUser! // belgenin adı = o kullanıcının UID’si olur
                .uid,
          ) //şu anki kullanıcıyı alıyoruz ve uid'sini yani benzersiz kimliğini alıyoruz
          .set({
            'email': email, // belgeye "email" alanını ekler
            'password': password, // belgeye "password" alanını ekler
          });
      // !!!!!FirebaseAuth sadece giriş-çıkış içindir, Firestore ise kullanıcıya dair ek bilgileri tutmamıza yarar.

      Navigator.pushReplacement(
        //navigator sayfalar arası geçişi sağlar
        //pushReplacement yeni oluşturulan sayfayı üzerine ekler yani bu sayfaya gele geri tuşuna basıp eski sayfaya geçemez
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      print("Hata: $e");
      /*ScaffoldMessenger.of(
        //geçici mesajları göstermek için kullanılan bir fonksiyon
        context, //context bağlı olduğu yani kullanıldığını widgetın bağlı olduğu widgetı bulur
        //hangi sayfada bu bağlı olduğu widget'takini göstereceğini bulmayı sağlar
      ).showSnackBar(SnackBar(content: Text(e.toString())));*/ //hepsinde aynı mesajı vermek yerine hata kodlarına göre farklı mesajlar verelim
      if (e.code == 'email-already-in-use') {
        //Firebase Authentication dökümantasyonunda her hata için sabit kodlar tanımlı.
        //Kullanıcı bu email ile zaten kayıt olmuş. kodudur bu if içinde verdiğimiz. firebase auth ulaşılır burada bu yazıyorsa bu hata mesajını kullanıcı için yazdırıyoruz
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bu email zaten kullanılıyor')));
      } else if (e.code == 'weak-password') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Şifre çok zayıf')));
      } else if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Geçersiz email')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bir hata oluştu, tekrar deneyiniz')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('KAYIT')),

      body: Center(
        child: Column(
          children: [
            TextField(
              controller: emailController,
              keyboardType: TextInputType
                  .emailAddress, //klavyeyi ekranda email yazmaya uygun yani @'li bir klavye çıkartıyor
              decoration: InputDecoration(
                //tesxtfielda'a görsel özellikler eklememizi sağlar
                hintText: 'Email Giriniz',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText:
                  true, //şifre alanına yazılanların görülmesini engeller

              decoration: InputDecoration(
                hintText: 'Şifre giriniz',
                border: OutlineInputBorder(),
              ),
            ),
            ElevatedButton(onPressed: _signUp, child: Text('Kayıt Ol')),
          ],
        ),
      ),
    );
  }
}
