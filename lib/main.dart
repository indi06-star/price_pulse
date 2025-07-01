import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting timestamp

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
      title: 'Firestore Demo',
      home: ProductsScreen(),
    );
  }
}

class ProductsScreen extends StatelessWidget {
  final CollectionReference products =
  FirebaseFirestore.instance.collection('products');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: StreamBuilder<QuerySnapshot>(
        stream: products.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final name = data['name'] ?? 'No Name';
              final price = data['price'] ?? 'N/A';
              final shop = data['shop'] ?? 'Unknown';
              final timestamp = data['timestamp'];
              final formattedTime = timestamp is Timestamp
                  ? DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate())
                  : 'No Date';

              return ListTile(
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$shop'),
                    Text('Price: R $price'),
                    Text('Added: $timestamp()'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
