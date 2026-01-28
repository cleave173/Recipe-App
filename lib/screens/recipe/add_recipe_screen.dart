import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../models/models.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/imgbb_service.dart';

class AddRecipeScreen extends StatefulWidget {
  final int? recipeId;

  const AddRecipeScreen({super.key, this.recipeId});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cookingTimeController = TextEditingController();
  final _servingsController = TextEditingController(text: '4');
  
  final ImagePicker _imagePicker = ImagePicker();
  final ImgBBService _imgBBService = ImgBBService();
  
  String _difficulty = 'medium';
  int _categoryId = 1;
  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  bool _isUploadingImage = false;
  final List<RecipeIngredient> _ingredients = [];
  final List<RecipeStep> _steps = [];
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.recipeId != null) {
      _isEditing = true;
      _loadRecipe();
    }
  }

  Future<void> _loadRecipe() async {
    final recipe = await context.read<RecipeProvider>().loadRecipe(widget.recipeId!);
    if (recipe != null && mounted) {
      setState(() {
        _titleController.text = recipe.title;
        _descriptionController.text = recipe.description ?? '';
        _cookingTimeController.text = recipe.cookingTime.toString();
        _servingsController.text = recipe.servings.toString();
        _difficulty = recipe.difficulty;
        _categoryId = recipe.categoryId;
        _imageUrl = recipe.imageUrl;
        _ingredients.addAll(recipe.ingredients);
        _steps.addAll(recipe.steps);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Widget _buildImageContent(ThemeData theme) {
    // Show uploading indicator
    if (_isUploadingImage && _selectedImageBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _selectedImageBytes!,
            fit: BoxFit.cover,
          ),
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Жүктелуде...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Show uploaded image
    if (_imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Icon(Icons.error_outline, size: 50, color: Colors.red),
              );
            },
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _pickImage,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show placeholder
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 50,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.addPhoto,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? AppStrings.editRecipe : AppStrings.addRecipe),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveRecipe,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppStrings.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              GestureDetector(
                onTap: _isUploadingImage ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildImageContent(theme),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppStrings.recipeName,
                  prefixIcon: const Icon(Icons.restaurant_menu_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppStrings.fieldRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: AppStrings.recipeDescription,
                  prefixIcon: const Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Cooking time and servings row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cookingTimeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.cookingTime,
                        prefixIcon: const Icon(Icons.timer_outlined),
                        suffixText: AppStrings.minutes,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppStrings.fieldRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _servingsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.servings,
                        prefixIcon: const Icon(Icons.people_outline),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Difficulty
              Text(
                AppStrings.difficulty,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDifficultyChip('easy', AppStrings.easy, AppColors.easy),
                  const SizedBox(width: 8),
                  _buildDifficultyChip('medium', AppStrings.medium, AppColors.medium),
                  const SizedBox(width: 8),
                  _buildDifficultyChip('hard', AppStrings.hard, AppColors.hard),
                ],
              ),
              const SizedBox(height: 24),

              // Category
              Text(
                AppStrings.category,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Consumer<RecipeProvider>(
                builder: (context, provider, _) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.categories.map((category) {
                      final isSelected = _categoryId == category.id;
                      return ChoiceChip(
                        label: Text(category.nameKk),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _categoryId = category.id);
                        },
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Ingredients section
              _buildSectionHeader(
                theme,
                AppStrings.ingredients,
                Icons.shopping_basket_outlined,
                () => _showAddIngredientDialog(),
              ),
              if (_ingredients.isEmpty)
                _buildEmptyHint(AppStrings.addIngredient)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ingredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = _ingredients[index];
                    return ListTile(
                      title: Text(ingredient.name),
                      subtitle: Text(ingredient.formattedQuantity),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          setState(() => _ingredients.removeAt(index));
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // Steps section
              _buildSectionHeader(
                theme,
                AppStrings.steps,
                Icons.format_list_numbered,
                () => _showAddStepDialog(),
              ),
              if (_steps.isEmpty)
                _buildEmptyHint(AppStrings.addStep)
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final step = _steps.removeAt(oldIndex);
                      _steps.insert(newIndex, step);
                      _renumberSteps();
                    });
                  },
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return ListTile(
                      key: ValueKey(step.stepNumber),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        step.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _showAddStepDialog(editIndex: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              setState(() {
                                _steps.removeAt(index);
                                _renumberSteps();
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String value, String label, Color color) {
    final isSelected = _difficulty == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _difficulty = value);
      },
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    IconData icon,
    VoidCallback onAdd,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: theme.textTheme.titleMedium),
          ],
        ),
        IconButton(
          onPressed: onAdd,
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyHint(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  void _showAddIngredientDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    String unit = MeasurementUnit.gram;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppStrings.addIngredient),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Атауы',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: AppStrings.quantity,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: unit,
                      decoration: InputDecoration(
                        labelText: AppStrings.unit,
                      ),
                      items: MeasurementUnit.all.map((u) {
                        return DropdownMenuItem(value: u, child: Text(u));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() => unit = value!);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _ingredients.add(RecipeIngredient(
                      ingredientId: _ingredients.length + 1,
                      name: nameController.text,
                      quantity: double.tryParse(quantityController.text) ?? 0,
                      unit: unit,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddStepDialog({int? editIndex}) {
    final descController = TextEditingController(
      text: editIndex != null ? _steps[editIndex].description : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editIndex != null ? 'Қадамды өңдеу' : AppStrings.addStep),
        content: TextField(
          controller: descController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Сипаттамасы',
            alignLabelWithHint: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (descController.text.isNotEmpty) {
                setState(() {
                  if (editIndex != null) {
                    _steps[editIndex] = _steps[editIndex].copyWith(
                      description: descController.text,
                    );
                  } else {
                    _steps.add(RecipeStep(
                      stepNumber: _steps.length + 1,
                      description: descController.text,
                    ));
                  }
                });
                Navigator.pop(context);
              }
            },
            child: Text(AppStrings.save),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Камерадан'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Галереядан'),
              onTap: () {
                Navigator.pop(context);
                _selectImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _isUploadingImage = true;
        });
        
        // Upload to imgBB
        final imageUrl = await _imgBBService.uploadImageBytes(bytes);
        
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
            if (imageUrl != null) {
              _imageUrl = imageUrl;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Сурет сәтті жүктелді!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Суретті жүктеу кезінде қате'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Қате: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _renumberSteps() {
    for (int i = 0; i < _steps.length; i++) {
      _steps[i] = _steps[i].copyWith(stepNumber: i + 1);
    }
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Кемінде бір ингредиент қосыңыз')),
      );
      return;
    }
    if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Кемінде бір қадам қосыңыз')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final provider = context.read<RecipeProvider>();
    
    // Проверяем, инициализирован ли userId
    if (!_isEditing) {
      // Для нового рецепта нужен userId
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Рецепт қосу үшін жүйеге кіріңіз'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    final recipe = Recipe(
      id: widget.recipeId ?? 0,
      userId: 1, // Будет переопределено в service
      title: _titleController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      cookingTime: int.parse(_cookingTimeController.text),
      difficulty: _difficulty,
      categoryId: _categoryId,
      imageUrl: _imageUrl,
      createdAt: DateTime.now(),
      ingredients: _ingredients,
      steps: _steps,
      servings: int.tryParse(_servingsController.text) ?? 4,
    );

    Recipe? result;
    if (_isEditing) {
      result = await provider.updateRecipe(recipe);
    } else {
      result = await provider.createRecipe(recipe);
    }

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? AppStrings.recipeUpdated : AppStrings.recipeAdded),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else if (mounted) {
      // Показываем ошибку
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Рецептті сақтау кезінде қате орын алды'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
