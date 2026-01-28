import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../widgets/recipe/recipe_card.dart';
import '../../widgets/common/shimmer_loading.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  RecipeFilters _filters = RecipeFilters();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.search),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onSubmitted: _onSearch,
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<RecipeProvider>().clearSearch();
                          setState(() {});
                        },
                      ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: _hasActiveFilters,
                        child: const Icon(Icons.tune_rounded),
                      ),
                      onPressed: () {
                        setState(() => _showFilters = !_showFilters);
                      },
                    ),
                  ],
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters panel
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            child: _showFilters ? _buildFiltersPanel(theme) : null,
          ),
          
          // Quick filters
          if (!_showFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildQuickFilter(
                    AppStrings.quickRecipes,
                    Icons.flash_on_rounded,
                    _filters.maxCookingTime == 30,
                    () => _toggleQuickFilter('quick'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickFilter(
                    AppStrings.vegetarian,
                    Icons.eco_rounded,
                    _filters.isVegetarian == true,
                    () => _toggleQuickFilter('vegetarian'),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickFilter(
                    AppStrings.dietaryRecipes,
                    Icons.monitor_weight_outlined,
                    _filters.isDietary == true,
                    () => _toggleQuickFilter('dietary'),
                  ),
                ],
              ),
            ),

          // Results
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const ShimmerGrid();
                }

                final results = provider.searchResults;
                
                if (_searchController.text.isEmpty && results.isEmpty) {
                  return _buildEmptySearch(theme);
                }

                if (results.isEmpty) {
                  return _buildNoResults(theme);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final recipe = results[index];
                    return RecipeCard(
                      recipe: recipe,
                      isFavorite: provider.isFavorite(recipe.id),
                      onTap: () => context.push('/recipe/${recipe.id}'),
                      onFavoriteTap: () => provider.toggleFavorite(recipe.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _filters.categoryId != null ||
      _filters.difficulty != null ||
      _filters.maxCookingTime != null ||
      _filters.isVegetarian == true ||
      _filters.isDietary == true;

  Widget _buildFiltersPanel(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Difficulty filter
          Text(AppStrings.difficulty, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(AppStrings.easy, 'easy', _filters.difficulty),
              _buildFilterChip(AppStrings.medium, 'medium', _filters.difficulty),
              _buildFilterChip(AppStrings.hard, 'hard', _filters.difficulty),
            ],
          ),
          const SizedBox(height: 16),
          
          // Sort options
          Text(AppStrings.sortBy, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildSortChip(AppStrings.sortByTime, 'cooking_time'),
              _buildSortChip(AppStrings.sortByRating, 'rating'),
              _buildSortChip(AppStrings.sortByDate, 'created_at'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _filters = RecipeFilters();
                    });
                  },
                  child: Text(AppStrings.clearFilters),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _showFilters = false);
                    _onSearch(_searchController.text);
                  },
                  child: Text(AppStrings.applyFilters),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String? currentValue) {
    final isSelected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filters = RecipeFilters(
            categoryId: _filters.categoryId,
            difficulty: isSelected ? null : value,
            maxCookingTime: _filters.maxCookingTime,
            isVegetarian: _filters.isVegetarian,
            isDietary: _filters.isDietary,
            sortBy: _filters.sortBy,
          );
        });
      },
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _filters.sortBy == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filters = RecipeFilters(
            categoryId: _filters.categoryId,
            difficulty: _filters.difficulty,
            maxCookingTime: _filters.maxCookingTime,
            isVegetarian: _filters.isVegetarian,
            isDietary: _filters.isDietary,
            sortBy: isSelected ? null : value,
          );
        });
      },
    );
  }

  Widget _buildQuickFilter(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return FilterChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
    );
  }

  void _toggleQuickFilter(String type) {
    setState(() {
      switch (type) {
        case 'quick':
          _filters = RecipeFilters(
            categoryId: _filters.categoryId,
            difficulty: _filters.difficulty,
            maxCookingTime: _filters.maxCookingTime == 30 ? null : 30,
            isVegetarian: _filters.isVegetarian,
            isDietary: _filters.isDietary,
            sortBy: _filters.sortBy,
          );
          break;
        case 'vegetarian':
          _filters = RecipeFilters(
            categoryId: _filters.categoryId,
            difficulty: _filters.difficulty,
            maxCookingTime: _filters.maxCookingTime,
            isVegetarian: _filters.isVegetarian == true ? null : true,
            isDietary: _filters.isDietary,
            sortBy: _filters.sortBy,
          );
          break;
        case 'dietary':
          _filters = RecipeFilters(
            categoryId: _filters.categoryId,
            difficulty: _filters.difficulty,
            maxCookingTime: _filters.maxCookingTime,
            isVegetarian: _filters.isVegetarian,
            isDietary: _filters.isDietary == true ? null : true,
            sortBy: _filters.sortBy,
          );
          break;
      }
    });
    if (_searchController.text.isNotEmpty) {
      _onSearch(_searchController.text);
    }
  }

  Widget _buildEmptySearch(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Рецепт іздеңіз',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Атауы немесе ингредиенті бойынша',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.noResults,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.tryDifferentSearch,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  void _onSearch(String query) {
    context.read<RecipeProvider>().searchRecipes(query, filters: _filters);
  }
}
