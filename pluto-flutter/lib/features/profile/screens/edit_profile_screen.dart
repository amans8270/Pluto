import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _eduCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();

  String _gender = 'M';

  // Store either the local File (if just picked) or String URL (if uploaded by backend)
  final List<dynamic> _photos = List.filled(6, null);
  final Set<int> _uploadingIndices = {};
  final Set<int> _selectedInterests = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeData());
  }

  void _initializeData() {
    final profile = ref.read(myProfileProvider).valueOrNull;
    if (profile == null) return;

    setState(() {
      _nameCtrl.text = profile['display_name'] ?? '';
      _ageCtrl.text = profile['age']?.toString() ?? '';
      _bioCtrl.text = profile['bio'] ?? '';
      _eduCtrl.text = profile['education'] ?? '';
      _jobCtrl.text = profile['occupation'] ?? '';

      final gender = profile['gender']?.toString().toUpperCase();
      if (gender == 'MALE') {
        _gender = 'M';
      } else if (gender == 'FEMALE')
        _gender = 'F';
      else
        _gender = 'O';

      // Photos
      final photos = profile['photos'] as List?;
      if (photos != null) {
        for (var p in photos) {
          int order = p['display_order'] ?? 0;
          if (order >= 0 && order < 6) {
            _photos[order] = p['gcs_url'];
          }
        }
      }

      // Interests
      final interests = profile['interests'] as List?;
      if (interests != null) {
        for (var i in interests) {
          _selectedInterests.add(i['id'] as int);
        }
      }
    });
  }

  Future<void> _pickImage(int index) async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _photos[index] =
            File(image.path); // Optimistic: Show local file immediately
        _uploadingIndices.add(index);
      });
      await _uploadPhoto(File(image.path), index);
    }
  }

  Future<void> _uploadPhoto(File file, int index) async {
    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
      });
      final resp = await dio.post('users/me/photos?display_order=$index',
          data: formData);

      if (mounted) {
        setState(() {
          _photos[index] = resp.data['url'];
          _uploadingIndices.remove(index);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingIndices.remove(index));
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload photo: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if at least one photo is uploaded
    if (_photos.where((p) => p != null).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least one photo')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      final payload = {
        "display_name": _nameCtrl.text.trim(),
        "age": int.parse(_ageCtrl.text.trim()),
        "gender":
            _gender == 'M' ? 'MALE' : (_gender == 'F' ? 'FEMALE' : 'OTHER'),
        "bio": _bioCtrl.text.trim(),
        "education": _eduCtrl.text.trim(),
        "occupation": _jobCtrl.text.trim(),
        "languages": [],
        "height_cm": null,
        "interest_ids": _selectedInterests.toList(),
      };

      final profileExists = ref.read(myProfileProvider).valueOrNull != null;

      if (profileExists) {
        await dio.put('users/me/profile', data: payload);
      } else {
        await dio.post('users/me/profile', data: payload);
      }

      // Refresh profile state so router lets us into /discover
      ref.invalidate(myProfileProvider);
      await ref.read(myProfileProvider.future);

      if (mounted) context.go('/discover');
    } on DioException catch (e) {
      final msg = e.response?.data['detail'] ?? e.message;
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $msg')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile',
            style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Done',
                    style: TextStyle(
                        color: PlutoColors.dating,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photos Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Media',
                      style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text('${_photos.where((p) => p != null).length}/6',
                      style: const TextStyle(
                          color: PlutoColors.dating,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: 6,
                itemBuilder: (ctx, i) {
                  final photo = _photos[i];
                  return GestureDetector(
                    onTap: () => _pickImage(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.red.shade100, width: 2),
                      ),
                      child: photo != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: photo is File
                                      ? Image.file(photo, fit: BoxFit.cover)
                                      : CachedNetworkImage(
                                          imageUrl: photo as String,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                            baseColor: Colors.grey.shade200,
                                            highlightColor:
                                                Colors.grey.shade100,
                                            child:
                                                Container(color: Colors.white),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error),
                                        ),
                                ),
                                if (_uploadingIndices.contains(i))
                                  Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    child: const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2)),
                                  ),
                              ],
                            )
                          : const Center(
                              child: Icon(Icons.add_circle,
                                  color: PlutoColors.dating, size: 32),
                            ),
                    ),
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 24),
                child: Text('Add up to 6 photos to show your personality.',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),

              // Basic Info
              const Text('Basic Info',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        labelStyle: TextStyle(color: Colors.grey.shade700),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        final age = int.tryParse(val);
                        if (age == null || age < 18) return 'Must be 18+';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontFamily: 'Outfit'),
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        labelText: 'Gender',
                        labelStyle: TextStyle(color: Colors.grey.shade700),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Male')),
                        DropdownMenuItem(value: 'F', child: Text('Female')),
                        DropdownMenuItem(value: 'O', child: Text('Other')),
                      ],
                      onChanged: (val) => setState(() => _gender = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bio
              const Text('Bio',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioCtrl,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Tell us a bit about yourself...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Additional Details
              const Text('More Details',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eduCtrl,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Education',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.school, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jobCtrl,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Occupation',
                  labelStyle: TextStyle(color: Colors.grey.shade700),
                  prefixIcon: const Icon(Icons.work, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Interests
              const Text('Interests',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Select 3-10 things you love.',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 16),

              ref.watch(availableInterestsProvider).when(
                    data: (interests) => Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: interests.map((item) {
                        final id = item['id'] as int;
                        final isSelected = _selectedInterests.contains(id);
                        return FilterChip(
                          label: Text(item['name']),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (_selectedInterests.length < 10)
                                  _selectedInterests.add(id);
                              } else {
                                _selectedInterests.remove(id);
                              }
                            });
                          },
                          selectedColor: PlutoColors.dating.withOpacity(0.2),
                          checkmarkColor: PlutoColors.dating,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? PlutoColors.dating
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading interests: $e'),
                  ),

              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('My Interests'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop())),
      body: const Center(child: Text('Interest tags — coming soon')),
    );
  }
}
