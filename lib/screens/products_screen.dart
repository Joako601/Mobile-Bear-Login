import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // 6.1 URL base segun el dispositivo:
  // - Chrome / iOS simulator: http://localhost:8090
  // - Emulador Android: http://10.0.2.2:8090
  // - Celular fisico: IP local de la computadora (misma red Wi-Fi)
  static const String baseUrl = 'http://192.168.1.69:8090';

  // Se guarda el Future para no repetir la peticion en cada rebuild
  late final Future<List<dynamic>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
  }

  // 6.2 Peticion GET a Spring Boot
  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      // El JSON es un arreglo -> List
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al cargar productos de la API');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Productos de Spring Boot')),
      // 6.3 FutureBuilder para pintar segun el estado de la peticion
      body: FutureBuilder<List<dynamic>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          // 6.4 Lista de productos (las llaves deben coincidir con el JSON)
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index] as Map<String, dynamic>;
              final category = product['category']?['category'] ?? '';
              return ListTile(
                leading: const Icon(Icons.shopping_basket),
                title: Text('${product['name']}'),
                subtitle: Text('Stock: ${product['stock']}  ·  $category'),
                trailing: Text(
                  '\$${product['price']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
