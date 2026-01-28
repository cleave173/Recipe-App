import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/collection_provider.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectionProvider>().loadCollections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.collections),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: Consumer<CollectionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final collections = provider.collections;

          if (collections.isEmpty) {
            return Center(
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
                      Icons.collections_bookmark_outlined,
                      size: 60,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppStrings.noCollections,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Рецепттерді топқа жинаңыз',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(AppStrings.createCollection),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: collection.coverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              collection.coverImageUrl!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.collections_bookmark_rounded,
                            color: theme.colorScheme.primary,
                          ),
                  ),
                  title: Text(
                    collection.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${collection.recipeCount} рецепт',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Text(AppStrings.delete),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteConfirmation(collection.id);
                      }
                    },
                  ),
                  onTap: () {
                    context.push('/collections/${collection.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.createCollection),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: AppStrings.collectionName,
            hintText: 'Мысалы: Достармен кешкі ас',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await this.context.read<CollectionProvider>().createCollection(
                  controller.text,
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

  void _showDeleteConfirmation(int collectionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.deleteConfirmTitle),
        content: Text(AppStrings.deleteCollectionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await this.context.read<CollectionProvider>().deleteCollection(collectionId);
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
