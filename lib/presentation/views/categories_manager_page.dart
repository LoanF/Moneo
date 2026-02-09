import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../../core/database/app_database.dart';
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
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 100, top: 16),
        itemCount: mainCategories.length,
        itemBuilder: (context, index) {
          final parent = mainCategories[index];
          final subCats = categories.where((c) => c.parentId == parent.id).toList();
          return _buildCategoryGroup(context, parent, subCats, vm);
        },
      ),
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
                title: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainText)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => _showCategorySheet(context, null, parent: parent)),
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showCategorySheet(context, parent)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _confirmDelete(context, parent, children, vm)),
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

  Widget _buildIconCircle(int code, int color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Color(color).withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Icon(IconData(code, fontFamily: 'MaterialIcons'), color: Color(color), size: 22),
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
        onSave: (name, icon, color) {
          context.read<HomeViewModel>().saveCategory(
            id: category?.id,
            name: name,
            iconCode: icon,
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