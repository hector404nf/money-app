import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/email_parser_template.dart';

class ManageEmailTemplateScreen extends StatefulWidget {
  final EmailParserTemplate? template;

  const ManageEmailTemplateScreen({super.key, this.template});

  @override
  State<ManageEmailTemplateScreen> createState() => _ManageEmailTemplateScreenState();
}

class _ManageEmailTemplateScreenState extends State<ManageEmailTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _senderController;
  late TextEditingController _subjectController;
  late TextEditingController _prefixController;
  late TextEditingController _suffixController;
  late TextEditingController _testTextController;
  
  bool _isExpense = true;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _senderController = TextEditingController(text: widget.template?.senderFilter ?? '');
    _subjectController = TextEditingController(text: widget.template?.subjectFilter ?? '');
    _prefixController = TextEditingController(text: widget.template?.amountPrefix ?? '');
    _suffixController = TextEditingController(text: widget.template?.amountSuffix ?? '');
    _testTextController = TextEditingController();
    _isExpense = widget.template?.isExpense ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderController.dispose();
    _subjectController.dispose();
    _prefixController.dispose();
    _suffixController.dispose();
    _testTextController.dispose();
    super.dispose();
  }

  void _testParsing() {
    final text = _testTextController.text;
    if (text.isEmpty) {
      setState(() => _testResult = 'Ingresa un texto de prueba');
      return;
    }

    // Create a temporary template
    final temp = EmailParserTemplate(
      id: 'temp',
      name: 'Temp',
      senderFilter: _senderController.text,
      subjectFilter: _subjectController.text,
      amountPrefix: _prefixController.text,
      amountSuffix: _suffixController.text,
      isExpense: _isExpense,
    );

    final amount = temp.extractAmount(text);
    if (amount != null) {
      setState(() {
        _testResult = '¡Éxito! Monto extraído: ${amount.toStringAsFixed(0)} (${_isExpense ? "Gasto" : "Ingreso"})';
      });
    } else {
      setState(() {
        _testResult = 'No se pudo extraer el monto. Verifica los prefijos/sufijos.';
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<DataProvider>(context, listen: false);
      
      final newTemplate = EmailParserTemplate(
        id: widget.template?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        senderFilter: _senderController.text,
        subjectFilter: _subjectController.text,
        amountPrefix: _prefixController.text,
        amountSuffix: _suffixController.text,
        isExpense: _isExpense,
      );

      if (widget.template != null) {
        provider.updateEmailTemplate(newTemplate);
      } else {
        provider.addEmailTemplate(newTemplate);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Editar Plantilla' : 'Nueva Plantilla'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la plantilla',
                  hintText: 'Ej. Banco GNB Compra',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              const Text('Filtros (Opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _senderController,
                decoration: const InputDecoration(
                  labelText: 'El remitente contiene',
                  hintText: 'Ej. alertas@banco.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'El asunto/cuerpo contiene',
                  hintText: 'Ej. Compra Aprobada',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Extracción de Monto', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Define qué texto está justo antes y después del monto en el correo.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prefixController,
                decoration: const InputDecoration(
                  labelText: 'Texto ANTES del monto',
                  hintText: 'Ej. Monto de compra:',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _suffixController,
                decoration: const InputDecoration(
                  labelText: 'Texto DESPUÉS del monto (Opcional)',
                  hintText: 'Ej. PYG',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Es un Gasto'),
                subtitle: Text(_isExpense ? 'El monto se registrará como negativo' : 'El monto se registrará como positivo'),
                value: _isExpense,
                onChanged: (val) => setState(() => _isExpense = val),
              ),

              const Divider(height: 32),
              const Text('Probar Plantilla', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _testTextController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pega aquí el texto del correo (Asunto o Cuerpo)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _testParsing,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Probar Extracción'),
              ),
              if (_testResult.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _testResult.contains('¡Éxito!') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _testResult.contains('¡Éxito!') ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    _testResult,
                    style: TextStyle(
                      color: _testResult.contains('¡Éxito!') ? Colors.green[800] : Colors.red[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
