import 'package:chime/app/route_names.dart';
import 'package:chime/common/common.dart';
import 'package:chime/home/bloc/home_bloc.dart';
import 'package:chime/home/models/menu_item.dart';
import 'package:chime/login/bloc/login_bloc.dart';
import 'package:chime/meetings/views/meetings_page.dart';
import 'package:chime/users/views/users_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final log = Logger();
  final PreferencesRepository pref = getIt<PreferencesRepository>();
  final CommonHelper commonHelper = CommonHelper();
  final UiHelper uiHelper = UiHelper();

  @override
  void initState() {
    super.initState();
    log.d("HomePage:::initState::Initializing");
    context.read<HomeBloc>().add(InitializeHomePage());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {
        if (state.status == LoginStatus.loggedOut) {
          RouteHistory.clear();
          context.goNamed(RouteNames.login);
        }
      },
      child: BlocConsumer<HomeBloc, HomeState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == HomeStatus.acccessRevoked) {
            context.read<LoginBloc>().add(Logout());
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: NetworkAwareScaffoldWithBanner(
              body: state.status == HomeStatus.initial
                  ? Center(child: LoaderWidget(loadingText: commonHelper.getStringLabel("initializing")))
                  : Stack(children: [_getBodyContent(state.selectedBottomMenuItem)]),
              bottomNavigationBar: state.showBottomNav
                  ? BottomNavigationWidget(
                      onClick: (menuItem) {
                        context.read<HomeBloc>().add(UpdateBottomNavItem(menuItem: menuItem));
                      },
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _getBodyContent(MenuItem menuItem) {
    switch (menuItem.url) {
      case "meetings":
        return const MeetingsPage();
      case "users":
        return const UsersPage();
      default:
        return Container();
    }
  }
}
