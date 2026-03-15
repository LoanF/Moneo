import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_colors.dart';
import '../view_models/auth_view_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    _nameController = TextEditingController(text: user?.username ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final user = vm.currentUser;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text("Mon profil", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.mainText)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: vm.isLoading ? null : _save,
              child: vm.isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Sauvegarder", style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar section
            Container(
              width: double.infinity,
              color: AppColors.secondaryBackground,
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.mainColor, width: 2.5),
                          ),
                          child: ClipOval(
                            child: _buildAvatar(user?.photoUrl),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.mainColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.secondaryBackground, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.username ?? "Utilisateur",
                    style: const TextStyle(color: AppColors.mainText, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? "",
                    style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Form section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel("INFORMATIONS"),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildFieldRow(
                            icon: Icons.person_outline_rounded,
                            label: "Nom d'affichage",
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(color: AppColors.mainText, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: "Votre nom",
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                                fillColor: Colors.transparent,
                                filled: false,
                              ),
                            ),
                          ),
                          const Divider(color: AppColors.thirdBackground, height: 1),
                          _buildFieldRow(
                            icon: Icons.email_outlined,
                            label: "Email",
                            child: Text(
                              user?.email ?? "",
                              style: const TextStyle(color: AppColors.secondaryText, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? photoUrl) {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover, width: 100, height: 100);
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(photoUrl, fit: BoxFit.cover, width: 100, height: 100);
    }
    return Container(
      color: AppColors.thirdBackground,
      child: const Icon(Icons.person_rounded, size: 48, color: AppColors.grey1),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.mainColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildFieldRow({required IconData icon, required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final success = await context.read<AuthViewModel>().updateProfile(
      newName: _nameController.text,
      newImageFile: _imageFile,
    );
    if (mounted && success) Navigator.pop(context);
  }
}
