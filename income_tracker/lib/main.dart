import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Tracker',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomePage(),
    );
  }
}

class Transaction {
  final int? id;
  final String type;
  final double amount;
  final String note;
  final String date;

  Transaction({this.id, required this.type, required this.amount, required this.note, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'note': note,
      'date': date,
    };
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Database database;
  List<Transaction> transactions = [];

  double get totalIncome => transactions
      .where((t) => t.type == 'income')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => transactions
      .where((t) => t.type == 'expense')
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  @override
  void initState() {
    super.initState();
    initDB();
  }

  Future<void> initDB() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'transactions.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY, type TEXT, amount REAL, note TEXT, date TEXT)',
        );
      },
      version: 1,
    );
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final List<Map<String, dynamic>> maps = await database.query('transactions');
    setState(() {
      transactions = List.generate(maps.length, (i) {
        return Transaction(
          id: maps[i]['id'],
          type: maps[i]['type'],
          amount: maps[i]['amount'],
          note: maps[i]['note'],
          date: maps[i]['date'],
        );
      });
    });
  }

  Future<void> addTransaction(Transaction t) async {
    await database.insert('transactions', t.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    loadTransactions();
  }

  void showAddTransactionDialog() {
    final _amountController = TextEditingController();
    final _noteController = TextEditingController();
    String type = 'income';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) => DropdownButton<String>(
                value: type,
                onChanged: (value) => setState(() => type = value!),
                items: [
                  DropdownMenuItem(child: Text('Income'), value: 'income'),
                  DropdownMenuItem(child: Text('Expense'), value: 'expense'),
                ],
              ),
            ),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Amount')),
            TextField(controller: _noteController, decoration: InputDecoration(labelText: 'Note')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final amount = double.tryParse(_amountController.text) ?? 0.0;
              final note = _noteController.text;
              final date = DateTime.now().toIso8601String();
              if (amount > 0) {
                addTransaction(Transaction(type: type, amount: amount, note: note, date: date));
              }
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Money Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Balance: Rs. ${balance.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Income: Rs. ${totalIncome.toStringAsFixed(2)}', style: TextStyle(color: Colors.green)),
                Text('Expense: Rs. ${totalExpense.toStringAsFixed(2)}', style: TextStyle(color: Colors.red)),
              ],
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  return ListTile(
                    title: Text('${t.type.toUpperCase()}: Rs. ${t.amount.toStringAsFixed(2)}'),
                    subtitle: Text('${t.note} - ${t.date.substring(0, 10)}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddTransactionDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
