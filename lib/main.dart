import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Transaction Tracker',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFFDEDED),
      ),
      home: const TransactionHomeScreen(),
    );
  }
}

class TransactionHomeScreen extends StatefulWidget {
  const TransactionHomeScreen({super.key});

  @override
  State<TransactionHomeScreen> createState() => _TransactionHomeScreenState();
}

class _TransactionHomeScreenState extends State<TransactionHomeScreen>
    with SingleTickerProviderStateMixin {
  final String apiUrl = 'https://transaction-backend-re1d.onrender.com/api/entries';
  
  late TabController _tabController;
  List<dynamic> entries = [];
  bool isLoading = true;
  String errorMessage = '';

  final List<String> categories = ['Rahul Side', 'Pants (250)', 'Papa Side'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: categories.length, vsync: this);
    fetchEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchEntries() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          entries = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load entries: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> addEntry(String category, double amount) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category': category,
          'amount': amount,
        }),
      );

      if (response.statusCode == 201) {
        fetchEntries();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add transaction')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddDialog(String categoryName) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add to $categoryName'),
          content: TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Amount (Rs)'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;
                if (amount > 0) {
                  addEntry(categoryName, amount);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  double calculateTotal(String category) {
    double total = 0;
    for (var item in entries) {
      if (item['category'] == category) {
        total += (item['amount'] is int)
            ? (item['amount'] as int).toDouble()
            : (item['amount'] ?? 0.0);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Text('Transaction Tracker'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: categories.map((cat) => Tab(text: cat)).toList(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)))
              : TabBarView(
                  controller: _tabController,
                  children: categories.map((category) {
                    final categoryEntries = entries
                        .where((item) => item['category'] == category)
                        .toList();
                    final total = calculateTotal(category);

                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.black12,
                                    child: const Icon(Icons.qr_code, size: 40),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Scan & Pay via UPI',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const Text(
                                        'divanshdave169@okicici',
                                        style: TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total: Rs ${total.toStringAsFixed(0)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[700],
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: categoryEntries.isEmpty
                                ? const Center(child: Text('No transactions yet.'))
                                : ListView.builder(
                                    itemCount: categoryEntries.length,
                                    itemBuilder: (context, index) {
                                      final item = categoryEntries[index];
                                      return ListTile(
                                        title: Text('Rs ${item['amount']}'),
                                        subtitle: Text(item['timestamp'] ?? ''),
                                      );
                                    },
                                  ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onPressed: () => _showAddDialog(category),
                              child: Text(
                                'Add Rs 150 to $category',
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
