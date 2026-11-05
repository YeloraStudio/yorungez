import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'account_models.dart';

String accountError(AppLocalizations t, Object error) {
  if (error is! AccountFailure) return t.serverError;
  return switch (error.kind) {
    AccountFailureKind.network => t.networkError,
    AccountFailureKind.timeout => t.timeoutError,
    AccountFailureKind.server => t.serverError,
    AccountFailureKind.protocol => t.protocolError,
    AccountFailureKind.unauthorized => t.credentialsError,
    AccountFailureKind.unconfirmed => t.confirmEmailFirst,
    AccountFailureKind.conflict => t.accountConflict,
    AccountFailureKind.validation => t.accountValidation,
    AccountFailureKind.throttled => t.accountThrottled,
    AccountFailureKind.storage => t.secureStorageError,
    AccountFailureKind.changed => t.accountChanged,
  };
}

class LanguagePicker extends ConsumerStatefulWidget {
  const LanguagePicker({super.key});
  @override
  ConsumerState<LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends ConsumerState<LanguagePicker> {
  bool _saving = false;
  int _selectionVersion = 0;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context),
        language = ref.watch(localeProvider).languageCode;
    return DropdownButtonFormField<String>(
      key: ValueKey((language, _selectionVersion)),
      isExpanded: true,
      initialValue: language,
      decoration: InputDecoration(
        labelText: t.language,
        suffixIcon: _saving
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: const [
        DropdownMenuItem(value: 'en', child: Text('English')),
        DropdownMenuItem(value: 'tr', child: Text('Türkçe')),
      ],
      onChanged: _saving
          ? null
          : (code) async {
              if (code == null || code == language) return;
              setState(() => _saving = true);
              try {
                final session = ref.read(accountSessionProvider);
                if (session.state.user != null) {
                  await session.setLanguage(code);
                } else {
                  ref.read(localeProvider.notifier).select(code);
                }
              } on AccountFailure catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        accountError(AppLocalizations.of(context), error),
                      ),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _saving = false;
                    _selectionVersion++;
                  });
                }
              }
            },
    );
  }
}

class AccountMenu extends ConsumerWidget {
  const AccountMenu({super.key, this.closeDrawer});
  final VoidCallback? closeDrawer;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context),
        account = ref.watch(accountStateProvider),
        user = account.user;
    void open(String route) {
      closeDrawer?.call();
      context.push(route);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (user == null) ...[
          FilledButton.icon(
            onPressed: () => open('/account'),
            icon: const Icon(Icons.login),
            label: Text(t.signIn),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => open('/account?mode=register'),
            child: Text(t.createAccount),
          ),
          if (account.restoring)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(t.restoringAccount),
            ),
          if (account.failure != null)
            TextButton(
              onPressed: () => open('/account'),
              child: Text(t.accountRetry),
            ),
        ] else ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(
              user.displayName.isEmpty ? t.myAccount : user.displayName,
            ),
            subtitle: Text(user.email),
            onTap: () => open('/account'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.book_outlined),
            title: Text(t.myNotebook),
            onTap: () => open('/notebook'),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(),
      ],
    );
  }
}
