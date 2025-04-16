import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editto_flutter/pages/newsstand_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:intl/intl.dart';

class BuyPage extends ConsumerStatefulWidget {
  const BuyPage({super.key});

  @override
  ConsumerState<BuyPage> createState() => _BuyPageState();
}

class _BuyPageState extends ConsumerState<BuyPage> {
  bool _isLoading = false;
  bool _isBrazil = false;
  late NumberFormat _currencyFormat;

  @override
  void initState() {
    super.initState();
    // We'll check locale in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkLocale();
  }

  void _checkLocale() {
    setState(() {
      // If system locale is Portuguese Brazil, use Brazil pricing
      _isBrazil = PlatformDispatcher.instance.locale.languageCode == 'pt' &&
          (PlatformDispatcher.instance.locale.countryCode == 'BR' ||
              PlatformDispatcher.instance.locale.countryCode == null);
      _currencyFormat = NumberFormat.currency(
        locale: _isBrazil ? 'pt_BR' : 'en_US',
        symbol: _isBrazil ? 'R\$' : '\$',
      );
    });
  }

  // Calculate discount percentage
  double _calculateDiscount(int coins, double price) {
    // Base price for 1 coin
    final basePrice = _isBrazil ? 2.00 : 1.00;
    // What the price would be without discount
    final normalPrice = basePrice * coins;
    // Calculate discount percentage
    final discountPercent = ((normalPrice - price) / normalPrice) * 100;
    return discountPercent;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final paddingWidth = size.width * 0.1;
    final texts = ref.watch(languageNotifierProvider)['texts'];

    // Mobile layout: one card per row
    Widget buildMobileContent(BuildContext context) {
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

    // Tablet layout: two cards in first row, one card in second row
    Widget buildTabletContent(BuildContext context) {
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

    // Desktop layout: all three cards in one row
    Widget buildDesktopContent(BuildContext context) {
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
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: HelperClass(
          mobile: buildMobileContent(context),
          tablet: buildTabletContent(context),
          desktop: buildDesktopContent(context),
          paddingWidth: paddingWidth,
          bgColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildPriceCard(
    BuildContext context,
    int coins,
    double price,
    String label,
    bool isPopular,
    Map<String, dynamic> texts,
  ) {
    // Calculate discount percentage (0 for standard package)
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                Text(
                  _currencyFormat.format(price),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

  Future<void> _processPurchase(
      BuildContext context, int coins, Map<String, dynamic> texts) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, here you would integrate with a payment processor
      // For this demo, we'll simulate a successful purchase
      await Future.delayed(const Duration(seconds: 2));

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update user's coins in Firestore
        final userRef =
            FirebaseFirestore.instance.collection('Users').doc(user.uid);

        // Get current coins and add the new ones
        final userData = await userRef.get();
        final currentCoins = userData.data()?['coins'] ?? 0;

        // Update with new total
        await userRef.update({
          'coins': currentCoins + coins,
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${texts['buy']?[7] ?? "Successfully purchased"} $coins ${texts['buy']?[8] ?? "coins"}!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts['buy']?[9] ??
                "Failed to complete purchase. Please try again."),
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
}
