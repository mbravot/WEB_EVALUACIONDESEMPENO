import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/main_scaffold.dart';
import '../services/competencias_service.dart';
import '../services/cargos_service.dart';

/// Pantalla: listado de cargos con buscador; al expandir se muestran las competencias del nivel del cargo.
/// Las competencias vienen de rrhh_dim_competencianivel (según nivel del cargo), no se asignan manualmente.
class CompetenciasScreen extends StatefulWidget {
  const CompetenciasScreen({super.key});

  @override
  State<CompetenciasScreen> createState() => _CompetenciasScreenState();
}

class _CompetenciasScreenState extends State<CompetenciasScreen> {
  List<Map<String, dynamic>> _cargos = [];
  bool _cargando = true;
  String? _error;
  final TextEditingController _busquedaController = TextEditingController();

  /// Competencias del nivel del cargo (rrhh_dim_competencianivel donde id_nivel = cargo.nivel). Solo lectura.
  final Map<int, List<Map<String, dynamic>>> _disponiblesPorCargo = {};
  final Set<int> _cargandoCompetencias = {};
  bool _cargandoConteoCompetencias = false;

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
      _disponiblesPorCargo.clear();
    });
    try {
      final lista = await CargosService.getList();
      if (!mounted) return;
      setState(() {
        _cargos = lista;
        _cargando = false;
      });
      _cargarConteoCompetenciasParaTodos();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _cargando = false;
      });
    }
  }

  Future<void> _cargarConteoCompetenciasParaTodos() async {
    if (_cargos.isEmpty) return;
    final ids = <int>[];
    for (final c in _cargos) {
      final id = c['id'] is int ? c['id'] as int : int.tryParse(c['id']?.toString() ?? '');
      if (id != null) ids.add(id);
    }
    if (ids.isEmpty) return;
    if (!mounted) return;
    setState(() => _cargandoConteoCompetencias = true);
    try {
      final resultados = await Future.wait(
        ids.map((id) => CompetenciasService.getDisponiblesByCargo(id).catchError((_) => <Map<String, dynamic>>[])),
      );
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < ids.length; i++) {
          _disponiblesPorCargo[ids[i]] = resultados[i];
        }
        _cargandoConteoCompetencias = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoConteoCompetencias = false);
    }
  }

  Future<void> _cargarCompetenciasDeCargo(int idCargo) async {
    if (_disponiblesPorCargo.containsKey(idCargo)) return;
    if (!mounted) return;
    setState(() => _cargandoCompetencias.add(idCargo));
    try {
      final disponibles = await CompetenciasService.getDisponiblesByCargo(idCargo).catchError((_) => <Map<String, dynamic>>[]);
      if (!mounted) return;
      setState(() {
        _disponiblesPorCargo[idCargo] = disponibles;
        _cargandoCompetencias.remove(idCargo);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _disponiblesPorCargo[idCargo] = [];
        _cargandoCompetencias.remove(idCargo);
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

  Future<void> _crearCompetenciaCatalogo() async {
    final nombreController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar competencia al catálogo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nombreController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej: Trabajo en equipo',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre' : null,
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
      ),
    );
    if (ok != true) return;
    try {
      await CompetenciasService.create(nombreController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Competencia creada. Define niveles en "Gestionar catálogo" para asignarlas a cargos.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  Future<void> _gestionarCatalogo() async {
    List<Map<String, dynamic>> catalogo = [];
    try {
      catalogo = await CompetenciasService.getCatalog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => _CatalogoCompetenciasDialog(
        competencias: catalogo,
        onCrear: () async {
          Navigator.of(context).pop();
          await _crearCompetenciaCatalogo();
        },
        onActualizar: () async {
          Navigator.of(context).pop();
          _gestionarCatalogo();
        },
      ),
    );
  }

  /// Contenido expandido: lista de solo lectura de las competencias del nivel (rrhh_dim_competencianivel).
  Widget _buildContenidoCompetenciasCargo(
    BuildContext context,
    ColorScheme scheme,
    int idCargo,
    Map<String, dynamic> cargo,
  ) {
    final disponibles = _disponiblesPorCargo[idCargo] ?? [];

    if (disponibles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Este cargo no tiene nivel o no hay competencias definidas para su nivel en el catálogo. '
            'Asigne nivel en "Funciones del cargo" y defina las competencias en "Gestionar catálogo".',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _disponiblesPorCargo.remove(idCargo));
              _cargarCompetenciasDeCargo(idCargo);
            },
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Competencias del nivel (${disponibles.length})',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        ...disponibles.map((disp) {
          final nombreDisp = disp['nombre_competencia']?.toString() ?? disp['nombre']?.toString() ?? 'Competencia ${disp['id']}';
          final defDisp = disp['definicion']?.toString();
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: ListTile(
              dense: true,
              leading: Icon(Icons.psychology_outlined, color: scheme.primary, size: 22),
              title: Text(
                nombreDisp,
                style: TextStyle(fontWeight: FontWeight.w500, color: scheme.onSurface, fontSize: 14),
              ),
              subtitle: defDisp != null && defDisp.isNotEmpty
                  ? Text(
                      defDisp,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtrados = _cargosFiltrados;

    return MainScaffold(
      title: 'Competencias por cargo',
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
                    if (!_cargando) ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _crearCompetenciaCatalogo,
                              icon: const Icon(Icons.add, size: 22),
                              label: const Text('Agregar competencia'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton.tonalIcon(
                            onPressed: _gestionarCatalogo,
                            icon: const Icon(Icons.apps_outlined, size: 20),
                            label: const Text('Gestionar catálogo'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
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
                              Icon(Icons.psychology_outlined, size: 64, color: scheme.onSurfaceVariant),
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
                        final isLoading = _cargandoCompetencias.contains(id);
                        final disponibles = _disponiblesPorCargo[id] ?? [];
                        final tieneDatos = _disponiblesPorCargo.containsKey(id);
                        final cantidad = disponibles.length;
                        final indicador = tieneDatos
                            ? (cantidad == 0
                                ? 'Sin competencias para este nivel'
                                : cantidad == 1
                                    ? '1 competencia (según nivel)'
                                    : '$cantidad competencias (según nivel)')
                            : (_cargandoConteoCompetencias ? 'Cargando...' : 'Toca para desplegar');

                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: scheme.primary.withOpacity(0.15),
                              child: Icon(Icons.psychology_outlined, color: scheme.primary),
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
                                                ? (cantidad > 0 ? Icons.check_circle_outline : Icons.info_outline)
                                                : (_cargandoConteoCompetencias ? Icons.schedule : Icons.touch_app_outlined),
                                            size: 16,
                                            color: tieneDatos
                                                ? (cantidad > 0 ? AppTheme.successColor : scheme.onSurfaceVariant)
                                                : scheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              indicador,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: tieneDatos
                                                    ? (cantidad > 0 ? AppTheme.successColor : scheme.onSurfaceVariant)
                                                    : scheme.onSurfaceVariant,
                                                fontWeight: cantidad > 0 ? FontWeight.w500 : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onExpansionChanged: (expanded) {
                              if (expanded) _cargarCompetenciasDeCargo(id);
                            },
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Center(child: CircularProgressIndicator()),
                                      )
                                    : _buildContenidoCompetenciasCargo(context, scheme, id, c),
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

/// Diálogo para listar competencias del catálogo, editar, eliminar y definir niveles.
class _CatalogoCompetenciasDialog extends StatefulWidget {
  final List<Map<String, dynamic>> competencias;
  final VoidCallback onCrear;
  final VoidCallback onActualizar;

  const _CatalogoCompetenciasDialog({
    required this.competencias,
    required this.onCrear,
    required this.onActualizar,
  });

  @override
  State<_CatalogoCompetenciasDialog> createState() => _CatalogoCompetenciasDialogState();
}

class _CatalogoCompetenciasDialogState extends State<_CatalogoCompetenciasDialog> {
  late List<Map<String, dynamic>> _lista;

  @override
  void initState() {
    super.initState();
    _lista = List.from(widget.competencias);
  }

  int? _id(Map<String, dynamic> e) {
    final v = e['id'];
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '');
  }

  Future<void> _editar(Map<String, dynamic> comp) async {
    final id = _id(comp);
    if (id == null) return;
    final c = TextEditingController(text: comp['nombre']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar competencia'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.of(ctx).pop(true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CompetenciasService.update(id, c.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Competencia actualizada'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
      );
      widget.onActualizar();
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

  Future<void> _eliminar(Map<String, dynamic> comp) async {
    final id = _id(comp);
    if (id == null) return;
    final nombre = comp['nombre']?.toString() ?? 'esta competencia';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar competencia'),
        content: Text('¿Eliminar "$nombre"? No se podrá si tiene niveles definidos.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await CompetenciasService.delete(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Competencia eliminada'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
      );
      setState(() => _lista.removeWhere((e) => _id(e) == id));
      widget.onActualizar();
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

  Future<void> _definirNiveles(Map<String, dynamic> comp) async {
    final idCompetencia = _id(comp);
    if (idCompetencia == null) return;
    const niveles = [1, 2, 3];
    List<Map<String, dynamic>> existentes = [];
    try {
      existentes = await CompetenciasService.getNiveles(idCompetencia: idCompetencia);
    } catch (_) {}
    final definiciones = <int, String>{};
    final idsNivel = <int, int>{}; // id_nivel -> id (competencianivel)
    for (final e in existentes) {
      final idN = e['id_nivel'] is int ? e['id_nivel'] as int : int.tryParse(e['id_nivel']?.toString() ?? '');
      final idCn = e['id'] is int ? e['id'] as int : int.tryParse(e['id']?.toString() ?? '');
      if (idN != null) {
        definiciones[idN] = e['definicion']?.toString() ?? '';
        if (idCn != null) idsNivel[idN] = idCn;
      }
    }
    for (final n in niveles) {
      definiciones.putIfAbsent(n, () => '');
    }

    final controllers = <int, TextEditingController>{};
    for (final n in niveles) {
      controllers[n] = TextEditingController(text: definiciones[n] ?? '');
    }
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Niveles: ${comp['nombre'] ?? idCompetencia}'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Definición por nivel (para asignar a cargos de ese nivel):',
                        style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      ...niveles.map((n) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: controllers[n],
                            decoration: InputDecoration(
                              labelText: 'Nivel $n',
                              hintText: 'Definición para nivel $n',
                              border: const OutlineInputBorder(),
                            ),
                            maxLines: 2,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (guardar != true) return;
    for (final n in niveles) {
      final def = controllers[n]!.text.trim();
      final idCn = idsNivel[n];
      try {
        if (idCn != null) {
          if (def.isEmpty) {
            await CompetenciasService.deleteNivel(idCn);
          } else {
            await CompetenciasService.updateNivel(idCn, def);
          }
        } else {
          if (def.isNotEmpty) {
            await CompetenciasService.createNivel(idCompetencia, n, def);
          }
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nivel $n: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Niveles guardados'), backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Catálogo de competencias'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onCrear();
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Nueva competencia'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: _lista.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No hay competencias. Crea una con "Nueva competencia".',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _lista.length,
                      itemBuilder: (context, i) {
                        final comp = _lista[i];
                        final nombre = comp['nombre']?.toString() ?? 'ID ${comp['id']}';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(Icons.psychology_outlined, color: scheme.primary),
                            title: Text(nombre),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _definirNiveles(comp),
                                  child: const Text('Niveles'),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit_outlined, size: 20, color: scheme.primary),
                                  onPressed: () => _editar(comp),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
                                  onPressed: () => _eliminar(comp),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
