import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemNavigator.pop()
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting timestamp
import 'dart:async'; // For debouncing

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());2;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Price Comparison App',
      theme: ThemeData(
        // Keep the primary theme data for consistency, but allow widget-specific overrides
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Define text theme for consistent styling (from previous code)
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            color: Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle( // For product names
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle( // For shop names
            fontSize: 14,
            color: Color(0xFF616161), // Custom grey from screenshot
            fontWeight: FontWeight.w500,
          ),
          displayMedium: TextStyle( // For prices
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          labelSmall: TextStyle( // For last updated text
            fontSize: 12,
            color: Color(0xFF9E9E9E), // Custom grey from screenshot
          ),
        ),
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
  final CollectionReference products =
  FirebaseFirestore.instance.collection('products');

  String _searchQuery = ''; // State variable to hold the search query
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // For debouncing the search input

  // List to hold all possible product and shop names for suggestions
  List<String> _allSearchableTerms = [];

  // State for the disclaimer visibility (from main (4).dart)
  bool _showDisclaimer = true;

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel any active debounce timer
    _searchController.dispose(); // Dispose the text editing controller
    super.dispose();
  }

  // Function to handle search input changes with debouncing
  void _onSearchChanged(String query) {
    // Cancel the previous timer if it exists
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    // Set a new timer
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Only update the state if the query has actually changed
      if (_searchQuery != query.toLowerCase()) {
        setState(() {
          _searchQuery = query.toLowerCase();
        });
      }
    });
  }

  // Function to handle search submission (when user presses Enter or selects a suggestion)
  void _onSearchSubmitted(String query) {
    _debounce?.cancel(); // Immediately cancel any pending debounce
    // Update the search query directly and trigger a rebuild
    if (_searchQuery != query.toLowerCase()) {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
    }
    FocusScope.of(context).unfocus(); // Dismiss the keyboard
  }

  // Function to handle selection from autocomplete suggestions
  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    _onSearchSubmitted(suggestion); // Treat selection as submission
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(































      backgroundColor: const Color(0xFF2E2D3B), // Background color from main (4).dart
      body: GestureDetector( // For unfocusing keyboard on tap outside
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              // Combined Top Bar (from main (4).dart)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white, // Color from main (4).dart
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A000000), // Shadow from main (4).dart
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0x1A6A1B9A), // Color from main (4).dart
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              'assets/image.png', // NOTE: You need to add 'assets/image.png' to your pubspec.yaml and project.
                              width: 30,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) => Icon( // Fallback icon if image fails
                                Icons.shopping_basket,
                                size: 30,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Price Pulse', // Text from main (4).dart
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.exit_to_app,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        onPressed: () {
                          SystemNavigator.pop(); // Functionality from main (4).dart
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white, // From main (4).dart
                    borderRadius: BorderRadius.only( // From main (4).dart
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(0),
                    ),
                    boxShadow: [ // From main (4).dart
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 15,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: CustomScrollView( // For better flexibility
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // "Find the Best Prices" information box (from main (4).dart)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEE7FF), // Color from main (4).dart
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Find the Best Prices', // Text from main (4).dart
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4C4A5C),
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Compare prices across all major South African\nretailers and save money on your shopping.', // Text from main (4).dart
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4C4A5C),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    // Search Bar with Autocomplete
                                    Autocomplete<String>(
                                      optionsBuilder: (TextEditingValue textEditingValue) {
                                        if (textEditingValue.text.isEmpty) {
                                          return const Iterable<String>.empty();
                                        }
                                        // Filter suggestions from _allSearchableTerms
                                        return _allSearchableTerms.where((String option) {
                                          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                        });
                                      },
                                      onSelected: (String selection) {
                                        _selectSuggestion(selection); // Use our custom selection handler
                                      },
                                      fieldViewBuilder: (BuildContext context,
                                          TextEditingController fieldTextEditingController,
                                          FocusNode fieldFocusNode,
                                          VoidCallback onFieldSubmitted) { // onFieldSubmitted is passed by Autocomplete
                                        // Ensure our _searchController is linked to Autocomplete's controller
                                        _searchController.text = fieldTextEditingController.text;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 15),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey[300]!),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF000000).withAlpha(25),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: TextField(
                                            controller: fieldTextEditingController, // Use Autocomplete's controller
                                            focusNode: fieldFocusNode,
                                            decoration: const InputDecoration(
                                              hintText: 'Search for products...',
                                              hintStyle: TextStyle(color: Colors.grey),
                                              border: InputBorder.none,
                                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                                              isDense: true,
                                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                                            ),
                                            onChanged: _onSearchChanged, // Still use our debounced onChanged
                                            onSubmitted: (value) {
                                              // *** MODIFICATION HERE ***
                                              // Do NOT call onFieldSubmitted();
                                              _onSearchSubmitted(value); // ONLY call our own submission handler
                                            },
                                          ),
                                        );
                                      },
                                      // ... rest of your Autocomplete code
                                      optionsViewBuilder: (BuildContext context,
                                          AutocompleteOnSelected<String> onSelected,
                                          Iterable<String> options) {
                                        // Only show suggestions if there are options and the search field has focus
                                        if (options.isEmpty || !_searchController.text.isNotEmpty) {
                                          return const SizedBox.shrink(); // Hide if no options or empty search
                                        }
                                        return Align(
                                          alignment: Alignment.topLeft,
                                          child: Material(
                                            elevation: 4.0,
                                            borderRadius: BorderRadius.circular(12), // Match search bar border radius
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                  maxHeight: MediaQuery.of(context).size.height * 0.3, // Limit height to 30% of screen
                                                  maxWidth: MediaQuery.of(context).size.width - 80 // To match search bar width
                                              ),
                                              child: ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                itemCount: options.length,
                                                itemBuilder: (BuildContext context, int index) {
                                                  final String option = options.elementAt(index);
                                                  return ListTile(
                                                    title: Text(
                                                      option,
                                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                                    ),
                                                    dense: true,
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                                                    visualDensity: VisualDensity.compact,
                                                    onTap: () {
                                                      onSelected(option);
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        // Disclaimer Section (Moved here, before StreamBuilder)
                        if (_showDisclaimer)
                          SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.only(bottom: 10, top: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.red[300], size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'Price Disclaimer\n', // Text from main (4).dart
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red[300],
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'Prices are updated regularly but may vary from actual store prices. Please verify prices before making purchases.', // Text from main (4).dart
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Dismiss button for the disclaimer
                                      IconButton(
                                        icon: Icon(Icons.close, color: Colors.grey[500], size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _showDisclaimer = false;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'For more information, visit our Terms & Conditions', // Text from main (4).dart
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // StreamBuilder for fetching and filtering products (existing functionality)
                        StreamBuilder<QuerySnapshot>(
                          stream: products.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return SliverFillRemaining(
                                  child: Center(child: Text('Error: ${snapshot.error}')));
                            }
                            if (!snapshot.hasData) {
                              return const SliverFillRemaining(
                                  child: Center(child: CircularProgressIndicator()));
                            }

                            // Populate _allSearchableTerms for suggestions (existing functionality)
                            _allSearchableTerms = [];
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['name'] ?? '').toString();
                              final shop = (data['shop'] ?? '').toString();
                              if (name.isNotEmpty) _allSearchableTerms.add(name);
                              if (shop.isNotEmpty) _allSearchableTerms.add(shop);
                            }
                            // Remove duplicates and sort for better suggestions
                            _allSearchableTerms = _allSearchableTerms.toSet().toList()..sort();

                            // If search query is empty, show a message instead of products (existing functionality)
                            if (_searchQuery.isEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                    'Start typing to search for products...',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }

                            // Filter documents based on the current _searchQuery (existing functionality)
                            final filteredDocs = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final name = (data['name'] ?? '').toLowerCase();
                              final shop = (data['shop'] ?? '').toLowerCase();
                              return name.contains(_searchQuery) || shop.contains(_searchQuery);
                            }).toList();

                            if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.sentiment_dissatisfied,
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No results found for "${_searchQuery}"',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Please try a different search term.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return SliverList(
                              delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  final data = filteredDocs[index].data() as Map<String, dynamic>;

                                  final name = data['name'] ?? 'No Name';
                                  final price = data['price'] ?? 'N/A';
                                  final shop = data['shop'] ?? 'Unknown';
                                  final isBestPrice = data['isBestPrice'] ?? false;
                                  final timestamp = data['timestamp'];
                                  // Assuming 'isAvailable' and 'isUnavailable' might exist in Firestore,
                                  // provide defaults if not.
                                  final isAvailable = data['isAvailable'] ?? true;
                                  final isUnavailable = data['isUnavailable'] ?? false;
                                  final imageUrl = data['imageUrl'] ?? 'https://placehold.co/80x80/cccccc/000000?text=No+Image'; // Placeholder if no image URL in Firestore

                                  String formattedTime = 'No Date';
                                  if (timestamp is Timestamp) {
                                    final now = DateTime.now();
                                    final productDate = timestamp.toDate();
                                    final difference = now.difference(productDate);

                                    if (difference.inMinutes < 60) {
                                      formattedTime = 'Last updated ${difference.inMinutes} Min ago';
                                    } else if (difference.inHours < 24) {
                                      formattedTime = 'Last updated ${difference.inHours} hours ago';
                                    } else {
                                      formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(productDate);
                                    }
                                  }

                                  return ProductCard(
                                    imagePath: imageUrl, // Use the image URL from Firestore
                                    productName: name,
                                    store: shop,
                                    price: price.toString(), // Ensure price is string
                                    lastUpdated: formattedTime,
                                    isBestPrice: isBestPrice,
                                    isAvailable: isAvailable,
                                    isUnavailable: isUnavailable,
                                    searchQuery: _searchQuery,
                                  );
                                },
                                childCount: filteredDocs.length,
                              ),
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
        ),
      ),
    );
  }
}

// Separate Widget for a single Product Card (Copied and adapted from main (4).dart)
class ProductCard extends StatelessWidget {
  final String imagePath;
  final String productName;
  final String store;
  final String price;
  final String lastUpdated;
  final bool isBestPrice;
  final bool isAvailable;
  final bool isUnavailable;
  final String? searchQuery;

  const ProductCard({
    super.key,
    required this.imagePath,
    required this.productName,
    required this.store,
    required this.price,
    required this.lastUpdated,
    this.isBestPrice = false,
    this.isAvailable = true,
    this.isUnavailable = false,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: (isUnavailable || !isAvailable) ? Colors.grey[100] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: (isUnavailable || !isAvailable) ? Colors.grey[200] : null,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF000000).withAlpha(25),
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: (isUnavailable || !isAvailable)
                          ? Icon(
                        Icons.block,
                        color: Colors.grey[500],
                        size: 40,
                      )
                          : ClipRRect( // Use ClipRRect for image to respect border radius
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imagePath,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (isUnavailable || !isAvailable) ? (searchQuery ?? 'Product') : productName,
                        style: TextStyle(
                          fontSize: 16,
                          color: (isUnavailable || !isAvailable) ? Colors.grey[600] : Colors.black87,
                          fontStyle: (isUnavailable || !isAvailable) ? FontStyle.italic : null,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        store,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: (isUnavailable || !isAvailable) ? Colors.grey[800] : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (isUnavailable || !isAvailable) ? 'N/A' : price,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: (isUnavailable || !isAvailable) ? Colors.red[300] : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        (isUnavailable || !isAvailable)
                            ? 'Product is unavailable at this store'
                            : 'Last updated $lastUpdated',
                        style: TextStyle(
                          fontSize: 12,
                          color: (isUnavailable || !isAvailable) ? Colors.grey[500] : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isBestPrice && (isAvailable && !isUnavailable))
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal[400],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Best Price',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (!isAvailable && !isUnavailable)
              Positioned(
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Out of Stock',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}