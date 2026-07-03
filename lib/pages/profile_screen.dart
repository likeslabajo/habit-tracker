import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habit_tracker_project/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({super.key, required this.username});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;

  String _name = '';
  String _age = '';
  String _country = '';
  String _usernameLocal = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = _name;
    _ageController.text = _age;
    _countryController.text = _country;
    _usernameController.text = widget.username;
    _usernameLocal = widget.username;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final docId = uid ?? widget.username;
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(docId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _name = (data?['name'] ?? '') as String;
          _age = (data?['age'] ?? '') as String;
          _country = (data?['country'] ?? '') as String;
          _usernameLocal = (data?['username'] ?? _usernameLocal) as String;

          _nameController.text = _name;
          _ageController.text = _age;
          _countryController.text = _country;
          _usernameController.text = _usernameLocal;
        });
      }
    } catch (e) {
      // ignore errors for now, could log or show UI
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _countryController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveProfile() {
    setState(() {
      _name = _nameController.text.trim();
      _age = _ageController.text.trim();
      _country = _countryController.text.trim();
      _usernameLocal = _usernameController.text.trim();
      _isEditing = false;
    });
    _persistProfile();
  }

  Future<void> _persistProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final docId = uid ?? widget.username;
      final docRef = FirebaseFirestore.instance
          .collection('profiles')
          .doc(docId);
      await docRef.set({
        'name': _name,
        'age': _age,
        'country': _country,
        'username': _usernameLocal,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore errors for now
    }
  }

  String _avatarInitial() {
    if (_name.trim().isNotEmpty) {
      return _name.trim()[0].toUpperCase();
    }
    final fallback = _usernameLocal.isNotEmpty
        ? _usernameLocal
        : widget.username;
    if (fallback.trim().isNotEmpty) {
      return fallback.trim()[0].toUpperCase();
    }
    return '?';
  }

  Widget _buildInfoRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(width: 48),
          Flexible(child: valueWidget),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: _startEditing,
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      _avatarInitial(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '@${_usernameLocal != '' ? _usernameLocal : widget.username}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Username
            _buildInfoRow(
              'Username',
              _isEditing
                  ? TextField(
                      controller: _usernameController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 8.0,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(
                      '@${_usernameLocal != '' ? _usernameLocal : widget.username}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.right,
                    ),
            ),

            // Name
            _buildInfoRow(
              'Name',
              _isEditing
                  ? TextField(
                      controller: _nameController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 8.0,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(
                      _name != '' ? _name : '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.right,
                    ),
            ),

            // Age
            _buildInfoRow(
              'Age',
              _isEditing
                  ? TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 8.0,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(
                      _age != '' ? _age : '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.right,
                    ),
            ),

            // Country
            _buildInfoRow(
              'Country',
              _isEditing
                  ? TextField(
                      controller: _countryController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 8.0,
                        ),
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(
                      _country != '' ? _country : '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.right,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
