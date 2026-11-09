import 'dart:async'; //3.1 importar el timer

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isObscure = true;

  //1.1 Maquina de estados / cerebro de las animaciones
  StateMachineController? _controller;

  //SatetMachineInput
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;
  SMINumber? _numLook;

  //3.2 Timer para detener el recorrido de la mirada
  Timer? _typingDebounce;

  //2.1 Crear variables para FocusNode
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  //4.1 Controllers para manipular lo que escribe el usuario
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  //4.2 Errores para mostrar en la UI
  String? emailError;
  String? passError;

  // 4.3 Validadores
  bool isValidEmail(String email) {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return re.hasMatch(email);
  }

  bool isValidPassword(String pass) {
    // mínimo 8, una mayúscula, una minúscula, un dígito y un especial
    final re = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
    );
    return re.hasMatch(pass);
  }

  // 4.4 Accion del boton
  void _onLogin() {
    //Recortar espacios en blanco accidentales
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;

    //recalcular errores
    final emailTypedError = isValidEmail(email) ? null : 'Email inválido';
    final passTypedError = isValidEmail(email) ? null : 'Password inválido';

    //4.5 Para mostrar el cambio
    setState(() {
      emailError = emailTypedError;
      passError = passTypedError;
    });

    //4.6 Cerrar el teclado y oso neutro
    FocusScope.of(context).unfocus();
    _typingDebounce?.cancel();
    _isChecking?.change(false);
    _isHandsUp?.change(false);
    _numLook?.value = 50.0;

    if (emailTypedError == null && passTypedError == null) {
      _trigSuccess?.fire();
    } else {
      _trigFail?.fire();
    }
  }

  //2.2 Crear los oyentes (listener)
  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus) {
        if (_isHandsUp != null) {
          _isHandsUp?.change(false);
          //3,3 mirada neutral
          _numLook?.value = 50.0;
        }
      }
    });
    _passwordFocus.addListener(() {
      //Manos arriba en password
      _isHandsUp?.change(_passwordFocus.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    //Obtiene el tamano de la pantalla
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(
                  width: screenSize.width,
                  height: 200,
                  child: RiveAnimation.asset(
                    'assets/login-bear-animation.riv',
                    stateMachines: ['Login Machine'],
                    //1,2 vincular la animacion
                    onInit: (artboard) {
                      _controller = StateMachineController.fromArtboard(
                        artboard,
                        'Login Machine',
                      );

                      //1.3 verificardor que unicio bien
                      if (_controller == null) return;
                      //agregar el controlador al escenario
                      artboard.addController(_controller!);
                      //1.4 vincular las variables
                      _isChecking = _controller!.findSMI('isChecking');
                      _isHandsUp = _controller!.findSMI('isHandsUp');
                      _trigSuccess = _controller!.findSMI('trigSuccess');
                      _trigFail = _controller!.findSMI('trigFail');
                      _numLook = _controller!.findSMI('numLook');
                    },
                  ),
                ),
                //Para separar ekementos
                SizedBox(height: 10),
                // Emial
                TextField(
                  //4.8 Vincular el controller
                  controller: emailCtrl,
                  //2.3 asignar el focus al textfield
                  focusNode: _emailFocus,
                  onChanged: (value) {
                    if (_isHandsUp != null) {
                      //     _isHandsUp!.change(false);
                    }
                    if (_isChecking == null) return;

                    _isChecking!.change(true);
                    //3.4 implementar recorrido de mirada
                    //ajustes de limites del 0 al 100
                    //80 medida de calibracion. Clamp es un ranfo
                    final look = (value.length / 80.0 * 100.0)
                        .clamp(0.0, 100.0)
                        .toDouble();
                    _numLook?.value = look;

                    //3.5 debounce: si vuelve a teclear, reinicia el contador
                    _typingDebounce?.cancel();
                    //crear nuevo timer
                    _typingDebounce = Timer(const Duration(seconds: 3), () {
                      //si se cierra la pantalla, termina la ejecucion
                      if (!mounted) return;
                      //Mirada neutra
                      _isChecking?.change(false);
                    });
                  },
                  decoration: InputDecoration(
                    //4.8
                    errorText: emailError,
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      //Para redondear los bordes
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                //Contrasena
                TextField(
                  //4.8 Vincular el controller
                  controller: passCtrl,
                  //2.3 asignar el focus al textfield
                  focusNode: _passwordFocus,
                  onChanged: (value) {
                    if (_isChecking != null) {
                      //    _isChecking!.change(false);
                    }
                    if (_isHandsUp == null) return;

                    _isHandsUp!.change(true);
                  },
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    //4.9 mostrar el error
                    errorText: passError,
                    hintText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        //refrescar el icono
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                      icon: Icon(
                        //If ternario
                        _isObscure ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    border: OutlineInputBorder(
                      //Para redondear los bordes
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: screenSize.width,
                  child: const Text(
                    "Forgot password?",
                    textAlign: TextAlign.right,
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(height: 10),
                MaterialButton(
                  //toma todo el ancho posible
                  minWidth: screenSize.width,
                  height: 50,
                  color: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onPressed: _onLogin,
                  child: Text(
                    "Login",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: screenSize.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Register",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    //3. 5 liberar timer
    _typingDebounce?.cancel();
    super.dispose();
  }
}
