import 'package:flutter/material.dart';

/// A one-field dialog that returns the entered text, or null if cancelled.
/// The dialog owns its controller, so it's disposed only after the closing
/// animation — disposing it right after `showDialog` returns (while the
/// field is still on screen) throws "used after being disposed".
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? message,
  String initialText = '',
  String? label,
  String? hint,
  bool obscure = false,
  int? maxLength,
  String cancelLabel = 'Cancel',
  String? Function(String value)? validator,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextPromptDialog(
    title: title,
    confirmLabel: confirmLabel,
    message: message,
    initialText: initialText,
    label: label,
    hint: hint,
    obscure: obscure,
    maxLength: maxLength,
    cancelLabel: cancelLabel,
    validator: validator,
  ),
);

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.confirmLabel,
    required this.message,
    required this.initialText,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.maxLength,
    required this.cancelLabel,
    required this.validator,
  });

  final String title, confirmLabel, initialText, cancelLabel;
  final String? message, label, hint;
  final bool obscure;
  final int? maxLength;
  final String? Function(String value)? validator;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final _controller = TextEditingController(text: widget.initialText);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final error = widget.validator?.call(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message != null) ...[
          Text(widget.message!),
          const SizedBox(height: 20),
        ],
        TextField(
          controller: _controller,
          autofocus: true,
          obscureText: widget.obscure,
          maxLength: widget.maxLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _confirm(),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            errorText: _error,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(widget.cancelLabel),
      ),
      FilledButton(onPressed: _confirm, child: Text(widget.confirmLabel)),
    ],
  );
}
