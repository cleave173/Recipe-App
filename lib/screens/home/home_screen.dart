import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/recipe.dart';
import '../../models/category.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/recipe/recipe_card.dart';
import '../../widgets/common/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipeProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<RecipeProvider>().loadRecipes();
          },
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '👋 Сәлем!',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.appName,
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => context.push('/shopping-list'),
                          icon: Badge(
                            label: const Text('3'),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category chips
              SliverToBoxAdapter(
                child: Consumer<RecipeProvider>(
                  builder: (context, provider, _) {
                    final categories = provider.categories;
                    return Container(
                      height: 50,
                      margin: const EdgeInsets.only(top: 20),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildCategoryChip(
                              context,
                              null,
                              AppStrings.allRecipes,
                              Icons.restaurant_menu_rounded,
                            );
                          }
                          final category = categories[index - 1];
                          return _buildCategoryChip(
                            context,
                            category.id,
                            category.nameKk,
                            _getCategoryIcon(category.name),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // Quick Recipes Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.flash_on_rounded,
                              color: AppColors.accentLight,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            AppStrings.quickRecipes,
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                      Text(
                        '30 мин-дан аз',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),

              // Quick Recipes Horizontal List
              SliverToBoxAdapter(
                child: Consumer<RecipeProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.recipes.isEmpty) {
                      return const ShimmerHorizontalList();
                    }
                    
                    final quickRecipes = provider.quickRecipes.take(5).toList();
                    
                    if (quickRecipes.isEmpty) {
                      return const SizedBox(height: 10);
                    }
                    
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: quickRecipes.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: RecipeCardSmall(
                              recipe: quickRecipes[index],
                              onTap: () => context.push('/recipe/${quickRecipes[index].id}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // All Recipes Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryId == null
                            ? AppStrings.allRecipes
                            : AppStrings.recipes,
                        style: theme.textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: () => context.go('/search'),
                        child: const Text('Барлығын көру'),
                      ),
                    ],
                  ),
                ),
              ),

              // Recipe Grid
              Consumer<RecipeProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.recipes.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: ShimmerGrid(),
                    );
                  }

                  final recipes = _selectedCategoryId == null
                      ? provider.recipes
                      : provider.getRecipesByCategory(_selectedCategoryId!);

                  if (recipes.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyState(context),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final recipe = recipes[index];
                          return RecipeCard(
                            recipe: recipe,
                            isFavorite: provider.isFavorite(recipe.id),
                            onTap: () => context.push('/recipe/${recipe.id}'),
                            onFavoriteTap: () => provider.toggleFavorite(recipe.id),
                          );
                        },
                        childCount: recipes.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-recipe'),
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addRecipe),
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    int? categoryId,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategoryId == categoryId;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: FilterChip(
          selected: isSelected,
          onSelected: (_) {
            setState(() => _selectedCategoryId = categoryId);
          },
          avatar: Icon(
            icon,
            size: 18,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
          label: Text(label),
          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
          checkmarkColor: theme.colorScheme.primary,
          side: isSelected
              ? BorderSide(color: theme.colorScheme.primary)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
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
                Icons.restaurant_rounded,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.noRecipesYet,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.startAddingRecipes,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'breakfast':
        return Icons.breakfast_dining_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'dessert':
        return Icons.cake_rounded;
      case 'snack':
        return Icons.fastfood_rounded;
      case 'soup':
        return Icons.soup_kitchen_rounded;
      case 'salad':
        return Icons.eco_rounded;
      case 'drink':
        return Icons.local_cafe_rounded;
      case 'bakery':
        return Icons.bakery_dining_rounded;
      case 'national':
        return Icons.restaurant_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}
