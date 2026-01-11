import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../utils/toast_utils.dart';
import '../widgets/loading_indicator.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _userController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  final _bioController = TextEditingController();
  final _picker = ImagePicker();
  String? _avatarPath;

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isRestoreMode = false;
  final _restoreController = TextEditingController();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _avatarPath = image.path);
    }
  }

  void _submit() async {
    final chat = context.read<ChatProvider>();
    setState(() => _isLoading = true);
    if (!mounted) return;

    try {
      if (_isLogin) {
        // Login flow - no onboarding
        final success = await chat.login(_userController.text, _passController.text);
        if (!success && mounted) {
          ToastUtils.showToast(context, 'Login failed', isError: true);
        }
      } else {
        // Registration flow - show onboarding
        final api = ApiService();
        final res = await api.register(
          _userController.text,
          _emailController.text,
          _passController.text,
        );

        if (res['id'] != null) {
          // Generate mnemonic BEFORE login
          final mnemonic = await chat.crypto.generateMnemonic();

          // Set flag to prevent auto-navigation to home
          chat.setNeedsOnboarding(true);

          // Now login
          final success = await chat.login(
            _userController.text,
            _passController.text,
            isRegistration: true,
          );
          if (success && chat.me != null) {
            // Store mnemonic
            await chat.crypto.storeMnemonic(chat.me!.username, mnemonic);

            // Update profile with Display Name and Bio
            await chat.updateProfile(
              bio: _bioController.text.isNotEmpty ? _bioController.text : null,
              displayName: _displayNameController.text.isNotEmpty
                  ? _displayNameController.text
                  : _userController.text,
            );

            if (_avatarPath != null) {
              await chat.uploadAvatar(_avatarPath!);
            }

            // Show onboarding (Declarative: Update state)
            chat.setCurrentMnemonic(mnemonic);
            // chat.setNeedsOnboarding(true) was already called above.

            // App.dart will see me != null AND needsOnboarding == true
            // and switch to RecoveryOnboardingView automatically.
          } else if (mounted) {
            ToastUtils.showToast(context, 'Registered but login failed', isError: true);
            setState(() => _isLogin = true);
          }
        } else if (mounted) {
          ToastUtils.showToast(context, res['message'] ?? 'Registration failed', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showToast(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitRestore() async {
    final mnemonic = _restoreController.text.trim();
    final words = mnemonic.split(RegExp(r'\s+'));

    if (words.length != 12) {
      ToastUtils.showToast(context, 'Recovery phrase must be exactly 12 words', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final chat = context.read<ChatProvider>();
      final success = await chat.login(
        _userController.text,
        _passController.text,
        mnemonic: mnemonic,
      );

      if (!success && mounted) {
        ToastUtils.showToast(
          context,
          'Restore failed. Check your credentials and phrase.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showToast(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scanQRCode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Scan Recovery Phrase QR'),
            backgroundColor: const Color.fromARGB(255, 29, 30, 126),
            foregroundColor: Colors.white,
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  Navigator.pop(context, barcode.rawValue);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _restoreController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Colors.black, const Color.fromARGB(255, 17, 38, 101)]
                : [const Color.fromARGB(255, 29, 30, 126), const Color.fromARGB(255, 107, 92, 255)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: SizedBox(height: _isLogin ? 16 : 40),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        '#Haki',
                        key: const ValueKey('logo'),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _isLogin ? 'Welcome back, yasta.' : 'Begin your journey.',
                        key: ValueKey(_isLogin ? 'login_sub' : 'signup_sub'),
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                    _isLogin ? const SizedBox(height: 48) : const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]!.withValues(alpha: 0.95)
                            : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _isLogin ? 'Login' : 'Create Account',
                              key: ValueKey(_isLogin ? 'login_title' : 'signup_title'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 32),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: !_isLogin
                                ? Column(
                                    children: [
                                      Center(
                                        child: GestureDetector(
                                          onTap: _pickImage,
                                          child: CircleAvatar(
                                            radius: 40,
                                            backgroundColor: Colors.grey[200],
                                            backgroundImage: _avatarPath != null
                                                ? FileImage(File(_avatarPath!))
                                                : null,
                                            child: _avatarPath == null
                                                ? const Icon(Icons.add_a_photo, color: Colors.grey)
                                                : null,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          _buildTextField(
                            controller: _userController,
                            label: 'Username',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 16),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: !_isLogin
                                ? Column(
                                    children: [
                                      _buildTextField(
                                        controller: _displayNameController,
                                        label: 'Display Name',
                                        icon: Icons.badge_outlined,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _emailController,
                                        label: 'Email',
                                        icon: Icons.email_outlined,
                                        inputType: TextInputType.emailAddress,
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          _buildTextField(
                            controller: _passController,
                            label: 'Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: !_isLogin
                                ? Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _bioController,
                                        label: 'Short Bio (Optional)',
                                        icon: Icons.info_outline,
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: (_isRestoreMode && _isLogin)
                                ? Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.blue.shade900.withValues(alpha: 0.3)
                                              : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(
                                                  Icons.info_outline,
                                                  color: Colors.blue,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Enter your 12-word recovery phrase',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.blue,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller: _restoreController,
                                                    maxLines: 3,
                                                    style: TextStyle(
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.onSurface,
                                                    ),
                                                    decoration: InputDecoration(
                                                      hintText: 'word1 word2 word3 ...',
                                                      filled: true,
                                                      fillColor:
                                                          Theme.of(context).brightness ==
                                                              Brightness.dark
                                                          ? Colors.black.withValues(alpha: 0.5)
                                                          : Colors.white,
                                                      border: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        borderSide: BorderSide.none,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: _scanQRCode,
                                                  icon: const Icon(Icons.qr_code_scanner),
                                                  iconSize: 32,
                                                  tooltip: 'Scan QR Code',
                                                  style: IconButton.styleFrom(
                                                    backgroundColor: Theme.of(context).primaryColor,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : (_isRestoreMode ? _submitRestore : _submit),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                              ),
                              child: _isLoading
                                  ? const LoadingIndicator(size: 24)
                                  : AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 300),
                                      child: Text(
                                        _isLogin ? 'Sign In' : 'Sign Up',
                                        key: ValueKey(_isLogin ? 'signin_btn' : 'signup_btn'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _isLogin ? const SizedBox(height: 32) : const SizedBox(height: 12),
                    if (_isLogin)
                      TextButton(
                        onPressed: () => setState(() => _isRestoreMode = !_isRestoreMode),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _isRestoreMode ? 'Use password login' : 'Restore from recovery phrase',
                            key: ValueKey(_isRestoreMode),
                            style: const TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    TextButton(
                      onPressed: () => setState(() => _isLogin = !_isLogin),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: RichText(
                          key: ValueKey(_isLogin),
                          text: TextSpan(
                            text: _isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: const TextStyle(color: Colors.white70),
                            children: [
                              TextSpan(
                                text: _isLogin ? "Sign Up" : "Login",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Theme.of(context).primaryColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withValues(alpha: 0.5)
            : Colors.grey.shade100,
      ),
    );
  }
}
