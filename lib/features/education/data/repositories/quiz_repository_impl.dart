import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:neuroup/core/services/logger_service.dart';
import 'package:neuroup/features/education/domain/entities/quiz.dart';
import 'package:neuroup/features/education/domain/repositories/quiz_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _quizzes =>
      _db.collection('quizzes');

  @override
  Future<Quiz?> getForLesson(String lessonId) async {
    final snap = await _quizzes.where('lessonId', isEqualTo: lessonId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return _quizFromDoc(snap.docs.first);
  }

  @override
  Future<void> seedIfEmpty() async {
    final existing = await _quizzes.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    LoggerService.info('Seeding quizzes collection...');
    final batch = _db.batch();
    for (final quiz in _defaultQuizzes()) {
      batch.set(_quizzes.doc(quiz.id), _quizToMap(quiz));
    }
    await batch.commit();
  }

  @override
  QuizResult evaluate(Quiz quiz, Map<String, int> answers) {
    var score = 0;
    var correct = 0;
    for (final q in quiz.questions) {
      final ans = answers[q.id];
      if (ans == null) continue;
      if (q.isCorrect(ans)) {
        score += q.points;
        correct++;
      }
    }
    final maxScore = quiz.totalPoints;
    final percentage = maxScore == 0 ? 0 : (score / maxScore) * 100;
    return QuizResult(
      totalScore: score,
      maxScore: maxScore,
      correctCount: correct,
      totalQuestions: quiz.questions.length,
      passed: percentage >= quiz.passingScore,
    );
  }

  Quiz _quizFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final questionsRaw = data['questions'] as List<dynamic>? ?? [];
    return Quiz(
      id: doc.id,
      lessonId: data['lessonId'] as String? ?? '',
      passingScore: (data['passingScore'] as num?)?.toInt() ?? 60,
      questions: questionsRaw.map((q) {
        final m = q as Map<String, dynamic>;
        return Question(
          id: m['id'] as String,
          text: m['text'] as String? ?? '',
          options: (m['options'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
          correctIndex: (m['correctIndex'] as num?)?.toInt() ?? 0,
          explanation: m['explanation'] as String? ?? '',
          points: (m['points'] as num?)?.toInt() ?? 10,
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _quizToMap(Quiz q) => {
        'lessonId': q.lessonId,
        'passingScore': q.passingScore,
        'questions': q.questions
            .map((qu) => {
                  'id': qu.id,
                  'text': qu.text,
                  'options': qu.options,
                  'correctIndex': qu.correctIndex,
                  'explanation': qu.explanation,
                  'points': qu.points,
                })
            .toList(),
      };
}

List<Quiz> _defaultQuizzes() => const [
      Quiz(
        id: 'quiz_math_basics',
        lessonId: 'math_basics',
        questions: [
          Question(
            id: 'q1',
            text: '7 + 5 kaçtır?',
            options: ['10', '11', '12', '13'],
            correctIndex: 2,
            explanation: '7 + 5 = 12',
            points: 10,
          ),
          Question(
            id: 'q2',
            text: '9 × 3 kaçtır?',
            options: ['18', '24', '27', '30'],
            correctIndex: 2,
            explanation: '9 × 3 = 27',
            points: 10,
          ),
          Question(
            id: 'q3',
            text: '56 ÷ 8 kaçtır?',
            options: ['6', '7', '8', '9'],
            correctIndex: 1,
            explanation: '56 ÷ 8 = 7',
            points: 10,
          ),
          Question(
            id: 'q4',
            text: 'Bir üçgenin iç açıları toplamı kaç derecedir?',
            options: ['90°', '180°', '270°', '360°'],
            correctIndex: 1,
            explanation: "Üçgenin iç açıları toplamı 180°'dir.",
            points: 10,
          ),
        ],
      ),
      Quiz(
        id: 'quiz_science_intro',
        lessonId: 'science_intro',
        questions: [
          Question(
            id: 'q1',
            text: 'Suyun kimyasal formülü nedir?',
            options: ['CO2', 'H2O', 'O2', 'NaCl'],
            correctIndex: 1,
            explanation: 'Su iki hidrojen ve bir oksijenden oluşur: H2O',
            points: 10,
          ),
          Question(
            id: 'q2',
            text: "Hangi gezegen Güneş'e en yakındır?",
            options: ['Venüs', 'Mars', 'Merkür', 'Dünya'],
            correctIndex: 2,
            explanation: "Merkür Güneş'e en yakın gezegendir.",
            points: 10,
          ),
          Question(
            id: 'q3',
            text: 'Fotosentez için ne gereklidir?',
            options: [
              'Sadece su',
              'Güneş ışığı ve karbondioksit',
              'Sadece oksijen',
              'Sadece toprak',
            ],
            correctIndex: 1,
            explanation: 'Bitkiler fotosentez için güneş ışığı ve CO2 kullanır.',
            points: 10,
          ),
        ],
      ),
      Quiz(
        id: 'quiz_history_ancient',
        lessonId: 'history_ancient',
        questions: [
          Question(
            id: 'q1',
            text: 'Yazıyı icat eden uygarlık hangisidir?',
            options: ['Mısır', 'Sümer', 'Yunan', 'Roma'],
            correctIndex: 1,
            explanation: 'Çivi yazısı Sümerler tarafından icat edilmiştir.',
            points: 10,
          ),
          Question(
            id: 'q2',
            text: 'Piramitler hangi uygarlığa aittir?',
            options: ['Sümer', 'Yunan', 'Mısır', 'Roma'],
            correctIndex: 2,
            explanation: "Piramitler Antik Mısır'a aittir.",
            points: 10,
          ),
        ],
      ),
      Quiz(
        id: 'quiz_tech_logic',
        lessonId: 'tech_logic',
        questions: [
          Question(
            id: 'q1',
            text: 'Algoritma nedir?',
            options: [
              'Bir programlama dili',
              'Problem çözme adımları',
              'Bir bilgisayar markası',
              'Bir donanım parçası',
            ],
            correctIndex: 1,
            explanation: 'Algoritma, bir problemi çözmek için izlenen adımlar dizisidir.',
            points: 10,
          ),
          Question(
            id: 'q2',
            text: 'Hangi sıralama algoritması en yavaştır (ortalama durumda)?',
            options: ['Quick Sort', 'Merge Sort', 'Bubble Sort', 'Heap Sort'],
            correctIndex: 2,
            explanation: 'Bubble Sort O(n²) karmaşıklığa sahiptir.',
            points: 10,
          ),
        ],
      ),
    ];
