// lib/presentation/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:retronova_app/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import '../../../core/constants/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../providers/ticket_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Contrôleurs pour l'édition
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _pseudoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDate;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _pseudoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final profile = await ApiService().getUserProfile();

      if (profile != null && mounted) {
        setState(() {
          _userProfile = profile;
          _populateControllers();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateControllers() {
    if (_userProfile != null) {
      _nomController.text = _userProfile!.nom;
      _prenomController.text = _userProfile!.prenom;
      _pseudoController.text = _userProfile!.pseudo;
      _emailController.text = _userProfile!.email;
      _phoneController.text = _userProfile!.numeroTelephone;
      _selectedDate = _userProfile!.dateNaissance;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      try {
        setState(() {
          _isSaving = true;
        });

        final updatedUser = _userProfile!.copyWith(
          nom: _nomController.text.trim(),
          prenom: _prenomController.text.trim(),
          pseudo: _pseudoController.text.trim(),
          email: _emailController.text.trim(),
          numeroTelephone: _phoneController.text.trim(),
          dateNaissance: _selectedDate!,
        );

        final savedUser = await ApiService().updateUserProfile(updatedUser);

        if (savedUser != null && mounted) {
          setState(() {
            _userProfile = savedUser;
            _isEditing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la sauvegarde: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _populateControllers(); // Restaurer les valeurs originales
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profileLabel),
        actions: [
          if (!_isEditing && _userProfile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Modifier le profil',
            ),
          if (_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'Annuler',
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isSaving ? null : _saveProfile,
              tooltip: 'Sauvegarder',
            ),
          ],
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _showLogoutDialog(context),
              tooltip: 'Se déconnecter',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Chargement du profil...'),
                ],
              ),
            )
          : _userProfile == null
          ? const Center(child: Text('Impossible de charger le profil'))
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: _isEditing ? _buildEditForm() : _buildProfileView(),
              ),
            ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),

        // Avatar utilisateur
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            _userProfile!.pseudo.isNotEmpty
                ? _userProfile!.pseudo[0].toUpperCase()
                : _userProfile!.prenom[0].toUpperCase(),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Nom d'utilisateur
        Text(
          _userProfile!.fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 8),

        // Pseudo
        Text(
          '@${_userProfile!.pseudo}',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 8),

        // Email
        Text(
          _userProfile!.email,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),

        const SizedBox(height: 32),

        // Solde de tickets
        GestureDetector(
          onTap: () {
            // Naviguer vers l'onglet Store
            // Si vous avez accès au MainNavigation, utilisez son index
            Navigator.of(context).popUntil((route) => route.isFirst);
            // Puis naviguer vers le store - ceci dépend de votre implémentation de navigation
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solde de tickets',
                          style: TextStyle(
                            color: AppColors.onPrimaryMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Consumer<TicketProvider>(
                          builder: (context, ticketProvider, child) {
                            return Text(
                              '${ticketProvider.ticketBalance}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Informations détaillées
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations personnelles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),

                _buildInfoRow('Prénom', _userProfile!.prenom),
                _buildInfoRow('Nom', _userProfile!.nom),
                _buildInfoRow('Pseudo', _userProfile!.pseudo),
                _buildInfoRow('Email', _userProfile!.email),
                _buildInfoRow('Téléphone', _userProfile!.numeroTelephone),
                _buildInfoRow(
                  'Date de naissance',
                  _formatDate(_userProfile!.dateNaissance),
                ),

                if (_userProfile!.createdAt != null)
                  _buildInfoRow(
                    'Membre depuis',
                    _formatDate(_userProfile!.createdAt!),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Bouton de déconnexion
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          const Text(
            'Modifier le profil',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Prénom et Nom
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _prenomController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Requis';
                    }
                    if (value.trim().length < 2) {
                      return 'Minimum 2 caractères';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.person_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Requis';
                    }
                    if (value.trim().length < 2) {
                      return 'Minimum 2 caractères';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Pseudo
          TextFormField(
            controller: _pseudoController,
            decoration: const InputDecoration(
              labelText: 'Pseudo',
              prefixIcon: Icon(Icons.alternate_email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre pseudo';
              }
              if (value.trim().length < 3) {
                return 'Le pseudo doit contenir au moins 3 caractères';
              }
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                return 'Le pseudo ne peut contenir que des lettres, chiffres et _';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
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

          // Téléphone
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              prefixIcon: Icon(Icons.phone_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Veuillez entrer votre numéro de téléphone';
              }
              if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                return 'Format: 10 chiffres (0123456789)';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Date de naissance
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date de naissance',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
              ),
              child: Text(
                _selectedDate != null
                    ? _formatDate(_selectedDate!)
                    : 'Sélectionner la date',
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancelEdit,
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
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
                      : const Text('Sauvegarder'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthProvider>(context, listen: false).signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );
  }
}
