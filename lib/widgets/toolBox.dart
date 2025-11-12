import 'package:flutter/material.dart';
import 'package:font_awesome_icon_class/font_awesome_icon_class.dart';


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
  Widget _buildTag(String label, Color color) {
    bool isSelected = (label == 'Doenças' && widget.doencaSelected) ||
        (label == 'Pragas' && widget.pragasSelected);

    return GestureDetector(
      onTap: widget.isEditing && !widget.eraserSelected ? () => widget.onTagSelected(label) : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
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

  Widget _buildPaintStyle(IconData icon) {
    bool isSelected = (icon == FontAwesomeIcons.paintbrush && widget.brushSelected) ||
        (icon == FontAwesomeIcons.eraser && widget.eraserSelected);

    return GestureDetector(
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
        if (widget.isEditing) ...[
          _buildPaintStyle(FontAwesomeIcons.paintbrush),
          const SizedBox(width: 10),
          _buildPaintStyle(FontAwesomeIcons.eraser),
        ],
      ],
    );
  }
}
