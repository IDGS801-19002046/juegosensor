import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recolecta los cubitos',
      home: GyroscopeGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GyroscopeGame extends StatefulWidget {
  @override
  _GyroscopeGameState createState() => _GyroscopeGameState();
}

class _GyroscopeGameState extends State<GyroscopeGame> {
  double x = 0.0;
  double y = 0.0;
  double squareSize = 50.0;
  double moveSpeed = 5.0;
  int currentLevel = 1;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;
  List<Offset> cubePositions = [];

  @override
  void initState() {
    super.initState();
    _initializeLevel();
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        // Escalar las lecturas del giroscopio para que el movimiento sea menos sensible
        double scaledX = event.y * moveSpeed * 0.5;
        double scaledY = event.x * moveSpeed * 0.5;

        // Aplicar suavizado básico para evitar movimientos bruscos
        x += scaledX;
        y += scaledY;

        _checkCubeCollection();

        // Limita el movimiento para que no se salga de la pantalla
        if (x < 0) x = 0;
        if (y < 0) y = 0;
        if (x > MediaQuery.of(context).size.width - squareSize)
          x = MediaQuery.of(context).size.width - squareSize;
        if (y > MediaQuery.of(context).size.height - squareSize)
          y = MediaQuery.of(context).size.height - squareSize;
      });
    });
  }

  @override
  void dispose() {
    _gyroscopeSubscription.cancel();
    super.dispose();
  }

  void _initializeLevel() {
    // Inicializar posiciones de los cubos dependiendo del nivel actual
    List<Offset> positions = [];
    for (int i = 0; i < currentLevel + 1; i++) {
      positions.add(Offset(
        (MediaQuery.of(context).size.width / (currentLevel + 2)) * i,
        (MediaQuery.of(context).size.height / (currentLevel + 2)) * i,
      ));
    }
    cubePositions = positions;

    // Ajustar la velocidad del movimiento en función del nivel
    moveSpeed =
        5.0 + (currentLevel - 1) * 1.0; // Incrementa la velocidad con el nivel
  }

  void _checkCubeCollection() {
    for (int i = 0; i < cubePositions.length; i++) {
      if ((x < cubePositions[i].dx + squareSize &&
          x + squareSize > cubePositions[i].dx &&
          y < cubePositions[i].dy + squareSize &&
          y + squareSize > cubePositions[i].dy)) {
        setState(() {
          cubePositions.removeAt(i);
        });

        if (cubePositions.isEmpty) {
          _showLevelCompleteDialog();
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cube Game - Nivel $currentLevel',
            style: TextStyle(
              color: Colors.white, // Color del texto en blanco
              fontWeight: FontWeight.bold, // Texto en negritas
            )),
        backgroundColor: Color(0xffe1376f),
      ),
      body: Stack(
        children: [
          Positioned(
            left: x,
            top: y,
            child: Container(
              width: squareSize,
              height: squareSize,
              color: Color(0xff24d0ab),
            ),
          ),
          ..._buildCubes(),
        ],
      ),
    );
  }

  List<Widget> _buildCubes() {
    return cubePositions.map((position) {
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: Container(
          width: squareSize,
          height: squareSize,
          color: Color(0xffea97d1),
        ),
      );
    }).toList();
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('¡Nivel Completado!'),
          content: Text('Has recolectado todos los cubos.'),
          actions: [
            TextButton(
              child: Text(
                  currentLevel < 10 ? 'Siguiente Nivel' : 'Reiniciar Juego'),
              onPressed: () {
                setState(() {
                  if (currentLevel < 10) {
                    currentLevel++;
                    _initializeLevel();
                  } else {
                    currentLevel = 1; // Reiniciar a nivel 1
                    _initializeLevel();
                  }
                });
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
          ],
        );
      },
    );
  }
}
