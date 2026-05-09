import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/di.dart';
import '../../core/notifiers/auth_notifier.dart';
import '../../core/services/user_service.dart';
import '../../core/themes/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../../data/models/app_user_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _userService = getIt<IAppUserService>();
  final _authNotifier = getIt<AuthNotifier>();

  late AppUser _user;
  bool _isUploadingPhoto = false;
  bool _isSavingName = false;

  @override
  void initState() {
    super.initState();
    _user = _authNotifier.appUser!;
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final url = await _userService.uploadAvatar(File(picked.path));
      final updated = _user.copyWith(photoUrl: url);
      await _userService.updateUser(updated);
      _authNotifier.refreshProfile(updated);
      if (!mounted) return;
      setState(() {
        _user = updated;
        _isUploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      _showError(handleError(e));
    }
  }

  Future<void> _editName() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _NameEditSheet(initialName: _user.username),
    );
    if (result == null || result == _user.username) return;

    setState(() => _isSavingName = true);
    try {
      final updated = _user.copyWith(username: result);
      await _userService.updateUser(updated);
      _authNotifier.refreshProfile(updated);
      if (!mounted) return;
      setState(() {
        _user = updated;
        _isSavingName = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingName = false);
      _showError(handleError(e));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text(
          "Mon profil",
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.mainText,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Avatar
            Container(
              width: double.infinity,
              color: AppColors.secondaryBackground,
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isUploadingPhoto ? null : _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.mainColor,
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(child: _buildAvatar()),
                        ),
                        if (_isUploadingPhoto)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black45,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.mainColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.secondaryBackground,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user.username,
                    style: const TextStyle(
                      color: AppColors.mainText,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _user.email,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Champs
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
                    child: Column(
                      children: [
                        _buildTappableRow(
                          icon: Icons.person_outline_rounded,
                          label: "Nom d'affichage",
                          value: _user.username,
                          isLoading: _isSavingName,
                          onTap: _isSavingName ? null : _editName,
                        ),
                        const Divider(
                          color: AppColors.thirdBackground,
                          height: 1,
                          indent: 50,
                        ),
                        _buildStaticRow(
                          icon: Icons.email_outlined,
                          label: "Email",
                          value: _user.email,
                        ),
                      ],
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

  Widget _buildTappableRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.grey1),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.mainText,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.mainColor,
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.grey1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.grey1),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final photoUrl = _user.photoUrl;
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
}

class _NameEditSheet extends StatefulWidget {
  final String initialName;

  const _NameEditSheet({required this.initialName});

  @override
  State<_NameEditSheet> createState() => _NameEditSheetState();
}

class _NameEditSheetState extends State<_NameEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final v = _controller.text.trim();
    Navigator.pop(context, v.isNotEmpty ? v : null);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nom d'affichage",
              style: TextStyle(
                color: AppColors.mainText,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: AppColors.mainText, fontSize: 15),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.thirdBackground,
                hintText: "Votre nom",
                hintStyle: const TextStyle(color: AppColors.secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.mainColor,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.thirdBackground),
                    ),
                    child: const Text(
                      "Annuler",
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Confirmer"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
