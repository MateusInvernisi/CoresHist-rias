import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    setState(() {
      _error = null;
    });

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() {
        _error = 'Preencha todos os campos.';
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _error = 'As senhas não coincidem.';
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // ajuste o nome deste método se no seu AuthService for diferente
      await _authService.register(email, password);

      if (!mounted) return;

      // Depois de registrar, volta pra tela de login
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao criar conta: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _goBackToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container
        (
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/fundo.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.85),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: SafeArea(
          minimum: const EdgeInsets.all(24),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'Cores & Histórias',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crie sua conta para começar a compartilhar stories pela cidade.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // E-MAIL
                    TextField(
                      controller: _emailController,
                      decoration: _fieldDecoration('E-mail'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // SENHA
                    TextField(
                      controller: _passwordController,
                      decoration: _fieldDecoration('Senha'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    // CONFIRMAR SENHA
                    TextField(
                      controller: _confirmController,
                      decoration: _fieldDecoration('Confirmar senha'),
                      obscureText: true,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // BOTÃO REGISTRAR
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _register,
                        child: _loading
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                          CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Registrar'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // VOLTAR PARA LOGIN
                    TextButton(
                      onPressed: _goBackToLogin,
                      child: const Text('Já tenho uma conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
