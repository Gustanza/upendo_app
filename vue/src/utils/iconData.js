// Curated Material Icons with Flutter MaterialIcons codepoints.
// code values match IconData(code, fontFamily: 'MaterialIcons') in Flutter
// and also render correctly via String.fromCodePoint(code) with the Material Icons web font.
export const MATERIAL_ICONS = [
  { code: 0xe88a, label: 'Home' },
  { code: 0xe87d, label: 'Love' },
  { code: 0xe838, label: 'Star' },
  { code: 0xe865, label: 'Book' },
  { code: 0xe80c, label: 'School' },
  { code: 0xe405, label: 'Music' },
  { code: 0xeb43, label: 'Fitness' },
  { code: 0xe56c, label: 'Food' },
  { code: 0xe548, label: 'Health' },
  { code: 0xeb3e, label: 'Wellness' },
  { code: 0xea30, label: 'Sports' },
  { code: 0xeaae, label: 'Church' },
  { code: 0xe7ef, label: 'Group' },
  { code: 0xe7fb, label: 'People' },
  { code: 0xe8f9, label: 'Work' },
  { code: 0xe40a, label: 'Art' },
  { code: 0xe412, label: 'Photo' },
  { code: 0xe430, label: 'Sunny' },
  { code: 0xe564, label: 'Terrain' },
  { code: 0xe566, label: 'Running' },
  { code: 0xe574, label: 'Category' },
  { code: 0xe406, label: 'Nature' },
  { code: 0xe53e, label: 'Flowers' },
  { code: 0xeb67, label: 'Children' },
  { code: 0xe2cc, label: 'Folder' },
  { code: 0xe8b8, label: 'Settings' },
  { code: 0xe7fd, label: 'Person' },
  { code: 0xe0c9, label: 'Chat' },
  { code: 0xe55a, label: 'Location' },
  { code: 0xe2bd, label: 'Cloud' },
  { code: 0xe5c3, label: 'Flag' },
  { code: 0xe86f, label: 'Map' },
  { code: 0xe53b, label: 'Store' },
  { code: 0xe8b0, label: 'Security' },
  { code: 0xe3a9, label: 'Explore' },
  { code: 0xe54e, label: 'Hotel' },
]

// Flutter stores colors as 0xAARRGGBB integers.
export const COLOR_OPTIONS = [
  { label: 'Blue',   value: 0xFF1565C0 },
  { label: 'Indigo', value: 0xFF283593 },
  { label: 'Purple', value: 0xFF6A1B9A },
  { label: 'Pink',   value: 0xFFAD1457 },
  { label: 'Red',    value: 0xFFC62828 },
  { label: 'Orange', value: 0xFFE65100 },
  { label: 'Amber',  value: 0xFFF57F00 },
  { label: 'Green',  value: 0xFF2E7D32 },
  { label: 'Teal',   value: 0xFF00695C },
  { label: 'Cyan',   value: 0xFF00838F },
  { label: 'Brown',  value: 0xFF4E342E },
  { label: 'Grey',   value: 0xFF37474F },
]

// Convert a Flutter 0xAARRGGBB integer to a CSS rgb() string.
export function flutterColorToCss(colorHex) {
  const r = (colorHex >>> 16) & 0xFF
  const g = (colorHex >>> 8) & 0xFF
  const b = colorHex & 0xFF
  return `rgb(${r}, ${g}, ${b})`
}

// Render a Material Icon codepoint as a single Unicode character.
export function iconChar(code) {
  const safe = Number.isFinite(code) && code > 0 ? code : 0xe2cc  // fallback: folder
  return String.fromCodePoint(safe)
}
