// Required imports for newsstand functionality
// Importações necessárias para funcionalidade da banca
import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/default_bottom_app_bar.dart';
import 'package:editto_flutter/widgets/language_switch.dart';
import 'package:editto_flutter/widgets/theme_switch.dart';
import 'package:flutter/material.dart';
import 'package:editto_flutter/utilities/helper_class.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final int _coins = 100; // TODO: Replace with actual user coins from database

  // Get price based on selected time period
  // Obtém preço baseado no período selecionado
  int get _price {
    switch (_selectedPeriod) {
      case TimePeriod.today:
        return 1;
      case TimePeriod.lastWeek:
        return 3;
      case TimePeriod.lastMonth:
        return 10;
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
            // Theme input field
            // Campo de entrada de tema
            TextField(
              controller: _themeController,
              decoration: InputDecoration(
                labelText: texts['newsstand']
                    [1], // "Enter theme" / "Digite o tema"
                hintText: texts['newsstand'][
                    2], // "e.g., Technology, Sports, Politics" / "ex: Tecnologia, Esportes, Política"
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit_note),
              ),
              maxLines: 3,
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
                      // TODO: Implement magazine generation
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
              child: Text(
                '${texts['newsstand'][6]} $_price ${texts['newsstand'][7]}', // "Buy for X coins" / "Comprar por X moedas"
                style: const TextStyle(fontSize: 18),
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
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Icon(Icons.monetization_on),
              const SizedBox(width: 4),
              Text(
                '$_coins',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
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
