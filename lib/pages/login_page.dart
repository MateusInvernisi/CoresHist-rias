import 'package:flutter/material.dart';
import 'registro_page.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _servicoAutenticacao = AuthService();

  bool _carregando = false;
  bool _googleCarregando = false;
  String? _error;

  /// Descarta os controladores quando a tela de login é cancelada.
  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  /// Realiza o login usando e-mail e senha
  Future<void> _login() async {
    setState(() {
      _carregando = true;
      _error = null;
    });

    try {
      await _servicoAutenticacao.login(
        _emailController.text.trim(),
        _senhaController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao entrar: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  /// Realiza o login utilizando a conta Google.
  Future<void> _entrarComGoogle() async {
    setState(() {
      _googleCarregando = true;
      _error = null;
    });

    try {
      await _servicoAutenticacao.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao entrar com Google: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _googleCarregando = false);
      }
    }
  }

  /// Navega para a página de registro para criar uma nova conta.
  void _irParaRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegistroPage(),
      ),
    );
  }

  /// Design utilizado nos campos de texto do formulário de login.
  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  /// Interface da tela de login
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
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
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 6,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Cores & Histórias',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entre para registrar histórias no mapa com as cores das suas fotos.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // E-MAIL
                        TextField(
                          controller: _emailController,
                          decoration: _fieldDecoration('E-mail'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // SENHA
                        TextField(
                          controller: _senhaController,
                          decoration: _fieldDecoration('Senha'),
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

                        // BOTÃO ENTRAR (EMAIL/SENHA)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _carregando ? null : _login,
                            child: _carregando
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                                : const Text('Entrar'),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // BOTÃO ENTRAR COM GOOGLE
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                            _googleCarregando ? null : _entrarComGoogle,
                            icon: _googleCarregando
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                                : const Icon(Icons.login),
                            label: Text(
                              _googleCarregando
                                  ? 'Entrando...'
                                  : 'Entrar com Google',
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // LINK PARA REGISTRO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Ainda não tem conta?'),
                            TextButton(
                              onPressed: _irParaRegistro,
                              child: const Text('Criar uma conta'),
                            ),
                          ],
                        ),
                      ],
                    ),
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
