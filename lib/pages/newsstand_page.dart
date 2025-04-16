// Required imports for newsstand functionality
// Importações necessárias para funcionalidade da banca
// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:editto_flutter/pages/buy_page.dart';
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/default_bottom_app_bar.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:editto_flutter/pages/creation_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserCoins();
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
                        );
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
        actions: const [
          ThemeSwitch(),
          LanguageSwitch(),
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
