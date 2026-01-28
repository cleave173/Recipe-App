import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/collection_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShoppingListProvider>().loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.shoppingList),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_purchased',
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline),
                    const SizedBox(width: 8),
                    const Text('Сатып алынғандарды өшіру'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text(AppStrings.clearList),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear_purchased') {
                context.read<ShoppingListProvider>().clearPurchased();
              } else if (value == 'clear_all') {
                _showClearConfirmation();
              }
            },
          ),
        ],
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      size: 60,
                      color: AppColors.accentLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.shoppingListEmpty,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Рецептерден ингредиенттерді қосыңыз',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          final unpurchased = provider.unpurchasedItems;
          final purchased = provider.purchasedItems;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Progress indicator
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Прогресс',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${provider.purchasedCount}/${provider.totalItems}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: provider.totalItems > 0
                          ? provider.purchasedCount / provider.totalItems
                          : 0,
                      backgroundColor: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Unpurchased items
              if (unpurchased.isNotEmpty) ...[
                Text(
                  AppStrings.notPurchased,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...unpurchased.map((item) => _buildShoppingItem(
                  item.id,
                  item.ingredientName,
                  item.quantity,
                  item.isPurchased,
                  item.recipeName,
                )),
                const SizedBox(height: 20),
              ],

              // Purchased items
              if (purchased.isNotEmpty) ...[
                Text(
                  AppStrings.purchased,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                ...purchased.map((item) => _buildShoppingItem(
                  item.id,
                  item.ingredientName,
                  item.quantity,
                  item.isPurchased,
                  item.recipeName,
                )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildShoppingItem(
    int id,
    String name,
    String quantity,
    bool isPurchased,
    String? recipeName,
  ) {
    final theme = Theme.of(context);
    
    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<ShoppingListProvider>().deleteItem(id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Checkbox(
            value: isPurchased,
            onChanged: (_) {
              context.read<ShoppingListProvider>().togglePurchased(id);
            },
            shape: const CircleBorder(),
          ),
          title: Text(
            name,
            style: TextStyle(
              decoration: isPurchased ? TextDecoration.lineThrough : null,
              color: isPurchased ? theme.textTheme.bodySmall?.color : null,
            ),
          ),
          subtitle: Row(
            children: [
              Text(quantity),
              if (recipeName != null) ...[
                const SizedBox(width: 8),
                Text(
                  '• $recipeName',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Қосу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Атауы',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Саны',
                hintText: 'Мысалы: 500 грамм',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await this.context.read<ShoppingListProvider>().addItem(
                  ingredientName: nameController.text,
                  quantity: quantityController.text.isEmpty 
                      ? '1 дана' 
                      : quantityController.text,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Тізімді тазалау'),
        content: Text(AppStrings.clearShoppingListConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              this.context.read<ShoppingListProvider>().clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppStrings.clearList),
          ),
        ],
      ),
    );
  }
}
