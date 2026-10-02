import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

enum GrupoAlimentar { carboidratos, proteinas, gorduras }

class ItemAlimento {
  final String nome;
  final double fatorPorGrama; // Quantidade de macronutriente por 1g de alimento
  final String unidadePadrao;
  final String detalhePreparo;

  const ItemAlimento({
    required this.nome,
    required this.fatorPorGrama,
    this.unidadePadrao = 'g',
    required this.detalhePreparo,
  });
}

class CalculadoraSubstituicaoAlimentosModal extends StatefulWidget {
  const CalculadoraSubstituicaoAlimentosModal({super.key});

  static Future<void> abrir(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CalculadoraSubstituicaoAlimentosModal(),
    );
  }

  @override
  State<CalculadoraSubstituicaoAlimentosModal> createState() =>
      _CalculadoraSubstituicaoAlimentosModalState();
}

class _CalculadoraSubstituicaoAlimentosModalState
    extends State<CalculadoraSubstituicaoAlimentosModal> {
  GrupoAlimentar _grupoSelecionado = GrupoAlimentar.carboidratos;
  late TextEditingController _quantidadeOrigemCtrl;

  // Base de Dados TACO (Tabela Brasileira de Composição de Alimentos)
  static const Map<GrupoAlimentar, List<ItemAlimento>> _bancoAlimentos = {
    GrupoAlimentar.carboidratos: [
      ItemAlimento(nome: 'Arroz Branco Cozido', fatorPorGrama: 0.281, detalhePreparo: 'cozido simples'),
      ItemAlimento(nome: 'Arroz Integral Cozido', fatorPorGrama: 0.258, detalhePreparo: 'cozido simples'),
      ItemAlimento(nome: 'Batata Doce Cozida', fatorPorGrama: 0.200, detalhePreparo: 'cozida sem casca'),
      ItemAlimento(nome: 'Mandioca / Aipim Cozido', fatorPorGrama: 0.301, detalhePreparo: 'cozida'),
      ItemAlimento(nome: 'Batata Inglesa Cozida', fatorPorGrama: 0.119, detalhePreparo: 'cozida'),
      ItemAlimento(nome: 'Aveia em Flocos', fatorPorGrama: 0.666, detalhePreparo: 'flocos cru'),
      ItemAlimento(nome: 'Pão Francês', fatorPorGrama: 0.587, detalhePreparo: '1 unidade ~ 50g'),
      ItemAlimento(nome: 'Pão Integral', fatorPorGrama: 0.499, detalhePreparo: '2 fatias ~ 50g'),
      ItemAlimento(nome: 'Macarrão Cozido', fatorPorGrama: 0.306, detalhePreparo: 'cozido al dente'),
      ItemAlimento(nome: 'Tapioca (Goma)', fatorPorGrama: 0.548, detalhePreparo: 'preparada na frigideira'),
      ItemAlimento(nome: 'Cuscuz de Milho', fatorPorGrama: 0.254, detalhePreparo: 'cozido no vapor'),
    ],
    GrupoAlimentar.proteinas: [
      ItemAlimento(nome: 'Peito de Frango Grelhado', fatorPorGrama: 0.320, detalhePreparo: 'sem pele, grelhado'),
      ItemAlimento(nome: 'Patinho Bovino Moído', fatorPorGrama: 0.359, detalhePreparo: 'grelhado / refogado'),
      ItemAlimento(nome: 'Filé de Tilápia / Peixe Branco', fatorPorGrama: 0.260, detalhePreparo: 'grelhado ou assado'),
      ItemAlimento(nome: 'Ovo de Galinha Inteiro', fatorPorGrama: 0.130, detalhePreparo: '1 ovo médio ~ 50g'),
      ItemAlimento(nome: 'Clara de Ovo', fatorPorGrama: 0.110, detalhePreparo: '1 clara ~ 35g'),
      ItemAlimento(nome: 'Whey Protein Concentrado 80%', fatorPorGrama: 0.800, detalhePreparo: 'pó solúvel'),
      ItemAlimento(nome: 'Queijo Cottage', fatorPorGrama: 0.125, detalhePreparo: 'fresco'),
      ItemAlimento(nome: 'Atum Sólido em Água', fatorPorGrama: 0.255, detalhePreparo: 'em conserva natural'),
    ],
    GrupoAlimentar.gorduras: [
      ItemAlimento(nome: 'Azeite de Oliva Extra Virgem', fatorPorGrama: 1.000, detalhePreparo: '1 colher sopa ~ 10g'),
      ItemAlimento(nome: 'Pasta de Amendoim Integral', fatorPorGrama: 0.500, detalhePreparo: '1 colher sopa ~ 15g'),
      ItemAlimento(nome: 'Castanha de Caju Torrada', fatorPorGrama: 0.460, detalhePreparo: '8 unidades ~ 20g'),
      ItemAlimento(nome: 'Castanha do Pará / Brasil', fatorPorGrama: 0.635, detalhePreparo: '3 unidades ~ 15g'),
      ItemAlimento(nome: 'Abacate', fatorPorGrama: 0.084, detalhePreparo: 'polpa in natura'),
    ],
  };

  late ItemAlimento _alimentoOrigem;
  late ItemAlimento _alimentoDestino;

  @override
  void initState() {
    super.initState();
    _quantidadeOrigemCtrl = TextEditingController(text: '100');
    _atualizarAlimentosPadrao();
  }

  void _atualizarAlimentosPadrao() {
    final lista = _bancoAlimentos[_grupoSelecionado]!;
    _alimentoOrigem = lista.first;
    _alimentoDestino = lista.length > 1 ? lista[1] : lista.first;
  }

  @override
  void dispose() {
    _quantidadeOrigemCtrl.dispose();
    super.dispose();
  }

  double _calcularEquivalencia() {
    final qtdOrigem = double.tryParse(_quantidadeOrigemCtrl.text) ?? 100.0;
    if (_alimentoDestino.fatorPorGrama <= 0) return 0.0;

    final macroTotal = qtdOrigem * _alimentoOrigem.fatorPorGrama;
    return macroTotal / _alimentoDestino.fatorPorGrama;
  }

  String _nomeMacro() {
    switch (_grupoSelecionado) {
      case GrupoAlimentar.carboidratos:
        return 'Carboidratos';
      case GrupoAlimentar.proteinas:
        return 'Proteínas';
      case GrupoAlimentar.gorduras:
        return 'Gorduras Boas';
    }
  }

  Color _corMacro() {
    switch (_grupoSelecionado) {
      case GrupoAlimentar.carboidratos:
        return AppTheme.warningAmber;
      case GrupoAlimentar.proteinas:
        return AppTheme.primaryAccent;
      case GrupoAlimentar.gorduras:
        return AppTheme.electricBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = AppTheme.isLight;
    final accentGreen = AppTheme.primaryAccent;
    final borderSubtle = isLight
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1E293B);

    final listaAtual = _bancoAlimentos[_grupoSelecionado]!;
    final qtdOrigem = double.tryParse(_quantidadeOrigemCtrl.text) ?? 100.0;
    final macroTotal = qtdOrigem * _alimentoOrigem.fatorPorGrama;
    final qtdDestino = _calcularEquivalencia();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderSubtle),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isLight ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.swap_horiz_rounded,
                        color: accentGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Substituição de Alimentos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Equivalência nutricional baseada na Tabela TACO',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Abas de Grupos Alimentares (Carboidratos, Proteínas, Gorduras)
            Container(
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF141C2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderSubtle),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _abaGrupo(GrupoAlimentar.carboidratos, 'Carboidratos', Icons.bakery_dining_rounded),
                  _abaGrupo(GrupoAlimentar.proteinas, 'Proteínas', Icons.egg_alt_rounded),
                  _abaGrupo(GrupoAlimentar.gorduras, 'Gorduras', Icons.opacity_rounded),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Seção 1: Alimento Prescrito (Origem)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. O QUE ESTÁ NA SUA DIETA?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Dropdown alimento origem
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ItemAlimento>(
                            value: _alimentoOrigem,
                            isExpanded: true,
                            items: listaAtual
                                .map(
                                  (al) => DropdownMenuItem(
                                    value: al,
                                    child: Text(
                                      al.nome,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (novo) {
                              if (novo != null) {
                                setState(() => _alimentoOrigem = novo);
                              }
                            },
                          ),
                        ),
                      ),

                      // Input Quantidade
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 42,
                            child: TextField(
                              controller: _quantidadeOrigemCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (_) => setState(() {}),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                filled: true,
                                fillColor: AppTheme.surfaceCard,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: borderSubtle),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'gramas (g)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Equivale a ${macroTotal.toStringAsFixed(1)}g de ${_nomeMacro()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _corMacro(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Ícone de troca central
            Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceCard,
                  border: Border.all(color: borderSubtle),
                ),
                child: Icon(Icons.arrow_downward_rounded, size: 18, color: accentGreen),
              ),
            ),

            const SizedBox(height: 14),

            // Seção 2: Alimento Substituto (Destino)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. PELO QUE VOCÊ DESEJA SUBSTITUIR HOJE?',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<ItemAlimento>(
                      value: _alimentoDestino,
                      isExpanded: true,
                      items: listaAtual
                          .map(
                            (al) => DropdownMenuItem(
                              value: al,
                              child: Text(
                                al.nome,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (novo) {
                        if (novo != null) {
                          setState(() => _alimentoDestino = novo);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Card com Resultado em Destaque
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentGreen.withValues(alpha: 0.18),
                    accentGreen.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentGreen.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Column(
                children: [
                  Text(
                    'QUANTIDADE EQUIVALENTE EXATA',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: accentGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${qtdDestino.toStringAsFixed(0)} g',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'de ${_alimentoDestino.nome}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '(${_alimentoDestino.detalhePreparo})',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tabela Rápida de Todas as Equivalências do Grupo
            Text(
              'Tabela Rápida de Equivalências',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Porções que fornecem exatamente os mesmos ${macroTotal.toStringAsFixed(1)}g de ${_nomeMacro()}:',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            ...listaAtual.map((al) {
              final eq = al.fatorPorGrama > 0 ? (macroTotal / al.fatorPorGrama) : 0.0;
              final ehSelecionado = al.nome == _alimentoDestino.nome;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: ehSelecionado
                      ? accentGreen.withValues(alpha: 0.12)
                      : (isLight ? const Color(0xFFF8FAFC) : const Color(0xFF141C2E)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ehSelecionado ? accentGreen : borderSubtle,
                    width: ehSelecionado ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            al.nome,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: ehSelecionado ? FontWeight.w800 : FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            al.detalhePreparo,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${eq.toStringAsFixed(0)} g',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ehSelecionado ? accentGreen : AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // Nota Técnica e Responsabilidade
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLight ? const Color(0xFFF1F5F9) : const Color(0xFF090D16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Valores de referência da Tabela TACO/UNICAMP. Variações mínimas de fibras e micronutrientes podem ocorrer. Em caso de dúvidas, valide com seu Personal Trainer.',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _abaGrupo(GrupoAlimentar grupo, String rotulo, IconData icone) {
    final selecionado = _grupoSelecionado == grupo;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _grupoSelecionado = grupo;
            _atualizarAlimentosPadrao();
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selecionado ? AppTheme.primaryAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icone,
                size: 15,
                color: selecionado ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                rotulo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
                  color: selecionado ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
