import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smh_front/pages/clients/panier.page.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  final Product? product;

  const ProductDetailPage({Key? key, required this.productId, this.product})
    : super(key: key);

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Product? product;
  List<Product> recommendedProducts = [];
  bool isLoading = true;
  bool isLoadingRecommended = true;
  String errorMessage = '';
  bool isFavorite = false;

  double selectedQuantity = 1.0;
  double currentTotalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      product = widget.product;
      isLoading = false;
      _initializePrice();
    } else {
      fetchProductDetail();
    }
    fetchRecommendedProducts();
    _checkFavoriteStatus();
  }

  void _initializePrice() {
    if (product != null) {
      currentTotalPrice = product!.pricePerUnit * selectedQuantity;
    }
  }

  Future<void> fetchProductDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception("🔒 Token non trouvé. Veuillez vous connecter.");
      }

      final uri = Uri.parse(
        "http://49.13.197.63:8004/api/products/products/${widget.productId}",
      );

      final response = await http
          .get(
            uri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("⏳ Timeout lors du chargement"),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null && mounted) {
          setState(() {
            product = Product.fromJson(data["data"]);
            isLoading = false;
            _initializePrice();
          });

          // Récupérer les produits recommandés après avoir chargé le produit principal
          fetchRecommendedProducts();
        }
      } else {
        throw Exception("Erreur ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "🚨 Erreur: $e";
        });
      }
    }
  }

  Future<void> fetchRecommendedProducts() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return;

      final uri = Uri.parse("http://49.13.197.63:8004/api/products/products");

      final response = await http
          .get(
            uri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null && mounted) {
          List<Product> allProducts = (data["data"] as List)
              .map((p) => Product.fromJson(p))
              .toList();

          // Filtrer les produits par district et sous-catégorie
          List<Product> filteredProducts = [];
          if (product != null) {
            filteredProducts = allProducts.where((p) {
              return p.districtId == product!.districtId &&
                  p.subCategoryId == product!.subCategoryId &&
                  p.id != product!.id; // Exclure le produit actuel
            }).toList();
          }

          // Si pas assez de produits dans la même sous-catégorie, ajouter des produits du même district
          if (filteredProducts.length < 4 && product != null) {
            final districtProducts = allProducts.where((p) {
              return p.districtId == product!.districtId &&
                  p.id != product!.id &&
                  !filteredProducts.contains(p); // Éviter les doublons
            }).toList();

            filteredProducts.addAll(districtProducts);
          }

          filteredProducts.shuffle();
          setState(() {
            recommendedProducts = filteredProducts.take(4).toList();
            isLoadingRecommended = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingRecommended = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final favorites = await _storage.read(key: 'favorites') ?? '[]';
      final favoritesList = List<String>.from(jsonDecode(favorites));
      if (mounted) {
        setState(() {
          isFavorite = favoritesList.contains(widget.productId);
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final favorites = await _storage.read(key: 'favorites') ?? '[]';
      List<String> favoritesList = List<String>.from(jsonDecode(favorites));

      if (isFavorite) {
        favoritesList.remove(widget.productId);
      } else {
        favoritesList.add(widget.productId);
      }

      await _storage.write(key: 'favorites', value: jsonEncode(favoritesList));

      if (mounted) {
        setState(() {
          isFavorite = !isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite ? 'Ajouté aux favoris' : 'Retiré des favoris',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: isFavorite ? Colors.green : Colors.grey,
          ),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _addToCart() async {
    if (product == null || !mounted) return;

    try {
      // Utiliser le service CartService pour ajouter le produit
      await CartService.addToCart(product!, selectedQuantity);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${product!.name} ajouté au panier (${selectedQuantity} ${product!.unit} - ${currentTotalPrice.toInt()} FCFA)',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir le panier',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentPage()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ajout au panier: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateQuantity(double newQuantity) {
    if (product != null && newQuantity > 0 && mounted) {
      setState(() {
        selectedQuantity = newQuantity;
        currentTotalPrice = product!.pricePerUnit * selectedQuantity;
      });
    }
  }

  double _getRating() {
    if (product == null) return 4.0;
    return 4.0 + (product!.name.hashCode % 10) / 10.0;
  }

  Widget _buildQuantitySelector() {
    if (product == null) return const SizedBox.shrink();

    List<double> quantities = [];
    String unit = product!.unit.toUpperCase();

    if (unit == 'KG') {
      quantities = [0.25, 0.5, 1.0, 2.0, 3.0, 5.0];
    } else if (unit == 'G') {
      quantities = [250, 500, 1000, 2000];
    } else if (unit == 'L') {
      quantities = [0.5, 1.0, 1.5, 2.0];
    } else {
      quantities = [1.0, 2.0, 3.0, 5.0, 10.0];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Choisissez la quantité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),

        // Sélecteur avec boutons rapides
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quantities.map((quantity) {
            bool isSelected = selectedQuantity == quantity;
            double price = product!.pricePerUnit * quantity;

            return InkWell(
              onTap: () => _updateQuantity(quantity),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4A90E2) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4A90E2)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${quantity} ${product!.unit}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${price.toInt()} FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // Sélecteur personnalisé avec stepper
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Quantité personnalisée:',
                  style: TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton diminuer
                  InkWell(
                    onTap: () {
                      double newQuantity =
                          selectedQuantity -
                          (unit == 'KG'
                              ? 0.25
                              : unit == 'G'
                              ? 250
                              : 0.5);
                      if (newQuantity > 0) _updateQuantity(newQuantity);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: Color(0xFF4A90E2),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Affichage de la quantité
                  Text(
                    '${selectedQuantity} ${product!.unit}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Bouton augmenter
                  InkWell(
                    onTap: () {
                      double increment = unit == 'KG'
                          ? 0.25
                          : unit == 'G'
                          ? 250
                          : 0.5;
                      _updateQuantity(selectedQuantity + increment);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedProducts() {
    if (isLoadingRecommended) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
          ),
        ),
      );
    }

    if (recommendedProducts.isEmpty) {
      return Container(
        height: 120,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'Aucun produit similaire disponible\ndans votre zone',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Vérifier si on a des produits de la même sous-catégorie
    int sameCategoryCount = 0;
    if (product != null) {
      sameCategoryCount = recommendedProducts
          .where((p) => p.subCategoryId == product!.subCategoryId)
          .length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicateur du type de recommandation
        if (sameCategoryCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4A90E2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$sameCategoryCount produit${sameCategoryCount > 1 ? 's' : ''} de la même catégorie',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4A90E2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        const SizedBox(height: 8),

        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommendedProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final recommendedProduct = recommendedProducts[index];
              final isSameCategory =
                  product != null &&
                  recommendedProduct.subCategoryId == product!.subCategoryId;

              return SizedBox(
                width: 100,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailPage(
                          productId: recommendedProduct.id,
                          product: recommendedProduct,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: recommendedProduct.imageUrl.isNotEmpty
                                    ? Image.network(
                                        recommendedProduct.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Center(
                                                child: Icon(
                                                  Icons.image,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),

                            // Badge pour produit de même catégorie
                            if (isSameCategory)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4A90E2),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        recommendedProduct.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Détails produit',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Erreur'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchProductDetail,
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
          ),
        ),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Produit non trouvé'),
          backgroundColor: Colors.white,
        ),
        backgroundColor: Colors.grey[50],
        body: const Center(child: Text('Produit non trouvé')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // AppBar avec image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Détails produit',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : const Color(0xFF2C3E50),
                  ),
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  child: product!.imageUrl.isNotEmpty
                      ? Image.network(
                          product!.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nom et rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product!.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.orange[400], size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _getRating().toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sélection de quantité avec prix dynamique
                  _buildQuantitySelector(),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product!.description.isNotEmpty
                        ? product!.description
                        : "Produit frais de qualité supérieure, riche en nutriments et parfait pour vos préparations culinaires.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Récapitulatif prix
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4A90E2).withOpacity(0.1),
                          const Color(0xFF4A90E2).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4A90E2).withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Prix unitaire:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '${product!.pricePerUnit.toInt()} FCFA/${product!.unit}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quantité:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '${selectedQuantity} ${product!.unit}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              '${currentTotalPrice.toInt()} FCFA',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A90E2),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Produits recommandés
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Produits similaires',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            Text(
                              'Dans votre zone de livraison',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Naviguer vers tous les produits de la même sous-catégorie
                        },
                        child: const Text(
                          'Voir tout',
                          style: TextStyle(
                            color: Color(0xFF4A90E2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Liste horizontale des produits recommandés
                  _buildRecommendedProducts(),

                  const SizedBox(height: 100), // Espace pour le bouton fixe
                ],
              ),
            ),
          ),
        ],
      ),

      // Bouton flottant "Ajouter au Panier" avec prix total
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(1),
        child: FloatingActionButton.extended(
          onPressed: _addToCart,
          backgroundColor: const Color(0xFFFFB347),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(45),
          ),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_cart_outlined,
                color: Color(0xFF2C3E50),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Ajouter ${currentTotalPrice.toInt()} FCFA',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// Modèles Product et ProductImage
class ProductImage {
  final String url;

  ProductImage({required this.url});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(url: json['url'] ?? '');
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final String unit;
  final double pricePerUnit;
  final String subCategoryId;
  final List<ProductImage> images;
  final int districtId;
  final String availabilityStatus;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.unit,
    required this.pricePerUnit,
    required this.subCategoryId,
    required this.images,
    required this.districtId,
    required this.availabilityStatus,
  });

  String get imageUrl => images.isNotEmpty ? images.first.url : '';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['productId'] ?? '',
      name: json['name'] ?? 'Nom inconnu',
      description: json['description'] ?? '',
      unit: json['unit'] ?? '',
      pricePerUnit: (json['pricePerUnit'] is num)
          ? (json['pricePerUnit'] as num).toDouble()
          : 0.0,
      subCategoryId: json['subCategoryId'] ?? '',
      images:
          (json['images'] as List<dynamic>?)
              ?.map((img) => ProductImage.fromJson(img))
              .toList() ??
          [],
      districtId: json['districtId'] ?? 0,
      availabilityStatus: json['availabilityStatus'] ?? 'OUT_OF_STOCK',
    );
  }
}
