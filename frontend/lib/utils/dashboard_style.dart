import 'package:flutter/material.dart';

const Color dsBackground = Color(0xFF081623);
const Color dsSurface = Color(0xFF10243A);
const Color dsSurfaceAlt = Color(0xFF132A46);
const Color dsAccent = Color(0xFF00E5FF);
const Color dsAccentSoft = Color(0xFF54C7FF);
const Color dsAccentDim = Color(0xFF0097A7);
const Color dsTextPrimary = Color(0xFFE8F4FD);
const Color dsTextSecondary = Color(0xFF8BA3BE);
const Color dsBorder = Color(0xFF1C3460);

BoxDecoration dsPanelDecoration({Color color = dsSurfaceAlt, double radius = 18}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: dsAccent.withOpacity(0.14), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.22),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

InputDecoration dsFormFieldDecoration({required String label}) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: dsTextSecondary),
    filled: true,
    fillColor: dsSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: dsBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: dsBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: dsAccent, width: 2),
    ),
  );
}

TextStyle dsHeadingStyle([double size = 18]) {
  return TextStyle(
    color: dsTextPrimary,
    fontSize: size,
    fontWeight: FontWeight.w700,
  );
}

TextStyle dsSubtitleStyle([double size = 14]) {
  return TextStyle(
    color: dsTextSecondary,
    fontSize: size,
    fontWeight: FontWeight.w500,
  );
}

Widget dsSectionTitle(String title, {IconData? icon}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      if (icon != null) Icon(icon, color: dsAccent, size: 18),
      if (icon != null) const SizedBox(width: 8),
      Text(title, style: dsHeadingStyle(16)),
      const Spacer(),
      Container(height: 1, width: 60, color: dsAccentSoft.withOpacity(0.5)),
    ],
  );
}
