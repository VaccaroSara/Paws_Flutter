import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/puppy_post_model.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../user_profile/user_profile_screen.dart';

class PuppyDetailsScreen extends StatefulWidget {
  final PuppyPost post;

  const PuppyDetailsScreen({super.key, required this.post});

  @override
  State<PuppyDetailsScreen> createState() => _PuppyDetailsScreenState();
}

class _PuppyDetailsScreenState extends State<PuppyDetailsScreen> {
  Map<String, dynamic>? _ownerData;
  bool _isLoadingOwner = true;

  @override
  void initState() {
    super.initState();
    _loadOwnerDetails();
  }

  void _loadOwnerDetails() async {
    final user = await FirebaseService.getUser(widget.post.uid);
    if (mounted) {
      setState(() {
        if (user != null) {
          _ownerData = {
            'username': user.username.isNotEmpty ? user.username : user.firstName,
            'phone': user.phone,
            'city': user.city,
            'province': user.province,
          };
        }
        _isLoadingOwner = false;
      });
    }
  }

  void _favoriteAndGoBack() async {
    await FirebaseService.favoritePost(widget.post);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${widget.post.name} salvato nei preferiti!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isFemale = post.gender.toLowerCase() == 'female';

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 200) {
          // Swipe right to favorite & exit
          _favoriteAndGoBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text(
                      "Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance spacing
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Image Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: post.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: post.imageUrl,
                                width: double.infinity,
                                height: 320,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  height: 320,
                                  color: AppColors.cardBackground,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  height: 320,
                                  color: AppColors.cardBackground,
                                  child: const Icon(Icons.pets, size: 60, color: AppColors.textMuted),
                                ),
                              )
                            : Container(
                                height: 320,
                                color: AppColors.cardBackground,
                                child: const Icon(Icons.pets, size: 60, color: AppColors.textMuted),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // Name and Gender Badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontFamily: AppTheme.fontSerif,
                              ),
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isFemale ? AppColors.femaleBg : AppColors.maleBg,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/icons/female.svg',
                              colorFilter: ColorFilter.mode(
                                isFemale ? Colors.pink : AppColors.primaryOrange,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Detail Capsules Row (Type & Age)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
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
                                  style: const TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              post.age,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Caption
                      if (post.caption.isNotEmpty) ...[
                        Text(
                          post.caption,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textDark,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Owner Info Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Owner Information",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isLoadingOwner
                                ? const CircularProgressIndicator()
                                : Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: const BoxDecoration(
                                          color: AppColors.inputBackground,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.person, color: AppColors.iconDark),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                final currentUid = FirebaseService.currentUser?.uid;
                                                if (post.uid != currentUid) {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => UserProfileScreen(userId: post.uid),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text("Questo è il tuo profilo")),
                                                  );
                                                }
                                              },
                                              child: Text(
                                                _ownerData?['username'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primaryOrange,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Phone: ${_ownerData?['phone'] ?? 'N/A'}",
                                              style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                                            ),
                                            if ((_ownerData?['city'] as String? ?? '').isNotEmpty)
                                              Text(
                                                "Location: ${_ownerData?['city']} (${_ownerData?['province']})",
                                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
