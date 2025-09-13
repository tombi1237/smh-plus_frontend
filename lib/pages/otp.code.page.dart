import 'package:flutter/material.dart';

class OTPCodePage extends StatefulWidget {
  const OTPCodePage({Key? key}) : super(key: key);

  @override
  _OTPCodePageState createState() => _OTPCodePageState();
}

class _OTPCodePageState extends State<OTPCodePage> {
  String otpCode = "";
  final int otpLength = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header avec bouton retour et titre
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 16),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black,
                          size: 18,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'OTP CODE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Pour centrer le titre
                  ],
                ),
              ),
            ),
          ),

          // Corps principal
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 30),
              child: Column(
                children: [
                  // Zone d'affichage du code OTP
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Entrez le code OTP reçu',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(otpLength, (index) {
                            return Container(
                              width: 45,
                              height: 55,
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: index < otpCode.length
                                      ? const Color(0xFF1B3B5C)
                                      : const Color(0xFFE0E0E0),
                                  width: index < otpCode.length ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  index < otpCode.length ? otpCode[index] : '',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 100),
                  // Bouton Continuer
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: otpCode.length == otpLength
                            ? () {
                                // Action de validation du code OTP
                                print('Code OTP: $otpCode');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3B5C),
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Continuer',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Clavier numérique
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Première ligne (1, 2, 3)
                          Row(
                            children: [
                              _buildKeypadButton('1', ''),
                              _buildKeypadButton('2', 'ABC'),
                              _buildKeypadButton('3', 'DEF'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Deuxième ligne (4, 5, 6)
                          Row(
                            children: [
                              _buildKeypadButton('4', 'GHI'),
                              _buildKeypadButton('5', 'JKL'),
                              _buildKeypadButton('6', 'MNO'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Troisième ligne (7, 8, 9)
                          Row(
                            children: [
                              _buildKeypadButton('7', 'PQRS'),
                              _buildKeypadButton('8', 'TUV'),
                              _buildKeypadButton('9', 'WXYZ'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Quatrième ligne (0, delete)
                          Row(
                            children: [
                              const Expanded(child: SizedBox()), // Espace vide
                              _buildKeypadButton('0', ''),
                              _buildDeleteButton(),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Indicateur du bas
                          Container(
                            width: 134,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String number, String letters) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              /*
              if (otpCode.length < otpLength) {
                setState(() {
                  otpCode += number;
                });
              }
              */
              Navigator.pushNamed(context, '/home');
            },
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[100]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  if (letters.isNotEmpty)
                    Text(
                      letters,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              if (otpCode.isNotEmpty) {
                setState(() {
                  otpCode = otpCode.substring(0, otpCode.length - 1);
                });
              }
            },
            onLongPress: () {
              setState(() {
                otpCode = "";
              });
            },
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[100]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Exemple d'utilisation dans une app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OTP Code App',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const OTPCodePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(MyApp());
}
