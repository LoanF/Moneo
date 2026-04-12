import 'package:flutter/material.dart' hide Category;
import '../../data/models/models.dart';
import '../../core/helpers/icon_helper.dart';
import '../../core/themes/app_colors.dart';

class CategoryFormSheet extends StatefulWidget {
  final Category? category;
  final String? parentId;
  final Function(String name, String iconName, int colorValue) onSave;

  const CategoryFormSheet({
    super.key,
    this.category,
    this.parentId,
    required this.onSave,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  late TextEditingController _nameController;
  late String _selectedIconName;
  late Color _selectedColor;

  final List<String> _iconNames = IconHelper.iconsMap.keys.toList();

  final List<Color> _colors = [
    AppColors.mainColor,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.deepOrange,
    Colors.cyan,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedIconName = widget.category?.iconCode ?? _iconNames.first;
    _selectedColor = Color(
      widget.category?.colorValue ?? _colors.first.toARGB32(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSub = widget.parentId != null || (widget.category?.parentId != null);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.category == null ? "Ajouter" : "Modifier",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mainText,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.grey1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: const TextStyle(color: AppColors.mainText),
                  decoration: InputDecoration(
                    hintText: "Nom de la catégorie",
                    hintStyle: const TextStyle(color: AppColors.grey1),
                    filled: true,
                    fillColor: AppColors.thirdBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (!isSub) ...[
                  const SizedBox(height: 24),
                  const Text(
                    "Couleur",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => setState(() => _selectedColor = _colors[i]),
                        child: Container(
                          width: 45,
                          decoration: BoxDecoration(
                            color: _colors[i],
                            shape: BoxShape.circle,
                            border: _selectedColor == _colors[i]
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Icône",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.grey2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: _iconNames.length,
                    itemBuilder: (context, i) {
                      final iconName = _iconNames[i];
                      final isSelected = _selectedIconName == iconName;

                      return GestureDetector(
                        onTap: () => setState(() => _selectedIconName = iconName),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? _selectedColor : AppColors.thirdBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            IconHelper.getIcon(iconName), // Récupère l'IconData via le nom
                            color: isSelected ? Colors.white : AppColors.grey1,
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.thirdBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.mainColor, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Cette sous-catégorie héritera du style de son parent.",
                            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.mainColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      if (_nameController.text.isEmpty) return;
                      widget.onSave(
                        _nameController.text,
                        _selectedIconName, // On enregistre le String
                        _selectedColor.toARGB32(),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Enregistrer",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}