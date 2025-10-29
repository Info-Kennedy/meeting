import 'package:chime/common/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final BuildContext context;
  final String title;
  final bool themeIcon;
  final Function()? onBackPressed;
  final List<Widget>? actions;

  const AppbarWidget({super.key, required this.context, required this.title, required this.themeIcon, this.onBackPressed, this.actions});

  @override
  Size get preferredSize => Size(double.infinity, AppBar().preferredSize.height);

  @override
  Widget build(BuildContext context) {
    CommonHelper commonHelper = CommonHelper();
    return AppBar(
      automaticallyImplyLeading: title.isNotEmpty,
      centerTitle: false,
      elevation: title.isNotEmpty ? 2.0 : 0.0,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
      ),
      leading: onBackPressed != null
          ? InkWell(
              onTap: () => onBackPressed != null ? onBackPressed!() : null,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: SvgPicture.asset(commonHelper.getIconPath('ic_back_arrow.svg'), width: 24, height: 24),
              ),
            )
          : null,
      // backgroundColor: Theme.of(context).colorScheme.surface,
      // surfaceTintColor: Theme.of(context).colorScheme.surface,
      // foregroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}
