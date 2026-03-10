import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_provider.dart';
import '../../../../core/theme/purdue_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    // Redirigir al home si ya está autenticado
    ref.listen(authStateProvider, (_, next) {
      if (next.isAuthenticated) context.go('/sampling');
    });

    return Scaffold(
      backgroundColor: PurdueColors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo / título ───────────────────────────────────────────
                const SizedBox(height: 24),
                const _PurdueLogo(),
                const SizedBox(height: 12),
                Text(
                  'Maize Disease Monitor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: PurdueColors.boilermakerGold,
                        letterSpacing: 0.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Purdue University',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: PurdueColors.railwayGray,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // ── Formulario ──────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        style: const TextStyle(color: PurdueColors.white),
                        decoration: _inputDeco('Email', Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu email';
                          if (!v.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscurePass,
                        autofillHints: const [AutofillHints.password],
                        style: const TextStyle(color: PurdueColors.white),
                        decoration: _inputDeco('Contraseña', Icons.lock_outline).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: PurdueColors.railwayGray,
                            ),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 8) return 'Mínimo 8 caracteres';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                // ── Error ───────────────────────────────────────────────────
                if (authState.error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: PurdueColors.riskHigh.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: PurdueColors.riskHigh.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: PurdueColors.riskHigh, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: const TextStyle(color: PurdueColors.riskHigh, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Botón login ─────────────────────────────────────────────
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PurdueColors.boilermakerGold,
                      foregroundColor: PurdueColors.black,
                      disabledBackgroundColor: PurdueColors.agedGold.withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: PurdueColors.black,
                            ),
                          )
                        : const Text('Iniciar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: PurdueColors.railwayGray),
        prefixIcon: Icon(icon, color: PurdueColors.railwayGray),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF3A3A3A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PurdueColors.boilermakerGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: PurdueColors.riskHigh),
        ),
        errorStyle: const TextStyle(color: PurdueColors.riskHigh),
      );

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authProvider.notifier).login(_emailCtrl.text.trim(), _passCtrl.text);
    }
  }
}

class _PurdueLogo extends StatelessWidget {
  const _PurdueLogo();

  @override
  Widget build(BuildContext context) {
    // Usar el logo institucional si se agrega en assets/images/purdue_logo.png
    // Por ahora, representación tipográfica con la P de Purdue
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: PurdueColors.boilermakerGold, width: 2),
          color: const Color(0xFF2A2A2A),
        ),
        child: Center(
          child: Text(
            'P',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: PurdueColors.boilermakerGold,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}
