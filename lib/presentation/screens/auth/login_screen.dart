// lib/presentation/screens/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:retronova_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? preFilledEmail;

  const LoginScreen({super.key, this.preFilledEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Pré-remplir l'email si fourni
    if (widget.preFilledEmail != null) {
      _emailController.text = widget.preFilledEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Effacer les erreurs précédentes
      authProvider.clearError();

      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Petite attente pour s'assurer que l'état est mis à jour
        await Future.delayed(const Duration(milliseconds: 200));

        // Forcer la vérification de l'état
        authProvider.checkAuthState();

        // La navigation sera gérée automatiquement par AuthWrapper
      } else if (mounted) {
        // En cas d'échec, vérifier si c'est parce que l'utilisateur est déjà connecté
        if (authProvider.isAuthenticated) {
          // Si l'utilisateur est déjà connecté, forcer la navigation
          print('User already authenticated, forcing navigation');
          authProvider.checkAuthState();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Erreur de connexion'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // Logo et titre
                Image.asset(
                  'assets/images/brand/retronova-logo-primary.png',
                  height: 148,
                  semanticLabel: 'Retronova',
                ),
                const SizedBox(height: 24),

                Text(
                  widget.preFilledEmail != null
                      ? 'Bienvenue ! Connectez-vous avec votre nouveau compte'
                      : 'Connectez-vous pour accéder à vos jeux',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.preFilledEmail != null
                        ? Colors.green
                        : Colors.grey,
                    fontWeight: widget.preFilledEmail != null
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 48),

                // Champ email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    // Mettre en évidence si pré-rempli
                    enabledBorder: widget.preFilledEmail != null
                        ? const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          )
                        : const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!EmailValidator.validate(value)) {
                      return 'Veuillez entrer un email valide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Champ mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                // Lien mot de passe oublié
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Mot de passe oublié ?'),
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton de connexion
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Lien vers l'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pas encore de compte ? '),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'S\'inscrire',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
