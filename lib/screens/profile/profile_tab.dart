import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../auth/sign_in_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isUploadingAvatar = false;

  void _pickAndUploadAvatar(String uid) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    setState(() => _isUploadingAvatar = true);

    try {
      final publicUrl = await SupabaseService.uploadProfileImage(uid, bytes);
      if (publicUrl != null) {
        await FirebaseService.updateUserFields(uid, {'profileImageUri': publicUrl});
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto profilo aggiornata!")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore caricamento: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _editFullNameDialog(UserModel user) {
    final firstController = TextEditingController(text: user.firstName);
    final lastController = TextEditingController(text: user.lastName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifica Nome e Cognome"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: firstController, decoration: const InputDecoration(hintText: "Nome")),
            TextField(controller: lastController, decoration: const InputDecoration(hintText: "Cognome")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.updateUserFields(user.uid, {
                'firstName': firstController.text.trim(),
                'lastName': lastController.text.trim(),
              });
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }

  void _editAddressDialog(UserModel user) {
    final cityController = TextEditingController(text: user.city);
    final provController = TextEditingController(text: user.province);
    final capController = TextEditingController(text: user.cap);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifica Indirizzo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cityController, decoration: const InputDecoration(hintText: "Città")),
            TextField(controller: provController, decoration: const InputDecoration(hintText: "Provincia")),
            TextField(controller: capController, decoration: const InputDecoration(hintText: "CAP")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.updateUserFields(user.uid, {
                'city': cityController.text.trim(),
                'province': provController.text.trim(),
                'cap': capController.text.trim(),
              });
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }

  void _editSingleFieldDialog(String uid, String field, String title, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.updateUserFields(uid, {field: controller.text.trim()});
            },
            child: const Text("Salva"),
          ),
        ],
      ),
    );
  }

  void _showPasswordResetDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reimposta Password"),
        content: Text("Inviare un'email di reset a $email?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annulla")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.sendPasswordResetEmail(email);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Email inviata!")),
              );
            },
            child: const Text("Invia"),
          ),
        ],
      ),
    );
  }

  void _showAccountTypeDialog(String uid) {
    final types = ["Private User", "Animal Shelter"];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Scegli Tipo Account"),
        children: types.map((t) {
          return SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.updateUserFields(uid, {'accountType': t});
            },
            child: Text(t),
          );
        }).toList(),
      ),
    );
  }

  void _shareProfile(UserModel user) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Check out my profile on Paws!\nUsername: ${user.username}")),
    );
  }

  void _logoutUser() async {
    await FirebaseService.signOut();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminare Account?"),
        content: const Text("Questa azione eliminerà definitivamente il tuo profilo e tutti i tuoi post. Sei sicuro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANNULLA")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseService.deleteAccount();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Account eliminato")),
                );
                _logoutUser();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Errore eliminazione account: ${e.toString()}")),
                );
              }
            },
            child: const Text("ELIMINA DEFINITIVAMENTE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: FirebaseService.userStream(currentUid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data ?? UserModel(uid: currentUid);
            final fullName = "${user.firstName} ${user.lastName}".trim();
            final address = "${user.city} (${user.province}) ${user.cap}".trim();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Header Title & Share Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontFamily: AppTheme.fontSerif,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share, color: AppColors.textDark),
                        onPressed: () => _shareProfile(user),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Avatar Pick Container
                  GestureDetector(
                    onTap: () => _pickAndUploadAvatar(currentUid),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            color: AppColors.inputBackground,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: user.profileImageUri.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: user.profileImageUri,
                                    fit: BoxFit.cover,
                                    placeholder: (ctx, url) => Container(color: AppColors.inputBackground),
                                    errorWidget: (ctx, url, err) => const Icon(Icons.person, size: 60, color: AppColors.textDark),
                                  )
                                : const Icon(Icons.person, size: 60, color: AppColors.textDark),
                          ),
                        ),
                        if (_isUploadingAvatar)
                          const CircularProgressIndicator(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Editable Rows
                  _buildProfileRow("Nome e Cognome", fullName.isNotEmpty ? fullName : "N/A", Icons.person_outline, () => _editFullNameDialog(user)),
                  _buildProfileRow("Indirizzo", address.isNotEmpty ? address : "N/A", Icons.location_on_outlined, () => _editAddressDialog(user)),
                  _buildProfileRow("Username", user.username.isNotEmpty ? user.username : "N/A", Icons.alternate_email, () => _editSingleFieldDialog(currentUid, "username", "Modifica Username", user.username)),
                  _buildProfileRow("Telefono", user.phone.isNotEmpty ? user.phone : "N/A", Icons.phone_outlined, () => _editSingleFieldDialog(currentUid, "phone", "Modifica Telefono", user.phone)),
                  _buildProfileRow("Email", user.email, Icons.mail_outline, () => _editSingleFieldDialog(currentUid, "email", "Modifica Email", user.email)),
                  _buildProfileRow("Password", "••••••••", Icons.lock_outline, () => _showPasswordResetDialog(user.email)),
                  _buildProfileRow("Tipo Account", user.accountType, Icons.badge_outlined, () => _showAccountTypeDialog(currentUid)),

                  const SizedBox(height: 30),

                  // Action Buttons (LOGOUT & DELETE)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryOrange, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: _logoutUser,
                      child: const Text(
                        "LOG OUT",
                        style: TextStyle(
                          color: AppColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onPressed: _confirmDeleteAccount,
                      child: const Text(
                        "ELIMINA ACCOUNT",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.iconDark, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
