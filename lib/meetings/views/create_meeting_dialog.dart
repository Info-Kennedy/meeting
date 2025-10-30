import 'package:chime/common/common.dart';
import 'package:chime/meetings/bloc/meetings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class CreateMeetingDialog extends StatefulWidget {
  const CreateMeetingDialog({super.key});

  @override
  State<CreateMeetingDialog> createState() => _CreateMeetingDialogState();
}

class _CreateMeetingDialogState extends State<CreateMeetingDialog> {
  final _formKey = GlobalKey<FormBuilderState>();
  final CommonHelper commonHelper = CommonHelper();

  void _handleSubmit(BuildContext context) {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final formData = _formKey.currentState!.value;
      final title = formData['title'] as String;
      final description = formData['description'] as String?;

      context.read<MeetingsBloc>().add(CreateMeeting(title: title, description: description?.isEmpty == true ? null : description));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MeetingsBloc, MeetingsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status && (current.status == MeetingsStatus.meetingCreated || current.status == MeetingsStatus.error),
      listener: (context, state) {
        if (state.status == MeetingsStatus.meetingCreated) {
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
                Text('Create New Meeting', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                InputFormField(
                  name: 'title',
                  labelText: 'Meeting Title',
                  keyboardType: TextInputType.text,
                  validation: [FormBuilderValidators.required(errorText: 'Meeting title is required')],
                ),
                const SizedBox(height: 16),
                InputFormField(
                  name: 'description',
                  labelText: 'Description (Optional)',
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  validation: [],
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
                              : const Text('Create'),
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
