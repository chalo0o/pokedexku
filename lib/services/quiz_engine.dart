import 'dart:math';

import '../models/evolution_model.dart';
import '../utils/formatters.dart';

/// Pertanyaan kuis "siapa evolusi berikutnya".
class QuizQuestion {
  final String prompt;
  final String correctAnswer;
  final List<String> options;

  const QuizQuestion({
    required this.prompt,
    required this.correctAnswer,
    required this.options,
  });
}

/// Menyusun soal dari rantai evolusi dan daftar nama Pokémon acak.
class QuizEngine {
  final EvolutionChainInfo chain;
  final List<String> randomNames;
  final Random _random;

  QuizEngine({required this.chain, required this.randomNames, Random? random})
    : _random = random ?? Random();

  void _collect(EvolutionNode node, List<EvolutionNode> output) {
    output.add(node);
    for (final child in node.evolvesTo) {
      _collect(child, output);
    }
  }

  QuizQuestion? buildQuestion() {
    final nodes = <EvolutionNode>[];
    _collect(chain.root, nodes);
    // Hanya tahap dengan satu anak yang dipakai supaya jawabannya tidak ambigu.
    final candidates = nodes
        .where((node) => node.evolvesTo.length == 1)
        .toList();
    if (candidates.isEmpty) {
      return null;
    }

    final source = candidates[_random.nextInt(candidates.length)];
    final correct = source.evolvesTo.first.name;
    final pool = List<String>.of(randomNames)..shuffle(_random);
    final distinct = <String>[];
    for (final name in pool) {
      final candidate = name.trim().toLowerCase();
      if (candidate.isEmpty || candidate == correct.toLowerCase()) {
        continue;
      }
      if (!distinct.contains(candidate)) {
        distinct.add(candidate);
      }
    }
    if (distinct.length < 3) {
      return null;
    }

    final options = <String>[correct, ...distinct.take(3)];
    options.shuffle(_random);
    return QuizQuestion(
      prompt: 'Siapa evolusi berikutnya dari ${titleCase(source.name)}?',
      correctAnswer: correct,
      options: options,
    );
  }

  bool isCorrect(String answer, QuizQuestion question) {
    return answer.trim().toLowerCase() ==
        question.correctAnswer.trim().toLowerCase();
  }
}
