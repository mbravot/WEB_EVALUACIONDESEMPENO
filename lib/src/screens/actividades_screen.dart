import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';

class ActividadesScreen extends StatelessWidget {
  const ActividadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: 'Actividades',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Pantalla de Actividades',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Funcionalidad en desarrollo',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
