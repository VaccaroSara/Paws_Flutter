import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/puppy_post_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../create_post/create_post_screen.dart';
import '../notifications/notifications_screen.dart';

class AddPuppyTab extends StatefulWidget {
  const AddPuppyTab({super.key});

  @override
  State<AddPuppyTab> createState() => _AddPuppyTabState();
}

class _AddPuppyTabState extends State<AddPuppyTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  String? _filterGender;
  String? _filterType;
  String? _filterAge;
  String? _filterUserType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreatePostScreen(initialImage: image),
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Filter My Posts"),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showSubFilterDialog("Age", ["All", "1 months", "6 months", "1 years", "2 years", "3 years", "5+ years"]);
            },
            child: const Text("Age"),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showSubFilterDialog("Gender", ["All", "Male", "Female"]);
            },
            child: const Text("Gender"),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showSubFilterDialog("Animal Type", ["All", "Dog", "Cat", "Bird"]);
            },
            child: const Text("Animal Type"),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _showSubFilterDialog("User Type", ["All", "Private User", "Animal Shelter"]);
            },
            child: const Text("User Type"),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _filterAge = null;
                _filterGender = null;
                _filterType = null;
                _filterUserType = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Filters cleared")),
              );
            },
            child: const Text("Clear All Filters", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSubFilterDialog(String title, List<String> items) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text("Select $title"),
        children: items.map((item) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                if (item == "All") {
                  if (title == "Age") _filterAge = null;
                  if (title == "Gender") _filterGender = null;
                  if (title == "Animal Type") _filterType = null;
                  if (title == "User Type") _filterUserType = null;
                } else {
                  if (title == "Age") _filterAge = item;
                  if (title == "Gender") _filterGender = item.toLowerCase();
                  if (title == "Animal Type") _filterType = item;
                  if (title == "User Type") _filterUserType = item;
                }
              });
            },
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }

  List<PuppyPost> _applyFilters(List<PuppyPost> posts) {
    return posts.where((post) {
      if (_searchQuery.isNotEmpty && !post.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filterAge != null && post.age != _filterAge) return false;
      if (_filterGender != null && post.gender.toLowerCase() != _filterGender) return false;
      if (_filterType != null && post.type != _filterType) return false;
      if (_filterUserType != null && post.userType != _filterUserType) return false;
      return true;
    }).toList();
  }

  void _confirmDeletePost(PuppyPost post) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Eliminare ${post.name}?"),
        content: const Text("Sei sicuro di voler eliminare definitivamente questo post? L'azione non può essere annullata."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANNULLA"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.deletePost(post);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${post.name} eliminato definitivamente")),
                );
              }
            },
            child: const Text("ELIMINA", style: TextStyle(color: Colors.red)),
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
        child: Column(
          children: [
            // Top Header (Greeting + Bell)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  StreamBuilder<UserModel?>(
                    stream: FirebaseService.userStream(currentUid),
                    builder: (context, snapshot) {
                      final firstName = snapshot.data?.firstName ?? '';
                      return Text(
                        firstName.isNotEmpty ? "Hi, $firstName" : "My Posts",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: AppColors.textDark, size: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar & Filter Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: AppColors.iconDark, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                              decoration: const InputDecoration(
                                hintText: "search for a puppy...",
                                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.tune, color: AppColors.iconDark, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Grid of My Posts (with fixed "+ Add Puppy" card at index 0)
            Expanded(
              child: StreamBuilder<List<PuppyPost>>(
                stream: FirebaseService.myPostsStream(currentUid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allMyPosts = snapshot.data ?? [];
                  final myPosts = _applyFilters(allMyPosts);

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: myPosts.length + 1, // +1 for Add button
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "+ Add Puppy" Button Card
                        return GestureDetector(
                          onTap: _openGallery,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0x4DF09B42), width: 1.5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryOrange,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "+ Add Puppy",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final post = myPosts[index - 1];
                      return _buildMyPostCard(context, post);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPostCard(BuildContext context, PuppyPost post) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: post.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: post.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: AppColors.inputBackground),
                          errorWidget: (context, url, err) => const Icon(Icons.pets, color: AppColors.textMuted),
                        )
                      : Container(color: AppColors.inputBackground, child: const Icon(Icons.pets, color: AppColors.textMuted)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StreamBuilder<int>(
                      stream: FirebaseService.postFavoritesCountStream(post.id),
                      builder: (context, countSnap) {
                        final count = countSnap.data ?? 0;
                        return Row(
                          children: [
                            const Icon(Icons.favorite, size: 14, color: AppColors.primaryOrange),
                            const SizedBox(width: 4),
                            Text(
                              "$count",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Edit & Delete Action Buttons
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreatePostScreen(existingPostId: post.id),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textDark),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _confirmDeletePost(post),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
