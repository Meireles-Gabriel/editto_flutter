// ignore_for_file: use_build_context_synchronously

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:url_launcher/url_launcher.dart';

/// Buy page widget for purchasing coins with web redirect payment flow
/// Widget da página de compra de moedas com fluxo de pagamento por redirecionamento web
class BuyPage extends ConsumerStatefulWidget {
  const BuyPage({super.key});

  // Static property to share test mode between pages
  // Propriedade estática para compartilhar o modo de teste entre páginas
  static bool isTestMode = false;

  @override
  ConsumerState<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends ConsumerState<BuyPage> {
  // UI state management
  // Gerenciamento de estado da UI
  bool _isLoading = false;
  bool _isBrazil = false;
  late NumberFormat _currencyFormat;

  // Toggle between test and production payment links
  // Alternar entre links de pagamento de teste e produção
  bool get isTestPayments => BuyPage.isTestMode; // Access the static property
  set isTestPayments(bool value) {
    if (BuyPage.isTestMode != value) {
      setState(() {
        BuyPage.isTestMode = value; // Update the static property
      });
    }
  }

  // Production Payment Links for Brazilian Portuguese (BRL)
  // Links de pagamento de produção em Português do Brasil (BRL)
  final String _prodMoeda1Link = 'https://buy.stripe.com/4gwdSP7Mr9LC7FmaEE';
  final String _prodMoeda10Link = 'https://buy.stripe.com/7sIeWT9Uz1f63p6145';
  final String _prodMoeda30Link = 'https://buy.stripe.com/fZeg0X2s7ga0bVC5kq';

  // Production Payment Links for English (USD)
  // Links de pagamento de produção em Inglês (USD)
  final String _prodCoin1Link = 'https://buy.stripe.com/dR6bKH4Af9LCbVCbIL';
  final String _prodCoin10Link = 'https://buy.stripe.com/bIYdSPfeT1f69NucMQ';
  final String _prodCoin30Link = 'https://buy.stripe.com/aEUeWT9Uz2ja3p628f';

  // Test Payment Links for Brazilian Portuguese (BRL)
  // Links de pagamento de teste em Português do Brasil (BRL)
  final String _testMoeda1Link =
      'https://buy.stripe.com/test_cN28yR79B3D8cc86oo';
  final String _testMoeda10Link =
      'https://buy.stripe.com/test_28o2at3Xp8Xsfok289';
  final String _testMoeda30Link =
      'https://buy.stripe.com/test_eVa5mF9hJ0qW6ROcMO';

  // Test Payment Links for English (USD)
  // Links de pagamento de teste em Inglês (USD)
  final String _testCoin1Link =
      'https://buy.stripe.com/test_eVabL379B7To5NK7sy';
  final String _testCoin10Link =
      'https://buy.stripe.com/test_cN2dTb3XpflQ4JG9AH';
  final String _testCoin30Link =
      'https://buy.stripe.com/test_3cs5mFbpR0qW3FC7sA';

  // Getters for the correct payment links based on test mode
  // Getters para os links de pagamento corretos com base no modo de teste
  String get _moeda1Link => isTestPayments ? _testMoeda1Link : _prodMoeda1Link;
  String get _moeda10Link =>
      isTestPayments ? _testMoeda10Link : _prodMoeda10Link;
  String get _moeda30Link =>
      isTestPayments ? _testMoeda30Link : _prodMoeda30Link;
  String get _coin1Link => isTestPayments ? _testCoin1Link : _prodCoin1Link;
  String get _coin10Link => isTestPayments ? _testCoin10Link : _prodCoin10Link;
  String get _coin30Link => isTestPayments ? _testCoin30Link : _prodCoin30Link;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLocale();
  }

  /// Detects the user's locale and sets the appropriate currency format
  /// Detecta o locale do usuário e define o formato de moeda apropriado
  void _checkLocale() {
    setState(() {
      // If system locale is Portuguese Brazil, use Brazil pricing
      // Se o locale do sistema for Português do Brasil, usa preços do Brasil
      _isBrazil = PlatformDispatcher.instance.locale.languageCode == 'pt' &&
          (PlatformDispatcher.instance.locale.countryCode == 'BR' ||
              PlatformDispatcher.instance.locale.countryCode == null);

      // Set the appropriate currency format based on locale
      // Define o formato de moeda apropriado com base no locale
      _currencyFormat = NumberFormat.currency(
        locale: _isBrazil ? 'pt_BR' : 'en_US',
        symbol: _isBrazil ? 'R\$' : '\$',
      );
    });
  }

  /// Calculates discount percentage based on coin amount vs unit price
  /// Calcula a porcentagem de desconto com base na quantidade de moedas vs preço unitário
  double _calculateDiscount(int coins, double price) {
    // Base price for 1 coin
    // Preço base para 1 moeda
    final basePrice = _isBrazil ? 2.00 : 1.00;

    // What the price would be without discount
    // Qual seria o preço sem desconto
    final normalPrice = basePrice * coins;

    // Calculate discount percentage
    // Calcula a porcentagem de desconto
    final discountPercent = ((normalPrice - price) / normalPrice) * 100;
    return discountPercent;
  }

  /// Gets payment link based on coin amount and locale
  /// Obtém link de pagamento com base na quantidade de moedas e locale
  String _getPaymentLink(int coins) {
    if (_isBrazil) {
      if (coins == 1) return _moeda1Link;
      if (coins == 10) return _moeda10Link;
      if (coins == 30) return _moeda30Link;
    } else {
      if (coins == 1) return _coin1Link;
      if (coins == 10) return _coin10Link;
      if (coins == 30) return _coin30Link;
    }
    return _coin1Link; // Default fallback
  }

  /// Process payment by opening the appropriate Stripe checkout URL
  /// Processa pagamento abrindo a URL de checkout do Stripe apropriada
  Future<void> _processPurchase(
      BuildContext context, int coins, Map<String, dynamic> texts) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the payment link for this product
      // Obtém o link de pagamento para este produto
      final paymentLink = _getPaymentLink(coins);

      // Try to extract session ID from test payment links (they contain cs_test_*)
      // Production links don't expose session IDs directly in the URL
      String? sessionId;
      final RegExp sessionRegex = RegExp(r'cs_(?:test|live)_[a-zA-Z0-9]+');
      final match = sessionRegex.firstMatch(paymentLink);
      if (match != null) {
        sessionId = match.group(0);
        if (kDebugMode) {
          print('Found Stripe session ID in link: $sessionId');
        }
      }

      // Mark the pending payment in Firebase
      // Marca o pagamento pendente no Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .update({
          'pendingPayment': true,
          'pendingCoins': coins,
          'pendingPaymentTime': FieldValue.serverTimestamp(),
          'pendingPaymentCurrency': _isBrazil ? 'brl' : 'usd',
          'pendingPaymentAmount': _isBrazil
              ? (coins == 1
                  ? 200
                  : coins == 10
                      ? 1700
                      : 4200) // BRL amounts in cents
              : (coins == 1
                  ? 100
                  : coins == 10
                      ? 850
                      : 2100), // USD amounts in cents
          'pendingPaymentLink': paymentLink,
          'pendingPaymentMode': isTestPayments ? 'test' : 'live',
          if (sessionId != null) 'pendingSessionId': sessionId,
          'userEmail': user.email,
        });
      }

      // Open the payment link in browser
      // Abre o link de pagamento no navegador
      final Uri url = Uri.parse(paymentLink);

      // Try launching with universal_link mode first
      // Tenta abrir primeiro com o modo universal_link
      try {
        // For most modern mobile devices, platformDefault works best
        // Para a maioria dos dispositivos móveis modernos, platformDefault funciona melhor
        await launchUrl(
          url,
          mode: LaunchMode.platformDefault,
        );
      } catch (e) {
        if (kDebugMode) {
          print('First launch attempt failed: $e, trying fallback method');
        }

        // Fallback to external application if platform default fails
        // Recorre à aplicação externa se o modo padrão da plataforma falhar
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        } else {
          // If both methods fail, throw an error
          // Se ambos os métodos falharem, lança um erro
          throw texts['buy']?[15] ?? 'Could not launch payment link';
        }
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        // Mostra mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts['buy']?[9] ??
                "Failed to complete purchase. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (kDebugMode) {
        print('Error processing purchase: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and localized texts
    // Obtém dimensões da tela e textos localizados
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.1;
    final texts = ref.watch(languageNotifierProvider)['texts'];

    return Scaffold(
      appBar: AppBar(
        title: Text(texts['buy']?[0] ?? "Buy Coins"),
        surfaceTintColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const NewsstandPage(),
            ),
          ),
        ),
        // Add developer toggle for test payments (only visible in debug mode)
        // Adiciona alternador para desenvolvedor para pagamentos de teste (visível apenas no modo debug)
        actions: kDebugMode
            ? [
                // Test payment mode toggle
                // Alternador de modo de pagamento de teste
                Row(
                  children: [
                    Text(
                      texts['buy']?[18] ?? "Test Mode",
                      style: TextStyle(
                        fontSize: 12,
                        color: isTestPayments
                            ? Colors.green
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                      ),
                    ),
                    Switch(
                      value: isTestPayments,
                      activeColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          isTestPayments = value;
                        });
                      },
                    ),
                  ],
                ),
              ]
            : null,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: HelperClass(
          mobile: _buildMobileContent(context, texts),
          tablet: _buildTabletContent(context, texts, size, paddingWidth),
          desktop: _buildDesktopContent(context, texts),
          paddingWidth: paddingWidth,
          bgColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  /// Builds mobile layout with stacked cards
  /// Constrói layout mobile com cards empilhados
  Widget _buildMobileContent(BuildContext context, Map<String, dynamic> texts) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    texts['buy']?[0] ?? "Buy Coins",
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    texts['buy']?[1] ?? "Select a package to purchase coins",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Build price cards for different coin packages
                  // Constrói cards de preço para diferentes pacotes de moedas
                  _buildPriceCard(
                    context,
                    1,
                    _isBrazil ? 2.00 : 1.00,
                    "",
                    false,
                    texts,
                  ),
                  const SizedBox(height: 20),
                  _buildPriceCard(
                    context,
                    10,
                    _isBrazil ? 17.00 : 8.50,
                    "",
                    true,
                    texts,
                  ),
                  const SizedBox(height: 20),
                  _buildPriceCard(
                    context,
                    30,
                    _isBrazil ? 42.00 : 21.00,
                    "",
                    false,
                    texts,
                  ),
                ],
              ),
            ),
    );
  }

  /// Builds tablet layout with 2+1 card arrangement
  /// Constrói layout tablet com arranjo de 2+1 cards
  Widget _buildTabletContent(BuildContext context, Map<String, dynamic> texts,
      Size size, double paddingWidth) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    texts['buy']?[0] ?? "Buy Coins",
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    texts['buy']?[1] ?? "Select a package to purchase coins",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // First row with two cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceCard(
                          context,
                          1,
                          _isBrazil ? 2.00 : 1.00,
                          "",
                          false,
                          texts,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildPriceCard(
                          context,
                          10,
                          _isBrazil ? 17.00 : 8.50,
                          "",
                          true,
                          texts,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Second row with one card centered
                  Center(
                    child: SizedBox(
                      width: (size.width - paddingWidth * 2 - 48) / 2,
                      child: _buildPriceCard(
                        context,
                        30,
                        _isBrazil ? 42.00 : 21.00,
                        "",
                        false,
                        texts,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Builds desktop layout with horizontal card arrangement
  /// Constrói layout desktop com arranjo horizontal de cards
  Widget _buildDesktopContent(
      BuildContext context, Map<String, dynamic> texts) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    texts['buy']?[0] ?? "Buy Coins",
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    texts['buy']?[1] ?? "Select a package to purchase coins",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceCard(
                          context,
                          1,
                          _isBrazil ? 2.00 : 1.00,
                          "",
                          false,
                          texts,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildPriceCard(
                          context,
                          10,
                          _isBrazil ? 17.00 : 8.50,
                          "",
                          true,
                          texts,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildPriceCard(
                          context,
                          30,
                          _isBrazil ? 42.00 : 21.00,
                          "",
                          false,
                          texts,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  /// Builds a price card for a coin package
  /// Constrói um card de preço para um pacote de moedas
  Widget _buildPriceCard(
    BuildContext context,
    int coins,
    double price,
    String label,
    bool isPopular,
    Map<String, dynamic> texts,
  ) {
    // Calculate discount percentage (0 for standard package)
    // Calcula a porcentagem de desconto (0 para o pacote padrão)
    final discountPercent = coins > 1 ? _calculateDiscount(coins, price) : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPopular
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Stack(
        children: [
          // Popular badge overlay
          // Sobreposição do badge de popular
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  texts['buy']?[5] ?? "Popular",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          // Card content
          // Conteúdo do card
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Optional title (currently not used)
                // Título opcional (atualmente não usado)
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPopular
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                const SizedBox(height: 16),
                // Coin amount
                // Quantidade de moedas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 32,
                      color: isPopular
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      coins.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isPopular
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Price
                // Preço
                Text(
                  _currencyFormat.format(price),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Discount badge
                // Badge de desconto
                if (discountPercent > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${discountPercent.toStringAsFixed(0)}${texts['buy']?[10] ?? "% OFF"}',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Buy button
                // Botão de compra
                ElevatedButton(
                  onPressed: () => _processPurchase(context, coins, texts),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPopular
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    foregroundColor: isPopular
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isPopular
                          ? BorderSide.none
                          : BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                    ),
                  ),
                  child: Text(
                    texts['buy']?[6] ?? "Buy Now",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
