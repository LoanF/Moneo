import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../state/providers.dart';
import '../../state/services.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';

// ── Champs partagés ──────────────────────────────────────────────────────────
//
// Les `autofillHints` et le regroupement dans un `AutofillGroup` sont ce qui permet
// aux gestionnaires de mots de passe (Proton Pass, 1Password, Bitwarden, trousseau
// iCloud, Google) de remplir les champs et de proposer l'enregistrement.

String? _validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Saisissez votre adresse email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Cette adresse email semble incomplète';
  }
  return null;
}

class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    this.newAccount = false,
    this.readOnly = false,
    this.autofocus = false,
  });
  final TextEditingController controller;

  /// Création de compte : le gestionnaire de mots de passe doit proposer un nouvel identifiant.
  final bool newAccount;
  final bool readOnly;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    readOnly: readOnly,
    autofocus: autofocus,
    keyboardType: TextInputType.emailAddress,
    textInputAction: TextInputAction.next,
    autocorrect: false,
    enableSuggestions: false,
    textCapitalization: TextCapitalization.none,
    autofillHints: readOnly
        ? const [AutofillHints.username]
        : [
            newAccount ? AutofillHints.newUsername : AutofillHints.username,
            AutofillHints.email,
          ],
    validator: readOnly ? null : _validateEmail,
    decoration: const InputDecoration(
      labelText: 'Adresse email',
      hintText: 'vous@exemple.fr',
    ),
  );
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Mot de passe',
    this.isNew = false,
    this.onSubmitted,
    this.helper,
  });
  final TextEditingController controller;
  final String label;

  /// Nouveau mot de passe : le gestionnaire peut en générer un et l'enregistrer.
  final bool isNew;
  final VoidCallback? onSubmitted;
  final String? helper;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: !_visible,
    keyboardType: TextInputType.visiblePassword,
    textInputAction: TextInputAction.done,
    autocorrect: false,
    enableSuggestions: false,
    autofillHints: [
      widget.isNew ? AutofillHints.newPassword : AutofillHints.password,
    ],
    onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    validator: (value) {
      if (value == null || value.isEmpty) return 'Saisissez votre mot de passe';
      if (widget.isNew && value.length < 8) {
        return 'Choisissez au moins 8 caractères';
      }
      return null;
    },
    decoration: InputDecoration(
      labelText: widget.label,
      helperText: widget.helper,
      suffixIcon: IconButton(
        onPressed: () => setState(() => _visible = !_visible),
        icon: Icon(
          _visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        ),
        tooltip: _visible
            ? 'Masquer le mot de passe'
            : 'Afficher le mot de passe',
      ),
    ),
  );
}

class CodeField extends StatelessWidget {
  const CodeField({super.key, required this.controller, this.onCompleted});
  final TextEditingController controller;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    autofillHints: const [AutofillHints.oneTimeCode],
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(6),
    ],
    style: context.text.headlineSmall?.copyWith(
      letterSpacing: 8,
      fontFeatures: tabular,
    ),
    textAlign: TextAlign.center,
    onChanged: (value) {
      if (value.length == 6) onCompleted?.call();
    },
    validator: (value) =>
        (value?.length ?? 0) == 6 ? null : 'Le code contient 6 chiffres',
    decoration: const InputDecoration(
      labelText: 'Code à 6 chiffres',
      counterText: '',
    ),
  );
}

/// Mise en page commune des écrans d'authentification.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showLogo = false,
    this.leading,
  });
  final String title, subtitle;
  final List<Widget> children;
  final bool showLogo;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      leading: leading,
      automaticallyImplyLeading: leading == null,
    ),
    body: Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: GlowBackdrop(height: 420),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(Gap.page, 0, Gap.page, Gap.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLogo) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 76,
                          height: 76,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.moneo.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: context.moneo.line),
                            boxShadow: [
                              BoxShadow(
                                color: context.moneo.glow,
                                blurRadius: 40,
                                offset: const Offset(0, 16),
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          child: SvgPicture.asset(
                            'assets/images/Moneo.svg',
                            semanticsLabel: 'Moneo',
                          ),
                        ),
                      ),
                      const SizedBox(height: Gap.xl),
                    ],
                    Semantics(
                      header: true,
                      child: Text(title, style: context.text.headlineMedium),
                    ),
                    const SizedBox(height: Gap.sm),
                    Text(
                      subtitle,
                      style: context.text.bodyLarge?.copyWith(
                        color: context.moneo.inkSoft,
                      ),
                    ),
                    const SizedBox(height: Gap.xl),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Message d'erreur affiché au-dessus du formulaire, annoncé aux lecteurs d'écran.
class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: Gap.lg),
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: context.scheme.errorContainer,
          borderRadius: BorderRadius.circular(Radii.field),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.error_outline_rounded,
                color: context.scheme.onErrorContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: Gap.sm),
            Expanded(
              child: Text(
                message!,
                style: TextStyle(color: context.scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logique commune : validation, état d'envoi, erreur.
mixin _FormLogic<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  bool busy = false;
  String? error;

  Future<void> submit(Future<void> Function() action) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class _GoogleButton extends ConsumerStatefulWidget {
  const _GoogleButton({required this.onError});
  final ValueChanged<String> onError;

  @override
  ConsumerState<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends ConsumerState<_GoogleButton> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final token = await ref.read(googleAuthProvider).idToken();
      if (token != null) await ref.read(sessionProvider.notifier).google(token);
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: _busy ? null : _signIn,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: SvgPicture.asset(
            'assets/images/google_logo.svg',
            width: 20,
            height: 20,
          ),
        ),
        const SizedBox(width: Gap.md),
        const Flexible(
          child: Text('Continuer avec Google', overflow: TextOverflow.ellipsis),
        ),
      ],
    ),
  );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Gap.lg),
    child: Row(
      children: [
        const Expanded(child: Perforation()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          child: Text(
            'ou',
            style: context.text.bodyMedium?.copyWith(
              color: context.moneo.inkSoft,
            ),
          ),
        ),
        const Expanded(child: Perforation()),
      ],
    ),
  );
}

// ── Connexion ────────────────────────────────────────────────────────────────

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> with _FormLogic {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() => submit(() async {
    await ref
        .read(sessionProvider.notifier)
        .login(_email.text.trim(), _password.text);
    // Signale au système que la saisie a réussi : il peut proposer d'enregistrer l'identifiant.
    TextInput.finishAutofillContext();
  });

  @override
  Widget build(BuildContext context) => AuthScaffold(
    showLogo: true,
    title: 'Bon retour',
    subtitle: 'Connectez-vous pour retrouver vos comptes.',
    children: [
      FormError(error),
      Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            children: [
              EmailField(controller: _email),
              const SizedBox(height: Gap.md),
              PasswordField(controller: _password, onSubmitted: _login),
            ],
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () =>
              context.push('/forgot-password', extra: _email.text.trim()),
          child: const Text('Mot de passe oublié ?'),
        ),
      ),
      const SizedBox(height: Gap.sm),
      SubmitButton(label: 'Se connecter', busy: busy, onPressed: _login),
      const _OrDivider(),
      _GoogleButton(onError: (message) => setState(() => error = message)),
      const SizedBox(height: Gap.xl),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Pas encore de compte ?', style: context.text.bodyMedium),
          TextButton(
            onPressed: () => context.push('/register'),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    ],
  );
}

// ── Inscription ──────────────────────────────────────────────────────────────

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> with _FormLogic {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() => submit(() async {
    await ref
        .read(sessionProvider.notifier)
        .register(_name.text.trim(), _email.text.trim(), _password.text);
    TextInput.finishAutofillContext();
  });

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: 'Créer un compte',
    subtitle: 'Trois champs, et vous saisissez votre première opération.',
    children: [
      FormError(error),
      Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                validator: (v) => (v?.trim().length ?? 0) >= 2
                    ? null
                    : 'Indiquez votre prénom (2 lettres au moins)',
                decoration: const InputDecoration(labelText: 'Prénom'),
              ),
              const SizedBox(height: Gap.md),
              EmailField(controller: _email, newAccount: true),
              const SizedBox(height: Gap.md),
              // Un seul champ, avec bouton « afficher » : pas de confirmation à retaper,
              // et le gestionnaire de mots de passe peut proposer le sien.
              PasswordField(
                controller: _password,
                isNew: true,
                onSubmitted: _register,
                helper:
                    '8 caractères au moins. Une phrase fonctionne très bien.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: Gap.xl),
      SubmitButton(label: 'Créer mon compte', busy: busy, onPressed: _register),
      const _OrDivider(),
      _GoogleButton(onError: (message) => setState(() => error = message)),
    ],
  );
}

// ── Mot de passe oublié ──────────────────────────────────────────────────────

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});
  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage>
    with _FormLogic {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _send() => submit(() async {
    await ref.read(apiProvider).forgotPassword(_email.text.trim());
    if (mounted) setState(() => _codeSent = true);
  });

  Future<void> _reset() => submit(() async {
    final email = _email.text.trim();
    await ref
        .read(apiProvider)
        .resetPassword(email, _code.text, _password.text);
    // Le nouveau mot de passe est enregistré par le gestionnaire, puis on connecte directement.
    TextInput.finishAutofillContext();
    await ref.read(sessionProvider.notifier).login(email, _password.text);
  });

  @override
  Widget build(BuildContext context) => AuthScaffold(
    title: _codeSent ? 'Nouveau mot de passe' : 'Mot de passe oublié',
    subtitle: _codeSent
        ? 'Si un compte existe pour ${_email.text.trim()}, un code vient de lui être envoyé. Il est valable 15 minutes.'
        : 'Indiquez votre adresse : nous vous envoyons un code pour choisir un nouveau mot de passe.',
    children: [
      FormError(error),
      Form(
        key: formKey,
        child: AutofillGroup(
          child: Column(
            children: [
              // L'adresse reste visible à la seconde étape : le gestionnaire sait quel identifiant mettre à jour.
              EmailField(
                controller: _email,
                readOnly: _codeSent,
                autofocus: !_codeSent && widget.initialEmail.isEmpty,
              ),
              if (_codeSent) ...[
                const SizedBox(height: Gap.md),
                CodeField(controller: _code),
                const SizedBox(height: Gap.md),
                PasswordField(
                  controller: _password,
                  label: 'Nouveau mot de passe',
                  isNew: true,
                  onSubmitted: _reset,
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: Gap.xl),
      SubmitButton(
        label: _codeSent ? 'Changer le mot de passe' : 'Recevoir un code',
        busy: busy,
        onPressed: _codeSent ? _reset : _send,
      ),
      if (_codeSent)
        TextButton(
          onPressed: busy ? null : _send,
          child: const Text('Renvoyer un code'),
        ),
    ],
  );
}

// ── Vérification de l'adresse ────────────────────────────────────────────────

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage>
    with _FormLogic {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() => submit(() async {
    final user = await ref.read(apiProvider).verifyEmail(_code.text);
    ref.read(sessionProvider.notifier).setUser(user);
  });

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(sessionProvider).value?.email ?? '';
    return AuthScaffold(
      leading: IconButton(
        onPressed: () => ref.read(sessionProvider.notifier).logout(),
        icon: const Icon(Icons.logout_rounded),
        tooltip: 'Se déconnecter',
      ),
      title: 'Vérifiez votre adresse',
      subtitle:
          'Un code à 6 chiffres a été envoyé à $email. Il est valable 24 heures.',
      children: [
        FormError(error),
        Form(
          key: formKey,
          child: AutofillGroup(
            child: CodeField(controller: _code, onCompleted: _verify),
          ),
        ),
        const SizedBox(height: Gap.xl),
        SubmitButton(label: 'Valider', busy: busy, onPressed: _verify),
        TextButton(
          onPressed: busy
              ? null
              : () => guard(
                  context,
                  () => ref.read(apiProvider).resendVerification(),
                  success: 'Nouveau code envoyé à $email',
                ),
          child: const Text('Renvoyer le code'),
        ),
      ],
    );
  }
}
