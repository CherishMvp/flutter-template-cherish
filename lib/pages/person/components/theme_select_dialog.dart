import 'package:com.cherish.mingji/provider/theme_provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThemeSelectorDialog extends StatelessWidget {
  const ThemeSelectorDialog({super.key});
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    int selectedThemeIndex = themeProvider.currentThemeIndex;

    return StatefulBuilder(
      builder: (context, setState) {
        return CupertinoAlertDialog(
          title: const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('主题'),
          ),
          content: Wrap(
            spacing: 6,
            runSpacing: 10,
            children: themeProvider.schemes.map((scheme) {
              final int index = themeProvider.schemes.indexOf(scheme);
              final isSelected = selectedThemeIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedThemeIndex = index;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FlexColorScheme.light(scheme: scheme).primary,
                    border: isSelected
                        ? Border.all(
                            color: Colors.black.withOpacity(0.3), width: 2)
                        : null,
                  ),
                  width: 40,
                  height: 40,
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                themeProvider
                    .setTheme(themeProvider.schemes[selectedThemeIndex]);
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('确认'),
              ),
            ),
          ],
        );
      },
    );
  }
}
