import 'package:editto_flutter/utilities/language_notifier.dart';
import 'package:editto_flutter/widgets/default_bottom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DefaultBottomAppBar extends ConsumerWidget {
  const DefaultBottomAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map texts = ref.watch(languageNotifierProvider)['texts'];
    return BottomAppBar(
      height: 70,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          DefaultBottomButton(
            text: texts['dashboard'][1],
            icon: Icons.shelves,
            action: () {},
          ),
          const VerticalDivider(),
          DefaultBottomButton(
            text: texts['dashboard'][0],
            icon: Icons.dashboard,
            action: () {},
          ),
        ],
      ),
    );
  }
}
