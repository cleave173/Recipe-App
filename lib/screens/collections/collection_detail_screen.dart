import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/models.dart';
import '../../providers/collection_provider.dart';
import '../../providers/recipe_provider.dart';

class CollectionDetailScreen extends StatelessWidget {
  final int collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CollectionProvider, RecipeProvider>(
      builder: (context, colProvider, recipeProvider, _) {
        final collection = colProvider.collections.firstWhere(
          (c) => c.id == collectionId,
          orElse: () => Collection(
            id: 0,
            userId: 0,
            name: '',
            createdAt: DateTime.now(),
          ),
        );

        if (collection.id == 0) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Коллекция табылмады')),
          );
        }

        final collectionRecipes = recipeProvider.recipes
            .where((r) => collection.recipeIds.contains(r.id))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(collection.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddRecipeDialog(
                  context,
                  collection,
                  recipeProvider.recipes,
                ),
              ),
            ],
          ),
          body: collectionRecipes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu_outlined, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Коллекция бос'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddRecipeDialog(
                          context,
                          collection,
                          recipeProvider.recipes,
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Рецепт қосу'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: collectionRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = collectionRecipes[index];
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
                          '${recipe.cookingTime} мин • ${recipe.difficulty}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeRecipe(context, collection.id, recipe.id),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _showAddRecipeDialog(
    BuildContext context,
    Collection collection,
    List<Recipe> allRecipes,
  ) {
    final availableRecipes = allRecipes
        .where((r) => !collection.recipeIds.contains(r.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Рецепт қосу'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: availableRecipes.isEmpty
              ? const Center(child: Text('Қолжетімді рецепттер жоқ'))
              : ListView.builder(
                  itemCount: availableRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = availableRecipes[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: recipe.imageUrl != null
                            ? CachedNetworkImageProvider(recipe.imageUrl!)
                            : null,
                        child: recipe.imageUrl == null
                            ? const Icon(Icons.restaurant, size: 16)
                            : null,
                      ),
                      title: Text(recipe.title),
                      trailing: IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                        onPressed: () async {
                          Navigator.pop(context);
                          await context
                              .read<CollectionProvider>()
                              .addRecipeToCollection(collection.id, recipe.id);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Жабу'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeRecipe(BuildContext context, int collectionId, int recipeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Рецептті өшіру'),
        content: const Text('Бұл рецептті коллекциядан өшіргіңіз келе ме?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Жоқ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Иә', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      context.read<CollectionProvider>().removeRecipeFromCollection(collectionId, recipeId);
    }
  }
}
