import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/category.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final cats = provider.categories;
          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                title: Text('Categories'),
                pinned: true,
              ),
              if (cats.isEmpty)
                const SliverFillRemaining(
                  child: _EmptyCategoriesState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _CategoryCard(
                        category: cats[i],
                        provider: provider,
                      ),
                      childCount: cats.length,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategorySheet(context, null),
        tooltip: 'Add Category',
        child: const Icon(Icons.add),
      ),
    );
  }

  static void _showCategorySheet(
      BuildContext context, Category? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppProvider>(),
        child: _CategorySheet(existing: existing),
      ),
    );
  }
}

// ─── Category card ────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final Category category;
  final AppProvider provider;

  const _CategoryCard({required this.category, required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(category.emoji,
                style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
              onPressed: () =>
                  CategoriesScreen._showCategorySheet(context, category),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: Colors.red.shade400),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Delete "${category.name}"?\n\nExpenses in this category will remain but lose their category link.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteCategory(category.id!);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Add / Edit category bottom sheet ────────────────────────────────────────

class _CategorySheet extends StatefulWidget {
  final Category? existing;
  const _CategorySheet({this.existing});

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  final _nameController = TextEditingController();
  String _emoji = '💰';
  int _color = 0xFF6C63FF;

  bool get _isEditing => widget.existing != null;

  static const _emojis = [
    '🍔', '🍕', '🍜', '🍷', '☕', '🛒', '🚗', '🚕', '🛵', '✈️',
    '⛽', '👕', '👗', '👟', '💊', '🏥', '🎬', '🎮', '🎵', '💡',
    '🏠', '📱', '💻', '📚', '✏️', '🏋️', '🐶', '🌿', '🎁', '💰',
    '🛍️', '🧴', '🎓', '🏖️', '🍎', '🧹', '🔧', '🎨', '🏃', '🧘',
  ];

  static const _colors = [
    0xFFE74C3C, // Red
    0xFFE67E22, // Orange
    0xFFF39C12, // Amber
    0xFF2ECC71, // Green
    0xFF1ABC9C, // Teal
    0xFF3498DB, // Blue
    0xFF6C63FF, // Purple
    0xFF9B59B6, // Violet
    0xFFE91E63, // Pink
    0xFF607D8B, // Blue-grey
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.existing!.name;
      _emoji = widget.existing!.emoji;
      _color = widget.existing!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final category = Category(
      id: widget.existing?.id,
      name: name,
      emoji: _emoji,
      color: _color,
    );

    if (_isEditing) {
      await provider.updateCategory(category);
    } else {
      await provider.addCategory(category);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            _isEditing ? 'Edit Category' : 'New Category',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Preview + name field
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(_color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                    child: Text(_emoji,
                        style: const TextStyle(fontSize: 30))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Emoji picker
          const Text('Choose emoji',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF888888))),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _emojis.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final e = _emojis[i];
                final selected = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? Color(_color).withOpacity(0.25)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: selected
                          ? Border.all(color: Color(_color), width: 2)
                          : null,
                    ),
                    child: Center(
                        child: Text(e,
                            style: const TextStyle(fontSize: 22))),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Color picker
          const Text('Choose color',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF888888))),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _colors[i];
                final selected = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Colors.black87, width: 3)
                          : Border.all(
                              color: Colors.transparent, width: 3),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                  color: Color(c).withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1)
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
              child: Text(
                  _isEditing ? 'Update Category' : 'Add Category'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyCategoriesState extends StatelessWidget {
  const _EmptyCategoriesState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.category_outlined,
            size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('No categories yet',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('Tap + to create your first category',
            style: TextStyle(
                color: Colors.grey.shade400, fontSize: 13)),
      ],
    );
  }
}
