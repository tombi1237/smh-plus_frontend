import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CategoryDetail extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryDetail({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);

  @override
  _CategoryDetailState createState() => _CategoryDetailState();
}

class _CategoryDetailState extends State<CategoryDetail> {
  late Future<void> _dataFuture;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();

  List<Product> categoryProducts = [];
  List<Product> filteredProducts = [];
  bool isLoading = true;
  String errorMessage = '';

  // Pagination
  int currentPage = 0;
  int itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchCategoryProducts();
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCategoryProducts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception("🔒 Token non trouvé. Veuillez vous connecter.");
      }

      // Récupérer tous les produits
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
                throw Exception("⏳ Timeout lors du chargement des produits"),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null) {
          List<Product> allProducts = (data["data"] as List)
              .map((p) => Product.fromJson(p))
              .toList();

          // Filtrer les produits selon la catégorie
          categoryProducts = allProducts.where((product) {
            return _getProductCategoryId(product.subCategoryId) ==
                widget.categoryId;
          }).toList();

          // Si aucun produit trouvé, prendre quelques exemples pour la démo
          if (categoryProducts.isEmpty) {
            categoryProducts = allProducts.take(4).toList();
          }

          filteredProducts = categoryProducts;
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "🚨 Erreur: $e";
      });
    }
  }

  String _getProductCategoryId(String subCategoryId) {
    // Utiliser la même logique que dans ProductsHome
    Map<String, String> subCatToCat = {
      '156be970-68bd-40b1-820b-47d05eb33b9a':
          '5f6789ab-cdef-0123-4567-89abcdef0123', // Légumes
      '11f078c1-b74c-e41a-9636-2afd32a4bf2b':
          '5f6789ab-cdef-0123-4567-89abcdef0123', // Légumes
      '11f078c1-b28a-78f2-9636-2afd32a4bf2b':
          '5f6789ab-cdef-0123-4567-89abcdef0123', // Légumes
      '11f078c1-b46e-2979-9636-2afd32a4bf2b':
          '5f6789ab-cdef-0123-4567-89abcdef0123', // Légumes
      '11f078c1-ad69-7b9a-9636-2afd32a4bf2b':
          '3d4e5f67-89ab-cdef-0123-456789abcdef', // Fruits
      '11f078c1-b402-9b95-9636-2afd32a4bf2b':
          '3d4e5f67-89ab-cdef-0123-456789abcdef', // Fruits
      '11f078c1-ae48-381d-9636-2afd32a4bf2b':
          '0a1b2c3d-4e5f-6789-abcd-ef0123456789', // Compléments
      '11f078c1-b0f8-6ad1-9636-2afd32a4bf2b':
          '1b2c3d4e-5f67-89ab-cdef-0123456789ab', // Viandes
      '5d51bb59-8338-49a0-910f-7b393054f4a2':
          '2c3d4e5f-6789-abcd-ef01-23456789abcd', // Légumineuses
    };
    return subCatToCat[subCategoryId] ?? widget.categoryId;
  }

  void _filterProducts() {
    String searchTerm = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = categoryProducts.where((product) {
        return product.name.toLowerCase().contains(searchTerm) ||
            product.description.toLowerCase().contains(searchTerm);
      }).toList();
      currentPage = 0;
    });
  }

  List<Product> getPaginatedProducts() {
    int startIndex = currentPage * itemsPerPage;
    int endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredProducts.length,
    );
    return filteredProducts.sublist(startIndex, endIndex);
  }

  int getTotalPages() {
    return (filteredProducts.length / itemsPerPage).ceil();
  }

  void _showProductDetail(Product product) {
    // Fonction pour afficher les détails du produit (à implémenter)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(product.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.imageUrl.isNotEmpty)
                Image.network(
                  product.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              Text(
                'Prix: ${product.pricePerUnit.toInt()} FCFA/${product.unit}',
              ),
              const SizedBox(height: 8),
              Text('Description: ${product.description}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header avec image de fond
          Container(
            height: 100,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1542838132-92c53300491e?ixlib=rb-4.0.3',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),

                      // Texte
                      const Text(
                        'Achetez près de chez vous..!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Bouton réduit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextButton(
                              onPressed: () {
                                // Logique pour choisir le lieu de livraison
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: const Text(
                                'Lieu de livraison',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenu principal
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de recherche
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: searchController,
                              decoration: const InputDecoration(
                                hintText: 'Rechercher un produit...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 15,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4A90E2),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _filterProducts();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Titre de section
                    Text(
                      'Produits ${widget.categoryName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Grille des produits
                    FutureBuilder<void>(
                      future: _dataFuture,
                      builder: (context, snapshot) {
                        if (isLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(50),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                          );
                        }

                        if (errorMessage.isNotEmpty) {
                          return Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Text(
                                    errorMessage,
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _dataFuture = fetchCategoryProducts();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4A90E2),
                                  ),
                                  child: const Text(
                                    'Réessayer',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (filteredProducts.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(50),
                              child: Text(
                                'Aucun produit trouvé dans cette catégorie',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Grille des produits (responsive)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Adapter le nombre de colonnes en fonction de la largeur
                                final crossAxisCount =
                                    constraints.maxWidth > 600 ? 3 : 2;

                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: 0.75,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: getPaginatedProducts().length,
                                  itemBuilder: (context, index) {
                                    final product =
                                        getPaginatedProducts()[index];
                                    return ProductDetailCard(
                                      product: product,
                                      onTap: () => _showProductDetail(product),
                                    );
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: 20),

                            // Navigation pagination
                            if (getTotalPages() > 1)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: currentPage > 0
                                        ? () {
                                            setState(() {
                                              currentPage--;
                                            });
                                          }
                                        : null,
                                    icon: const Icon(Icons.arrow_back_ios),
                                    style: IconButton.styleFrom(
                                      backgroundColor: currentPage > 0
                                          ? const Color(0xFF4A90E2)
                                          : Colors.grey[300],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Page ${currentPage + 1} sur ${getTotalPages()}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    onPressed: currentPage < getTotalPages() - 1
                                        ? () {
                                            setState(() {
                                              currentPage++;
                                            });
                                          }
                                        : null,
                                    icon: const Icon(Icons.arrow_forward_ios),
                                    style: IconButton.styleFrom(
                                      backgroundColor:
                                          currentPage < getTotalPages() - 1
                                          ? const Color(0xFF4A90E2)
                                          : Colors.grey[300],
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF2C3E50),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBottomNavItem(Icons.home, 'Home', true),
            _buildBottomNavItem(Icons.shopping_cart_outlined, '', false),
            _buildBottomNavItem(Icons.person_outline, '', false),
            _buildBottomNavItem(Icons.settings_outlined, '', false),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFFFFB74D) : Colors.grey[400],
          size: 28,
        ),
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFFFFB74D) : Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

// Widget pour les cartes de produits de détail (avec étoiles et ratings)
class ProductDetailCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductDetailCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Rating factice pour la démo (entre 4.0 et 5.0)
    double rating = 4.0 + (product.name.hashCode % 10) / 10.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit (cliquable)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  color: Colors.grey[100],
                ),
                child: product.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'Image non disponible',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4A90E2),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                'Image ${product.name}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Informations du produit
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Rating avec étoiles
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.orange[400], size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ],
                    ),

                    // Nom du produit
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Prix
                    Text(
                      '${product.pricePerUnit.toInt()} FCFA/${product.unit}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Réutilisation du modèle Product existant
class Product {
  final String id;
  final String name;
  final String description;
  final String unit;
  final double pricePerUnit;
  final String imageUrl;
  final String subCategoryId;
  final int districtId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.pricePerUnit,
    required this.imageUrl,
    required this.subCategoryId,
    required this.districtId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String image = "";
    if (json["images"] != null && json["images"].isNotEmpty) {
      image = json["images"][0]["url"];
    }
    return Product(
      id: json["productId"] ?? "",
      name: json["name"] ?? "Nom inconnu",
      description: json["description"] ?? "",
      unit: json["unit"] ?? "",
      pricePerUnit: (json["pricePerUnit"] is num)
          ? (json["pricePerUnit"] as num).toDouble()
          : 0.0,
      imageUrl: image,
      subCategoryId: json["subCategoryId"] ?? "",
      districtId: json["districtId"] ?? 0,
    );
  }
}
