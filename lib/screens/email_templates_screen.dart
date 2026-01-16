import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/email_parser_template.dart';
import 'manage_email_template_screen.dart';

class EmailTemplatesScreen extends StatelessWidget {
  const EmailTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final templates = provider.emailTemplates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantillas de Correo'),
      ),
      body: templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No hay plantillas definidas',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea una plantilla para mejorar la\ndetección de correos de tu banco.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return ListTile(
                  title: Text(template.name),
                  subtitle: Text(
                    'Filtro: ${template.senderFilter.isNotEmpty ? template.senderFilter : "Cualquiera"} / ${template.subjectFilter.isNotEmpty ? template.subjectFilter : "Cualquiera"}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar plantilla'),
                          content: const Text('¿Estás seguro de eliminar esta plantilla?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                provider.deleteEmailTemplate(template.id);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
                        builder: (_) => ManageEmailTemplateScreen(template: template),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ManageEmailTemplateScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
