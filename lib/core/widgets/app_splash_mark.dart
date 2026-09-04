// Marca animada exibida durante o carregamento inicial (splash).
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSplashMark extends StatefulWidget {
  const AppSplashMark({super.key});

  @override
  State<AppSplashMark> createState() => _AppSplashMarkState();
}

class _AppSplashMarkState extends State<AppSplashMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _scale,
    child: SvgPicture.asset(
      'assets/images/loading_mark.svg',
      width: 56,
      height: 56,
      semanticsLabel: 'Carregando',
    ),
  );
}