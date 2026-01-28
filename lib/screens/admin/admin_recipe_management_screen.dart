import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';

class AdminRecipeManagementScreen extends StatelessWidget {
  const AdminRecipeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рецепттерді басқару'),
      ),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final recipes = provider.recipes;
          
          if (recipes.isEmpty) {
            return const Center(child: Text('Рецепттер жоқ'));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => context.push('/recipe/${recipe.id}'),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: recipe.imageUrl != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(recipe.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[200],
                    ),
                    child: recipe.imageUrl == null
                        ? const Icon(Icons.restaurant, color: Colors.grey)
                        : null,
                  ),
                  title: Text(
                    recipe.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${recipe.authorName ?? "Белгісіз"} • ${recipe.cookingTime} мин',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push('/edit-recipe/${recipe.id}'),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                        onPressed: () => _confirmDelete(context, recipe),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Recipe recipe) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Рецептті өшіру'),
        content: Text('"${recipe.title}" рецептін өшіргіңіз келе ме?'),
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
    
    if (confirm == true && context.mounted) {
      await context.read<RecipeProvider>().deleteRecipe(recipe.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рецепт өшірілді'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
