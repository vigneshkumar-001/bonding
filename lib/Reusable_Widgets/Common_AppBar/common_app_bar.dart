import 'package:bonding_app/Bonding_Utils/ColorHandlers/AppColors.dart';
import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool usePaddedLeading;
  final bool Centertittle;
  final List<Widget>? actions;
  final Color? bg;

  const CommonAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.Centertittle = true,
    this.usePaddedLeading = false,
    this.actions,
    this.bg,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppBar(
      backgroundColor: bg ?? theme.scaffoldBackgroundColor,
      centerTitle: Centertittle,
      leading: showBackButton
          ? usePaddedLeading
                ? Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Container(
                      height: 30,
                      width: 30,
                      // decoration: BoxDecoration(
                      //   borderRadius: BorderRadius.circular(20),
                      //   color: isDark ? Colors.black : Colors.white,
                      // ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.arrow_back, color: cs.onSurface),
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.iconTheme.color ?? cs.onSurface,
                    ),
                  )
          : null,
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: cs.onSurface,
        ),
      ),
      iconTheme: theme.iconTheme,
      actions: actions ?? [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
