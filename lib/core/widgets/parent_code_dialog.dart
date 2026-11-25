import 'dart:async';

import 'package:curio/theme/curio_tokens.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/auth_messages.dart';
import '../../features/auth/presentation/widgets/otp_code_field.dart';
import '../config/supabase_config.dart';
import '../services/auth_service.dart';

/// Emails the signed-in parent a one-time code and asks for it before
/// something protected happens (opening parent areas, deleting the account).
///
/// [onCode] does the protected thing with the code (checks it, or hands it
/// to the server) and throws to show an error. [onPassword], when given,
/// offers "use your password instead" for accounts that have one. Returns
/// true once one of them succeeded.
Future<bool> showParentCodeDialog(
  BuildContext context, {
  required AuthService auth,
  required String title,
  required String message,
  required String confirmLabel,
  required Future<void> Function(String code) onCode,
  Future<void> Function(String password)? onPassword,
  bool destructive = false,
  Key confirmKey = const Key('parent_code_submit'),
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ParentCodeDialog(
        auth: auth,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onCode: onCode,
        onPassword: onPassword,
        destructive: destructive,
        confirmKey: confirmKey,
      ),
    ) ==
    true;

class ParentCodeDialog extends StatefulWidget {
  const ParentCodeDialog({
    required this.auth,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onCode,
    this.onPassword,
    this.destructive = false,
    this.confirmKey = const Key('parent_code_submit'),
    super.key,
  });

  final AuthService auth;
  final String title, message, confirmLabel;
  final Future<void> Function(String code) onCode;
  final Future<void> Function(String password)? onPassword;
  final bool destructive;
  final Key confirmKey;

  /// Supabase lets each address request one email per minute.
  static const resendCooldown = Duration(seconds: 60);

  @override
  State<ParentCodeDialog> createState() => _ParentCodeDialogState();
}

class _ParentCodeDialogState extends State<ParentCodeDialog> {
  static final _codePattern = RegExp(r'^\d{6,10}$');
  final _code = TextEditingController();
  final _password = TextEditingController();
  Timer? _ticker;
  int _resendIn = 0;
  bool _sending = false, _busy = false, _usePassword = false, _hidden = true;
  String? _error, _info;

  @override
  void initState() {
    super.initState();
    _send(first: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _ticker?.cancel();
    setState(() => _resendIn = seconds);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _send({bool first = false}) async {
    if (_sending || _resendIn > 0) return;
    setState(() {
      _sending = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.auth.sendParentCode();
      if (!mounted) return;
      _code.clear();
      if (!first) {
        _info = 'A new code is on its way. Only the newest code will work.';
      }
      _startCooldown(ParentCodeDialog.resendCooldown.inSeconds);
    } catch (error) {
      if (!mounted) return;
      final wait = retryAfterSeconds(error);
      if (wait != null) {
        // A code went out moments ago; that one still works.
        _info = 'We sent a code a moment ago. Use the newest email.';
        _startCooldown(wait);
      } else {
        _error = authErrorMessage(error);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool get _ready => _usePassword
      ? _password.text.isNotEmpty
      : _codePattern.hasMatch(_code.text.trim());

  Future<void> _submit([String? _]) async {
    if (_busy || _sending || !_ready) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_usePassword) {
        await widget.onPassword!(_password.text);
      } else {
        await widget.onCode(_code.text.trim());
      }
      _password.clear();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error =
            error is AuthException && error.code == 'invalid_credentials'
            ? 'That password didn’t match. Please try again.'
            : error is AuthException
            ? authErrorMessage(error)
            : 'We couldn’t confirm that. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = CurioTokens.textSecondary;
    final email = widget.auth.currentEmail ?? 'your email';
    final danger = CurioTokens.wrong;
    return PopScope(
      canPop: !_busy,
      // A plain Dialog rather than AlertDialog: AlertDialog measures its
      // content's intrinsic size, which the code boxes' LayoutBuilder can't
      // report.
      child: Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(widget.message, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 16),
                if (_usePassword)
                  TextField(
                    key: const Key('parent_password'),
                    controller: _password,
                    enabled: !_busy,
                    autofocus: true,
                    obscureText: _hidden,
                    autocorrect: false,
                    enableSuggestions: false,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: _submit,
                    decoration: InputDecoration(
                      labelText: 'Account password',
                      suffixIcon: IconButton(
                        tooltip: _hidden ? 'Show password' : 'Hide password',
                        onPressed: () => setState(() => _hidden = !_hidden),
                        icon: Icon(
                          _hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Text.rich(
                    TextSpan(
                      style: TextStyle(color: muted, height: 1.5),
                      children: [
                        TextSpan(
                          text: _sending && _resendIn == 0
                              ? 'Sending a code to '
                              : 'Enter the code we emailed to ',
                        ),
                        TextSpan(
                          text: email,
                          style: TextStyle(
                            color: CurioTokens.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: _code,
                    builder: (context, _) => OtpCodeField(
                      controller: _code,
                      length: SupabaseConfig.otpLength,
                      hasError: _error != null,
                      enabled: !_busy,
                      onSubmitted: _submit,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _resendIn > 0
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'New code in ${_resendIn ~/ 60}:${(_resendIn % 60).toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        : TextButton.icon(
                            key: const Key('parent_code_resend'),
                            onPressed: _sending || _busy ? null : () => _send(),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Send a new code'),
                          ),
                  ),
                ],
                if (_info != null) ...[
                  const SizedBox(height: 8),
                  Text(_info!, style: TextStyle(color: muted, fontSize: 13)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (widget.onPassword != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('parent_use_password'),
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _usePassword = !_usePassword;
                              _error = null;
                              _info = null;
                            }),
                      child: Text(
                        _usePassword
                            ? 'Use an email code instead'
                            : 'Use your password instead',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ListenableBuilder(
                      listenable: Listenable.merge([_code, _password]),
                      builder: (context, _) => FilledButton(
                        key: widget.confirmKey,
                        style: widget.destructive
                            ? FilledButton.styleFrom(
                                backgroundColor: danger,
                                foregroundColor: Colors.white,
                              )
                            : null,
                        onPressed: _busy || _sending || !_ready
                            ? null
                            : _submit,
                        child: _busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(widget.confirmLabel),
                      ),
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
