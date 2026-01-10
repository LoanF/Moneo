import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/services/user_service.dart';
import '../../core/di.dart';
import '../../data/models/category_model.dart';
import '../../core/themes/app_colors.dart';
import '../widgets/category_form_sheet.dart';

class CategoriesManagerPage extends StatefulWidget {
  const CategoriesManagerPage({super.key});

  @override
  State<CategoriesManagerPage> createState() => _CategoriesManagerPageState();
}

class _CategoriesManagerPageState extends State<CategoriesManagerPage> {
  final _userService = getIt<IAppUserService>();

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthNotifier>().appUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Catégories", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.mainBackground,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.mainColor,
        onPressed: () => _showCategorySheet(context, uid),
        label: const Text("Nouvelle", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _userService.getCategoriesStream(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final categories = snapshot.data!;
          final mainCategories = categories.where((c) => c.parentId == null).toList();

          if (mainCategories.isEmpty) {
            return const Center(
              child: Text("Aucune catégorie", style: TextStyle(color: AppColors.secondaryText)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 16),
            itemCount: mainCategories.length,
            itemBuilder: (context, index) {
              final parent = mainCategories[index];
              final subCats = categories.where((c) => c.parentId == parent.id).toList();

              return _buildCategoryGroup(context, uid, parent, subCats);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryGroup(BuildContext context, String uid, CategoryModel parent, List<CategoryModel> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 8, top: 16),
          child: Text(parent.name.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.mainColor, letterSpacing: 1.2)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: _buildIconCircle(parent.iconCode, parent.colorValue),
                  title: Text(parent.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.mainText)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.grey2),
                        onPressed: () => _showCategorySheet(context, uid, parent: parent),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.grey2),
                        onPressed: () => _showCategorySheet(context, uid, category: parent),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.grey2),
                        onPressed: () => _showDeleteConfirmation(context, uid, parent, children),
                      ),
                    ],
                  ),
                ),

                if (children.isNotEmpty) const Divider(height: 1, indent: 70, color: AppColors.thirdBackground),
                ...children.map((sub) => ListTile(
                  contentPadding: const EdgeInsets.only(left: 70, right: 16),
                  title: Text(sub.name, style: const TextStyle(color: AppColors.mainText, fontSize: 14)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.grey1),
                    onPressed: () => _userService.deleteCategory(uid, sub.id),
                  ),
                  onTap: () => _showCategorySheet(context, uid, category: sub, parent: parent),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconCircle(int? code, int? color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(color ?? 0xFF000000).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        IconData(code ?? Icons.category.codePoint, fontFamily: 'MaterialIcons'),
        color: Color(color ?? 0xFF000000),
        size: 22,
      ),
    );
  }

  void _showCategorySheet(BuildContext context, String uid, {CategoryModel? category, CategoryModel? parent}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => CategoryFormSheet(
        uid: uid,
        category: category,
        parent: parent,
        onSave: (cat) => _userService.saveCategory(uid, cat),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String uid, CategoryModel category, List<CategoryModel> subCategories) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Supprimer la catégorie ?", style: TextStyle(color: AppColors.mainText)),
        content: Text(
          subCategories.isNotEmpty
              ? "Cela supprimera également les ${subCategories.length} sous-catégories associées."
              : "Voulez-vous vraiment supprimer cette catégorie ?",
          style: const TextStyle(color: AppColors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler", style: TextStyle(color: AppColors.mainText)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              for (var sub in subCategories) {
                await _userService.deleteCategory(uid, sub.id);
              }
              await _userService.deleteCategory(uid, category.id);

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );
  }
}