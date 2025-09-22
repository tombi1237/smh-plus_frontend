// smh.client.home.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math' as math;

class SMHClientHome extends StatefulWidget {
  const SMHClientHome({Key? key}) : super(key: key);

  @override
  _SMHClientHomeState createState() => _SMHClientHomeState();
}

class _SMHClientHomeState extends State<SMHClientHome> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<String> _carouselImages = [];
  int _currentCarouselIndex = 0;
  late Timer _carouselTimer;
  final PageController _carouselController = PageController();
  bool _isLoading = true;
  String _errorMessage = '';

  // Images par défaut en cas d'erreur ou de chargement
  final List<String> _defaultCarouselImages = [
    'https://images.unsplash.com/photo-1542838132-92c53300491e?ixlib=rb-4.0.3',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?ixlib=rb-4.0.3',
    'https://images.unsplash.com/photo-1565958011703-44f9829ba187?ixlib=rb-4.0.3',
    'https://images.unsplash.com/photo-1467003909585-2f8a72700288?ixlib=rb-4.0.3',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProductImages();
  }

  @override
  void dispose() {
    if (_carouselTimer.isActive) {
      _carouselTimer.cancel();
    }
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _fetchProductImages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception("Token non trouvé. Veuillez vous connecter.");
      }

      // Récupérer les produits depuis l'API
      final productsUri = Uri.parse(
        "http://49.13.197.63:8004/api/products/products",
      );

      final response = await http
          .get(
            productsUri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception("Timeout lors du chargement des produits"),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null) {
          // Extraire les URLs d'images des produits
          List<String> productImages = [];
          for (var productData in data["data"]) {
            if (productData["images"] != null &&
                productData["images"].isNotEmpty) {
              for (var image in productData["images"]) {
                if (image["url"] != null && image["url"].isNotEmpty) {
                  productImages.add(image["url"]);
                }
              }
            }
          }

          // Mélanger les images de façon aléatoire
          productImages.shuffle(math.Random());

          // Prendre exactement 3 images pour le carrousel
          if (productImages.length >= 3) {
            productImages = productImages.sublist(0, 3);
          } else if (productImages.isNotEmpty) {
            // Si moins de 3 images, compléter avec les images par défaut
            while (productImages.length < 3 &&
                _defaultCarouselImages.length > productImages.length) {
              productImages.add(_defaultCarouselImages[productImages.length]);
            }
          }

          setState(() {
            _carouselImages = productImages;
            _isLoading = false;
          });

          // Démarrer le timer pour le carrousel automatique
          _startCarouselTimer();
        } else {
          throw Exception("Aucune donnée de produit trouvée");
        }
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur: $e";
        _carouselImages = _defaultCarouselImages.sublist(0, 3);
        _isLoading = false;
      });
      _startCarouselTimer();
    }
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_carouselImages.isEmpty) return;

      if (_currentCarouselIndex < _carouselImages.length - 1) {
        _currentCarouselIndex++;
      } else {
        _currentCarouselIndex = 0;
      }

      if (_carouselController.hasClients) {
        _carouselController.animateToPage(
          _currentCarouselIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _navigateToClientPage() {
    Navigator.pushNamed(context, '/client_home');
  }

  void _retryLoading() {
    _fetchProductImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo SMH+
              SizedBox(
                width: 180,
                height: 180,
                child: Image.asset("assets/images/logo.png"),
              ),

              const SizedBox(height: 40),

              // Carrousel d'images ou indicateur de chargement
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4A90E2),
                            ),
                          ),
                        ),
                      )
                    else if (_errorMessage.isNotEmpty &&
                        _carouselImages.isEmpty)
                      Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 50,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _retryLoading,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFFFA726,
                              ), // Orange color
                            ),
                            child: const Text(
                              'Réessayer',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        height: 300,
                        child: PageView.builder(
                          controller: _carouselController,
                          itemCount: _carouselImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentCarouselIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Card(
                                elevation: 8,
                                shadowColor: Colors.black26,
                                color: const Color(
                                  0xFF424242,
                                ), // Couleur sombre pour la card
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    _carouselImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
                                                      null
                                                  ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                  : null,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(
                                                    Color(
                                                      0xFFFFA726,
                                                    ), // Orange color
                                                  ),
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Indicateurs de page - limités à 3 points maximum
                    if (_carouselImages.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          math.min(
                            3,
                            _carouselImages.length,
                          ), // Limité à 3 points max
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentCarouselIndex == index
                                  ? const Color(
                                      0xFFFFA726,
                                    ) // Orange pour l'indicateur actif
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Bouton Continuer
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: _navigateToClientPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFFFA726,
                    ), // Couleur orange/jaune
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors
                          .black87, // Texte sombre pour meilleur contraste
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
