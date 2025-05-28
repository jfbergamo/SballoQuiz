import 'package:flutter/material.dart';
import 'package:html/dom.dart' as parser;

class SballoButton extends StatelessWidget {
    
    final String text;
    final Function() action;
    final Color primary;
    final Color background;

    const SballoButton({super.key, required this.text, required this.action, required this.primary, required this.background});

    @override
    Widget build(BuildContext context) {
        return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18),
                    backgroundColor: background,
                    foregroundColor: primary
                ),
                child: Text(parser.DocumentFragment.html(text).text.toString())
            )
        );
    }

}