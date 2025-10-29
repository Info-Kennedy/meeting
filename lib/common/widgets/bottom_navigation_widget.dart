import 'package:chime/common/common.dart';
import 'package:chime/home/bloc/home_bloc.dart';
import 'package:chime/home/models/menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logger/logger.dart';

class BottomNavigationWidget extends StatefulWidget {
  final Function(MenuItem) onClick;

  const BottomNavigationWidget({super.key, required this.onClick});

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  final Logger log = Logger();
  final UiHelper uiHelper = UiHelper();

  @override
  Widget build(BuildContext context) {
    final userTheme = Constants.themeConfig.LIGHT;
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        final bottomPadding = uiHelper.getSystemBottomPadding(context);
        final totalHeight = uiHelper.getBottomNavigationHeight(context);

        return Material(
          elevation: 8.0,
          child: Container(
            height: totalHeight,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: state.bottomMenuItems.map((menu) {
                  return _buildNavItem(userTheme, menu, state.selectedBottomMenuItem.id);
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(String userTheme, MenuItem menuItem, String selectedId) {
    CommonHelper commonHelper = CommonHelper();
    return InkWell(
      onTap: () => widget.onClick(menuItem),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.08,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.center,
              height: 25,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: menuItem.id == selectedId ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.4) : Colors.transparent,
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: SvgPicture.asset(
                userTheme == Constants.themeConfig.DARK
                    ? commonHelper.getIconPath(menuItem.id == selectedId ? "${menuItem.icon}.svg" : "${menuItem.icon}_active.svg")
                    : commonHelper.getIconPath(menuItem.id == selectedId ? "${menuItem.icon}_active.svg" : "${menuItem.icon}.svg"),
                height: 20,
                width: 20,
                colorFilter: userTheme == Constants.themeConfig.DARK
                    ? ColorFilter.mode(Theme.of(context).colorScheme.onSurface, BlendMode.srcIn)
                    : null,
                fit: BoxFit.fitWidth,
              ),
            ),
            SizedBox(height: 2),
            Text(
              menuItem.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: menuItem.id == selectedId ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
