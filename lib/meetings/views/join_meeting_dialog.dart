import 'package:chime/common/common.dart';
import 'package:chime/meetings/bloc/meetings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class JoinMeetingDialog extends StatefulWidget {
  final String? initialMeetingId;
  const JoinMeetingDialog({super.key, this.initialMeetingId});

  @override
  State<JoinMeetingDialog> createState() => _JoinMeetingDialogState();
}

class _JoinMeetingDialogState extends State<JoinMeetingDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  final CommonHelper commonHelper = CommonHelper();

  void _handleSubmit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final meetingId = formData['meetingId'] as String;
      final name = formData['name'] as String?;

      if (meetingId.trim().isEmpty) {
        ToastUtil.showErrorToast(context, 'Meeting ID is required');
        return;
      }

      context.read<MeetingsBloc>().add(JoinMeeting(meetingId: meetingId.trim(), name: name?.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeetingsBloc, MeetingsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && (current.status == MeetingsStatus.meetingJoined || current.status == MeetingsStatus.error),
      listener: (context, state) {
        if (state.status == MeetingsStatus.meetingJoined) {
          // Close the dialog - navigation will be handled by MeetingsScreen listener
          Navigator.of(context).pop();
        } else if (state.status == MeetingsStatus.error) {
          ToastUtil.showErrorToast(context, state.message);
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FormBuilder(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.meeting_room, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Join Meeting', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                InputFormField(
                  name: 'meetingId',
                  labelText: 'Meeting ID',
                  keyboardType: TextInputType.text,
                  validation: [FormBuilderValidators.required(errorText: 'Meeting ID is required')],
                  // initialize with provided id and lock when present
                  initialValue: widget.initialMeetingId,
                  enable: widget.initialMeetingId == null,
                ),
                const SizedBox(height: 16),
                InputFormField(
                  name: 'name',
                  labelText: 'Your Name',
                  keyboardType: TextInputType.text,
                  validation: [FormBuilderValidators.required(errorText: 'Name is required')],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    BlocBuilder<MeetingsBloc, MeetingsState>(
                      builder: (context, state) {
                        final isLoading = state.status == MeetingsStatus.loading;
                        return ElevatedButton(
                          onPressed: isLoading ? null : () => _handleSubmit(context),
                          child: isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Join'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
