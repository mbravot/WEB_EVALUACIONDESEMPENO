import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/funciones_service.dart';
import '../services/cargos_service.dart';

/// Pantalla: listado de cargos con buscador; al tocar un cargo se despliegan sus funciones.
/// Si un cargo no tiene funciones, permite agregar. Estilo coherente con evaluador_screen.
class FuncionesScreen extends StatefulWidget {
  const FuncionesScreen({super.key});

  @override
  State<FuncionesScreen> createState() => _FuncionesScreenState();
}

class _FuncionesScreenState extends State<FuncionesScreen> {
  List<Map<String, dynamic>> _cargos = [];
  bool _cargando = true;
  String? _error;
  final TextEditingController _busquedaController = TextEditingController();

  /// Caché: id_cargo -> lista de funciones asignadas.
  final Map<int, List<Map<String, dynamic>>> _funcionesPorCargo = {};
  final Set<int> _cargandoFunciones = {};
  bool _cargandoConteoFunciones = false;
  List<Map<String, dynamic>> _catalogo = [];
  bool _catalogoCargado = false;

  static const List<int> _nivelesPermitidos = [1, 2, 3];

  @override
  void initState() {
    super.initState();
    _cargarCargos();
    _busquedaController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _cargosFiltrados {
    final q = _busquedaController.text.trim().toLowerCase();
    if (q.isEmpty) return _cargos;
    return _cargos.where((c) {
      final nombre = (c['nombre']?.toString() ?? '').toLowerCase();
      final nivel = (c['nivel']?.toString() ?? '').toLowerCase();
      final id = (c['id']?.toString() ?? '').toLowerCase();
      return nombre.contains(q) || nivel.contains(q) || id.contains(q);
    }).toList();
  }

  Future<void> _cargarCargos() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
      _funcionesPorCargo.clear();
    });
    try {
      final lista = await CargosService.getList();
      if (!mounted) return;
      setState(() {
        _cargos = lista;
        _cargando = false;
      });
      _cargarConteoFuncionesParaTodos();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  /// Carga el conteo de funciones de todos los cargos para mostrar en la card sin desplegar.
  Future<void> _cargarConteoFuncionesParaTodos() async {
    if (_cargos.isEmpty) return;
    final ids = <int>[];
    for (final c in _cargos) {
      final id = c['id'] is int ? c['id'] as int : int.tryParse(c['id']?.toString() ?? '');
      if (id != null) ids.add(id);
    }
    if (ids.isEmpty) return;
    if (!mounted) return;
    setState(() => _cargandoConteoFunciones = true);
    try {
      final resultados = await Future.wait(
        ids.map((id) => FuncionesService.getByCargo(id).catchError((_) => <Map<String, dynamic>>[])),
      );
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < ids.length; i++) {
          _funcionesPorCargo[ids[i]] = resultados[i];
        }
        _cargandoConteoFunciones = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoConteoFunciones = false);
    }
  }

  Future<void> _cargarFuncionesDeCargo(int idCargo) async {
    if (_funcionesPorCargo.containsKey(idCargo)) return;
    if (!mounted) return;
    setState(() => _cargandoFunciones.add(idCargo));
    try {
      final lista = await FuncionesService.getByCargo(idCargo);
      if (!mounted) return;
      setState(() {
        _funcionesPorCargo[idCargo] = lista;
        _cargandoFunciones.remove(idCargo);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _funcionesPorCargo[idCargo] = [];
        _cargandoFunciones.remove(idCargo);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _asegurarCatalogo() async {
    if (_catalogoCargado) return;
    try {
      final lista = await FuncionesService.getCatalog();
      if (!mounted) return;
      setState(() {
        _catalogo = lista;
        _catalogoCargado = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _agregarFuncion(int idCargo) async {
    await _asegurarCatalogo();
    if (!mounted) return;
    final funcionesActuales = _funcionesPorCargo[idCargo] ?? [];
    if (_catalogo.isEmpty) {
      final creada = await _mostrarDialogoCrearFuncion(idCargo: idCargo, catalogoVacio: true);
      if (creada != null && mounted) return _agregarFuncion(idCargo);
      return;
    }

    int? idFuncionSeleccionado;
    final idsYaAsignados = funcionesActuales.map((e) => e['id_funcion']).toSet();

    final resultado = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final disponibles = _catalogo.where((f) => !idsYaAsignados.contains(f['id'])).toList();
            return AlertDialog(
              title: const Text('Agregar función al cargo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      value: idFuncionSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Función',
                        border: OutlineInputBorder(),
                      ),
                      items: disponibles
                          .map((f) => DropdownMenuItem<int>(
                                value: f['id'] is int ? f['id'] as int : int.tryParse(f['id'].toString()),
                                child: Text(f['nombre']?.toString() ?? 'ID ${f['id']}'),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => idFuncionSeleccionado = v),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop(); // cierra este diálogo
                        final creada = await _mostrarDialogoCrearFuncion(idCargo: idCargo, catalogoVacio: false);
                        if (creada != null && mounted) _agregarFuncion(idCargo); // reabre para elegir o agregar otra
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('Crear nueva función en el catálogo'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: idFuncionSeleccionado == null ? null : () => Navigator.of(context).pop(idFuncionSeleccionado),
                  child: const Text('Agregar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (resultado == null) return;
    try {
      await FuncionesService.assignToCargo(idCargo, resultado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Función asignada correctamente'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _cargarFuncionesDeCargo(idCargo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _mostrarDialogoCrearFuncion({required int? idCargo, bool catalogoVacio = false}) async {
    final nombreController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool asignarAlCargoActual = idCargo != null;

    final creado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Crear función en el catálogo'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (catalogoVacio)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            'No hay funciones en el catálogo. Crea una para poder asignarla a los cargos.',
                            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ),
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la función',
                          hintText: 'Ej: Gestión de inventarios',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
                      ),
                      if (idCargo != null) ...[
                        const SizedBox(height: 16),
                        CheckboxListTile(
                          value: asignarAlCargoActual,
                          onChanged: (v) => setDialogState(() => asignarAlCargoActual = v ?? true),
                          title: Text('Asignar también a este cargo', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop({
                        'nombre': nombreController.text.trim(),
                        'asignarAlCargoActual': asignarAlCargoActual,
                        'idCargo': idCargo,
                      });
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );

    if (creado == null || creado['nombre'] == null) return null;

    try {
      final item = await FuncionesService.createFuncion(creado['nombre'] as String);
      if (!mounted) return null;
      setState(() => _catalogoCargado = false);
      await _asegurarCatalogo();

      final idFuncion = item['id'] is int ? item['id'] as int : int.tryParse(item['id']?.toString() ?? '');
      final asignarAlCargo = creado['asignarAlCargoActual'] == true && idCargo != null && idFuncion != null;

      if (asignarAlCargo) {
        try {
          await FuncionesService.assignToCargo(idCargo, idFuncion!);
          if (!mounted) return item;
          await _cargarFuncionesDeCargo(idCargo);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Función "${item['nombre']}" creada y asignada al cargo.'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          if (!mounted) return item;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Función creada, pero no se pudo asignar: ${e.toString().replaceFirst('Exception: ', '')}'),
              backgroundColor: AppTheme.warningColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función creada. Puedes asignarla a un cargo al expandir el cargo y pulsar "Agregar función".'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return item;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }
  }

  Future<void> _editarCargo(Map<String, dynamic> cargo) async {
    final id = cargo['id'] is int ? cargo['id'] as int : int.tryParse(cargo['id']?.toString() ?? '');
    if (id == null) return;
    final nombreController = TextEditingController(text: cargo['nombre']?.toString() ?? '');
    final nivelActual = cargo['nivel'] is int
        ? (cargo['nivel'] as int)
        : int.tryParse(cargo['nivel']?.toString() ?? '');
    int? nivelSeleccionado = nivelActual != null && _nivelesPermitidos.contains(nivelActual)
        ? nivelActual
        : null;
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar cargo'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: nivelSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Nivel',
                          border: OutlineInputBorder(),
                        ),
                        items: _nivelesPermitidos
                            .map((n) => DropdownMenuItem<int>(value: n, child: Text('Nivel $n')))
                            .toList(),
                        onChanged: (v) => setDialogState(() => nivelSeleccionado = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop(true);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;

    try {
      await CargosService.update(id, nombre: nombreController.text.trim(), nivel: nivelSeleccionado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargo actualizado'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cargarCargos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _crearCargo() async {
    final nombreController = TextEditingController();
    int? nivelSeleccionado = 1;
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Agregar cargo'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre *',
                          hintText: 'Ej: Administrador de Sistemas',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: nivelSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Nivel',
                          border: OutlineInputBorder(),
                        ),
                        items: _nivelesPermitidos
                            .map((n) => DropdownMenuItem<int>(value: n, child: Text('Nivel $n')))
                            .toList(),
                        onChanged: (v) => setDialogState(() => nivelSeleccionado = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) Navigator.of(context).pop(true);
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;

    try {
      await CargosService.create(nombreController.text.trim(), nivel: nivelSeleccionado);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargo creado correctamente'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cargarCargos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _eliminarCargo(Map<String, dynamic> cargo) async {
    final id = cargo['id'] is int ? cargo['id'] as int : int.tryParse(cargo['id']?.toString() ?? '');
    if (id == null) return;
    final nombre = cargo['nombre']?.toString() ?? 'este cargo';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cargo'),
        content: Text(
          '¿Eliminar "$nombre"? Si tiene funciones asignadas o está en uso, no se podrá eliminar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await CargosService.delete(id);
      if (!mounted) return;
      _funcionesPorCargo.remove(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargo eliminado'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _cargarCargos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _eliminarFuncion(int idCargo, Map<String, dynamic> item) async {
    final nombre = item['nombre_funcion']?.toString() ?? 'esta función';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar asignación'),
        content: Text('¿Quitar "$nombre" de las funciones de este cargo?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final idPivot = item['id'] is int ? item['id'] as int : int.tryParse(item['id'].toString());
    if (idPivot == null) return;

    try {
      await FuncionesService.delete(idPivot);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignación eliminada'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _cargarFuncionesDeCargo(idCargo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtrados = _cargosFiltrados;

    return MainScaffold(
      title: 'Funciones por cargo',
      drawer: null,
      body: RefreshIndicator(
        onRefresh: _cargarCargos,
        color: scheme.primary,
        child: _cargando
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: scheme.primary),
                    const SizedBox(height: 16),
                    Text('Cargando cargos...', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Card(
                        color: scheme.errorContainer,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: scheme.error, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 14)),
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh, color: scheme.onErrorContainer),
                                onPressed: _cargarCargos,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Buscador de cargos (como en evaluador)
                    if (!_cargando && _cargos.isNotEmpty) ...[
                      TextField(
                        controller: _busquedaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar cargos por nombre, nivel o ID...',
                          prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
                          suffixIcon: _busquedaController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: scheme.onSurfaceVariant),
                                  onPressed: () => _busquedaController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_busquedaController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${filtrados.length} de ${_cargos.length} cargos',
                          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                      ] else
                        const SizedBox(height: 16),
                    ],
                    // Botón Agregar cargo entre buscador y lista
                    if (!_cargando) ...[
                      FilledButton.icon(
                        onPressed: _crearCargo,
                        icon: const Icon(Icons.add, size: 22),
                        label: const Text('Agregar cargo'),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (filtrados.isEmpty)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.badge_outlined, size: 64, color: scheme.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text(
                                _cargos.isEmpty ? 'No hay cargos registrados' : 'Ningún cargo coincide con la búsqueda',
                                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...filtrados.map((c) {
                        final id = c['id'] is int ? c['id'] as int : int.tryParse(c['id']?.toString() ?? '');
                        if (id == null) return const SizedBox.shrink();
                        final nombre = c['nombre']?.toString() ?? 'ID $id';
                        final nivel = c['nivel'];
                        final isLoading = _cargandoFunciones.contains(id);
                        final funciones = _funcionesPorCargo[id] ?? [];

                        final tieneDatos = _funcionesPorCargo.containsKey(id);
                        final cantidadFunciones = funciones.length;
                        final indicadorFunciones = tieneDatos
                            ? (cantidadFunciones == 0
                                ? 'Sin funciones asignadas'
                                : cantidadFunciones == 1
                                    ? '1 función asignada'
                                    : '$cantidadFunciones funciones asignadas')
                            : (_cargandoConteoFunciones ? 'Cargando...' : 'Toca para desplegar');

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.primary.withOpacity(0.15),
                              child: Icon(Icons.badge_outlined, color: scheme.primary),
                            ),
                            title: Text(
                              nombre,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (nivel != null)
                                        Text(
                                          'Nivel: $nivel',
                                          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            tieneDatos
                                                ? (cantidadFunciones > 0 ? Icons.check_circle_outline : Icons.info_outline)
                                                : (_cargandoConteoFunciones ? Icons.schedule : Icons.touch_app_outlined),
                                            size: 16,
                                            color: tieneDatos
                                                ? (cantidadFunciones > 0 ? AppTheme.successColor : scheme.onSurfaceVariant)
                                                : scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              indicadorFunciones,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: tieneDatos
                                                    ? (cantidadFunciones > 0 ? AppTheme.successColor : scheme.onSurfaceVariant)
                                                    : scheme.onSurfaceVariant,
                                                fontWeight: cantidadFunciones > 0 ? FontWeight.w500 : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, size: 22, color: scheme.primary),
                                  onPressed: () => _editarCargo(c),
                                  tooltip: 'Editar cargo',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 22, color: scheme.error),
                                  onPressed: () => _eliminarCargo(c),
                                  tooltip: 'Eliminar cargo',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                ),
                              ],
                            ),
                            onExpansionChanged: (expanded) {
                              if (expanded) _cargarFuncionesDeCargo(id);
                            },
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Center(child: CircularProgressIndicator()),
                                      )
                                    : funciones.isEmpty
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              const SizedBox(height: 8),
                                              Text(
                                                'Este cargo no tiene funciones asignadas.',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: scheme.onSurfaceVariant,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 12),
                                              FilledButton.icon(
                                                onPressed: () => _agregarFuncion(id),
                                                icon: const Icon(Icons.add, size: 20),
                                                label: const Text('Agregar función'),
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: scheme.primary,
                                                  foregroundColor: scheme.onPrimary,
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Funciones (${funciones.length})',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: scheme.onSurfaceVariant,
                                                    ),
                                                  ),
                                                  TextButton.icon(
                                                    onPressed: () => _agregarFuncion(id),
                                                    icon: const Icon(Icons.add, size: 18),
                                                    label: const Text('Agregar'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              ...funciones.map((f) {
                                                final nombreFuncion = f['nombre_funcion']?.toString() ?? 'Función ${f['id_funcion']}';
                                                return Card(
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  elevation: 1,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                  child: ListTile(
                                                    dense: true,
                                                    leading: Icon(Icons.work_outline, color: scheme.primary, size: 22),
                                                    title: Text(
                                                      nombreFuncion,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        color: scheme.onSurface,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    trailing: IconButton(
                                                      icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
                                                      onPressed: () => _eliminarFuncion(id, f),
                                                      tooltip: 'Quitar función',
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }
}
