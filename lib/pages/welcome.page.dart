import 'package:flutter/material.dart';
import 'package:smh_front/widgets/common/common.widget.dart';

class SMHWelcomePage extends StatefulWidget {
  const SMHWelcomePage({Key? key}) : super(key: key);

  @override
  _SMHWelcomePageState createState() => _SMHWelcomePageState();
}

class _SMHWelcomePageState extends State<SMHWelcomePage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size; // taille écran

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.bleu,
        child: SafeArea(
          child: Column(
            children: [
              // Logo placé plus haut
              Expanded(
                flex: 6, // occupe plus d’espace
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: size.height * 0.08,
                    ), // 8% de la hauteur en haut
                    child: Container(
                      width:
                          size.width *
                          0.55, // un peu plus grand (55% largeur écran)
                      constraints: const BoxConstraints(
                        maxWidth: 250,
                      ), // max taille logo
                      child: Image.asset("assets/images/logo.png"),
                    ),
                  ),
                ),
              ),

              // Bouton en bas
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: size.height * 0.08),
                    child: SizedBox(
                      width: size.width * 0.85,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(
                            context,
                            '/reset-password',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.bleu,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black38,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Commencer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.bleu,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Exemple d’utilisation
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMH+ Welcome',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const SMHWelcomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(MyApp());
}
