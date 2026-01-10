class CategoryModel {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;
  final String? parentId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.parentId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconCode': iconCode,
    'colorValue': colorValue,
    'parentId': parentId,
  };

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'],
    name: json['name'],
    iconCode: json['iconCode'],
    colorValue: json['colorValue'],
    parentId: json['parentId'],
  );
}