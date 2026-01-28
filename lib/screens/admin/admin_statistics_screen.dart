import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/recipe_provider.dart';
import 'package:provider/provider.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _userCount = 0;
  int _recipeCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final recipesSnapshot = await _firestore.collection('recipes').get();
      
      if (mounted) {
        setState(() {
          _userCount = usersSnapshot.docs.length;
          _recipeCount = recipesSnapshot.docs.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.statistics),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStatCard(
                    context,
                    icon: Icons.people_rounded,
                    title: 'Пайдаланушылар',
                    value: '$_userCount',
                    color: AppColors.primaryLight,
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Рецепттер',
                    value: '$_recipeCount',
                    color: AppColors.accentLight,
                  ),
                  const SizedBox(height: 16),
                  Consumer<RecipeProvider>(
                    builder: (context, provider, _) {
                      final topRecipes = List.of(provider.recipes)
                        ..sort((a, b) => b.rating.compareTo(a.rating));
                      final top5 = topRecipes.take(5).toList();
                      
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Үздік рецепттер',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (top5.isEmpty)
                                const Text('Рецепттер жоқ')
                              else
                                ...top5.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final recipe = entry.value;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(recipe.title),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 18),
                                        Text(' ${recipe.rating.toStringAsFixed(1)}'),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
