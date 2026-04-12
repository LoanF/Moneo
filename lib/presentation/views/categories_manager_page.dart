import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';
import '../../core/helpers/icon_helper.dart';
import '../../core/themes/app_colors.dart';
import '../../data/models/models.dart';
import '../view_models/home_view_model.dart';
import '../widgets/category_form_sheet.dart';

class CategoriesManagerPage extends StatelessWidget {
  const CategoriesManagerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    final categories = vm.categories;
    final mainCategories = categories.where((c) => c.parentId == null).toList();

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Catégories", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.mainBackground,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mainColor,
        onPressed: () => _showCategorySheet(context, null),
        label: const Text("Nouvelle", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: mainCategories.isEmpty
          ? const Center(child: Text("Aucune catégorie", style: TextStyle(color: AppColors.secondaryText)))
          : SafeArea(child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: mainCategories.length,
        itemBuilder: (context, index) {
          final parent = mainCategories[index];
          final subCats = categories.where((c) => c.parentId == parent.id).toList();
          return _buildCategoryGroup(context, parent, subCats, vm);
        },
      )),
    );
  }

  Widget _buildCategoryGroup(BuildContext context, Category parent, List<Category> children, HomeViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8, top: 16),
          child: Text(parent.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mainColor)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.secondaryBackground, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              ListTile(
                leading: _buildIconCircle(parent.iconCode, parent.colorValue),
                title: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainText), overflow: TextOverflow.ellipsis),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.grey1),
                  color: AppColors.secondaryBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) {
                    if (value == 'add') _showCategorySheet(context, null, parent: parent);
                    if (value == 'edit') _showCategorySheet(context, parent);
                    if (value == 'delete') _confirmDelete(context, parent, children, vm);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'add', child: Text("Ajouter sous-cat.", style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'edit', child: Text("Modifier", style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text("Supprimer", style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ),
              if (children.isNotEmpty) const Divider(height: 1, indent: 70, color: AppColors.thirdBackground),
              ...children.map((sub) => ListTile(
                contentPadding: const EdgeInsets.only(left: 70, right: 16),
                title: Text(sub.name, style: const TextStyle(color: AppColors.mainText, fontSize: 14)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => vm.deleteCategory(sub),
                ),
                onTap: () => _showCategorySheet(context, sub, parent: parent),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconCircle(String iconName, int color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Color(color).withValues(alpha: 0.15),
          shape: BoxShape.circle
      ),
      child: Icon(
        IconHelper.getIcon(iconName),
        color: Color(color),
        size: 22,
      ),
    );
  }

  void _showCategorySheet(BuildContext context, Category? category, {Category? parent}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormSheet(
        category: category,
        parentId: parent?.id,
        onSave: (name, iconName, color) {
          context.read<HomeViewModel>().saveCategory(
            id: category?.id,
            name: name,
            iconCode: iconName,
            colorValue: color,
            parentId: parent?.id ?? category?.parentId,
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category, List<Category> subCategories, HomeViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Text("Supprimer ?"),
        content: Text(subCategories.isNotEmpty ? "Cela supprimera aussi les ${subCategories.length} sous-catégories." : "Confirmer la suppression ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          FilledButton(onPressed: () { vm.deleteCategory(category); Navigator.pop(context); }, child: const Text("Supprimer")),
        ],
      ),
    );
  }
}