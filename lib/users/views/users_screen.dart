import 'package:cached_network_image/cached_network_image.dart';
import 'package:chime/common/common.dart';
import 'package:chime/users/bloc/users_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final log = Logger();
  final CommonHelper commonHelper = CommonHelper();

  @override
  void initState() {
    super.initState();
    log.d("UsersScreen:::initState::Initializing");
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersBloc, UsersState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == UsersStatus.error) {
          ToastUtil.showErrorToast(context, state.message);
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            // appBar: AppbarWidget(context: context, themeIcon: false, title: commonHelper.getStringLabelSync("users")),
            body: state.status == UsersStatus.loading || state.status == UsersStatus.initial
                ? Center(child: LoaderWidget(loadingText: commonHelper.getStringLabelSync("loading_text")))
                : state.users.isEmpty
                ? Center(child: Text(commonHelper.getStringLabelSync("no_data_found")))
                : ListView.separated(
                    itemCount: state.users.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      final String name = user['name'] ?? '';
                      final String? avatar = user['avatar'];
                      final DateTime? createdAt = user['createdAt'] != null ? DateTime.tryParse(user['createdAt']) : null;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          foregroundImage: avatar != null && avatar.isNotEmpty ? CachedNetworkImageProvider(avatar) : null,
                          child: avatar == null || avatar.isEmpty ? Icon(Icons.person, color: Colors.grey[500]) : null,
                        ),
                        title: Text(name, style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: createdAt != null
                            ? Text(
                                'Joined: ${createdAt.year}-${createdAt.month.toString().padLeft(2, "0")}-${createdAt.day.toString().padLeft(2, "0")}',
                                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                              )
                            : null,
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        onTap: () {
                          // Optionally handle tap on user
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
