import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smh_front/pages/clients/product.detail.page.dart';

class DistrictsProductsPage extends StatefulWidget {
  final int districtId;
  final String districtName;

  const DistrictsProductsPage({
    Key? key,
    required this.districtId,
    required this.districtName,
  }) : super(key: key);

  @override
  _DistrictsProductsPageState createState() => _DistrictsProductsPageState();
}

class _DistrictsProductsPageState extends State<DistrictsProductsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController searchController = TextEditingController();

  List<DistrictProduct> allProducts = [];
  List<DistrictProduct> filteredProducts = [];
  bool isLoading = true;
  String errorMessage = '';

  // Pagination
  int currentPage = 0;
  int itemsPerPage = 6;

  @override
  void initState() {
    super.initState();
    fetchDistrictProducts();
    searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterProducts);
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchDistrictProducts() async {
    if (!mounted) return;

    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception("🔒 Token non trouvé. Veuillez vous connecter.");
      }

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

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null) {
          List<DistrictProduct> products = (data["data"] as List)
              .map((p) => DistrictProduct.fromJson(p))
              .toList();

          // Filtrer les produits selon le district
          allProducts = products.where((product) {
            return product.districtId == widget.districtId;
          }).toList();

          filteredProducts = allProducts;
        }
      } else {
        throw Exception("Erreur lors du chargement des produits");
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
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

  void _filterProducts() {
    if (!mounted) return;

    String searchTerm = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((product) {
        return product.name.toLowerCase().contains(searchTerm) ||
            product.description.toLowerCase().contains(searchTerm);
      }).toList();
      currentPage = 0;
    });
  }

  List<DistrictProduct> getPaginatedProducts() {
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

  void _navigateToProductDetail(DistrictProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(productId: product.productId),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: _filterProducts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid() {
    if (filteredProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun produit trouvé\ndans cette zone de livraison',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Titre avec nombre de produits
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Produits disponibles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredProducts.length} produit${filteredProducts.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A90E2),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Grille des produits
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: getPaginatedProducts().length,
                itemBuilder: (context, index) {
                  final product = getPaginatedProducts()[index];
                  return DistrictProductCard(
                    product: product,
                    onTap: () => _navigateToProductDetail(product),
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // Navigation pagination
        if (getTotalPages() > 1) _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 0
                ? () {
                    if (mounted) {
                      setState(() {
                        currentPage--;
                      });
                    }
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
                    if (mounted) {
                      setState(() {
                        currentPage++;
                      });
                    }
                  }
                : null,
            icon: const Icon(Icons.arrow_forward_ios),
            style: IconButton.styleFrom(
              backgroundColor: currentPage < getTotalPages() - 1
                  ? const Color(0xFF4A90E2)
                  : Colors.grey[300],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(50),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              onPressed: fetchDistrictProducts,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // AppBar personnalisée
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2C3E50),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Produits - ${widget.districtName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Header avec informations du district
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF4A90E2).withOpacity(0.8),
                    const Color(0xFF4A90E2).withOpacity(0.6),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Zone de livraison: ${widget.districtName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Découvrez nos produits frais disponibles dans cette zone',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Barre de recherche
            _buildSearchBar(),

            // Contenu principal
            Expanded(
              child: SingleChildScrollView(
                child: isLoading
                    ? _buildLoadingState()
                    : errorMessage.isNotEmpty
                    ? _buildErrorState()
                    : _buildProductsGrid(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les cartes de produits du district
class DistrictProductCard extends StatelessWidget {
  final DistrictProduct product;
  final VoidCallback onTap;

  const DistrictProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit avec badge
            Expanded(
              flex: 4, // <-- plus d’espace pour l’image
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF4A90E2),
                                  ),
                                ),
                              );
                            },
                          )
                        : _buildImagePlaceholder(),
                  ),

                  // Badge disponibilité
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: product.availabilityStatus == 'IN_STOCK'
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        product.availabilityStatus == 'IN_STOCK'
                            ? 'Dispo'
                            : 'Rupture',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Infos produit
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nom du produit
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF2C3E50),
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Prix
                    Text(
                      '${product.pricePerUnit.toInt()} FCFA / ${product.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A90E2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Description (optionnelle)
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image, size: 50, color: Colors.grey),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Image ${product.name}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Modèles pour les données
class DistrictProduct {
  final String productId;
  final String name;
  final String description;
  final String unit;
  final double pricePerUnit;
  final String subCategoryId;
  final List<ProductImage> images;
  final int districtId;
  final String sellerType;
  final String availabilityStatus;

  DistrictProduct({
    required this.productId,
    required this.name,
    required this.description,
    required this.unit,
    required this.pricePerUnit,
    required this.subCategoryId,
    required this.images,
    required this.districtId,
    required this.sellerType,
    required this.availabilityStatus,
  });

  String get imageUrl => images.isNotEmpty ? images.first.url : '';

  factory DistrictProduct.fromJson(Map<String, dynamic> json) {
    return DistrictProduct(
      productId: json['productId'] ?? '',
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
      sellerType: json['sellerType'] ?? 'UNKNOWN',
      availabilityStatus: json['availabilityStatus'] ?? 'OUT_OF_STOCK',
    );
  }
}

class ProductImage {
  final String url;

  ProductImage({required this.url});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(url: json['url'] ?? '');
  }
}
