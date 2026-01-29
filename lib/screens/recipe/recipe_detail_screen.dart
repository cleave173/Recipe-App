import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/collection_provider.dart';
import '../../widgets/common/shimmer_loading.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Recipe? _recipe;
  int? _userRating;
  String? _userNote;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecipe();
  }

  Future<void> _loadRecipe() async {
    final provider = context.read<RecipeProvider>();
    final recipe = await provider.loadRecipe(widget.recipeId);
    if (mounted && recipe != null) {
      setState(() => _recipe = recipe);
      // Load user's rating
      final userRating = await provider.getUserRating(recipe.firestoreId);
      if (mounted) {
        setState(() => _userRating = userRating);
      }
      // Load user's note
      final userNote = await provider.getUserNote(recipe.firestoreId!);
      if (mounted) {
        setState(() => _userNote = userNote);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && _recipe == null) {
            return const ShimmerRecipeDetail();
          }

          final recipe = _recipe ?? provider.selectedRecipe;
          if (recipe == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60),
                  const SizedBox(height: 16),
                  Text(AppStrings.errorOccurred),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text(AppStrings.close),
                  ),
                ],
              ),
            );
          }

          final isFavorite = provider.isFavorite(recipe.id);

          return CustomScrollView(
            slivers: [
              // Hero Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    onPressed: () => context.pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                        color: isFavorite ? Colors.red : null,
                      ),
                      onPressed: () => provider.toggleFavorite(recipe.id),
                    ),
                  ),
                  if (recipe.authorId == provider.currentUserId)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (value) => _handleMenuAction(value, recipe),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined),
                                const SizedBox(width: 12),
                                Text(AppStrings.edit),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                const SizedBox(width: 12),
                                Text(
                                  AppStrings.delete,
                                  style: TextStyle(color: theme.colorScheme.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      recipe.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: recipe.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.restaurant_rounded,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recipe Info
              SliverToBoxAdapter(
                child: Container(
                  transform: Matrix4.translationValues(0, -30, 0),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          recipe.title,
                          style: theme.textTheme.displaySmall,
                        ),
                        const SizedBox(height: 12),
                        
                        // Author
                        if (recipe.authorName != null) ...[
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  recipe.authorName![0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                recipe.authorId == provider.currentUserId
                                    ? '${recipe.authorName!} (Сіздікі)'
                                    : recipe.authorName!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: recipe.authorId == provider.currentUserId
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Info badges
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildInfoBadge(
                              context,
                              Icons.timer_outlined,
                              recipe.formattedCookingTime,
                              AppColors.accentLight,
                            ),
                            _buildInfoBadge(
                              context,
                              Icons.signal_cellular_alt_rounded,
                              recipe.difficultyLevel.nameKk,
                              _getDifficultyColor(recipe.difficulty),
                            ),
                            _buildInfoBadge(
                              context,
                              Icons.restaurant_rounded,
                              '${recipe.servings} порция',
                              AppColors.secondaryLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Rating
                        Row(
                          children: [
                            RatingBar.builder(
                              initialRating: _userRating?.toDouble() ?? 0,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: false,
                              itemCount: 5,
                              itemSize: 28,
                              itemPadding: const EdgeInsets.symmetric(horizontal: 2),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                              ),
                              unratedColor: Colors.grey[300],
                              onRatingUpdate: (rating) {
                                setState(() => _userRating = rating.toInt());
                                provider.rateRecipe(recipe.id, rating.toInt());
                              },
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${recipe.rating.toStringAsFixed(1)} (${recipe.ratingCount})',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Description
                        if (recipe.description != null) ...[
                          Text(
                            recipe.description!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Tabs
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: AppStrings.ingredients),
                      Tab(text: AppStrings.steps),
                      Tab(text: AppStrings.notes),
                    ],
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.textTheme.bodySmall?.color,
                    indicatorColor: theme.colorScheme.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                  theme.scaffoldBackgroundColor,
                ),
              ),

              // Tab content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildIngredientsTab(recipe),
                    _buildStepsTab(recipe),
                    _buildNotesTab(recipe),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoBadge(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab(Recipe recipe) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: recipe.ingredients.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final ingredient = recipe.ingredients[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          title: Text(ingredient.name),
          subtitle: Text(ingredient.formattedQuantity),
        );
      },
    );
  }

  Widget _buildStepsTab(Recipe recipe) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: recipe.steps.length,
      itemBuilder: (context, index) {
        final step = recipe.steps[index];
        final theme = Theme.of(context);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${step.stepNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    if (step.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: step.imageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotesTab(Recipe recipe) {
    if (_userNote != null && _userNote!.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                _userNote!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showNoteDialog(recipe),
              icon: const Icon(Icons.edit),
              label: const Text('Жазбаны өзгерту'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_add_outlined,
            size: 60,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Жеке жазбаларыңызды қосыңыз',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showNoteDialog(recipe),
            icon: const Icon(Icons.add),
            label: Text(AppStrings.addNote),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(Recipe recipe) {
    final controller = TextEditingController(text: _userNote);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Жазба'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Осы рецепт туралы жазба жазыңыз...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Болдырмау'),
          ),
          ElevatedButton(
            onPressed: () async {
              final note = controller.text;
              if (recipe.firestoreId != null) {
                await context.read<RecipeProvider>().saveUserNote(recipe.firestoreId!, note);
                setState(() => _userNote = note);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Сақтау'),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return AppColors.easy;
      case 'medium':
        return AppColors.medium;
      case 'hard':
        return AppColors.hard;
      default:
        return AppColors.medium;
    }
  }

  void _handleMenuAction(String action, Recipe recipe) async {
    switch (action) {
      case 'edit':
        final result = await context.push<bool>('/edit-recipe/${recipe.id}');
        if (result == true) {
          // Перезагружаем рецепт после редактирования
          _loadRecipe();
        }
        break;
      case 'delete':
        _showDeleteConfirmation(recipe);
        break;
    }
  }

  void _showAddToCollectionDialog() {
    // TODO: Implement add to collection dialog
  }

  void _showDeleteConfirmation(Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteConfirmTitle),
        content: Text(AppStrings.deleteRecipeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await this.context.read<RecipeProvider>().deleteRecipe(recipe.id);
              if (success && mounted) {
                this.context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppStrings.delete),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
