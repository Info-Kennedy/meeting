import 'package:chime/common/common.dart';
import 'package:chime/meetings/bloc/meetings_bloc.dart';
import 'package:chime/meetings/views/create_meeting_dialog.dart';
import 'package:chime/meetings/views/join_meeting_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  void _showCreateMeetingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(value: context.read<MeetingsBloc>(), child: const CreateMeetingDialog()),
    );
  }

  void _showJoinMeetingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(value: context.read<MeetingsBloc>(), child: const JoinMeetingDialog()),
    );
  }

  void _showJoinMeetingWithId(BuildContext context, String meetingId) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<MeetingsBloc>(),
        child: JoinMeetingDialog(initialMeetingId: meetingId),
      ),
    );
  }

  // Removed unused _joinMeeting; joins are handled via dialogs and navigation

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MeetingsBloc, MeetingsState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == MeetingsStatus.error) {
          ToastUtil.showErrorToast(context, state.message);
        } else if (state.status == MeetingsStatus.meetingCreated || state.status == MeetingsStatus.meetingJoined) {
          // Navigate to active meeting screen
          if (state.currentMeeting != null) {
            final meeting = state.currentMeeting!;
            log.d("MeetingsScreen:::Navigating to active meeting: ${meeting.roomName}, accessToken: ${meeting.accessToken?.substring(0, 20)}...");

            // Use WidgetsBinding to ensure we're not navigating during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                context.push('/meetings/active', extra: meeting);
                log.d("MeetingsScreen:::Navigation pushed successfully");
              } catch (e) {
                log.e("MeetingsScreen:::Navigation error: $e");
                ToastUtil.showErrorToast(context, 'Failed to navigate to meeting: $e');
              }
            });
          } else {
            log.w("MeetingsScreen:::No current meeting available for navigation");
          }
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Meetings'),
              actions: [
                IconButton(icon: const Icon(Icons.meeting_room), tooltip: 'Join Meeting', onPressed: () => _showJoinMeetingDialog(context)),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () {
                    context.read<MeetingsBloc>().add(const RefreshMeetings());
                  },
                ),
              ],
            ),
            floatingActionButton: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(heroTag: 'join', onPressed: () => _showJoinMeetingDialog(context), child: const Icon(Icons.login)),
                const SizedBox(height: 8),
                FloatingActionButton(heroTag: 'create', onPressed: () => _showCreateMeetingDialog(context), child: const Icon(Icons.add)),
              ],
            ),
            body: state.status == MeetingsStatus.loading || state.status == MeetingsStatus.initial
                ? Center(child: LoaderWidget(loadingText: commonHelper.getStringLabelSync("loading_text")))
                : state.meetings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_call_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(commonHelper.getStringLabelSync("no_data_found"), style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateMeetingDialog(context),
                          icon: const Icon(Icons.add),
                          label: Text(commonHelper.getStringLabelSync("create_your_first_meeting")),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      context.read<MeetingsBloc>().add(const RefreshMeetings());
                    },
                    child: ListView.separated(
                      itemCount: state.meetings.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade300),
                      itemBuilder: (context, index) {
                        final meeting = state.meetings[index];
                        final String title = meeting['title'] ?? '';
                        final String? description = meeting['description'];
                        final String? meetingId = meeting['id'] ?? meeting['meetingId'];
                        final bool isActive = meeting['isActive'] ?? false;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: Icon(Icons.video_call, color: Theme.of(context).colorScheme.primary),
                          ),
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (description != null) Text(description, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                              if (isActive)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: () {
                            if (meetingId != null) {
                              _showJoinMeetingWithId(context, meetingId);
                            }
                          },
                        );
                      },
                    ),
                  ),
          ),
        );
      },
    );
  }
}
