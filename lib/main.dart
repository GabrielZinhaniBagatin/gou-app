import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA7nildHHNphoCPfYpoRoG9vFxXcxTP7HU",
      authDomain: "gou-sao-miguel-app.firebaseapp.com",
      databaseURL: "https://gou-sao-miguel-app-default-rtdb.firebaseio.com",
      projectId: "gou-sao-miguel-app",
      storageBucket: "gou-sao-miguel-app.firebasestorage.app",
      messagingSenderId: "296044760500",
      appId: "1:296044760500:web:e33d5f3d96adb6399eb6e1",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anotações do GOU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A2E5C), // Azul São Miguel
        primaryColor: const Color(0xFF3B66F5),
        fontFamily: 'Roboto',
      ),
      home: const TelaPrincipal(),
    );
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _abaSelecionada = 0; 
  int tagSelecionada = 0;

  final List<String> tags = ['Ideias Gerais', 'Projetos'];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _novoTituloController = TextEditingController();
  final TextEditingController _novaTagController = TextEditingController();
  final TextEditingController _novaTarefaCalendarioController = TextEditingController();
  String _textoPesquisa = "";

  CalendarFormat _formatoCalendario = CalendarFormat.month;
  DateTime _diaFocado = DateTime.now();
  DateTime? _diaSelecionado;

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _diaSelecionado = _diaFocado;
    _searchController.addListener(() {
      setState(() {
        _textoPesquisa = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _novoTituloController.dispose();
    _novaTagController.dispose();
    _novaTarefaCalendarioController.dispose();
    super.dispose();
  }

  String _formatarChaveData(DateTime data) {
    return "${data.year}-${data.month}-${data.day}";
  }

  String _formatarDataVisual(DateTime dt) {
    final List<String> meses = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    String minutoStr = dt.minute < 10 ? '0${dt.minute}' : '${dt.minute}';
    String horaStr = dt.hour < 10 ? '0${dt.hour}' : '${dt.hour}';
    return "${dt.day} de ${meses[dt.month - 1]} às $horaStr:$minutoStr";
  }

  Future<void> _adicionarNotaNuvem(String titulo) async {
    await _databaseRef.child('notas').push().set({
      'titulo': titulo,
      'conteudo': '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _atualizarNotaNuvem(String id, String novoConteudo, String conteudoOriginal) async {
    final dados = <String, dynamic>{'conteudo': novoConteudo};
    if (novoConteudo != conteudoOriginal) {
      dados['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    }
    await _databaseRef.child('notas').child(id).update(dados);
  }

  Future<void> _deletarNotaNuvem(String id) async {
    await _databaseRef.child('notas').child(id).remove();
  }

  Future<void> _adicionarEventoNuvem(String dataChave, String eventoTexto) async {
    await _databaseRef.child('calendario').push().set({
      'dataChave': dataChave,
      'evento': eventoTexto,
    });
  }

  Future<void> _deletarEventoNuvem(String id) async {
    await _databaseRef.child('calendario').child(id).remove();
  }

  void _confirmarExclusaoTag(int index) {
    if (tags.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você precisa manter pelo menos uma categoria!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Tem certeza?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Você deseja mesmo excluir a categoria "${tags[index]}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                setState(() {
                  tags.removeAt(index);
                  if (tagSelecionada >= tags.length) {
                    tagSelecionada = tags.length - 1;
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmarExclusaoNota(String id, String titulo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Excluir Anotação?', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Tem certeza que deseja apagar permanentemente "$titulo"? Todo o grupo perderá o acesso.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Manter Nota', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              onPressed: () {
                _deletarNotaNuvem(id);
                Navigator.pop(context);
              },
              child: const Text('Apagar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _modalCriarNovaCategoria() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Nova Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _novaTagController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome da Categoria',
              hintText: 'Ex: Igreja, Estudos...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _novaTagController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B66F5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_novaTagController.text.isNotEmpty) {
                  setState(() {
                    tags.add(_novaTagController.text);
                  });
                  _novaTagController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _modalCriarNovaPagina() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nova Página de Anotação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 16),
                TextField(
                  controller: _novoTituloController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Título da Anotação',
                    hintText: 'Ex: Oração, Compromissos...',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _novoTituloController.clear();
                        Navigator.pop(context);
                      },
                      child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B66F5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_novoTituloController.text.isNotEmpty) {
                          _adicionarNotaNuvem(_novoTituloController.text);
                          _novoTituloController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Criar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _modalAdicionarTarefaCalendario() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Adicionar Nota ao Dia', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _novaTarefaCalendarioController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ex: Ensaio do Coro, Missa...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B66F5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (_novaTarefaCalendarioController.text.isNotEmpty && _diaSelecionado != null) {
                  _adicionarEventoNuvem(_formatarChaveData(_diaSelecionado!), _novaTarefaCalendarioController.text);
                  _novaTarefaCalendarioController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _abrirEditorDeTexto(String docId, String titulo, String conteudoOriginal) {
    TextEditingController controller = TextEditingController(text: conteudoOriginal);
    FocusNode focusNode = FocusNode();
    
    final List<String> simbolosCatolicos = ['✝', '☩', 'αω', '🪽'];

    void inserirMarcador(String marcador) {
      final text = controller.text;
      final selection = controller.selection;
      final start = selection.isValid ? selection.start : text.length;
      final end = selection.isValid ? selection.end : text.length;

      final newText = text.replaceRange(start, end, '$marcador ');
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: start + marcador.length + 1);
      focusNode.requestFocus();
    }

    controller.addListener(() {
      final text = controller.text;
      final selection = controller.selection;

      if (selection.isValid && selection.isCollapsed && selection.start > 0) {
        int indexCursor = selection.start;
        
        if (text[indexCursor - 1] == '\n') {
          int indexTextoAnterior = indexCursor - 2;
          if (indexTextoAnterior >= 0) {
            String subTextoAteEnter = text.substring(0, indexCursor - 1);
            List<String> linhas = subTextoAteEnter.split('\n');
            String ultimaLinhaCompleta = linhas.isNotEmpty ? linhas.last : "";

            for (String simb in simbolosCatolicos) {
              if (ultimaLinhaCompleta.startsWith(simb)) {
                controller.removeListener(() {});
                
                String stringInjetar = "$simb ";
                final novoTextoCompleto = text.replaceRange(indexCursor, indexCursor, stringInjetar);
                
                controller.text = novoTextoCompleto;
                controller.selection = TextSelection.collapsed(offset: indexCursor + stringInjetar.length);
                break;
              }
            }
          }
        }
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
              onPressed: () {
                _atualizarNotaNuvem(docId, controller.text, conteudoOriginal);
                Navigator.pop(context);
              },
            ),
            title: Text(titulo, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // BARRA DE SÍMBOLOS CORRIGIDA (SEM BARRAS PRETAS E COM ROLAGEM DIRETAMENTE ACESSÍVEL)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    const Text('Listas:', style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildBotaoSimbolo(texto: '✝ Cruz', simbolo: '✝', onTap: inserirMarcador),
                            _buildBotaoSimbolo(texto: '☩ Jerus', simbolo: '☩', onTap: inserirMarcador),
                            _buildBotaoSimbolo(texto: 'αω Ictis', simbolo: 'αω', onTap: inserirMarcador),
                            _buildBotaoSimbolo(texto: '🪽 Anjo', simbolo: '🪽', onTap: inserirMarcador),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Digite aqui... Pressione Enter para continuar a lista automaticamente.',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoSimbolo({required String texto, required String simbolo, required Function(String) onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onTap(simbolo),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Text(
            texto,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF3B66F5)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PAPEL DE PAREDE CORRIGIDO - APENAS O TEXTO "GOU" CENTRALIZADO, LIMPO E SUAVE
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Opacity(
                opacity: 0.04, 
                child: const Text(
                  'GOU',
                  style: TextStyle(
                    fontSize: 90,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 6,
                  ),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Text(
                    _abaSelecionada == 0 ? 'Anotações do GOU ⚔️' : 'Calendário ⚔️',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                Expanded(
                  child: _abaSelecionada == 0 
                      ? _construirInterfaceNotas() 
                      : _construirInterfaceCalendario(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), spreadRadius: 4, blurRadius: 24, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.notes_rounded, color: _abaSelecionada == 0 ? const Color(0xFF3B66F5) : Colors.black26, size: 28),
              onPressed: () => setState(() => _abaSelecionada = 0),
            ),
            IconButton(
              icon: Icon(Icons.calendar_today_rounded, color: _abaSelecionada == 1 ? const Color(0xFF3B66F5) : Colors.black26, size: 24),
              onPressed: () => setState(() => _abaSelecionada = 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirInterfaceNotas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEBEFF5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.black26, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Pesquisar...',
                      hintStyle: TextStyle(color: Colors.black26, fontSize: 15),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(color: Colors.black87, fontSize: 15),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black26, size: 18),
                    onPressed: () => _searchController.clear(),
                  )
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    bool selecionada = tagSelecionada == index;
                    return GestureDetector(
                      onTap: () => setState(() => tagSelecionada = index),
                      onLongPress: () => _confirmarExclusaoTag(index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: selecionada ? const Color(0xFF5E636E) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: selecionada ? Colors.transparent : const Color(0xFFEBEFF5)),
                        ),
                        child: Center(
                          child: Text(
                            tags[index],
                            style: TextStyle(
                              color: selecionada ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder_rounded, color: Colors.white70, size: 24),
              onPressed: _modalCriarNovaCategoria,
              tooltip: 'Nova Categoria',
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24, left: 4),
              child: InkWell(
                onTap: _modalCriarNovaPagina,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEBEFF5)),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF3B66F5), size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Expanded(
          child: StreamBuilder(
            stream: _databaseRef.child('notas').onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.hasError) return const Center(child: Text('Erro ao carregar dados.', style: TextStyle(color: Colors.white)));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));

              final Map<dynamic, dynamic>? data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;
              
              if (data == null || data.isEmpty) {
                return const Center(child: Text('Nenhuma anotação encontrada.', style: TextStyle(color: Colors.white54)));
              }

              final listaNotas = data.entries.toList();
              listaNotas.sort((a, b) => b.value['timestamp'].compareTo(a.value['timestamp']));

              final notasFiltradas = listaNotas.where((entry) {
                final titulo = entry.value['titulo'].toString().toLowerCase();
                return titulo.contains(_textoPesquisa);
              }).toList();

              if (notasFiltradas.isEmpty) {
                return const Center(child: Text('Nenhuma anotação encontrada.', style: TextStyle(color: Colors.white54)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: notasFiltradas.length,
                itemBuilder: (context, index) {
                  final id = notasFiltradas[index].key;
                  final nota = notasFiltradas[index].value;
                  final DateTime dataTimestamp = DateTime.fromMillisecondsSinceEpoch(nota['timestamp']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEBEFF5)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () => _abrirEditorDeTexto(id, nota['titulo'], nota['conteudo']),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.amber, size: 24),
                      ),
                      title: Text(
                        nota['titulo'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _formatarDataVisual(dataTimestamp),
                          style: const TextStyle(color: Colors.black38, fontSize: 13),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.black26, size: 22),
                        onPressed: () => _confirmarExclusaoNota(id, nota['titulo']),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _construirInterfaceCalendario() {
    String chaveSelecionada = _diaSelecionado != null ? _formatarChaveData(_diaSelecionado!) : "";

    return StreamBuilder(
      stream: _databaseRef.child('calendario').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        final Map<dynamic, dynamic>? data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>?;

        final Map<String, List<String>> tarefasDoDiaMap = {};
        final Map<String, List<String>> idTarefasMap = {};

        if (data != null) {
          data.forEach((id, val) {
            String ch = val['dataChave'];
            String ev = val['evento'];
            
            if (tarefasDoDiaMap[ch] == null) {
              tarefasDoDiaMap[ch] = [];
              idTarefasMap[ch] = [];
            }
            tarefasDoDiaMap[ch]!.add(ev);
            idTarefasMap[ch]!.add(id);
          });
        }

        List<String> tarefasDoDiaSelecionado = tarefasDoDiaMap[chaveSelecionada] ?? [];
        List<String> idsDoDiaSelecionado = idTarefasMap[chaveSelecionada] ?? [];

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(24), 
                    border: Border.all(color: const Color(0xFFEBEFF5))
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2025, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _diaFocado,
                    calendarFormat: _formatoCalendario,
                    selectedDayPredicate: (day) => isSameDay(_diaSelecionado, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() { 
                        _diaSelecionado = selectedDay; 
                        _diaFocado = focusedDay; 
                      });
                    },
                    onFormatChanged: (format) => setState(() => _formatoCalendario = format),
                    eventLoader: (day) {
                      return tarefasDoDiaMap[_formatarChaveData(day)] ?? [];
                    },
                    // CORREÇÃO VISUAL DOS MESES DO CALENDÁRIO: Trocando estilo do texto do Header para preto
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false, 
                      titleCentered: true,
                      titleTextStyle: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.bold),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black87),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black87),
                    ),
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(color: Color(0xFFEBEFF5), shape: BoxShape.circle),
                      todayTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      selectedDecoration: BoxDecoration(color: Color(0xFF3B66F5), shape: BoxShape.circle),
                      markerDecoration: BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Compromissos do Dia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white70, size: 26),
                      onPressed: _modalAdicionarTarefaCalendario,
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: tarefasDoDiaSelecionado.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEBEFF5))),
                        child: const Center(child: Text('Nenhum evento ou lembrete para hoje.', style: TextStyle(color: Colors.black38))),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tarefasDoDiaSelecionado.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFEBEFF5))),
                            child: ListTile(
                              leading: const Icon(Icons.church, color: Colors.amber, size: 20),
                              title: Text(tarefasDoDiaSelecionado[index], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, color: Colors.black26, size: 18),
                                onPressed: () => _deletarEventoNuvem(idsDoDiaSelecionado[index]),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}