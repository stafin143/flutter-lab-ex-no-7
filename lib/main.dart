import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EmployeeApp());
}

class EmployeeApp extends StatelessWidget {
  const EmployeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Records',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const EmployeePage(),
    );
  }
}

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});

  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _deptController = TextEditingController();
  final _salaryController = TextEditingController();

  final CollectionReference<Map<String, dynamic>> _employees =
      FirebaseFirestore.instance.collection('employees');

  Future<void> _addEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _employees.add({
        'name': _nameController.text.trim(),
        'empId': _idController.text.trim(),
        'department': _deptController.text.trim(),
        'salary': double.parse(_salaryController.text.trim()),
      });
      _nameController.clear();
      _idController.clear();
      _deptController.clear();
      _salaryController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee saved to Firestore')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Records (Firestore)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Employee Name', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                      labelText: 'Employee ID', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deptController,
                  decoration: const InputDecoration(
                      labelText: 'Department', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Salary (₹)', border: OutlineInputBorder()),
                  validator: (v) => double.tryParse(v ?? '') == null
                      ? 'Enter a valid salary'
                      : null,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addEmployee,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Save to Firestore'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Stored Employees',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _employees.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No employees found'),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final d = doc.data();
                  return Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('${d['name']}'),
                      subtitle: Text('ID: ${d['empId']}  |  ${d['department']}'),
                      trailing: Text('₹${d['salary']}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

