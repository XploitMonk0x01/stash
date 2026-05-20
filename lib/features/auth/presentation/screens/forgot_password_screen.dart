import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../auth/data/auth_repository.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(
            _emailController.text,
          );
      if (mounted) {
        setState(() => _emailSent = true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to send reset email');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _emailSent ? _buildSuccessState(theme, isDark) : _buildForm(theme, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState(ThemeData theme, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 40,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check your email',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a password reset link to\n${_emailController.text}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 40,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reset Password',
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email and we\'ll send you\na link to reset your password',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendResetEmail(),
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Send Reset Link'),
            ),
          ),
        ],
      ),
    );
  }
}
