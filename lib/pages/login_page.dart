// ignore_for_file: use_build_context_synchronously

// Required imports for login functionality
// Importações necessárias para funcionalidade de login
import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:editto_flutter/widgets/show_snack_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

          // Update last login time
          // Atualiza hora do último login
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .update({
              'lastLoginTime': FieldValue.serverTimestamp(),
            });
          }
        } else {
          // Sign up with Firebase
          // Cadastro com Firebase
          final userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          // Update user display name
          // Atualiza nome de exibição do usuário
          await userCredential.user?.updateDisplayName(
            _nameController.text.trim(),
          );

          // Create user document in Firestore
          // Cria documento do usuário no Firestore
          await FirebaseFirestore.instance
              .collection('Users')
              .doc(userCredential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'id': userCredential.user!.uid,
            'coins': 1,
            // Add payment verification fields
            // Adiciona campos para verificação de pagamento
            'pendingPayment': false,
            'pendingCoins': 0,
            'pendingPaymentTime': null,
            'lastLoginTime': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
          });
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
          showSnackBar(
              context,
              texts['login']![
                  10]); // "Wrong email or password." / "Email ou senha incorreta."
        } else if (e.code == 'invalid-email') {
          showSnackBar(
              context,
              texts['login']![
                  9]); // "The email address is badly formatted." / "O formato do endereço de email é inválido."
        } else if (e.code == 'email-already-in-use') {
          showSnackBar(
              context,
              texts['login']![
                  11]); // "The provided email is already in use by an account." / "O email fornecido já está sendo utilizado por uma conta."
        } else {
          showSnackBar(
              context,
              texts['login']![
                  8]); // "Something went wrong. Please try again later." / "Algo deu errado. Tente novamente mais tarde."
        }
      } catch (e) {
        setState(() => _isLoading = false);
        showSnackBar(
            context,
            texts['login']![
                8]); // "Something went wrong. Please try again later." / "Algo deu errado. Tente novamente mais tarde."
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
          Theme.of(context).brightness == Brightness.light
              ? Image.asset(
                  'assets/logo_light.png',
                  height: 64,
                )
              : Image.asset(
                  'assets/logo_dark.png',
                  height: 64,
                ),
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                texts['intro']?[0] ?? 'Éditto',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              Text(
                texts['intro']![
                    1], // "Truly Yours Magazine" / "Verdadeiramente Sua Magazine"
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
                labelText: texts['login']![0], // "Name" / "Nome"
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return texts['login']![
                      5]; // "Fill in all fields." / "Preencha todos os campos."
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
              labelText: texts['login']![1], // "Email" / "Email"
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return texts['login']![
                    5]; // "Fill in all fields." / "Preencha todos os campos."
              }
              if (!value.contains('@')) {
                return texts['login']![
                    7]; // "Invalid Email." / "Email inválido."
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
              labelText: texts['login']![2], // "Password" / "Senha"
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return texts['login']![
                    5]; // "Fill in all fields." / "Preencha todos os campos."
              }
              if (value.length < 6) {
                return texts['login']![
                    6]; // "The password must be at least 6 characters long." / "A senha deve ter pelo menos 6 caracteres."
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
                    _isLogin
                        ? texts['login']![3]
                        : texts['login']![
                            4], // "Log In" / "Entrar" or "Sign Up" / "Cadastrar"
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
          const SizedBox(height: 16),

          // Toggle mode button
          // Botão para alternar modo
          TextButton(
            onPressed: _toggleMode,
            child: Text(
              _isLogin
                  ? texts['login']![4]
                  : texts['login']![
                      3], // "Sign Up" / "Cadastrar" or "Log In" / "Entrar"
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

                    // Handle password reset with Firebase Auth
                    // Lidar com redefinição de senha com Firebase Auth
                    Future<void> handleResetPassword() async {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: emailController.text.trim(),
                        );
                        Navigator.pop(context);
                        showSnackBar(
                            context,
                            texts['login']![
                                13]); // "An email has been sent with the link to create a new password." / "Um email foi enviado com o link para criar uma nova senha."
                      } on FirebaseAuthException {
                        showSnackBar(
                            context,
                            texts['login']![
                                8]); // "Something went wrong. Please try again later." / "Algo deu errado. Tente novamente mais tarde."
                        Navigator.pop(context);
                      }
                    }

                    // Password reset dialog
                    // Diálogo de redefinição de senha
                    return AlertDialog(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      title: Text(texts['login']![
                          12]), // "Forgot your password?" / "Esqueceu sua senha?"
                      content: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: texts['login']![1], // "Email" / "Email"
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => handleResetPassword(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                              texts['login']![14]), // "Cancel" / "Cancelar"
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: handleResetPassword,
                          child: Text(texts['login']![15]), // "Send" / "Enviar"
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text(
                texts['login']![
                    12], // "Forgot your password?" / "Esqueceu sua senha?"
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],

          // Terms of Use and Privacy Policy button
          // Botão para Termos de Uso e Política de Privacidade
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    title: Text(texts['login']?[17] ??
                        'Terms of Use and Privacy Policy'), // "Terms of Use and Privacy Policy" / "Termos de Uso e Política de Privacidade"
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            texts['login']?[19] ??
                                'By using Éditto, you agree to the following terms:', // "By using Éditto, you agree to the following terms:" / "Ao usar o Éditto, você concorda com os seguintes termos:"
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // AI Magazine Generation
                          Text(
                            texts['login']?[20] ??
                                '1. AI-Generated Content', // "1. AI-Generated Content" / "1. Conteúdo Gerado por IA"
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            texts['login']?[21] ??
                                'Éditto uses artificial intelligence to create magazine PDFs. The content is generated based on your chosen theme and may contain inaccuracies or errors. The sources of information are listed at the bottom of each magazine.', // "Éditto uses artificial intelligence..." / "O Éditto usa inteligência artificial..."
                          ),
                          const SizedBox(height: 12),

                          // AI Cover Generation
                          Text(
                            texts['login']?[22] ??
                                '2. Magazine Covers', // "2. Magazine Covers" / "2. Capas de Revistas"
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            texts['login']?[23] ??
                                'Magazine covers are AI-generated and while they attempt to relate to the theme you provide, they may sometimes appear random or not fully aligned with the content.', // "Magazine covers are AI-generated..." / "As capas das revistas são geradas por IA..."
                          ),
                          const SizedBox(height: 12),

                          // Content Sources and Accuracy
                          Text(
                            texts['login']?[24] ??
                                '3. Content Accuracy', // "3. Content Accuracy" / "3. Precisão do Conteúdo"
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            texts['login']?[25] ??
                                'The magazine content is based on articles found about your chosen theme but is rewritten by AI. This process may introduce errors or inaccuracies. Source articles are always cited at the bottom of each magazine.', // "The magazine content is based..." / "O conteúdo da revista é baseado..."
                          ),
                          const SizedBox(height: 12),

                          // Payment and Coins
                          Text(
                            texts['login']?[26] ??
                                '4. Payments and Refunds', // "4. Payments and Refunds" / "4. Pagamentos e Reembolsos"
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            texts['login']?[27] ??
                                'Users can purchase coins to generate magazines. These purchases are final and non-refundable. By making a purchase, you acknowledge and accept this no-refund policy.', // "Users can purchase coins..." / "Os usuários podem comprar moedas..."
                          ),
                          const SizedBox(height: 12),

                          // Agreement
                          Text(
                            texts['login']?[28] ??
                                '5. User Agreement', // "5. User Agreement" / "5. Acordo do Usuário"
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            texts['login']?[29] ??
                                'By using this application, you agree to these terms of use and privacy policies. If you do not agree with these terms, please discontinue use of the application.', // "By using this application, you agree..." / "Ao usar este aplicativo, você concorda..."
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(texts['login']?[18] ??
                            'Close'), // "Close" / "Fechar"
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(
              texts['login']?[17] ??
                  'Terms of Use and Privacy Policy', // "Terms of Use and Privacy Policy" / "Termos de Uso e Política de Privacidade"
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get localized texts and screen dimensions
    // Obtém textos localizados e dimensões da tela
    final texts = ref.watch(languageNotifierProvider)['texts'];
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.1;

    // Build responsive UI based on device size
    // Constrói UI responsiva com base no tamanho do dispositivo
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['login']![16]), // "Login/Signup" / "Login/Cadastro"
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
