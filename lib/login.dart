import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traffic/dashbard.dart';
import 'signup.dart';
import 'forgot.dart';
import 'package:traffic/const/constant.dart';
import 'util/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formSignInKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;
  bool rememberPassword = true;

  void login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (_areFieldsEmpty(email, password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      final errorMessage = _handleFirebaseAuthException(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print("Erreur inattendue: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une erreur inattendue s'est produite")),
      );
    }
  }

  bool _areFieldsEmpty(String email, String password) {
    return email.isEmpty || password.isEmpty;
  }

  String _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "Aucun utilisateur trouvé avec cet e-mail";
      case 'wrong-password':
        return "Mot de passe incorrect";
      case 'invalid-email':
        return "E-mail invalide";
      default:
        print("Erreur Firebase: ${e.code} - ${e.message}");
        return "Une erreur s'est produite";
    }
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            color: selectionColor,
            child: Image.asset(
              'icons/smart_light_management.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formSignInKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 30.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sign in to continue to your account',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildFormFields(isDesktop: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
  return Stack(
    children: [
      Positioned.fill(
        child: Image.asset(
          'icons/smart_light_management.png',
          fit: BoxFit.cover,
        ),
      ),
      Column(
        children: [
          const Expanded(flex: 1, child: SizedBox(height: 10)),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: _buildFormFields(isDesktop: false),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}


  Widget _buildFormFields({bool isDesktop = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isDesktop) ...[
        Center(
    child: const Text(
      'Welcome back',
      style: TextStyle(
        fontSize: 30.0,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
      ),
    ),
  ),
  const SizedBox(height: 40),
],
        
        _buildTextField(
          controller: emailController,
          hint: 'Enter Email',
          icon: Icons.email,
          isPassword: false,
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 20),
      
        _buildTextField(
          controller: passwordController,
          hint: 'Enter Password',
          icon: Icons.lock,
          isPassword: true,
          isDesktop: isDesktop,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: isDesktop ? 450 : double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: rememberPassword,
                    onChanged: (value) {
                      setState(() {
                        rememberPassword = value!;
                      });
                    },
                    activeColor: selectionColor,
                  ),
                  const Text(
                    'Remember me',
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'Forget password?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: selectionColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      Center(
  child: SizedBox(
    width: isDesktop ? 300 : double.infinity,
    height: isDesktop ? 48 : 50,
    child: ElevatedButton(
      onPressed: login,
      style: ElevatedButton.styleFrom(
        backgroundColor: selectionColor,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: const Text(
        'Sign In',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    ),
  ),
      ),

        const SizedBox(height: 25),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account?",
                style: TextStyle(color: Colors.black45),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text(
                  'Sign up',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isDesktop ? 16 : 14,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isPassword,
    required bool isDesktop,
  }) {
    return SizedBox(
      width: isDesktop ? 450 : double.infinity,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: const TextStyle(color: Colors.black),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26),
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: selectionColor, width: 2.0),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Responsive.isDesktop(context)
          ? _buildDesktopLayout()
          : _buildMobileLayout(),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
