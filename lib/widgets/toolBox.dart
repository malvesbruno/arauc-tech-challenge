import 'package:flutter/material.dart';
import 'package:font_awesome_icon_class/font_awesome_icon_class.dart';


/// Widget da "caixa de ferramentas", responsável pela escolha das tags e do brush ou borracha 
/// 
/// [isEditing] variável que define se estamos ou não editando
/// [doencaSelected] variável que define o estado da tag doença
/// [pragasSelected] variável que define o estado da tag pragas
/// [brushSelected] variável que define o estado da brush
/// [eraserSelected] variável que define o estado da borracha
/// [onTagSelected] função que seleciona a tag
/// [onBrushSelected] função que seleciona o brush ou a borracha

class ToolBox extends StatefulWidget {
  final bool isEditing;
  final bool doencaSelected;
  final bool pragasSelected;
  final bool brushSelected;
  final bool eraserSelected;
  final void Function(String) onTagSelected;
  final void Function(String) onBrushSelected;

  const ToolBox({
    super.key,
    required this.isEditing,
    required this.doencaSelected,
    required this.pragasSelected,
    required this.brushSelected,
    required this.eraserSelected,
    required this.onTagSelected,
    required this.onBrushSelected,
  });

  @override
  State<ToolBox> createState() => _ToolBoxState();
}

class _ToolBoxState extends State<ToolBox> {

  // widget para as tags doenças e pragas
  /// [label] titulo da tag
  /// [color] cor da tag
  
  Widget _buildTag(String label, Color color) {
    // se a label for igual a doença e a doença estiver selecionada, o isSelect dele será verdadeiro
    // se a label for igual a pragas e a pragas estiver selecionada, o isSelect dela será verdadeiro
    bool isSelected = (label == 'Doenças' && widget.doencaSelected) ||
        (label == 'Pragas' && widget.pragasSelected);

    return GestureDetector(
      // se estamos editando e a borracha não estiver ativa, ao clicarmos na tag ela é selecionada
      onTap: widget.isEditing && !widget.eraserSelected ? () => widget.onTagSelected(label) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            // caso o isSelected for verdadeiro, a borda é azul. Caso contrário, cinza 
            color: isSelected ? const Color(0xFF446ECC) : const Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            Container(width: 15, height: 15, color: color),
          ],
        ),
      ),
    );
  }


  // widget para as tags do brush e borracha
  /// [icon] titulo da tag

  Widget _buildPaintStyle(IconData icon) {
    // se o icon for igual a brush e a brush estiver selecionada, o isSelect dele será verdadeiro
    // se o icon for igual a borracha e a borracha estiver selecionada, o isSelect dela será verdadeiro
    bool isSelected = (icon == FontAwesomeIcons.paintbrush && widget.brushSelected) ||
        (icon == FontAwesomeIcons.eraser && widget.eraserSelected);

    return GestureDetector(
      // se o icon for igual a paintBrush, o brush será selecionada. Caso não, seja borracha
      onTap: () => widget.onBrushSelected(icon == FontAwesomeIcons.paintbrush ? 'brush' : 'eraser'),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF446ECC) : const Color(0xFFD9D9D9),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF446ECC) : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildTag('Doenças', Colors.red),
        const SizedBox(width: 10),
        _buildTag('Pragas', Colors.blue),
        const Spacer(),
        // tag de paint só vai aparecer se o isEditing for veradeiro
        if (widget.isEditing) ...[
          _buildPaintStyle(FontAwesomeIcons.paintbrush),
          const SizedBox(width: 10),
          _buildPaintStyle(FontAwesomeIcons.eraser),
        ],
      ],
    );
  }
}
