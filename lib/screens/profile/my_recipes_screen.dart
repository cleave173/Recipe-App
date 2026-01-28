import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/recipe/recipe_card.dart';
import '../../widgets/common/shimmer_loading.dart';

class MyRecipesScreen extends StatefulWidget {
  const MyRecipesScreen({super.key});

  @override
  State<MyRecipesScreen> createState() => _MyRecipesScreenState();
}

class _MyRecipesScreenState extends State<MyRecipesScreen> {
  List<Recipe> _myRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyRecipes();
  }

  Future<void> _loadMyRecipes() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<RecipeProvider>();
    final currentUserId = provider.currentUserId;
    
    // Фильтруем локально по authorId
    final allRecipes = provider.recipes;
    final myRecipes = allRecipes.where((r) => r.authorId == currentUserId).toList();
    
    if (mounted) {
      setState(() {
        _myRecipes = myRecipes;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Менің рецепттерім'),
        actions: [
          IconButton(
            onPressed: () => context.push('/add-recipe'),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyRecipes,
        child: _isLoading
            ? const ShimmerGrid()
            : _myRecipes.isEmpty
                ? _buildEmptyState(theme)
                : _buildRecipeGrid(theme),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 60,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Сіз әлі рецепт қосқан жоқсыз',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Өзіңіздің алғашқы рецептіңізді қосыңыз!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.push('/add-recipe'),
                icon: const Icon(Icons.add_rounded),
                label: const Text(AppStrings.addRecipe),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(ThemeData theme) {
    return Consumer<RecipeProvider>(
      builder: (context, provider, _) {
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: _myRecipes.length,
          itemBuilder: (context, index) {
            final recipe = _myRecipes[index];
            return RecipeCard(
              recipe: recipe,
              isFavorite: provider.isFavorite(recipe.id),
              onTap: () => context.push('/recipe/${recipe.id}'),
              onFavoriteTap: () => provider.toggleFavorite(recipe.id),
            );
          },
        );
      },
    );
  }
}
