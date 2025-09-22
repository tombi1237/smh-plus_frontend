import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smh_front/pages/clients/pages/districts_products_page.dart';

class DistrictsWidget extends StatefulWidget {
  const DistrictsWidget({Key? key}) : super(key: key);

  @override
  _DistrictsWidgetState createState() => _DistrictsWidgetState();
}

class _DistrictsWidgetState extends State<DistrictsWidget> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<District> districts = [];
  List<District> filteredDistricts = []; // 👈 Liste filtrée
  bool isLoading = false;
  String errorMessage = '';
  final TextEditingController _searchController =
      TextEditingController(); // 👈 controller

  @override
  void initState() {
    super.initState();
    _fetchDistricts();
  }

  Future<void> _fetchDistricts() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        setState(() {
          isLoading = false;
          errorMessage = "🔒 Token non trouvé. Veuillez vous connecter.";
        });
        return;
      }

      final uri = Uri.parse("http://49.13.197.63:8002/api/geography/districts");

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
            onTimeout: () =>
                throw Exception("⏳ Timeout lors du chargement des zones"),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null && data["data"] is List) {
          final fetchedDistricts = (data["data"] as List)
              .map((d) => District.fromJson(d))
              .toList();

          setState(() {
            districts = fetchedDistricts;
            filteredDistricts = fetchedDistricts; // 👈 copie initiale
          });
        } else {
          setState(() {
            errorMessage = "Aucune donnée reçue";
          });
        }
      } else {
        throw Exception(
          "Erreur ${response.statusCode} lors du chargement des zones",
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = "🚨 Erreur: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterDistricts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDistricts = districts;
      } else {
        filteredDistricts = districts
            .where(
              (d) =>
                  d.name.toLowerCase().contains(query.toLowerCase()) ||
                  d.city.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choisir une zone de livraison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // 🔎 Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filterDistricts,
                decoration: InputDecoration(
                  hintText: "Rechercher un district ou une ville...",
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4A90E2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Content
            Expanded(child: _buildDistrictsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildDistrictsList() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchDistricts,
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

    if (filteredDistricts.isEmpty) {
      return const Center(
        child: Text(
          'Aucun district trouvé',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredDistricts.length,
      itemBuilder: (context, index) {
        final district = filteredDistricts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
              ),
            ],
          ),
          child: ListTile(
            leading: const Icon(Icons.location_on, color: Color(0xFF4A90E2)),
            title: Text(
              district.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            subtitle: Text("Ville: ${district.city}"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DistrictsProductsPage(
                    districtId: district.id,
                    districtName: district.name,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Helper (inchangé)
class DistrictsHelper {
  static void showDistrictsDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const DistrictsWidget();
      },
    );
  }
}

// ====== Modèles (inchangés) ======
class District {
  final int id;
  final String name;
  final String city;
  final int departmentId;
  final List<Station> stations;
  final Chef? chef;
  final String? status;

  District({
    required this.id,
    required this.name,
    required this.city,
    required this.departmentId,
    required this.stations,
    this.chef,
    this.status,
  });

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      city: json['city'] ?? '',
      departmentId: json['departmentId'] ?? 0,
      stations:
          (json['stations'] as List<dynamic>?)
              ?.map((s) => Station.fromJson(s))
              .toList() ??
          [],
      chef: json['chef'] != null ? Chef.fromJson(json['chef']) : null,
      status: json['status'],
    );
  }
}

class Station {
  final int id;
  final String name;
  final int districtId;
  final String status;
  final dynamic chef;

  Station({
    required this.id,
    required this.name,
    required this.districtId,
    required this.status,
    this.chef,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      districtId: json['districtId'] ?? 0,
      status: json['status'] ?? 'inactive',
      chef: json['chef'],
    );
  }
}

class Chef {
  final int id;
  final String firstName;
  final String lastName;

  Chef({required this.id, required this.firstName, required this.lastName});

  factory Chef.fromJson(Map<String, dynamic> json) {
    return Chef(
      id: json['id'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';
}
