import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher_string.dart';
import 'dart:collection'; // Import for SplayTreeMap

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
        primarySwatch: Colors.orange, // You can keep this or change for app bar, but the search section will be orange
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: ProductsScreen(),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

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

  // Define all known stores
  final List<String> _allStores = ['Shopleft', 'Woowies', 'CheekaCart', 'PackNPush'];

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    final List<Map<String, dynamic>> combined = [];

    // --- Shopleft ---
    final shopleftSnapshot = await FirebaseFirestore.instance.collection('Shopleft').get();
    for (var doc in shopleftSnapshot.docs) {
      final data = doc.data();
      if (data['name'] != null) {
        combined.add({
          'name': data['name'],
          'store': data['retailer'] ?? 'Shopleft',
          'price': data['price'],
          'image': 'https://i.imgur.com/lTFFPNa.png',
          'url': data['url'],
          'scraped_at': data['scraped_at'],
        });
      }
    }

    // --- Woowies ---
    final woowiesSnapshot = await FirebaseFirestore.instance.collection('Woowies').get();
    print('Woowies documents count: ${woowiesSnapshot.docs.length}'); // Debugging line
    for (var doc in woowiesSnapshot.docs) {
      final data = doc.data();
      print('  Woowies Document Data: $data'); // Debugging line: Print raw document data
      if (data['name'] != null) {
        combined.add({
          'name': data['name'],
          'store': data['retailer'] ?? 'Woowies', // Ensure this matches _allStores list
          'price': data['price'],
          'image': 'https://i.imgur.com/jFSVOyk.png',
          'url': data['link'], // Ensure 'link' is the correct field name in Firestore
          'scraped_at': data['timestamp'], // Ensure 'timestamp' is the correct field name in Firestore
        });
      }
    }
    print('Combined products after Woowies: ${combined.length}'); // Debugging line

    // --- CheekaCart ---
    final cheekaCartSnapshot = await FirebaseFirestore.instance.collection('CheekaCart').get();
    for (var doc in cheekaCartSnapshot.docs) {
      final data = doc.data();
      if (data['name'] != null) {
        combined.add({
          'name': data['name'],
          'store': data['retailer'] ?? 'CheekaCart',
          'image': 'https://i.imgur.com/GgmrVDw.png',
          'price': data['price'],
          'url': data['url'],
          'scraped_at': data['scraped_at'],
        });
      }
    }

    // --- PackNPush ---
    final packNPushSnapshot = await FirebaseFirestore.instance.collection('PackNPush').get();
    print('PackNPush documents count: ${packNPushSnapshot.docs.length}'); // Debugging line
    for (var doc in packNPushSnapshot.docs) {
      final data = doc.data();
      print('  PackNPush Document Data: $data'); // Debugging line: Print raw document data
      if (data['name'] != null) {
        combined.add({
          'name': data['name'],
          'store': data['retailer'] ?? 'PackNPush', // Ensure 'PackNPush' matches _allStores list
          'price': data['price'],
          'image': 'https://i.imgur.com/onUDTXw.png',
          'url': data['link'], // Ensure 'link' is the correct field name in Firestore
          'scraped_at': data['timestamp'], // Ensure 'timestamp' is the correct field name in Firestore
        });
      }
    }
    print('Combined products after PackNPush: ${combined.length}'); // Debugging line

    setState(() {
      _allProducts = combined;
      _dataLoaded = true;
    });
    print('Total _allProducts after loading: ${_allProducts.length}'); // Final check
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
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
    if (query.isEmpty || !_dataLoaded) {
      setState(() {
        _results = [];
        _autocompleteNames = [];
        // When query is empty, show all stores as unavailable
        _results = _allStores.map((storeName) => {
          'name': 'No results for "$query"', // Or just "N/A"
          'store': storeName,
          'price': 'Unavailable',
          'is_available': false,
        }).toList();
      });
      return;
    }

    final trimmed = query.trim().toLowerCase();
    print('Search query (trimmed): "$trimmed"');
    print('Number of total products in _allProducts: ${_allProducts.length}');

    if (trimmed == _lastSearchQuery && _results.isNotEmpty && _results.any((element) => element['is_available'] == true)) {
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
        .where((item) {
      final itemName = item['name']?.toString().toLowerCase() ?? '';
      final containsQuery = itemName.contains(trimmed);
      return containsQuery;
    })
        .toList();

    print('Number of filtered products (matching "$trimmed"): ${filtered.length}');
    if (filtered.isEmpty) {
      print('No products matched the search query "$trimmed".');
    } else {
      print('Matched products:');
      for (var p in filtered) {
        print('  - Name: ${p['name']}, Store: ${p['store']}, Price: ${p['price']}');
      }
    }

    // Group products by store and find the cheapest within each store
    final Map<String, Map<String, dynamic>> cheapestPerStore = SplayTreeMap();

    for (var product in filtered) {
      final store = product['store']?.toString() ?? 'Unknown Store';

      // --- FIX STARTS HERE ---
      String? rawPriceString = product['price']?.toString();
      double? currentPrice;

      if (rawPriceString != null) {
        // Remove 'R' and any leading/trailing spaces
        String cleanedPriceString = rawPriceString.replaceAll('R', '').trim();
        currentPrice = double.tryParse(cleanedPriceString);
      }
      // --- FIX ENDS HERE ---

      print('Processing for cheapestPerStore: Product: ${product['name']}, Store: $store, Price: $currentPrice'); // Debugging
      if (currentPrice != null) {
        if (!cheapestPerStore.containsKey(store) ||
            (double.tryParse(cheapestPerStore[store]!['price']?.toString() ?? '') ?? double.maxFinite) > currentPrice) {
          // Store the actual parsed price, not the original string, for correct comparison and display
          cheapestPerStore[store] = { ...product, 'price': currentPrice };
        }
      } else {
        print('WARNING: Product "${product['name']}" from store "$store" has null or non-parseable price: "${product['price']}"');
      }
    }

    print('Cheapest product per store after grouping:');
    cheapestPerStore.forEach((store, product) {
      print('  $store: Name: ${product['name']}, Price: ${product['price']}');
    });

    // Populate final results with available products and unavailable placeholders
    final List<Map<String, dynamic>> finalResults = [];

    for (String storeName in _allStores) {
      if (cheapestPerStore.containsKey(storeName)) {
        print('Adding available item for store: $storeName');
        finalResults.add({
          ...cheapestPerStore[storeName]!,
          'is_available': true,
        });
      } else {
        print('Adding unavailable placeholder for store: $storeName');
        // Add placeholder for unavailable store
        finalResults.add({
          'name': query, // Show the searched query name for context
          'store': storeName,
          'price': 'Unavailable',
          'is_available': false,
        });
      }
    }

    print('Final results before sorting:');
    for (var r in finalResults) {
      print('  - Store: ${r['store']}, Name: ${r['name']}, Price: ${r['price']}, Available: ${r['is_available']}');
    }

    // Sort available items by price, keeping unavailable items at the bottom or in their sorted store order
    finalResults.sort((a, b) {
      final bool aAvailable = a['is_available'] ?? false;
      final bool bAvailable = b['is_available'] ?? false;

      if (aAvailable && !bAvailable) {
        return -1; // Available comes before unavailable
      } else if (!aAvailable && bAvailable) {
        return 1; // Unavailable comes after available
      } else if (aAvailable && bAvailable) {
        // Both available, sort by price
        // Ensure to parse the price from the 'finalResults' list, which might be the cleaned double
        final priceA = double.tryParse(a['price']?.toString() ?? '');
        final priceB = double.tryParse(b['price']?.toString() ?? '');

        if (priceA == null && priceB == null) return 0;
        if (priceA == null) return 1;
        if (priceB == null) return -1;
        return priceA.compareTo(priceB);
      } else {
        // Both unavailable, sort by store name for consistency
        return (a['store'] as String).compareTo(b['store'] as String);
      }
    });

    setState(() {
      _results = finalResults;
      _loading = false;
    });
    print('Final _results list count: ${_results.length}');
  }

  Widget _buildSearchInput() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center( // <--- Add this widget
                child: const Text(
                  'Find the Best Prices',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Compare prices of all major South African retailers and save money on your shopping.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                onSubmitted: (query) {
                  FocusScope.of(context).unfocus();
                  _performSearch(query);
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search for products...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
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
    if (_results.isEmpty && !_loading && _searchController.text.isNotEmpty) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "Press enter to search for \"${_searchController.text}\" across all stores.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 30),
          _buildDisclaimer(),
        ],
      );
    } else if (_results.isEmpty && !_loading && _searchController.text.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.search, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            "Search for products to compare prices",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 30),
          _buildDisclaimer(),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              final bool isAvailable = item['is_available'] ?? false;
              // Check if this is the cheapest overall by being the first available item in the sorted list
              final bool isCheapestOverall = isAvailable && _results.where((e) => e['is_available'] == true).toList().indexOf(item) == 0;

              final String priceDisplay = isAvailable
                  ? (item['price'] != null ? 'R ${item['price'].toStringAsFixed(2)}' : 'N/A') // Format price to 2 decimal places
                  : 'Unavailable';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                color: isAvailable ? Colors.white : Colors.grey[100], // Lighter grey for unavailable
                elevation: isAvailable ? 2 : 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Display image if available and product is available
                      isAvailable && item['image'] != null && item['image'].toString().isNotEmpty
                          ? Image.network(
                        item['image'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to a store icon if image fails to load
                          return Icon(Icons.store, size: 60, color: Colors.grey[700]);
                        },
                      )
                          : Icon(isAvailable ? Icons.store : Icons.info_outline, size: 60, color: isAvailable ? Colors.deepOrange : Colors.grey[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAvailable ? (item['name'] ?? 'No Name') : 'Product: ${item['name'] ?? 'N/A'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isAvailable ? Colors.black87 : Colors.grey[600],
                                fontStyle: isAvailable ? FontStyle.normal : FontStyle.italic,
                              ),
                            ),
                            Text(
                              'Store: ${item['store'] ?? 'N/A'}',
                              style: TextStyle(color: isAvailable ? Colors.black54 : Colors.grey[500]),
                            ),
                            Text(
                              'Price: $priceDisplay',
                              style: TextStyle(
                                fontWeight: isAvailable ? FontWeight.bold : FontWeight.normal,
                                color: isAvailable ? Colors.green[700] : Colors.red, // Green for available price
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Show "Buy Now" only if it's available AND it's the cheapest overall
                      if (isCheapestOverall)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final url = item['url']?.toString();
                            if (url != null && await canLaunchUrlString(url)) {
                              await launchUrlString(url);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not launch URL')),
                              );
                            }
                          },
                          icon: const Icon(Icons.shopping_cart, size: 18),
                          label: const Text('Buy Now', style: TextStyle(fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        )
                      else if (!isAvailable) // Only display 'Not Found' if it's explicitly unavailable
                        const Text(
                          'Not Found',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildDisclaimer(),
      ],
    );
  }

  Widget _buildDisclaimer() {
    return Column(
      children: [
        Icon(Icons.info_outline, color: Colors.grey[500], size: 24),
        const SizedBox(height: 5),
        Text(
          'Price Disclaimer',
          style: TextStyle(
            color: Colors.red[700],
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Prices are updated regularly but may vary from actual store prices.\nPlease verify prices before making purchase.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () async {
            const url = 'https://example.com/terms_conditions'; // Replace with your actual Terms & Conditions URL
            if (await canLaunchUrlString(url)) {
              await launchUrlString(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open Terms & Conditions')),
              );
            }
          },
          child: Text(
            'For more information, visit our Terms & Conditions',
            style: TextStyle(
              color: Colors.blue[700],
              decoration: TextDecoration.underline,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row( // <-- Changed to Row
          mainAxisSize: MainAxisSize.min, // Make the row compact
          children: [
            // Your default logo here
            Image.asset(
              'assets/Group 5.png', // Make sure this path is correct and file exists
              height: 30, // Adjust size as needed
              width: 30,  // Adjust size as needed
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.shopping_cart, size: 30, color: Colors.black87); // Fallback icon if image fails
              },
            ),
            const SizedBox(width: 8), // Spacing between logo and text
            const Text(
              "Price Pulse",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
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