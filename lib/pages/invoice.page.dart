import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice App',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: InvoicePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InvoicePage extends StatefulWidget {
  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  String? selectedMacaboMerchant;
  String? selectedPlantainMerchant;
  TextEditingController observationsController = TextEditingController();

  final List<String> merchants = [
    'Sélectionner un commerçant',
    'Boulangerie Dubois',
    'Épicerie Martin',
    'Marché Central',
    'Supermarché Durand',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'INV-2024-001',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Marie NGA',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.fromLTRB(15, 10, 15, 40),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Macabo Section
              _buildProductSection(
                'Macabo',
                '500 Fcfa',
                selectedMacaboMerchant,
                (String? value) {
                  setState(() {
                    selectedMacaboMerchant = value;
                  });
                },
              ),

              SizedBox(height: 24),

              // Plantain Section
              _buildProductSection(
                'Plantain',
                '500 Fcfa',
                selectedPlantainMerchant,
                (String? value) {
                  setState(() {
                    selectedPlantainMerchant = value;
                  });
                },
              ),

              SizedBox(height: 24),

              // Observations Section
              _buildObservationsSection(),

              SizedBox(height: 32),

              // Purchase Summary
              _buildPurchaseSummary(),

              SizedBox(height: 32),

              // Validate Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1E3A5F),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Valider l\'achat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductSection(
    String productName,
    String price,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              productName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),

        SizedBox(height: 12),

        Row(
          children: [
            Text(
              'Nom du commerçant',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            Text('*', style: TextStyle(fontSize: 14, color: Colors.red)),
          ],
        ),

        SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButton<String>(
            value: selectedValue,
            hint: Text(
              'Sélectionner un commerçant',
              style: TextStyle(color: Colors.grey[600]),
            ),
            isExpanded: true,
            underline: SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
            items: merchants.map((String merchant) {
              return DropdownMenuItem<String>(
                value: merchant,
                child: Text(merchant),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildObservationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              'Observations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '(optionnel)',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),

        SizedBox(height: 12),

        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: TextField(
            controller: observationsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ajouter des observations sur cet achat...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Récapitulatif des achats',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        SizedBox(height: 20),

        _buildSummaryItem(
          'Pain complet',
          '2.50 F',
          '2 unités',
          'Boulangerie Dubois',
        ),

        SizedBox(height: 20),

        _buildSummaryItem(
          'Lait bio 1L',
          '1.80 F',
          '1 unité',
          'Épicerie Martin',
        ),

        SizedBox(height: 20),

        Divider(color: Colors.grey[300]),

        SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Montant total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '4.30 F',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A5F),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    String title,
    String price,
    String quantity,
    String merchant,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Quantité: $quantity',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              Text(
                'Commerçant: $merchant',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Text(
          price,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
