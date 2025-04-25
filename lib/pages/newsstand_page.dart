// Required imports for newsstand functionality
// Importações necessárias para funcionalidade da banca
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editto_flutter/pages/buy_page.dart';
import 'package:editto_flutter/pages/login_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/default_bottom_app_bar.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/pages/creation_page.dart';
import 'package:http/http.dart' as http;

// Time period enum for magazine generation
// Enum de período para geração de revista
enum TimePeriod {
  today,
  lastWeek,
  lastMonth,
}

// Newsstand page widget with state management
// Widget da página da banca com gerenciamento de estado
class NewsstandPage extends ConsumerStatefulWidget {
  const NewsstandPage({super.key});

  @override
  ConsumerState<NewsstandPage> createState() => _NewsstandPageState();
}

class _NewsstandPageState extends ConsumerState<NewsstandPage> {
  // State variables for theme and time period
  // Variáveis de estado para tema e período
  final TextEditingController _themeController = TextEditingController();
  TimePeriod _selectedPeriod = TimePeriod.today;
  int _coins = 0;
  String? _themeError;
  bool _isBrazil = false; // Whether the user is in Brazil or using BRL

  // Toggle between test and production payment verification
  // Alternar entre verificação de pagamento de teste e produção
  bool get isTestMode => kDebugMode
      ? BuyPage.isTestMode
      : false; // Use BuyPage's static test mode flag

  // Stripe API keys
  // In production, these should be securely stored and accessed through a backend
  final String _stripeLiveSecretKey =
      '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';
  final String _stripeTestSecretKey =
      'sk_test_51REXUcCYesJnp9Wu2l70h2OAbFRF3p7lwep16XLkvYTQ1m5PEtsyDqI4GQk0DChyHHcFSQFqbJpIlKfxQUINSfFC00BYsgEwJT';

  @override
  void initState() {
    super.initState();
    // Check for pending payments when app starts
    // Verifica pagamentos pendentes quando o app inicia
    _checkLocale();
    _checkPendingPayments();
    _loadUserCoins();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload coins when page becomes visible again (e.g., after navigating back)
    // Recarrega moedas quando a página se torna visível novamente (após retornar)
    _loadUserCoins();
  }

  /// Checks the user's locale to determine if they are in Brazil
  void _checkLocale() {
    setState(() {
      // If system locale is Portuguese Brazil, use Brazil pricing
      // Se o locale do sistema for Português do Brasil, usa preços do Brasil
      _isBrazil = PlatformDispatcher.instance.locale.languageCode == 'pt' &&
          (PlatformDispatcher.instance.locale.countryCode == 'BR' ||
              PlatformDispatcher.instance.locale.countryCode == null);
    });
  }

  /// Checks for pending payments in Firestore
  /// Verifica pagamentos pendentes no Firestore
  Future<void> _checkPendingPayments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();

      if (userData.data()?.containsKey('pendingPayment') == true &&
          userData.data()?['pendingPayment'] == true) {
        // Check if payment was completed via Stripe API
        // Verifica se o pagamento foi concluído via API do Stripe
        final paymentCompleted = await _verifyStripePayment(userData.data());

        if (paymentCompleted) {
          // Payment was successful, update coins
          await _completePayment(userData.data()?['pendingCoins'] ?? 0);
        } else {
          // Payment not confirmed by Stripe - do not award coins
          // Just log for debugging but keep the pending status
          if (kDebugMode) {
            print('Payment not confirmed by Stripe yet for user: ${user.uid}');
          }

          // Check if this is a very old pending payment (over 24 hours)
          // and clean it up if necessary to prevent indefinite pending status
          final pendingTime =
              userData.data()?['pendingPaymentTime'] as Timestamp?;
          final currentTime = Timestamp.now();

          if (pendingTime != null &&
              currentTime.seconds - pendingTime.seconds > 86400) {
            // 24 hours
            // Clean up stale pending payment status after 24 hours
            await FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .update({
              'pendingPayment': false,
              'pendingCoins': 0,
            });

            if (kDebugMode) {
              print(
                  'Cleared stale pending payment status for user: ${user.uid}');
            }
          }
        }
      }
    }
  }

  /// Verifies a payment with Stripe API
  /// Verifica um pagamento com a API do Stripe
  Future<bool> _verifyStripePayment(Map<String, dynamic>? userData) async {
    if (userData == null) return false;

    try {
      if (kDebugMode) {
        print('Verifying payment in ${isTestMode ? "TEST" : "LIVE"} mode');
      }

      // Get payment data stored in Firebase
      final pendingCoins = userData['pendingCoins'] ?? 0;
      final pendingCurrency = userData['pendingPaymentCurrency'] as String? ??
          (_isBrazil ? 'brl' : 'usd');
      final pendingAmount = userData['pendingPaymentAmount'] as int? ?? 0;
      final pendingSessionId = userData['pendingSessionId'] as String?;
      final paymentMode = userData['pendingPaymentMode'] as String? ??
          (isTestMode ? 'test' : 'live');
      final userEmail = userData['userEmail'] as String? ??
          FirebaseAuth.instance.currentUser?.email;

      if (userEmail == null) {
        if (kDebugMode) {
          print('No user email available for payment verification');
        }
        return false;
      }

      // Use the appropriate API key based on the payment mode stored in Firebase
      // This ensures we use the right key even if the app's mode changed since payment initiation
      final apiKey =
          paymentMode == 'test' ? _stripeTestSecretKey : _stripeLiveSecretKey;

      // 1. If we have a session ID, check it directly (most reliable)
      if (pendingSessionId != null && pendingSessionId.isNotEmpty) {
        if (kDebugMode) {
          print('Checking Stripe session ID: $pendingSessionId');
        }

        final sessionResponse = await http.get(
          Uri.parse(
              'https://api.stripe.com/v1/checkout/sessions/$pendingSessionId'),
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        );

        if (sessionResponse.statusCode == 200) {
          final sessionData = jsonDecode(sessionResponse.body);
          if (sessionData['payment_status'] == 'paid' &&
              sessionData['status'] == 'complete') {
            if (kDebugMode) {
              print('Session $pendingSessionId is paid and complete!');
            }
            return true;
          } else {
            if (kDebugMode) {
              print(
                  'Session found but payment not complete: ${sessionData['payment_status']}');
            }
          }
        } else {
          if (kDebugMode) {
            print('Error checking session: ${sessionResponse.body}');
          }
        }
      }

      // 2. Look for recent sessions by email (no customer ID required)
      // Find any sessions in the last 24 hours that match our criteria
      final timestamp = DateTime.now()
              .subtract(const Duration(hours: 24))
              .millisecondsSinceEpoch ~/
          1000;

      final sessionsResponse = await http.get(
        Uri.parse(
            'https://api.stripe.com/v1/checkout/sessions?limit=10&created[gte]=$timestamp'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (sessionsResponse.statusCode == 200) {
        final sessionsData = jsonDecode(sessionsResponse.body);

        // Loop through recent sessions
        for (var session in sessionsData['data']) {
          // Only consider paid and complete sessions
          if (session['payment_status'] == 'paid' &&
              session['status'] == 'complete') {
            // Check if this session matches our pending payment
            // We'll check customer_email, but also amount and currency
            final sessionEmail =
                session['customer_details']?['email']?.toString().toLowerCase();
            final sessionAmount = session['amount_total'] ?? 0;
            final sessionCurrency =
                session['currency']?.toString().toLowerCase();

            if (kDebugMode) {
              print(
                  'Found session: $sessionEmail, $sessionAmount $sessionCurrency');
            }

            // First check if email matches
            if (sessionEmail != null &&
                sessionEmail == userEmail.toLowerCase()) {
              if (kDebugMode) {
                print(
                    'Email matches! Checking amount: $sessionAmount == $pendingAmount');
              }

              // Then check if amount and currency match
              if (pendingAmount > 0 && pendingCurrency.isNotEmpty) {
                if (sessionCurrency == pendingCurrency &&
                    sessionAmount == pendingAmount) {
                  if (kDebugMode) {
                    print('Amount and currency match! Payment verified.');
                  }
                  return true;
                }
              } else {
                // Fall back to standard pricing logic
                bool matchesExpectedAmount = false;
                int expectedAmountInCents;

                if (pendingCoins == 1) {
                  expectedAmountInCents =
                      100; // $1.00 or R$2.00 (depends on currency)
                  matchesExpectedAmount = (sessionCurrency == 'usd' &&
                          sessionAmount == expectedAmountInCents) ||
                      (sessionCurrency == 'brl' &&
                          sessionAmount == expectedAmountInCents * 2);
                } else if (pendingCoins == 10) {
                  expectedAmountInCents = 850; // $8.50 or R$17.00
                  matchesExpectedAmount = (sessionCurrency == 'usd' &&
                          sessionAmount == expectedAmountInCents) ||
                      (sessionCurrency == 'brl' &&
                          sessionAmount == expectedAmountInCents * 2);
                } else if (pendingCoins == 30) {
                  expectedAmountInCents = 2100; // $21.00 or R$42.00
                  matchesExpectedAmount = (sessionCurrency == 'usd' &&
                          sessionAmount == expectedAmountInCents) ||
                      (sessionCurrency == 'brl' &&
                          sessionAmount == expectedAmountInCents * 2);
                }

                if (matchesExpectedAmount) {
                  if (kDebugMode) {
                    print(
                        'Amount and currency match standard pricing! Payment verified.');
                  }
                  return true;
                }
              }
            }
          }
        }
      } else {
        if (kDebugMode) {
          print('Error fetching sessions: ${sessionsResponse.body}');
        }
      }

      // 3. Check for payment intents linked to this email
      // This is our last resort and may not work well for one-time payments
      final paymentResponse = await http.get(
        Uri.parse(
            'https://api.stripe.com/v1/payment_intents?limit=10&created[gte]=$timestamp'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (paymentResponse.statusCode == 200) {
        final paymentData = jsonDecode(paymentResponse.body);

        // Check through payments
        for (var payment in paymentData['data']) {
          if (payment['status'] == 'succeeded') {
            // We need to match by receipt_email, amount and currency
            final paymentEmail =
                payment['receipt_email']?.toString().toLowerCase();
            final paymentAmount = payment['amount'] ?? 0;
            final paymentCurrency =
                payment['currency']?.toString().toLowerCase();

            if (kDebugMode) {
              print(
                  'Found payment: $paymentEmail, $paymentAmount $paymentCurrency');
            }

            // First check if the email matches
            if (paymentEmail != null &&
                paymentEmail == userEmail.toLowerCase()) {
              // Then verify amount
              if (pendingAmount > 0 && pendingCurrency.isNotEmpty) {
                if (paymentCurrency == pendingCurrency &&
                    paymentAmount == pendingAmount) {
                  return true;
                }
              } else {
                // Fallback to standard price matching
                bool matchesExpectedAmount = false;

                if (pendingCoins == 1) {
                  matchesExpectedAmount =
                      (paymentCurrency == 'usd' && paymentAmount == 100) ||
                          (paymentCurrency == 'brl' && paymentAmount == 200);
                } else if (pendingCoins == 10) {
                  matchesExpectedAmount =
                      (paymentCurrency == 'usd' && paymentAmount == 850) ||
                          (paymentCurrency == 'brl' && paymentAmount == 1700);
                } else if (pendingCoins == 30) {
                  matchesExpectedAmount =
                      (paymentCurrency == 'usd' && paymentAmount == 2100) ||
                          (paymentCurrency == 'brl' && paymentAmount == 4200);
                }

                if (matchesExpectedAmount) {
                  return true;
                }
              }
            }
          }
        }
      }

      // No matching successful payment found
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying Stripe payment: $e');
      }
      return false;
    }
  }

  /// Completes a payment by adding coins and clearing pending status
  /// Completa um pagamento adicionando moedas e limpando o status pendente
  Future<void> _completePayment(int coins) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user data from Firestore
        // Obtém os dados do usuário do Firestore
        final userRef =
            FirebaseFirestore.instance.collection('Users').doc(user.uid);
        final userData = await userRef.get();
        final currentCoins = userData.data()?['coins'] ?? 0;

        // Payment successful, update coins and clear pending status
        // Pagamento bem-sucedido, atualiza moedas e limpa status pendente
        await userRef.update({
          'coins': currentCoins + coins,
          'pendingPayment': false,
          'pendingCoins': 0,
        });

        // Show success message if the widget is still mounted
        // Mostra mensagem de sucesso se o widget ainda estiver montado
        if (mounted) {
          final texts = ref.read(languageNotifierProvider)['texts'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${texts['buy']?[7] ?? "Successfully purchased"} $coins ${texts['buy']?[8] ?? "coins"}!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Update local state to reflect new coin balance
          setState(() {
            _coins = currentCoins + coins;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error completing payment: $e');
      }
    }
  }

  Future<void> _loadUserCoins() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .get();
      setState(() {
        _coins = userData.data()?['coins'] ?? 0;
      });
    }
  }

  // Get price based on selected time period
  // Obtém preço baseado no período selecionado
  int get _price {
    switch (_selectedPeriod) {
      case TimePeriod.today:
        return 1;
      case TimePeriod.lastWeek:
        return 3;
      case TimePeriod.lastMonth:
        return 7;
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    // Obtém dimensões da tela para layout responsivo
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.1;

    // Get localized texts
    // Obtém textos localizados
    final texts = ref.watch(languageNotifierProvider)['texts'];

    // Build main content of the page
    // Constrói conteúdo principal da página
    Widget buildContent(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coin counter
            // Contador de moedas
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_coins',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const BuyPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text(
              texts['newsstand'][7],
              // "Enter a theme, set a time period and let us take care of the rest." / "Informe um tema, defina um período e deixe-nos cuidar do resto."
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),

            // Theme input field
            // Campo de entrada de tema
            TextField(
              controller: _themeController,
              decoration: InputDecoration(
                labelText: texts['newsstand'][1],
                // "Enter theme" / "Digite o tema"
                hintText: texts['newsstand'][2],
                // "e.g., Technology, Sports, Politics" / "ex: Tecnologia, Esportes, Política"
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit_note),
                errorText: _themeError,
              ),
              maxLength: 30,
              maxLines: null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                // Clear error when user types
                // Limpa erro quando o usuário digita
                if (_themeError != null) {
                  setState(() {
                    _themeError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Time period selection buttons
            // Botões de seleção de período
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPeriodButton(
                  context,
                  TimePeriod.today,
                  texts['newsstand'][3], // "Today" / "Hoje"
                  Icons.today,
                ),
                _buildPeriodButton(
                  context,
                  TimePeriod.lastWeek,
                  texts['newsstand'][4], // "Last Week" / "Última Semana"
                  Icons.calendar_view_week,
                ),
                _buildPeriodButton(
                  context,
                  TimePeriod.lastMonth,
                  texts['newsstand'][5], // "Last Month" / "Último Mês"
                  Icons.calendar_month,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Buy button with price
            // Botão de compra com preço
            ElevatedButton(
              onPressed: _coins >= _price
                  ? () {
                      if (_themeController.text.trim().length < 2) {
                        setState(() {
                          _themeError = texts['newsstand'][8];
                          // "Theme must be at least 2 characters long." / "O tema deve ter pelo menos 2 caracteres."
                        });
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreationPage(
                              language: ref
                                  .read(languageNotifierProvider)['language'],
                              topic: _themeController.text.trim(),
                              coins: _price,
                            ),
                          ),
                        ).then((_) {
                          // Always reload coins when returning from CreationPage
                          _loadUserCoins();
                        });
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${texts['newsstand'][6]}', // "Buy for" / "Comprar por"
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.monetization_on),
                  const SizedBox(width: 4),
                  Text(
                    '$_price',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Build scaffold with responsive layout
    // Constrói scaffold com layout responsivo
    return Scaffold(
      appBar: AppBar(
        title: Text(texts['newsstand'][0]), // "Newsstand" / "Banca de Revistas"
        actions: [
          const ThemeSwitch(),
          const LanguageSwitch(),
          // Logout button
          // Botão de logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Log out the user
              // Desconecta o usuário
              await FirebaseAuth.instance.signOut();

              // Navigate to login page
              // Navega para a página de login
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: const DefaultBottomAppBar(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: HelperClass(
          mobile: buildContent(context),
          tablet: buildContent(context),
          desktop: buildContent(context),
          paddingWidth: paddingWidth,
          bgColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  // Build time period selection button
  // Constrói botão de seleção de período
  Widget _buildPeriodButton(
    BuildContext context,
    TimePeriod period,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedPeriod == period;
    return ElevatedButton(
      onPressed: () => setState(() => _selectedPeriod = period),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }
}
