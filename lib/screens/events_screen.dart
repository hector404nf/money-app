import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/event.dart';
import '../utils/constants.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final events = provider.events;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos / Viajes'),
      ),
      body: events.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.airplane_ticket_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay eventos registrados',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: event.isActive ? AppColors.primary : Colors.grey,
                      child: Icon(
                        Icons.flight,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(event.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${DateFormat('dd/MM/yyyy').format(event.startDate)} - ${event.endDate != null ? DateFormat('dd/MM/yyyy').format(event.endDate!) : 'En curso'}\nMoneda: ${event.defaultCurrency ?? 'PYG'}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        // Confirm dialog
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar evento'),
                            content: const Text('¿Estás seguro? Esto no borrará los movimientos asociados, pero perderán la referencia al evento.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  provider.deleteEvent(event.id);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEventScreen(event: event),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEventScreen()),
          );
        },
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddEventScreen extends StatefulWidget {
  final Event? event;
  const AddEventScreen({super.key, this.event});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _currencyController;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?.name ?? '');
    _currencyController = TextEditingController(text: widget.event?.defaultCurrency ?? 'USD');
    if (widget.event != null) {
      _startDate = widget.event!.startDate;
      _endDate = widget.event!.endDate;
      _isActive = widget.event!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Nuevo Evento' : 'Editar Evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Evento',
                  hintText: 'Ej. Vacaciones Brasil 2026',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Ingresa un nombre' : null,
              ),
              const SizedBox(height: 16),
              
              // Fechas
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _startDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Inicio',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fin (Opcional)',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : '---'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Moneda
              TextFormField(
                controller: _currencyController,
                decoration: const InputDecoration(
                  labelText: 'Moneda por defecto',
                  hintText: 'Ej. BRL, USD',
                  border: OutlineInputBorder(),
                  helperText: 'Moneda sugerida al agregar gastos a este evento',
                ),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Evento Activo'),
                subtitle: const Text('Aparecerá en la pantalla de agregar gasto'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: const Text('Guardar Evento'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      final newEvent = Event(
        id: widget.event?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        startDate: _startDate,
        endDate: _endDate,
        defaultCurrency: _currencyController.text.toUpperCase(),
        isActive: _isActive,
      );

      if (widget.event == null) {
        provider.addEvent(newEvent);
      } else {
        provider.updateEvent(newEvent);
      }
      Navigator.pop(context);
    }
  }
}
