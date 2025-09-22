import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smh_front/pages/clients/category.detail.dart';
import 'package:smh_front/pages/clients/widgets/districts_widget.dart';

// --- Modèle Catégorie ---
class Category {
  final String id;
  final String name;
  final String description;

  Category({required this.id, required this.name, required this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json["id"] ?? "",
      name: json["name"] ?? "Catégorie inconnue",
      description: json["description"] ?? "",
    );
  }
}

// --- Modèle Sous-catégorie ---
class SubCategory {
  final String id;
  final String name;
  final String categoryId;
  final String description;

  SubCategory({
    required this.id,
    required this.name,
    required this.categoryId,
    this.description = "",
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json["subCategoryId"] ?? json["id"] ?? "",
      name: json["name"] ?? "Sous-catégorie inconnue",
      categoryId: json["categoryId"] ?? "",
      description: json["description"] ?? "",
    );
  }
}

// --- Page d'accueil ---
class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  late Future<void> _dataFuture;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Données
  List<SubCategory> allSubCategories = [];
  List<SubCategory> filteredSubCategories = [];
  List<Category> categories = [];
  Map<String, String> categoryMap = {};

  // Contrôleurs et état
  final TextEditingController searchController = TextEditingController();
  String selectedCategoryId = 'all';
  bool isLoading = true;
  String errorMessage = '';

  // Pagination
  int currentPage = 0;
  int itemsPerPage = 8; // Augmenté pour une meilleure utilisation de l'espace

  // Couleurs des catégories pour un design plus visuel
  final List<Color> categoryColors = [
    Color(0xFF6C5CE7), // Violet
    Color(0xFF74B9FF), // Bleu clair
    Color(0xFF00B894), // Vert
    Color(0xFFE17055), // Orange
    Color(0xFFF39C12), // Jaune
    Color(0xFFE84393), // Rose
    Color(0xFF00CEC9), // Turquoise
    Color(0xFFFF7675), // Rouge clair
  ];

  // Icônes par défaut pour les catégories
  final List<IconData> categoryIcons = [
    Icons.restaurant,
    Icons.local_grocery_store,
    Icons.shopping_basket,
    Icons.store,
    Icons.kitchen,
    Icons.local_dining,
    Icons.coffee,
    Icons.bakery_dining,
  ];

  Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  IconData getCategoryIcon(int index) {
    return categoryIcons[index % categoryIcons.length];
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception("🔒 Token non trouvé. Veuillez vous connecter.");
      }

      // --- Récupérer les catégories ---
      final categoriesUri = Uri.parse(
        "http://49.13.197.63:8004/api/products/categories/",
      );

      final categoriesResponse = await http
          .get(
            categoriesUri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () =>
                throw Exception("⏳ Timeout lors du chargement des catégories"),
          );

      if (categoriesResponse.statusCode == 200) {
        final categoriesData = jsonDecode(categoriesResponse.body);
        if (categoriesData["data"] != null) {
          categories = (categoriesData["data"] as List)
              .map((c) => Category.fromJson(c))
              .toList();

          for (var category in categories) {
            categoryMap[category.id] = category.name;
          }
        }
      }

      // --- Récupérer les sous-catégories ---
      final subCatUri = Uri.parse(
        "http://49.13.197.63:8004/api/products/subCategories/",
      );

      final subCatResponse = await http
          .get(
            subCatUri,
            headers: {
              "Accept": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception(
              "⏳ Timeout lors du chargement des sous-catégories",
            ),
          );

      if (subCatResponse.statusCode == 200) {
        final subCatData = jsonDecode(subCatResponse.body);
        if (subCatData["data"] != null) {
          allSubCategories = (subCatData["data"] as List)
              .map((sc) => SubCategory.fromJson(sc))
              .toList();
        }
      }

      filteredSubCategories = allSubCategories;
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

  void _filterSubCategories() {
    String searchTerm = searchController.text.toLowerCase();

    setState(() {
      filteredSubCategories = allSubCategories.where((subCategory) {
        bool matchesSearch =
            subCategory.name.toLowerCase().contains(searchTerm) ||
            subCategory.description.toLowerCase().contains(searchTerm);
        bool matchesCategory =
            selectedCategoryId == 'all' ||
            subCategory.categoryId == selectedCategoryId;
        return matchesSearch && matchesCategory;
      }).toList();

      currentPage = 0;
    });
  }

  List<SubCategory> getPaginatedSubCategories() {
    int startIndex = currentPage * itemsPerPage;
    int endIndex = (startIndex + itemsPerPage).clamp(
      0,
      filteredSubCategories.length,
    );
    return filteredSubCategories.sublist(startIndex, endIndex);
  }

  int getTotalPages() {
    return (filteredSubCategories.length / itemsPerPage).ceil();
  }

  void _navigateToCategoryDetail(String categoryId, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CategoryDetail(categoryId: categoryId, categoryName: categoryName),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _dataFuture = fetchData();
    searchController.addListener(_filterSubCategories);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final crossAxisCount = isTablet ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color(0xFF1E3A5F),
        elevation: 2,
        title: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Accueil',
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          // Contenu principal
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 24 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de recherche améliorée
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher une sous-catégorie...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: isTablet ? 16 : 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF74B9FF),
                            size: isTablet ? 24 : 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 16,
                            vertical: isTablet ? 16 : 12,
                          ),
                        ),
                        style: TextStyle(fontSize: isTablet ? 16 : 14),
                      ),
                    ),

                    SizedBox(height: isTablet ? 24 : 10),

                    // Section Catégories avec design amélioré
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Catégories',
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF74B9FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.tune,
                              color: Color(0xFF74B9FF),
                              size: isTablet ? 24 : 20,
                            ),
                            onPressed: () {
                              // Logique du filtre
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isTablet ? 16 : 12),

                    // Dropdown des catégories modernisé
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 20 : 16,
                            vertical: isTablet ? 16 : 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF74B9FF),
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'all',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.apps,
                                  color: Color(0xFF74B9FF),
                                  size: isTablet ? 20 : 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Toutes les catégories',
                                  style: TextStyle(
                                    fontSize: isTablet ? 16 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...categories.asMap().entries.map((entry) {
                            int index = entry.key;
                            Category category = entry.value;
                            return DropdownMenuItem<String>(
                              value: category.id,
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: getCategoryColor(
                                        index,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      getCategoryIcon(index),
                                      color: getCategoryColor(index),
                                      size: isTablet ? 16 : 14,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategoryId = newValue!;
                            _filterSubCategories();
                          });
                        },
                      ),
                    ),

                    SizedBox(height: isTablet ? 32 : 13),

                    // Section Sous-catégories
                    Text(
                      'Variétés',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),

                    SizedBox(height: isTablet ? 16 : 10),

                    // Grille des sous-catégories
                    FutureBuilder<void>(
                      future: _dataFuture,
                      builder: (context, snapshot) {
                        if (isLoading) {
                          return Container(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF74B9FF),
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        }

                        if (errorMessage.isNotEmpty) {
                          return Container(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: isTablet ? 16 : 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _dataFuture = fetchData();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF74B9FF),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Réessayer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (filteredSubCategories.isEmpty) {
                          return Container(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucune sous-catégorie trouvée',
                                    style: TextStyle(
                                      fontSize: isTablet ? 18 : 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            // Grille des sous-catégories
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: isTablet ? 0.85 : 0.9,
                                    crossAxisSpacing: isTablet ? 20 : 15,
                                    mainAxisSpacing: isTablet ? 20 : 15,
                                  ),
                              itemCount: getPaginatedSubCategories().length,
                              itemBuilder: (context, index) {
                                final subCategory =
                                    getPaginatedSubCategories()[index];
                                return GestureDetector(
                                  onTap: () {
                                    Category? parentCategory = categories
                                        .firstWhere(
                                          (cat) =>
                                              cat.id == subCategory.categoryId,
                                          orElse: () => categories.isNotEmpty
                                              ? categories.first
                                              : Category(
                                                  id: subCategory.categoryId,
                                                  name: 'Catégorie',
                                                  description: '',
                                                ),
                                        );

                                    _navigateToCategoryDetail(
                                      subCategory.categoryId,
                                      parentCategory.name,
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        isTablet ? 16 : 12,
                                      ),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          spreadRadius: 0,
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(
                                          isTablet ? 16 : 12,
                                        ),
                                        onTap: () {
                                          Category? parentCategory = categories
                                              .firstWhere(
                                                (cat) =>
                                                    cat.id ==
                                                    subCategory.categoryId,
                                                orElse: () =>
                                                    categories.isNotEmpty
                                                    ? categories.first
                                                    : Category(
                                                        id: subCategory
                                                            .categoryId,
                                                        name: 'Catégorie',
                                                        description: '',
                                                      ),
                                              );

                                          _navigateToCategoryDetail(
                                            subCategory.categoryId,
                                            parentCategory.name,
                                          );
                                        },
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            isTablet ? 16 : 12,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Icône de catégorie
                                              Container(
                                                width: isTablet ? 56 : 48,
                                                height: isTablet ? 56 : 48,
                                                decoration: BoxDecoration(
                                                  color: getCategoryColor(
                                                    subCategory.hashCode %
                                                        categoryColors.length,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        isTablet ? 14 : 12,
                                                      ),
                                                ),
                                                child: Icon(
                                                  getCategoryIcon(
                                                    subCategory.hashCode %
                                                        categoryIcons.length,
                                                  ),
                                                  size: isTablet ? 28 : 24,
                                                  color: getCategoryColor(
                                                    subCategory.hashCode %
                                                        categoryColors.length,
                                                  ),
                                                ),
                                              ),

                                              SizedBox(
                                                height: isTablet ? 12 : 8,
                                              ),

                                              // Nom de la sous-catégorie
                                              Text(
                                                subCategory.name,
                                                style: TextStyle(
                                                  fontSize: isTablet ? 16 : 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade800,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),

                                              SizedBox(
                                                height: isTablet ? 6 : 4,
                                              ),

                                              // Nom de la catégorie parent
                                              Text(
                                                categoryMap[subCategory
                                                        .categoryId] ??
                                                    'Catégorie',
                                                style: TextStyle(
                                                  fontSize: isTablet ? 12 : 10,
                                                  fontWeight: FontWeight.w400,
                                                  color: Colors.grey.shade500,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: isTablet ? 32 : 10),

                            // Pagination moderne
                            if (getTotalPages() > 1)
                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 24 : 0,
                                ),
                                padding: EdgeInsets.all(isTablet ? 20 : 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    isTablet ? 20 : 16,
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      spreadRadius: 0,
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Bouton Précédent
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: currentPage > 0
                                            ? () {
                                                setState(() {
                                                  currentPage--;
                                                });
                                              }
                                            : null,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 20 : 10,
                                            vertical: isTablet ? 12 : 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: currentPage > 0
                                                ? const Color(
                                                    0xFF74B9FF,
                                                  ).withOpacity(0.1)
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: currentPage > 0
                                                  ? const Color(
                                                      0xFF74B9FF,
                                                    ).withOpacity(0.3)
                                                  : Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.chevron_left,
                                                size: isTablet ? 20 : 18,
                                                color: currentPage > 0
                                                    ? const Color(0xFF74B9FF)
                                                    : Colors.grey.shade400,
                                              ),
                                              SizedBox(width: isTablet ? 6 : 4),
                                              Text(
                                                'Précédent',
                                                style: TextStyle(
                                                  color: currentPage > 0
                                                      ? const Color.fromARGB(
                                                          255,
                                                          19,
                                                          113,
                                                          207,
                                                        )
                                                      : Colors.grey.shade400,
                                                  fontSize: isTablet ? 14 : 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Indicateur de page
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isTablet ? 20 : 20,
                                        vertical: isTablet ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFF74B9FF,
                                            ).withOpacity(0.1),
                                            const Color(
                                              0xFF0984E3,
                                            ).withOpacity(0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF74B9FF,
                                          ).withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${currentPage + 1} / ${getTotalPages()}',
                                        style: TextStyle(
                                          fontSize: isTablet ? 16 : 15,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0984E3),
                                        ),
                                      ),
                                    ),

                                    // Bouton Suivant
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: currentPage < getTotalPages() - 1
                                            ? () {
                                                setState(() {
                                                  currentPage++;
                                                });
                                              }
                                            : null,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isTablet ? 20 : 16,
                                            vertical: isTablet ? 12 : 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                currentPage <
                                                    getTotalPages() - 1
                                                ? const Color(
                                                    0xFF74B9FF,
                                                  ).withOpacity(0.1)
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color:
                                                  currentPage <
                                                      getTotalPages() - 1
                                                  ? const Color(
                                                      0xFF74B9FF,
                                                    ).withOpacity(0.3)
                                                  : Colors.grey.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Suivant',
                                                style: TextStyle(
                                                  color: const Color.fromARGB(
                                                    255,
                                                    23,
                                                    57,
                                                    117,
                                                  ),
                                                  fontSize: isTablet ? 14 : 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: isTablet ? 18 : 16,
                                                color: const Color.fromARGB(
                                                  255,
                                                  22,
                                                  22,
                                                  22,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
    );
  }
}

// --- Widget Carte Sous-catégorie Amélioré ---
class SubCategoryCard extends StatelessWidget {
  final SubCategory subCategory;
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;
  final bool isTablet;

  const SubCategoryCard({
    Key? key,
    required this.subCategory,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
    this.isTablet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section supérieure avec icône et couleur
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [categoryColor.withOpacity(0.8), categoryColor],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categoryIcon,
                      size: isTablet ? 40 : 32,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 12 : 8,
                      vertical: isTablet ? 6 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      categoryName,
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section inférieure avec informations
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nom de la sous-catégorie
                  Text(
                    subCategory.name,
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Description si disponible
                  if (subCategory.description.isNotEmpty)
                    Text(
                      subCategory.description,
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
                        color: Color(0xFF95A5A6),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const Spacer(),

                  // Indicateur d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10 : 8,
                          vertical: isTablet ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Explorer',
                          style: TextStyle(
                            fontSize: isTablet ? 12 : 10,
                            color: categoryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(isTablet ? 8 : 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: isTablet ? 14 : 12,
                          color: categoryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
