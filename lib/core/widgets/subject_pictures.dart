import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Картинки предмета на обложке, как наклейки на тетради: одна крупная
/// и две поменьше. Иллюстрации — Twemoji (CC-BY 4.0), лежат
/// в `assets/subjects/` под кодами символов Unicode.
class SubjectPictures extends StatelessWidget {
  const SubjectPictures({super.key, required this.subjectId, this.height = 64});

  final String subjectId;
  final double height;

  /// Предмет → [крупная, вторая, третья].
  static const pictures = <String, List<String>>{
    'math': ['1f9ee', '1f4cf', '270f'], // счёты, линейка, карандаш
    'algebra': ['1f4c8', '1f522', '2716'], // график, цифры, умножить
    'geometry': ['1f4d0', '1f4cf', '1f53a'], // угольник, линейка, треугольник
    'tajik_lang': ['1f4d6', '270d', '1f1f9-1f1ef'], // книга, пишет, флаг
    'tajik_lit': ['1f4dc', '1fab6', '1f4da'], // свиток, перо, книги
    'russian': ['1f4d5', '1f524', '1f1f7-1f1fa'], // учебник, буквы, флаг
    'english': ['1f1ec-1f1e7', '1f524', '1f4ac'], // флаг, буквы, разговор
    'history': ['1f3db', '1f4dc', '2694'], // здание, свиток, мечи
    'world_history': ['1f3fa', '1f5fa', '23f3'], // амфора, карта, часы
    'geography': ['1f30d', '1f3d4', '1f9ed'], // глобус, горы, компас
    'biology': ['1f331', '1f52c', '1f9ec'], // росток, микроскоп, ДНК
    'physics': ['1f9f2', '1f4a1', '26a1'], // магнит, лампа, молния
    'chemistry': ['1f9ea', '2697', '1f9eb'], // пробирка, колба, чашка
    'informatics': ['1f4bb', '1f5b1', '2328'], // ноутбук, мышь, клавиатура
    'nature': ['1f333', '1f98b', '2600'], // дерево, бабочка, солнце
  };

  @override
  Widget build(BuildContext context) {
    final codes = pictures[subjectId];
    if (codes == null) return SizedBox(height: height);
    final h = height;

    Widget picture(String code, double size, double angle) => Transform.rotate(
      angle: angle,
      child: SvgPicture.asset(
        'assets/subjects/$code.svg',
        width: size,
        height: size,
      ),
    );

    return SizedBox(
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: picture(codes[0], h * 0.92, -0.08),
          ),
          Positioned(
            left: h * 1.0,
            top: -h * 0.04,
            child: picture(codes[1], h * 0.56, 0.14),
          ),
          Positioned(
            left: h * 1.55,
            top: h * 0.38,
            child: picture(codes[2], h * 0.5, -0.12),
          ),
        ],
      ),
    );
  }
}
