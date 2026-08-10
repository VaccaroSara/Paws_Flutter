import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/puppy_post_model.dart';
import '../../models/notification_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../puppy_details/puppy_details_screen.dart';
import '../user_profile/user_profile_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
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

  void resetSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = "";
      _filterGender = null;
      _filterType = null;
      _filterAge = null;
      _filterUserType = null;
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Filter Puppies"),
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

  List<PuppyPost> _applyPostFilters(List<PuppyPost> posts, Set<String> favoritedIds) {
    return posts.where((post) {
      if (favoritedIds.contains(post.id)) return false;
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

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
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
                          firstName.isNotEmpty ? "Hi, $firstName" : "Welcome",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    // Bell Icon with unread badge stream
                    StreamBuilder<List<NotificationItem>>(
                      stream: FirebaseService.notificationsStream(currentUid),
                      builder: (context, notifSnap) {
                        final hasNotifications = (notifSnap.data ?? []).isNotEmpty;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none, color: AppColors.textDark, size: 28),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                );
                              },
                            ),
                            if (hasNotifications)
                              Positioned(
                                right: 12,
                                top: 12,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryOrange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
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
                                  hintText: "search for a user...",
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

              // "Puppies for you" Label (hidden when searching)
              if (_searchQuery.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Puppies for you",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              // Main Feed / Search Content
              Expanded(
                child: StreamBuilder<Set<String>>(
                  stream: FirebaseService.favoritesIdsStream(currentUid),
                  builder: (context, favSnap) {
                    final favoritedIds = favSnap.data ?? {};

                    return StreamBuilder<List<PuppyPost>>(
                      stream: FirebaseService.globalFeedStream(currentUid),
                      builder: (context, feedSnap) {
                        if (feedSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final allPosts = feedSnap.data ?? [];
                        final filteredPosts = _applyPostFilters(allPosts, favoritedIds);

                        if (_searchQuery.length >= 2) {
                          // Combine user search results + post results
                          return FutureBuilder<List<UserModel>>(
                            future: FirebaseService.searchUsers(_searchQuery, currentUid),
                            builder: (context, userSearchSnap) {
                              final users = userSearchSnap.data ?? [];

                              if (users.isEmpty && filteredPosts.isEmpty) {
                                return const Center(
                                  child: Text("No results found", style: TextStyle(color: AppColors.textMuted)),
                                );
                              }

                              return ListView(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                children: [
                                  if (users.isNotEmpty) ...[
                                    const Text("Users", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    ...users.map((user) => _buildUserSearchTile(context, user)),
                                    const SizedBox(height: 16),
                                  ],
                                  if (filteredPosts.isNotEmpty) ...[
                                    const Text("Puppies", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 8),
                                    ...filteredPosts.map((post) => _buildFeedCard(context, post)),
                                  ],
                                ],
                              );
                            },
                          );
                        }

                        if (filteredPosts.isEmpty) {
                          return const Center(
                            child: Text(
                              "Nessun cucciolo disponibile al momento",
                              style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                            ),
                          );
                        }

                        // Feed Card PageView / ListView
                        return PageView.builder(
                          scrollDirection: Axis.vertical,
                          itemCount: filteredPosts.length,
                          itemBuilder: (context, index) {
                            final post = filteredPosts[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: _buildFeedCard(context, post),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSearchTile(BuildContext context, UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.inputBackground,
          backgroundImage: user.profileImageUri.isNotEmpty
              ? NetworkImage(user.profileImageUri)
              : null,
          child: user.profileImageUri.isEmpty
              ? const Icon(Icons.person, color: AppColors.textDark)
              : null,
        ),
        title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        subtitle: Text(user.accountType, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.uid)),
          );
        },
      ),
    );
  }

  Widget _buildFeedCard(BuildContext context, PuppyPost post) {
    final isFemale = post.gender.toLowerCase() == 'female';

    return Dismissible(
      key: Key("post_${post.id}"),
      direction: DismissDirection.startToEnd, // Swipe Right to Favorite
      confirmDismiss: (direction) async {
        await FirebaseService.favoritePost(post);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${post.name} salvato nei preferiti!")),
          );
        }
        return true;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 30),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Icon(Icons.favorite, color: AppColors.primaryOrange, size: 40),
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: post.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: post.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: AppColors.inputBackground),
                        errorWidget: (context, url, err) => const Icon(Icons.pets, size: 60, color: AppColors.textMuted),
                      )
                    : Container(color: AppColors.inputBackground, child: const Icon(Icons.pets, size: 60, color: AppColors.textMuted)),
              ),
            ),

            // Bottom Gradient Overlay & Details Pill
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xB3000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            post.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Image.asset(
                                post.type.toLowerCase() == 'cat'
                                    ? 'assets/images/cat.png'
                                    : post.type.toLowerCase() == 'bird'
                                        ? 'assets/images/bird.png'
                                        : 'assets/images/dog.png',
                                width: 18,
                                height: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                post.type,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Gender Badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isFemale ? AppColors.femaleBg : AppColors.maleBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFemale ? Icons.female : Icons.male,
                        color: isFemale ? Colors.pink : AppColors.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PuppyDetailsScreen(post: post)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: StreamBuilder<int>(
                          stream: FirebaseService.postFavoritesCountStream(post.id),
                          builder: (context, countSnap) {
                            final count = countSnap.data ?? 0;
                            return Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  "$count",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
