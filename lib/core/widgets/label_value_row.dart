import 'package:flutter/material.dart';

class LabelValueRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? valueWidget;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const LabelValueRow({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.labelStyle,
    this.valueStyle,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: spacing),
        Flexible(
          child: valueWidget ??
              Text(
                value ?? '',
                style: valueStyle,
                overflow: TextOverflow.ellipsis,
              ),
        ),
      ],
    );
  }
}
