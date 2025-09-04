import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_new/screens/home_page.dart';
import 'package:flutter_chat_new/screens/sign_up_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _signIn() async {
    //giriş fonksiyonu oluşturduk
    String email = emailController
        .text; //email yazısına emailController'ı yani doğru yanlışı kontrol edecek fonksiyonu atadık
    String password = passwordController.text;
    print('Email: $email');
    print('Password: $password');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        //FireBase authentication'a instance ile erişim sağlıyoruz yani kullanıcı işlemlerini tümüyle kontrol eden nesneye.
        //signInWithEmailAndPassword firebase'deki kullanıcı giriş email ve şifrelerini tutar
        //biz firebase'deki veriyle uyuşuyor mu kontrolünü yapmak için
        email: email,
        password: password,
      );
    } catch (e) {
      print("Hata: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('hata mesajı ')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CHAT')),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          width: 200,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 20),
                TextFormField(
                  controller:
                      emailController, //controllerları textField'lara bağladk. giriş verisi almak için
                  decoration: InputDecoration(
                    hintText: 'Email giriniz',
                    border:
                        OutlineInputBorder(), //TextField yani giriş alan ve içindeki yönergeyle yazılacak şeyi yönlendiren widget'a kenarlık ekler
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email boş olamaz ';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir email giriniz';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: //şifre alanına yazılanların görülmesini engeller
                      true, //şifre alanına yazılanların görülmesini engeller
                  decoration: InputDecoration(
                    hintText: 'Şifrenizi giriniz',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(onPressed: _signIn, child: Text('Giriş Yap')),

                SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green, //butonun arka plan rengini yeşil yaptık
                    elevation: 12, // Increase this value for a bigger shadow
                    shadowColor: Colors.black.withAlpha(
                      4,
                    ), // Optional: change shadow color
                  ),
                  //
                  onPressed: () {
                    //onPressed'ı fonksiyon haline getirdik ki basılınca işlem gerçekleşsin
                    //fonksiyon yapmasaydık direkt yönlendirme çalışırdı
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpPage(),
                      ), //kayıt ol sayfasına yönlendirme
                    );
                  },
                  child: Text(
                    'Kayıt Ol',
                  ), //elevatedButton'un yani kayıt ol butonunun yazısı
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
