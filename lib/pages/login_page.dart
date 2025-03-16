// ignore_for_file: use_build_context_synchronously

// Required imports for login functionality
// Importações necessárias para funcionalidade de login
import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:editto_flutter/widgets/show_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';

// Login page widget with state management
// Widget da página de login com gerenciamento de estado
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // Form controllers and state variables
  // Controladores de formulário e variáveis de estado
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;

  // Focus nodes for form fields
  // Nós de foco para campos do formulário
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  // Cleanup resources
  // Limpa recursos
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // Toggle between login and signup modes
  // Alterna entre modos de login e cadastro
  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  // Handle form submission
  // Manipula envio do formulário
  Future<void> _submitForm() async {
    final texts = ref.read(languageNotifierProvider)['texts'];

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        if (_isLogin) {
          // Login with Firebase
          // Login com Firebase
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          // Sign up with Firebase
          // Cadastro com Firebase
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          // Update user display name
          // Atualiza nome de exibição do usuário
          await FirebaseAuth.instance.currentUser?.updateDisplayName(
            _nameController.text.trim(),
          );
        }

        // Navigate to main page on success
        // Navega para página principal em caso de sucesso
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const NewsstandPage(),
          ),
        );
      } on FirebaseAuthException catch (e) {
        // Handle Firebase authentication errors
        // Manipula erros de autenticação do Firebase
        setState(() => _isLoading = false);

        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          showSnackBar(context, texts['login']![10]);
        } else if (e.code == 'invalid-email') {
          showSnackBar(context, texts['login']![9]);
        } else if (e.code == 'email-already-in-use') {
          showSnackBar(context, texts['login']![11]);
        } else {
          showSnackBar(context, texts['login']![8]);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        showSnackBar(context, texts['login']![8]);
      }
    }
  }

  // Build login form UI
  // Constrói interface do formulário de login
  Widget _buildLoginForm(
      BuildContext context, Map<String, List<String>> texts) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // App logo and title
          // Logo e título do app
          Icon(
            Icons.menu_book_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Text(
                'Éditto',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              Text(
                texts['intro']![1],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Name field (signup only)
          // Campo de nome (apenas para cadastro)
          if (!_isLogin) ...[
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              onFieldSubmitted: (_) {
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
              decoration: InputDecoration(
                labelText: texts['login']![0],
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return texts['login']![5];
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Email field
          // Campo de email
          TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            onFieldSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: texts['login']![1],
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return texts['login']![5];
              }
              if (!value.contains('@')) {
                return texts['login']![7];
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          // Campo de senha
          TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            onFieldSubmitted: (_) {
              if (!_isLoading) {
                _submitForm();
              }
            },
            obscureText: true,
            decoration: InputDecoration(
              labelText: texts['login']![2],
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return texts['login']![5];
              }
              if (value.length < 6) {
                return texts['login']![6];
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit button with loading state
          // Botão de envio com estado de carregamento
          ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isLogin ? texts['login']![3] : texts['login']![4],
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),

          // Toggle mode button
          // Botão para alternar modo
          TextButton(
            onPressed: _toggleMode,
            child: Text(
              _isLogin ? texts['login']![4] : texts['login']![3],
            ),
          ),

          // Forgot Password Button (only for login)
          if (_isLogin) ...[
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final emailController = TextEditingController();

                    Future<void> handleResetPassword() async {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: emailController.text.trim(),
                        );
                        Navigator.pop(context);
                        showSnackBar(
                            context, texts['login']![13]); // Email sent
                      } on FirebaseAuthException {
                        showSnackBar(
                            context, texts['login']![8]); // Generic error
                        Navigator.pop(context);
                      }
                    }

                    return AlertDialog(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      title: Text(texts['login']![12]), // Forgot your password?
                      content: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: texts['login']![1], // Email
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => handleResetPassword(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(texts['login']![14]), // Cancel
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: handleResetPassword,
                          child: Text(texts['login']![15]), // Send
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                texts['login']![12], // Forgot your password?
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = ref.watch(languageNotifierProvider)['texts'];
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditto Magazine'),
        actions: const [
          ThemeSwitch(),
          LanguageSwitch(),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: HelperClass(
          mobile: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildLoginForm(context, texts),
          ),
          tablet: Center(
            child: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildLoginForm(context, texts),
              ),
            ),
          ),
          desktop: Center(
            child: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildLoginForm(context, texts),
              ),
            ),
          ),
          paddingWidth: paddingWidth,
          bgColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
