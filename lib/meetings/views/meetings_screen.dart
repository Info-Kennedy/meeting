import 'package:chime/common/common.dart';
import 'package:chime/meetings/bloc/meetings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  final log = Logger();
  final CommonHelper commonHelper = CommonHelper();

  @override
  void initState() {
    super.initState();
    log.d("MeetingsScreen:::initState::Initializing");
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MeetingsBloc, MeetingsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == MeetingsStatus.error) {
          ToastUtil.showErrorToast(context, state.message);
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            // appBar: AppbarWidget(context: context, themeIcon: false, title: commonHelper.getStringLabel("users")),
            body: state.status == MeetingsStatus.loading || state.status == MeetingsStatus.initial
                ? Center(child: LoaderWidget(loadingText: commonHelper.getStringLabel("loading_text")))
                : state.meetings.isEmpty
                ? Center(child: Text(commonHelper.getStringLabel("no_data_found")))
                : ListView.separated(
                    itemCount: state.meetings.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
                    itemBuilder: (context, index) {
                      final meeting = state.meetings[index];
                      final String title = meeting['title'] ?? '';
                      final String? description = meeting['description'];
                      return ListTile(
                        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: description != null ? Text(description, style: TextStyle(color: Colors.grey[700], fontSize: 12)) : null,
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
