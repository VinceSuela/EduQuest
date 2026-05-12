import 'package:flutter/material.dart';

// Maps letters to hex digits to create a color from a name.
// A and B = 2, C and D = 3, ..., Y and Z = E. Non-letters default to 8.
const Map<String, String> _letterHexMap = {
  'A': '2', 'B': '2',
  'C': '3', 'D': '3',
  'E': '4', 'F': '4',
  'G': '5', 'H': '5',
  'I': '6', 'J': '6',
  'K': '7', 'L': '7',
  'M': '8', 'N': '8',
  'O': '9', 'P': '9',
  'Q': 'A', 'R': 'A',
  'S': 'B', 'T': 'B',
  'U': 'C', 'V': 'C',
  'W': 'D', 'X': 'D',
  'Y': 'E', 'Z': 'E',
};

String _letterToHex(String letter) =>
    _letterHexMap[letter.toUpperCase()] ?? '8';

// Derives a Color from the first 3 letters of a name. Non-letters are ignored.
Color colorFromName(String name) {
  final clean = name.replaceAll(RegExp(r'[^a-zA-Z]'), '');
  if (clean.isEmpty) return const Color(0xFF888888);
  final r = _letterToHex(clean.length > 0 ? clean[0] : 'M');
  final g = _letterToHex(clean.length > 1 ? clean[1] : 'M');
  final b = _letterToHex(clean.length > 2 ? clean[2] : 'M');
  final hex = '$r$r$g$g$b$b';
  return Color(int.parse('FF$hex', radix: 16));
}

// Returns 1–2 letter initials. Splits on spaces, @, dots, underscores.
String initialsFromName(String name) {
  final clean = name.trim();
  if (clean.isEmpty) return '?';
  final parts = clean.split(RegExp(r'[\s@._]+'));
  if (parts.length >= 2 && parts[1].isNotEmpty) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}

// White or black depending on background luminance.
Color textColorForBackground(Color bg) =>
    bg.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;


// Circular avatar — shows asset image or initials fallback.
// Used by leaderboard, profile, and anywhere else that shows a user avatar.
class AvatarWidget extends StatelessWidget {
  final String displayName;
  final String? avatarAssetPath;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const AvatarWidget({
    super.key,
    required this.displayName,
    this.avatarAssetPath,
    this.size = 48,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bg       = colorFromName(displayName);
    final initials = initialsFromName(displayName);

    final Widget inner = avatarAssetPath != null && avatarAssetPath!.isNotEmpty
        ? Image.asset(
            avatarAssetPath!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                _InitialsInner(initials: initials, bg: bg, size: size),
          )
        : _InitialsInner(initials: initials, bg: bg, size: size);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: borderColor != null
            ? [BoxShadow(color: borderColor!.withOpacity(0.35), blurRadius: 10, spreadRadius: 1)]
            : [BoxShadow(color: bg.withOpacity(0.4), blurRadius: 14, spreadRadius: 2)],
      ),
      child: ClipOval(child: inner),
    );
  }
}

class _InitialsInner extends StatelessWidget {
  final String initials;
  final Color bg;
  final double size;

  const _InitialsInner({
    required this.initials,
    required this.bg,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
            color: textColorForBackground(bg),
            letterSpacing: size > 60 ? 2 : 0,
          ),
        ),
      ),
    );
  }
}