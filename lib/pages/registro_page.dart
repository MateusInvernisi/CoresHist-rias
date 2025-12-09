import 'package:flutter/material.dart';

import '../services/auth_service.dart';

/// Página para criação de uma nova conta.
class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPagePageState();
}

/// Responsável por gerenciar formulário e validações.
class _RegistroPagePageState extends State<RegistroPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _servicoAutenticacao  = AuthService();

  bool _carregando = false;
  String? _error;

  /// Descarta os controladores de texto quando cancelado.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Design utilizado nos campos do formulário de registro.
  InputDecoration _fieldDecoration(String rotulo) {
    return InputDecoration(
      labelText: rotulo,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  /// Criação de conta.
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
      _carregando = true;
    });

    try {
      await _servicoAutenticacao .register(email, password);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao criar conta: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  /// Volta para a tela de login.
  void _VoltarParaLogin() {
    Navigator.pop(context);
  }

  /// Interface de registro com formulário e botão de criação de conta.
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
                          .headlineSmall
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
                        onPressed: _carregando ? null : _register,
                        child: _carregando
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
                      onPressed: _VoltarParaLogin,
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
