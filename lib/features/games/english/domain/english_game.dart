import 'dart:math';

class WordQuestion {
  const WordQuestion(this.prompt, this.options, this.answer, this.explanation);
  final String prompt, answer, explanation;
  final List<String> options;
}

const wordQuestions = [
  WordQuestion(
    'Which word means the same as happy?',
    ['Glad', 'Tired', 'Cold', 'Angry'],
    'Glad',
    'Happy and glad are synonyms: words with similar meanings.',
  ),
  WordQuestion(
    'Which word is the opposite of tiny?',
    ['Small', 'Huge', 'Little', 'Short'],
    'Huge',
    'Tiny means very small. Huge means very big.',
  ),
  WordQuestion(
    'Choose the right word: The birds ___ in the sky.',
    ['fly', 'swim', 'dig', 'crawl'],
    'fly',
    'Birds use their wings to fly in the sky.',
  ),
  WordQuestion(
    'Which word names an action?',
    ['Jump', 'Blue', 'Table', 'Soft'],
    'Jump',
    'Jump is a verb: it tells us what someone does.',
  ),
  WordQuestion(
    'Which word rhymes with light?',
    ['Night', 'Leaf', 'Late', 'Lift'],
    'Night',
    'Light and night end with the same sound.',
  ),
  WordQuestion(
    'Choose the correct sentence.',
    [
      'She has a kite.',
      'She have a kite.',
      'She having kite.',
      'She a kite has.',
    ],
    'She has a kite.',
    'With she, he or it, we use has rather than have.',
  ),
  WordQuestion(
    'Which word describes how something feels?',
    ['Rough', 'Run', 'Desk', 'Sing'],
    'Rough',
    'Rough describes a texture. It is an adjective.',
  ),
  WordQuestion(
    'What is the plural of child?',
    ['Children', 'Childs', 'Childes', 'Childrens'],
    'Children',
    'Some plurals change their spelling: one child, two children.',
  ),
  WordQuestion(
    'Mia packed an umbrella because the sky was dark. What did she expect?',
    ['Rain', 'Snow for certain', 'A sunny beach', 'A birthday party'],
    'Rain',
    'An umbrella and dark clouds are clues that Mia expected rain.',
  ),
  WordQuestion(
    'Which word means the opposite of begin?',
    ['Finish', 'Start', 'Open', 'Try'],
    'Finish',
    'Begin means to start. Finish means to reach the end.',
  ),
  WordQuestion(
    'Choose the right word: I ate ___ apple.',
    ['an', 'a', 'two', 'many'],
    'an',
    'We use an before a vowel sound, as in an apple.',
  ),
  WordQuestion(
    'Which word names a person, place or thing?',
    ['Library', 'Quickly', 'Gently', 'Very'],
    'Library',
    'Library names a place. A naming word is called a noun.',
  ),
  WordQuestion(
    'Which word means the same as quiet?',
    ['Silent', 'Noisy', 'Busy', 'Heavy'],
    'Silent',
    'Silent means without sound. Quiet and silent have similar meanings.',
  ),
  WordQuestion(
    'Which word rhymes with tree?',
    ['Bee', 'Train', 'Try', 'Tray'],
    'Bee',
    'Tree and bee share the same ending sound.',
  ),
  WordQuestion(
    'Choose the right word: Yesterday, we ___ to the park.',
    ['walked', 'walk', 'walking', 'walks'],
    'walked',
    'Yesterday tells us it happened in the past: we walked.',
  ),
  WordQuestion(
    'A puppy wagged its tail and ran to greet Sam. How did it probably feel?',
    ['Excited', 'Sleepy', 'Lonely', 'Bored'],
    'Excited',
    'Wagging its tail and running to greet someone suggest excitement.',
  ),
  WordQuestion(
    'Which word describes a sound?',
    ['Loud', 'Round', 'Green', 'Sweet'],
    'Loud',
    'Loud describes a strong sound.',
  ),
  WordQuestion(
    'Which word is spelled correctly?',
    ['Friend', 'Freind', 'Frend', 'Friand'],
    'Friend',
    'Friend is spelled f-r-i-e-n-d.',
  ),
  WordQuestion(
    'Choose the right word: The book belongs to me. It is ___.',
    ['mine', 'yours', 'theirs', 'ours'],
    'mine',
    'Mine tells us that something belongs to the person speaking.',
  ),
  WordQuestion(
    'Which word is the opposite of empty?',
    ['Full', 'Hollow', 'Vacant', 'Open'],
    'Full',
    'An empty cup has nothing in it. A full cup is filled.',
  ),
  WordQuestion(
    'Choose the right word: Two ___ swam in the pond.',
    ['fish', 'fishs', 'fishies', 'fishing'],
    'fish',
    'In this sentence, fish is both the singular and plural form.',
  ),
  WordQuestion(
    'Which sentence asks a question?',
    ['Where is my hat?', 'Here is my hat.', 'I like my hat.', 'Wear your hat.'],
    'Where is my hat?',
    'A question asks for information and ends with a question mark.',
  ),
  WordQuestion(
    'Which word means the same as quick?',
    ['Fast', 'Slow', 'Late', 'Still'],
    'Fast',
    'Quick and fast both describe speed.',
  ),
  WordQuestion(
    'Choose the right word: The flowers smell ___.',
    ['sweet', 'sweetly running', 'swim', 'yesterday'],
    'sweet',
    'Sweet describes the smell of the flowers.',
  ),
];

const buildingWords = <(String, String)>[
  ('PLANT', 'A living thing with roots and leaves'),
  ('CLOUD', 'A white or grey shape in the sky'),
  ('SMILE', 'A happy expression on your face'),
  ('RIVER', 'Water that flows towards a lake or sea'),
  ('BREAD', 'You can use slices of this to make a sandwich'),
  ('CHAIR', 'A seat with a back, usually for one person'),
  ('NIGHT', 'The time between sunset and sunrise'),
  ('BRUSH', 'Use this with toothpaste to clean your teeth'),
  ('HOUSE', 'A building where people live'),
  ('GREEN', 'The colour of most leaves'),
  ('MUSIC', 'Sounds arranged in a tune or rhythm'),
  ('WATER', 'A clear liquid we drink'),
  ('TIGER', 'A big wild cat with stripes'),
  ('BEACH', 'A sandy or pebbly place beside the sea'),
  ('DREAM', 'A story or pictures in your mind while you sleep'),
  ('TRAIN', 'A line of carriages that travels on rails'),
  ('APPLE', 'A round fruit that can be red or green'),
  ('LIGHT', 'What helps us see when it is dark'),
  ('SHEEP', 'A farm animal with a woolly coat'),
  ('STORY', 'A tale with characters and events'),
  ('HEART', 'The organ that pumps blood around your body'),
  ('EARTH', 'The planet we live on'),
  ('SPOON', 'Use this to eat soup'),
  ('CLOCK', 'Something that shows the time'),
];

List<WordQuestion> questionsForDay(int day) => [
  for (var i = 0; i < 5; i++)
    wordQuestions[(day * 5 + i) % wordQuestions.length],
];

List<(String, String)> wordsForDay(int day) => [
  for (var i = 0; i < 5; i++)
    buildingWords[(day * 5 + i) % buildingWords.length],
];

List<String> shuffledLetters(String word, int seed) {
  final letters = word.split('')..shuffle(Random(seed));
  if (letters.join() == word) {
    final different = letters.indexWhere((l) => l != letters.first);
    if (different > 0) {
      final first = letters.first;
      letters[0] = letters[different];
      letters[different] = first;
    }
  }
  return letters;
}
