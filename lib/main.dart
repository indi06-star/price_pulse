import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Price Comparison App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ProductsScreen(),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _results = [];
  List<String> _autocompleteNames = [];
  bool _loading = false;
  String _lastSearchQuery = '';
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    final List<Map<String, dynamic>> combined = [];

    final productsSnapshot = await FirebaseFirestore.instance.collection('Products').get();
    for (var doc in productsSnapshot.docs) {
      final data = doc.data();
      if (data['name'] != null) {
        combined.add({
          'name': data['name'],
          'store': data['shop'] ?? 'Products',
          'price': data['price'],
          'url': data['link'],
        });
      }
    }

    final woolworthsSnapshot = await FirebaseFirestore.instance.collection('Woolworths').get();
    for (var doc in woolworthsSnapshot.docs) {
      final data = doc.data();
      if (data['name'] != null) {
        combined.add({
          'name': data['name'],
          'store': 'Woolworths',
          'price': data['price'],
          'image': data['image'],
          'url': data['link'],
        });
      }
    }

    final checkersSnapshot = await FirebaseFirestore.instance.collection('Checkers').get();
    for (var doc in checkersSnapshot.docs) {
      final data = doc.data();
      if (data['name'] != null) {
        combined.add({
          'name': data['name'],
          'store': 'Checkers',
          'price': data['on_special_price'] ?? data['price'],
          'url': data['url'],
        });
      }
    }

    setState(() {
      _allProducts = combined;
      _dataLoaded = true;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double parsePrice(dynamic price) {
    if (price == null) return 0;
    if (price is num) return price.toDouble();
    final cleaned = price.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  void _onSearchChanged(String query) {
    if (!_dataLoaded) return;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _fetchAutocompleteSuggestions(query.trim());
    });
  }

  void _fetchAutocompleteSuggestions(String query) {
    if (query.isEmpty || !_dataLoaded) {
      setState(() => _autocompleteNames = []);
      return;
    }

    final lower = query.toLowerCase();
    final suggestions = _allProducts
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.toLowerCase().contains(lower))
        .toSet()
        .toList()
        .take(8)
        .toList();

    setState(() {
      _autocompleteNames = suggestions;
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty || !_dataLoaded) return;

    final trimmed = query.trim().toLowerCase();

    if (trimmed == _lastSearchQuery && _results.isNotEmpty) {
      setState(() {
        _autocompleteNames = [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _autocompleteNames = [];
      _lastSearchQuery = trimmed;
    });

    final filtered = _allProducts
        .where((item) => (item['name']?.toString().toLowerCase() ?? '').contains(trimmed))
        .toList();

    filtered.sort((a, b) => parsePrice(a['price']).compareTo(parsePrice(b['price'])));

    setState(() {
      _results = filtered;
      _loading = false;
    });
  }

  Widget _buildSearchInput() {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          onSubmitted: (query) {
            FocusScope.of(context).unfocus();
            _performSearch(query);
          },
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search for products...',
            border: OutlineInputBorder(),
          ),
        ),
        if (_autocompleteNames.isNotEmpty && _searchController.text.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Card(
              elevation: 4,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _autocompleteNames.length,
                itemBuilder: (context, index) {
                  final suggestion = _autocompleteNames[index];
                  return ListTile(
                    title: Text(suggestion),
                    onTap: () {
                      _searchController.text = suggestion;
                      FocusScope.of(context).unfocus();
                      _performSearch(suggestion);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildResultsList() {
    return _results.isEmpty
        ? const Text("No results.")
        : ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return Card(
          child: ListTile(
            leading: item['image'] != null
                ? Image.network(item['image'], width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.store),
            title: Text(item['name']),
            subtitle: Text('Store: ${item['store']}'),
            trailing: Text('R${parsePrice(item['price']).toStringAsFixed(2)}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Search"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _autocompleteNames = [];
                _results = [];
                _lastSearchQuery = '';
                _focusNode.requestFocus();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSearchInput(),
            const SizedBox(height: 10),
            _loading
                ? const CircularProgressIndicator()
                : Expanded(child: _buildResultsList()),
          ],
        ),
      ),
    );
  }
}
