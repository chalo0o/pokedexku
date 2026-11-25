import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:ma_game/models/evolution_model.dart';
import 'package:ma_game/services/quiz_engine.dart';

EvolutionChainInfo _chain(String parent, String child) {
  return EvolutionChainInfo(
    root: EvolutionNode(
      name: parent,
      id: 1,
      evolvesTo: [EvolutionNode(name: child, id: 2)],
    ),
  );
}

void main() {
  test('buildQuestion menyusun 4 opsi unik berisi jawaban benar', () {
    final engine = QuizEngine(
      chain: _chain('charmander', 'charmeleon'),
      randomNames: ['pikachu', 'bulbasaur', 'squirtle', 'eevee', 'charizard'],
    );

    final question = engine.buildQuestion()!;

    expect(question.prompt, contains('Charmander'));
    expect(question.correctAnswer, 'charmeleon');
    expect(question.options, contains('charmeleon'));
    expect(question.options.length, 4);
    expect(question.options.toSet().length, 4);
    expect(engine.isCorrect('charmeleon', question), true);
    expect(engine.isCorrect('pikachu', question), false);
  });

  test('single-node chain tidak menghasilkan soal', () {
    final engine = QuizEngine(
      chain: const EvolutionChainInfo(
        root: EvolutionNode(name: 'mewtwo', id: 150),
      ),
      randomNames: ['pikachu', 'bulbasaur', 'squirtle', 'eevee'],
    );

    expect(engine.buildQuestion(), isNull);
  });

  test('nama duplikat tetap menghasilkan 4 opsi unik', () {
    final engine = QuizEngine(
      chain: _chain('charmander', 'charmeleon'),
      randomNames: ['pikachu', 'pikachu', 'bulbasaur', 'squirtle', 'eevee'],
    );

    final question = engine.buildQuestion()!;

    expect(question.options.length, 4);
    expect(question.options.toSet().length, 4);
    expect(question.options, contains('charmeleon'));
  });

  test('kurang dari tiga pengganggu unik tidak menghasilkan soal', () {
    final engine = QuizEngine(
      chain: _chain('charmander', 'charmeleon'),
      randomNames: ['pikachu', 'pikachu', 'charmeleon'],
    );

    expect(engine.buildQuestion(), isNull);
  });

  test('pengganggu diambil dari kumpulan yang diacak', () {
    final engine = QuizEngine(
      chain: _chain('charmander', 'charmeleon'),
      randomNames: ['bulbasaur', 'ivysaur', 'venusaur', 'pikachu', 'eevee'],
      random: Random(0),
    );

    final question = engine.buildQuestion()!;

    expect(question.options, contains('pikachu'));
    expect(question.options, isNot(contains('bulbasaur')));
  });

  test('cabang evolusi tidak dipakai sebagai soal yang ambigu', () {
    final engine = QuizEngine(
      chain: EvolutionChainInfo(
        root: EvolutionNode(
          name: 'eevee',
          id: 133,
          evolvesTo: [
            EvolutionNode(name: 'vaporeon', id: 134),
            EvolutionNode(name: 'jolteon', id: 135),
          ],
        ),
      ),
      randomNames: ['pikachu', 'bulbasaur', 'squirtle', 'eevee'],
    );

    expect(engine.buildQuestion(), isNull);
  });
}
