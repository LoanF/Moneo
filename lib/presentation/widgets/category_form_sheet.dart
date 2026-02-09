import 'package:flutter/material.dart';
import '../../core/database/app_database.dart';
import '../../core/themes/app_colors.dart';

class CategoryFormSheet extends StatefulWidget {
  final Category? category;
  final String? parentId;
  final Function(String name, int iconCode, int colorValue) onSave;

  const CategoryFormSheet({super.key, this.category, this.parentId, required this.onSave});
  
  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  late TextEditingController _nameController;
  late int _selectedIcon;
  late Color _selectedColor;

  final List<IconData> _icons = [
    Icons.shopping_cart_rounded, Icons.restaurant_rounded, Icons.directions_car_rounded,
    Icons.home_rounded, Icons.flash_on_rounded, Icons.medical_services_rounded,
    Icons.school_rounded, Icons.fitness_center_rounded, Icons.movie_rounded,
    Icons.flight_rounded, Icons.pets_rounded, Icons.account_balance_rounded,
    Icons.celebration_rounded, Icons.work_rounded, Icons.local_gas_station_rounded,
    Icons.checkroom_rounded, Icons.smartphone_rounded, Icons.coffee_rounded,
    Icons.fastfood_rounded, Icons.subscriptions_rounded, Icons.savings_rounded,
  ];

  final List<Color> _colors = [
    AppColors.mainColor, Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    Colors.amber, Colors.deepOrange, Colors.cyan, Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedIcon = widget.category?.iconCode ?? _icons.first.codePoint;
    _selectedColor = Color(widget.category?.colorValue ?? _colors.first.toARGB32());
  }

  @override
  Widget build(BuildContext context) {
    final isSub = widget.parentId != null || (widget.category?.parentId != null);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.mainText)
                  ),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: AppColors.grey1)
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),

              if (!isSub) ...[
                const SizedBox(height: 24),
                const Text("Couleur", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey2)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = _colors[i]),
                      child: Container(
                        width: 45,
                        decoration: BoxDecoration(
                          color: _colors[i],
                          shape: BoxShape.circle,
                          border: _selectedColor == _colors[i] ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text("Icône", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey2)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12
                  ),
                  itemCount: _icons.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => setState(() => _selectedIcon = _icons[i].codePoint),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedIcon == _icons[i].codePoint ? _selectedColor : AppColors.thirdBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                          _icons[i],
                          color: _selectedIcon == _icons[i].codePoint ? Colors.white : AppColors.grey1
                      ),
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.thirdBackground, borderRadius: BorderRadius.circular(16)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.mainColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              "Cette sous-catégorie héritera du style de son parent.",
                              style: TextStyle(color: AppColors.secondaryText, fontSize: 13)
                          )
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  onPressed: () {
                    if (_nameController.text.isEmpty) return;
                    widget.onSave(
                      _nameController.text,
                      _selectedIcon,
                      _selectedColor.toARGB32(),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("Enregistrer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}