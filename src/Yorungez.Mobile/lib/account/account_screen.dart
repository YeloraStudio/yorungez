import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'account_models.dart';
import 'account_widgets.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, this.initialMode = 'login'});
  final String initialMode;
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController(),
      _last = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController();
  late String _mode;
  String? _profileOwner;
  bool _busy = false, _obscured = true, _emailSent = false;
  Object? _error;
  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  void _change(String mode) {
    setState(() {
      _mode = mode;
      _error = null;
      _emailSent = false;
      _password.clear();
    });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _emailSent = false;
    });
    try {
      final session = ref.read(accountSessionProvider);
      if (session.state.user != null) {
        await session.updateName(_first.text, _last.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
          );
        }
      } else if (_mode == 'register') {
        await session.register(
          _first.text,
          _last.text,
          _email.text,
          _password.text,
        );
        if (mounted) {
          setState(() {
            _emailSent = true;
            _mode = 'login';
            _password.clear();
          });
        }
      } else if (_mode == 'forgot' || _mode == 'resend') {
        await session.requestEmail(_email.text, reset: _mode == 'forgot');
        if (mounted) setState(() => _emailSent = true);
      } else {
        await session.signIn(_email.text, _password.text);
        _password.clear();
      }
    } on AccountFailure catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        state = ref.watch(accountStateProvider),
        user = state.user;
    if (user != null && _profileOwner != user.id) {
      _profileOwner = user.id;
      _first.text = user.firstName ?? '';
      _last.text = user.lastName ?? '';
    } else if (user == null && _profileOwner != null) {
      _profileOwner = null;
      _first.clear();
      _last.clear();
      _email.clear();
      _password.clear();
    }
    final registering = _mode == 'register',
        emailOnly = _mode == 'forgot' || _mode == 'resend';
    final heading = user != null
        ? t.myAccount
        : registering
        ? t.createAccount
        : _mode == 'forgot'
        ? t.forgotPassword
        : _mode == 'resend'
        ? t.resendConfirmation
        : t.signIn;
    String? nameValidator(String? value) =>
        value == null || value.trim().isEmpty || value.trim().length > 100
        ? t.nameRequired
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(heading)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: AutofillGroup(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Yorungez',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      Text(user == null ? t.accountIntro : user.email),
                      const SizedBox(height: 28),
                      if (user == null) ...[
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(
                              value: 'login',
                              label: Text(t.signIn),
                            ),
                            ButtonSegment(
                              value: 'register',
                              label: Text(t.createAccount),
                            ),
                          ],
                          selected: {registering ? 'register' : 'login'},
                          onSelectionChanged: _busy
                              ? null
                              : (values) => _change(values.first),
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (user != null || registering) ...[
                        TextFormField(
                          controller: _first,
                          enabled: !_busy,
                          decoration: InputDecoration(labelText: t.firstName),
                          autofillHints: const [AutofillHints.givenName],
                          textCapitalization: TextCapitalization.words,
                          maxLength: 100,
                          validator: nameValidator,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _last,
                          enabled: !_busy,
                          decoration: InputDecoration(labelText: t.lastName),
                          autofillHints: const [AutofillHints.familyName],
                          textCapitalization: TextCapitalization.words,
                          maxLength: 100,
                          validator: nameValidator,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (user == null) ...[
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: t.emailAddress,
                          ),
                          maxLength: 254,
                          validator: (value) =>
                              value != null &&
                                  RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(value.trim())
                              ? null
                              : t.emailRequired,
                        ),
                        const SizedBox(height: 16),
                        if (!emailOnly) ...[
                          TextFormField(
                            controller: _password,
                            enabled: !_busy,
                            obscureText: _obscured,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: [
                              registering
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            maxLength: 128,
                            decoration: InputDecoration(
                              labelText: t.password,
                              helperText: registering ? t.passwordRules : null,
                              helperMaxLines: 3,
                              suffixIcon: IconButton(
                                tooltip: _obscured
                                    ? t.showPassword
                                    : t.hidePassword,
                                onPressed: () =>
                                    setState(() => _obscured = !_obscured),
                                icon: Icon(
                                  _obscured
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                value != null &&
                                    value.isNotEmpty &&
                                    (!registering || value.length >= 15)
                                ? null
                                : t.passwordRules,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                      if (_emailSent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(t.emailRequestAccepted),
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(
                              accountError(t, _error!),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ),
                      if (state.restoring)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(t.restoringAccount),
                        ),
                      FilledButton(
                        onPressed: _busy || state.restoring ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                user != null
                                    ? t.saveProfile
                                    : emailOnly
                                    ? t.sendEmail
                                    : heading,
                              ),
                      ),
                      const SizedBox(height: 16),
                      if (user == null) ...[
                        TextButton(
                          onPressed: _busy ? null : () => _change('resend'),
                          child: Text(t.resendConfirmation),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy ? null : () => _change('forgot'),
                          child: Text(t.forgotPassword),
                        ),
                        if (state.failure != null) ...[
                          Text(accountError(t, state.failure!)),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () =>
                                      ref.read(accountSessionProvider).retry(),
                            child: Text(t.accountRetry),
                          ),
                        ],
                      ] else ...[
                        const LanguagePicker(),
                        const SizedBox(height: 12),
                        Text(t.accountPreferencesHelp),
                        if (state.failure != null) ...[
                          Text(accountError(t, state.failure!)),
                          TextButton(
                            onPressed: () => ref
                                .read(accountSessionProvider)
                                .refreshProfile(),
                            child: Text(t.accountRetry),
                          ),
                        ],
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () => context.push('/notebook'),
                          icon: const Icon(Icons.book_outlined),
                          label: Text(t.myNotebook),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () async {
                                  setState(() {
                                    _busy = true;
                                    _error = null;
                                  });
                                  try {
                                    final revoked = await ref
                                        .read(accountSessionProvider)
                                        .signOut();
                                    if (context.mounted && !revoked) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(t.signOutLocalOnly),
                                        ),
                                      );
                                    }
                                  } on AccountFailure catch (error) {
                                    if (mounted) setState(() => _error = error);
                                  } finally {
                                    if (mounted) setState(() => _busy = false);
                                  }
                                },
                          child: Text(t.signOut),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(t.backToSky),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
