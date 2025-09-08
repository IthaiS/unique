import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isRegister = false;
  bool _loading = false;
  bool _rememberDevice = true;
  String? _error;

  // Optional owner fields for register
  final _ownerName = TextEditingController();
  final _stateProv = TextEditingController();
  final _country = TextEditingController();

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isRegister) {
        await AuthService.register(
          _email.text.trim(),
          _password.text,
          ownerName:
              _ownerName.text.trim().isEmpty ? null : _ownerName.text.trim(),
          state: _stateProv.text.trim().isEmpty ? null : _stateProv.text.trim(),
          country: _country.text.trim().isEmpty ? null : _country.text.trim(),
        );
      } else {
        await AuthService.login(_email.text.trim(), _password.text);
      }
      if (!mounted) return;
      await AuthService.persistRememberChoice(_rememberDevice);
      Navigator.pushReplacementNamed(context, '/app');
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 12);
    return WillPopScope(onWillPop: () async => false, child: Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: Text(_isRegister ? 'Register' : 'Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email')),
                spacing,
                TextField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true),
                if (_isRegister) ...[
                  spacing,
                  TextField(
                      controller: _ownerName,
                      decoration: const InputDecoration(
                          labelText: 'Account owner name')),
                  spacing,
                  TextField(
                      controller: _stateProv,
                      decoration:
                          const InputDecoration(labelText: 'State/Province')),
                  spacing,
                  TextField(
                      controller: _country,
                      decoration: const InputDecoration(labelText: 'Country')),
                ],
                spacing,
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                spacing,
                CheckboxListTile(
                  value: _rememberDevice,
                  onChanged: (v) => setState(() => _rememberDevice = v ?? true),
                  title: const Text('Remember this device'),
                  contentPadding: EdgeInsets.zero,
                ),
                _loading
                    ? const CircularProgressIndicator()
                    : FilledButton(
                        onPressed: _submit,
                        child: Text(_isRegister ? 'Create account' : 'Login'),
                      ),
                TextButton(
                  onPressed: () => setState(() => _isRegister = !_isRegister),
                  child: Text(_isRegister
                      ? 'Have an account? Sign in'
                      : 'Create a new account'),
                )
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
