import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/content.dart' show ContentController;
import '../../../data/models/question.dart';
import '../../auth/application/auth_service.dart';

/// Вопрос, найденный в тексте, до добавления в тему.
class ImportedQuestion {
  const ImportedQuestion({
    required this.textTg,
    required this.optionsTg,
    required this.correctIndex,
    this.textRu = '',
    this.optionsRu = const [],
    this.explanationTg,
    this.explanationRu,
  });

  final String textTg;
  final String textRu;
  final List<String> optionsTg;
  final List<String> optionsRu;

  /// -1 — правильный ответ в тексте не отмечен.
  final int correctIndex;
  final String? explanationTg;
  final String? explanationRu;

  bool get hasAnswer => correctIndex >= 0 && correctIndex < optionsTg.length;
  bool get isValid => textTg.isNotEmpty && optionsTg.length >= 2 && hasAnswer;
  bool get isTranslated => textRu.isNotEmpty;

  Question toQuestion(String topicId) {
    final ru = optionsRu.length == optionsTg.length ? optionsRu : optionsTg;
    return Question(
      id: ContentController.newId('q'),
      topicId: topicId,
      textTg: textTg,
      textRu: textRu,
      optionsTg: optionsTg.take(6).toList(),
      optionsRu: [
        for (var i = 0; i < optionsTg.length && i < 6; i++)
          ru[i].isEmpty ? optionsTg[i] : ru[i],
      ],
      correctIndex: correctIndex,
      explanationTg: explanationTg,
      explanationRu: explanationRu,
    );
  }
}

/// Как удалось разобрать текст.
enum ImportMode {
  /// Gemini нашёл вопросы и перевёл на русский.
  ai,

  /// Без ИИ (нет Firebase, интернета или ИИ не включён) —
  /// только разбор по образцу, без перевода.
  basic,
}

class ImportResult {
  const ImportResult(this.questions, this.mode);

  final List<ImportedQuestion> questions;
  final ImportMode mode;
}

final questionImportProvider = Provider<QuestionImport>(
  (ref) => QuestionImport(useAi: ref.watch(firebaseReadyProvider)),
);

/// Разбор вставленного текста с тестом: вопросы, варианты, правильный ответ,
/// перевод на русский.
class QuestionImport {
  const QuestionImport({required this.useAi});

  final bool useAi;

  /// Модели по порядку: если первой нет, пробуем следующую.
  static const _models = ['gemini-flash-latest', 'gemini-2.5-flash'];

  Future<ImportResult> parse(String text) async {
    if (useAi) {
      try {
        final questions = await _parseWithAi(text);
        if (questions.isNotEmpty) {
          return ImportResult(questions, ImportMode.ai);
        }
      } on Object catch (e) {
        debugPrint('Импорт через Gemini: $e');
      }
    }
    return ImportResult(parseBasic(text), ImportMode.basic);
  }

  static const _instruction = '''
Ты помогаешь учителю школы в Таджикистане перенести тест в приложение.
Тебе дают текст теста, обычно на таджикском языке, в любом виде: из Word,
Excel, Telegram, с нумерацией или без.

1. Найди все вопросы. У каждого — варианты ответа (от 2 до 6) и правильный
   ответ. Правильный ответ обычно отмечен: *, +, ✓, «(дуруст)», жирным в тексте
   не видно, поэтому смотри на пометки или строки «Ҷавоб: б», «Ответ: в».
   Если правильный ответ нигде не отмечен — поставь correctIndex = -1.
   Сам не угадывай.
2. Таджикский текст переноси как есть: без номеров и букв вариантов
   («1.», «а)»), без пометок правильного ответа. Исправляй только явные опечатки.
3. Переведи вопрос, варианты и объяснение на русский так, как написал бы
   учитель в российском школьном учебнике: простыми, естественными фразами,
   без канцелярита и дословных оборотов. Термины — как в учебниках
   (математика, физика, грамматика). Числа, формулы, имена и названия
   не меняй; таджикские имена и топонимы пиши в принятом русском написании
   (Душанбе, Худжанд, Рудаки, Айни).
4. Если в тексте есть объяснение к вопросу («Шарҳ:», «Объяснение:»),
   перенеси его и переведи. Не придумывай объяснений сам.
5. Не добавляй вопросов, которых нет в тексте.
''';

  Future<List<ImportedQuestion>> _parseWithAi(String text) async {
    final schema = Schema.object(
      properties: {
        'questions': Schema.array(
          items: Schema.object(
            properties: {
              'textTg': Schema.string(),
              'textRu': Schema.string(),
              'optionsTg': Schema.array(items: Schema.string()),
              'optionsRu': Schema.array(items: Schema.string()),
              'correctIndex': Schema.integer(),
              'explanationTg': Schema.string(nullable: true),
              'explanationRu': Schema.string(nullable: true),
            },
            optionalProperties: ['explanationTg', 'explanationRu'],
          ),
        ),
      },
    );

    Object? lastError;
    for (final name in _models) {
      try {
        final model = FirebaseAI.googleAI().generativeModel(
          model: name,
          systemInstruction: Content.system(_instruction),
          generationConfig: GenerationConfig(
            temperature: 0.2,
            responseMimeType: 'application/json',
            responseSchema: schema,
          ),
        );
        final response = await model
            .generateContent([Content.text(text)])
            .timeout(const Duration(minutes: 2));
        final json = jsonDecode(response.text ?? '{}') as Map<String, dynamic>;
        return [
          for (final q in (json['questions'] as List? ?? const []))
            _fromJson(q as Map<String, dynamic>),
        ];
      } on FirebaseAIException catch (e) {
        // Нет такой модели — пробуем следующую; остальные ошибки — сразу наверх
        if (!e.message.contains('not found')) rethrow;
        lastError = e;
      }
    }
    throw lastError ?? StateError('Нет доступной модели Gemini');
  }

  static ImportedQuestion _fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? v) => [
      for (final s in (v as List? ?? const [])) '$s'.trim(),
    ];
    String? text(Object? v) {
      final s = (v as String?)?.trim();
      return s == null || s.isEmpty ? null : s;
    }

    return ImportedQuestion(
      textTg: (json['textTg'] as String? ?? '').trim(),
      textRu: (json['textRu'] as String? ?? '').trim(),
      optionsTg: strings(json['optionsTg']),
      optionsRu: strings(json['optionsRu']),
      correctIndex: (json['correctIndex'] as num? ?? -1).toInt(),
      explanationTg: text(json['explanationTg']),
      explanationRu: text(json['explanationRu']),
    );
  }

  // ── Разбор без ИИ ────────────────────────────────────────────

  /// Буквы вариантов: таджикские/русские и латинские.
  static const _letters = 'абвгде';
  static const _latin = 'abcdef';

  static final _questionStart = RegExp(
    r'^\s*(?:(?:савол|вопрос|question)\s*)?\d{1,3}\s*[.)]\s*',
    caseSensitive: false,
  );
  static final _optionStart = RegExp(
    r'^\s*([а-еa-f])\s*[).:]\s+',
    caseSensitive: false,
  );
  static final _bullet = RegExp(r'^\s*[-•–]\s+');
  static final _answerLine = RegExp(
    r'^\s*(?:ҷавоби\s+дуруст|ҷавоб|правильный\s+ответ|ответ|answer)\s*[:\-–]\s*(.+)$',
    caseSensitive: false,
  );
  static final _explanationLine = RegExp(
    r'^\s*(?:шарҳ|объяснение|пояснение)\s*[:\-–]\s*(.+)$',
    caseSensitive: false,
  );
  static final _correctMark = RegExp(
    r'(^\s*[*✓✔]\s*|\s*[*✓✔]\s*$|\s*\((?:дуруст|правильно|\+)\)\s*$)',
    caseSensitive: false,
  );

  /// Разбор по образцу:
  ///
  /// ```
  /// 1. Савол?
  /// а) вариант
  /// б) правильный вариант *
  /// Ҷавоб: б          (можно вместо звёздочки)
  /// Шарҳ: объяснение  (необязательно)
  /// ```
  ///
  /// Строки из Excel (через табуляцию): вопрос, варианты, правильный
  /// (буква, номер или текст варианта).
  static List<ImportedQuestion> parseBasic(String text) {
    final lines = const LineSplitter().convert(text);
    if (lines.where((l) => '\t'.allMatches(l).length >= 3).length >=
        lines.where((l) => l.trim().isNotEmpty).length / 2) {
      return _parseTable(lines);
    }

    final result = <ImportedQuestion>[];
    String? question;
    final options = <String>[];
    var correct = -1;
    String? explanation;

    void flush() {
      if (question != null && options.length >= 2) {
        result.add(
          ImportedQuestion(
            textTg: question!,
            optionsTg: List.of(options),
            correctIndex: correct,
            explanationTg: explanation,
          ),
        );
      }
      question = null;
      options.clear();
      correct = -1;
      explanation = null;
    }

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final answer = _answerLine.firstMatch(line);
      if (answer != null && options.isNotEmpty) {
        correct = _answerIndex(answer.group(1)!, options);
        continue;
      }
      final explain = _explanationLine.firstMatch(line);
      if (explain != null && question != null) {
        explanation = explain.group(1)!.trim();
        continue;
      }

      final option = _optionStart.firstMatch(line) ?? _bullet.firstMatch(line);
      if (option != null && question != null && options.length < 6) {
        var value = line.substring(option.end);
        if (_correctMark.hasMatch(value)) {
          correct = options.length;
          value = value.replaceAll(_correctMark, '');
        }
        options.add(value.trim());
        continue;
      }

      // Новый вопрос: строка с номером или любая строка после вариантов
      if (_questionStart.hasMatch(line) || options.isNotEmpty) {
        flush();
        question = line.replaceFirst(_questionStart, '').trim();
      } else {
        // Продолжение текста вопроса на следующей строке
        question = question == null ? line : '$question $line';
      }
    }
    flush();
    return result;
  }

  static List<ImportedQuestion> _parseTable(List<String> lines) {
    final result = <ImportedQuestion>[];
    for (final line in lines) {
      final cells = [for (final c in line.split('\t')) c.trim()]
        ..removeWhere((c) => c.isEmpty);
      if (cells.length < 4) continue;
      final options = cells.sublist(1, cells.length - 1).take(6).toList();
      final correct = _answerIndex(cells.last, options);
      // Строка заголовков («Савол», «A», «B», …) не даёт правильного ответа
      if (correct < 0 && result.isEmpty) continue;
      result.add(
        ImportedQuestion(
          textTg: cells.first.replaceFirst(_questionStart, ''),
          optionsTg: options,
          correctIndex: correct,
        ),
      );
    }
    return result;
  }

  /// «б», «b», «2» или текст варианта → индекс; -1, если не найдено.
  static int _answerIndex(String value, List<String> options) {
    final v = value.trim().toLowerCase().replaceAll(RegExp(r'[).:\s]+$'), '');
    if (v.length == 1) {
      final i = _letters.indexOf(v);
      if (i >= 0 && i < options.length) return i;
      final j = _latin.indexOf(v);
      if (j >= 0 && j < options.length) return j;
    }
    final n = int.tryParse(v);
    if (n != null && n >= 1 && n <= options.length) return n - 1;
    return options.indexWhere((o) => o.toLowerCase() == v);
  }
}
