import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('users').get();
      setState(() {
        _users = snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Қате: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.userManagement),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(child: Text('Пайдаланушылар жоқ'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isAdmin = user['role'] == 'admin';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAdmin 
                              ? AppColors.primaryLight 
                              : theme.colorScheme.secondary,
                          child: Text(
                            (user['username'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(user['username'] ?? 'Белгісіз'),
                            if (isAdmin) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Админ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _handleUserAction(value, user),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: isAdmin ? 'removeAdmin' : 'makeAdmin',
                              child: Row(
                                children: [
                                  Icon(
                                    isAdmin ? Icons.person_remove : Icons.admin_panel_settings,
                                    color: isAdmin ? Colors.orange : AppColors.primaryLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isAdmin ? 'Админ құқығын алу' : 'Админ жасау'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                  const SizedBox(width: 8),
                                  Text('Өшіру', style: TextStyle(color: theme.colorScheme.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _handleUserAction(String action, Map<String, dynamic> user) async {
    final userId = user['id'] as String;
    
    switch (action) {
      case 'makeAdmin':
        await _firestore.collection('users').doc(userId).update({'role': 'admin'});
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пайдаланушы админ болды'), backgroundColor: Colors.green),
          );
        }
        break;
      case 'removeAdmin':
        await _firestore.collection('users').doc(userId).update({'role': 'user'});
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Админ құқығы алынды'), backgroundColor: Colors.orange),
          );
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Пайдаланушыны өшіру'),
            content: Text('${user['username']} пайдаланушысын өшіргіңіз келе ме?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Жоқ'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Иә, өшіру'),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await _firestore.collection('users').doc(userId).delete();
          _loadUsers();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Пайдаланушы өшірілді'), backgroundColor: Colors.red),
            );
          }
        }
        break;
    }
  }
}
