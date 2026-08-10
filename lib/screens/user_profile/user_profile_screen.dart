import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/puppy_post_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../puppy_details/puppy_details_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? _filterGender;
  String? _filterType;
  String? _filterAge;

  void _makeCall(String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Telefono non disponibile")),
      );
      return;
    }
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossibile avviare la chiamata")),
      );
    }
  }

  void _shareProfile(String username) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Share: Check out $username's profile on Paws!")),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Filter Posts"),
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
              setState(() {
                _filterAge = null;
                _filterGender = null;
                _filterType = null;
              });
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
                } else {
                  if (title == "Age") _filterAge = item;
                  if (title == "Gender") _filterGender = item.toLowerCase();
                  if (title == "Animal Type") _filterType = item;
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
      if (_filterAge != null && post.age != _filterAge) return false;
      if (_filterGender != null && post.gender.toLowerCase() != _filterGender) return false;
      if (_filterType != null && post.type != _filterType) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textDark),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: StreamBuilder<UserModel?>(
        stream: FirebaseService.userStream(widget.userId),
        builder: (context, userSnap) {
          final user = userSnap.data;
          final username = user?.username ?? 'User';
          final fullName = "${user?.firstName ?? ''} ${user?.lastName ?? ''}".trim();
          final accountType = user?.accountType ?? 'Private User';
          final phone = user?.phone ?? '';
          final city = user?.city ?? '';
          final province = user?.province ?? '';
          final location = city.isNotEmpty ? "$city ($province)" : "N/A";
          final avatarUrl = user?.profileImageUri ?? '';

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: AppColors.inputBackground,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: avatarUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: avatarUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, url) => Container(color: AppColors.inputBackground),
                                  errorWidget: (ctx, url, err) => const Icon(Icons.person, size: 50, color: AppColors.textDark),
                                )
                              : const Icon(Icons.person, size: 50, color: AppColors.textDark),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Username & Full Name
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontFamily: AppTheme.fontSerif,
                        ),
                      ),
                      if (fullName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          fullName,
                          style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                        ),
                      ],
                      const SizedBox(height: 6),

                      // Account Type Capsule & Location
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.maleBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              accountType,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Text(
                            location,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons (Call & Share)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: () => _makeCall(phone),
                            icon: const Icon(Icons.phone, size: 18, color: Colors.white),
                            label: const Text("Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryOrange),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            onPressed: () => _shareProfile(username),
                            icon: const Icon(Icons.share, size: 18, color: AppColors.primaryOrange),
                            label: const Text("Share", style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
            body: StreamBuilder<List<PuppyPost>>(
              stream: FirebaseService.userPostsStream(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = _applyFilters(snapshot.data ?? []);

                if (posts.isEmpty) {
                  return const Center(
                    child: Text("Nessun post presente", style: TextStyle(color: AppColors.textMuted)),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _buildGridCard(context, post, currentUid);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, PuppyPost post, String currentUid) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PuppyDetailsScreen(post: post)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  child: Text(
                    post.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontFamily: AppTheme.fontSerif,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Favorite Button
            Positioned(
              top: 8,
              right: 8,
              child: StreamBuilder<bool>(
                stream: FirebaseService.isPostFavoritedStream(currentUid, post.id),
                builder: (context, favSnap) {
                  final isFav = favSnap.data ?? false;
                  return GestureDetector(
                    onTap: () async {
                      await FirebaseService.toggleFavoritePost(post);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.primaryOrange : AppColors.iconDark,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
