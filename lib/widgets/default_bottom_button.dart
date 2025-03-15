import 'package:flutter/material.dart';

class DefaultBottomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final dynamic action;
  const DefaultBottomButton({
    super.key,
    required this.text,
    required this.icon,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: action,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: .1, vertical: .1),
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                ),
                Text(
                  text,
                  style: Theme.of(context).textTheme.labelSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
