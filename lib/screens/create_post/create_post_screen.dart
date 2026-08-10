import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/puppy_post_model.dart';
import '../../services/firebase_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_input.dart';

class CreatePostScreen extends StatefulWidget {
  final XFile? initialImage;
  final String? existingPostId;

  const CreatePostScreen({
    super.key,
    this.initialImage,
    this.existingPostId,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _existingImageUrl;

  String _currentGender = "male";
  String _currentType = "Dog";
  String _currentAge = "1 years";

  int _remainingChars = 450;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
    if (_selectedImage != null) {
      _loadInitialImageBytes();
    }

    _captionController.addListener(_updateCharCount);

    if (widget.existingPostId != null) {
      _loadExistingPostData();
    }
  }

  void _loadInitialImageBytes() async {
    final bytes = await _selectedImage?.readAsBytes();
    if (mounted && bytes != null) {
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  void _updateCharCount() {
    setState(() {
      _remainingChars = 450 - _captionController.text.length;
    });
  }

  void _loadExistingPostData() async {
    final postId = widget.existingPostId!;
    final docSnap = await FirebaseService.db.collection('posts').doc(postId).get();
    if (docSnap.exists && docSnap.data() != null && mounted) {
      final post = PuppyPost.fromMap(docSnap.data()!, docSnap.id);
      setState(() {
        _nameController.text = post.name;
        _captionController.text = post.caption;
        _currentGender = post.gender;
        _currentType = post.type;
        _currentAge = post.age;
        _existingImageUrl = post.imageUrl;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  void _selectGender() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Select Gender"),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _currentGender = "male");
              Navigator.pop(ctx);
            },
            child: const Text("Male"),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _currentGender = "female");
              Navigator.pop(ctx);
            },
            child: const Text("Female"),
          ),
        ],
      ),
    );
  }

  void _selectType() {
    final types = ["Dog", "Cat", "Bird"];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Select Type"),
        children: types.map((type) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _currentType = type);
              Navigator.pop(ctx);
            },
            child: Text(type),
          );
        }).toList(),
      ),
    );
  }

  void _selectAge() {
    final ages = ["1 months", "6 months", "1 years", "2 years", "3 years", "5+ years"];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Select Age"),
        children: ages.map((age) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _currentAge = age);
              Navigator.pop(ctx);
            },
            child: Text(age),
          );
        }).toList(),
      ),
    );
  }

  void _shareOrUpdatePost() async {
    final name = _nameController.text.trim();
    final caption = _captionController.text;
    final user = FirebaseService.currentUser;

    if (user == null) return;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inserisci un nome")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseService.getUser(user.uid);
      final userType = userDoc?.accountType ?? "Private User";
      final isUpdate = widget.existingPostId != null;
      final postId = widget.existingPostId ?? const Uuid().v4();

      String imageUrl = _existingImageUrl ?? '';

      // Upload image to Supabase if newly selected
      if (_selectedImageBytes != null) {
        final uploadedUrl = await SupabaseService.uploadPostImage(postId, _selectedImageBytes!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final postData = {
        'id': postId,
        'uid': user.uid,
        'name': name.isEmpty ? name : name[0].toUpperCase() + name.substring(1),
        'imageUrl': imageUrl,
        'gender': _currentGender,
        'type': _currentType,
        'age': _currentAge,
        'caption': caption,
        'userType': userType,
        'timestamp': DateTime.now(),
      };

      if (isUpdate) {
        await FirebaseService.updatePost(postId, postData);
      } else {
        await FirebaseService.savePost(postData, postId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isUpdate ? "Modifiche salvate!" : "Post condiviso!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPostId != null;
    final isFemale = _currentGender == 'female';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            isEditing ? "Edit Post" : "Create Post",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview Card
              GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: double.infinity,
                    height: 240,
                    color: AppColors.cardBackground,
                    child: _selectedImageBytes != null
                        ? Image.memory(
                            _selectedImageBytes!,
                            width: double.infinity,
                            height: 240,
                            fit: BoxFit.cover,
                          )
                        : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: _existingImageUrl!,
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.cover,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_a_photo_outlined, size: 48, color: AppColors.primaryOrange),
                                  SizedBox(height: 8),
                                  Text("Tap to select photo", style: TextStyle(color: AppColors.textMuted)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name Input
              const Text("Puppy Name", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              CustomInputField(
                controller: _nameController,
                hintText: "Enter puppy name",
              ),
              const SizedBox(height: 16),

              // Caption Input & Counter
              const Text("Caption", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _captionController,
                  maxLines: 4,
                  maxLength: 450,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: const InputDecoration(
                    hintText: "Write something about your puppy...",
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "$_remainingChars characters remaining",
                  style: TextStyle(
                    fontSize: 12,
                    color: _remainingChars < 0 ? Colors.red : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Selectors Row (Gender, Type, Age)
              Row(
                children: [
                  // Gender Selector
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectGender,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isFemale ? AppColors.femaleBg : AppColors.maleBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isFemale ? Icons.female : Icons.male,
                              color: isFemale ? Colors.pink : AppColors.primaryOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _currentGender.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isFemale ? Colors.pink : AppColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Type Selector
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectType,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              _currentType.toLowerCase() == 'cat'
                                  ? 'assets/images/cat.png'
                                  : _currentType.toLowerCase() == 'bird'
                                      ? 'assets/images/bird.png'
                                      : 'assets/images/dog.png',
                              width: 16,
                              height: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentType,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Age Selector
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectAge,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            _currentAge,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Submit Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: isEditing ? "SAVE CHANGES" : "SHARE POST",
                      onPressed: _shareOrUpdatePost,
                    ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
