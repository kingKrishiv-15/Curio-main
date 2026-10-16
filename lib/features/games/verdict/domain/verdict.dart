/// Verdict: one claim, one piece of evidence, one decision. Does the evidence
/// support the claim, go against it, or can't it tell us yet?
///
/// Every answer comes with a short explanation and a named thinking tool
/// ("Fair test", "Counter-example", "Together isn’t because"…), so children
/// collect the ideas, not just a score. The scenarios are invented and
/// self-contained: the right verdict follows from the text alone, never from
/// facts about the outside world.
///
/// Pure Dart (no Flutter), so the bank, the daily deal and the rules are all
/// unit-tested.
library;

enum Verdict {
  supports('Supports it'),
  against('Goes against it'),
  cantTell('Can’t tell yet');

  const Verdict(this.label);

  /// The answer button's words.
  final String label;
}

/// The reasoning idea behind an answer, shown as a small tag once it is
/// revealed. The first three back a claim up (or knock it down); the rest
/// name what is missing when the evidence can't tell yet.
enum ThinkingTool {
  fairTest('Fair test'),
  enoughToTell('Enough to tell'),
  measured('Measured, not guessed'),
  counterExample('Counter-example'),
  tooFew('Too few to tell'),
  noComparison('No comparison'),
  together('Together isn’t because'),
  offTopic('Off topic'),
  opinion('Opinion, not evidence'),
  oneStory('One story isn’t proof'),
  notYet('Hasn’t happened yet');

  const ThinkingTool(this.label);
  final String label;
}

class VerdictItem {
  const VerdictItem({
    required this.id,
    required this.claim,
    required this.evidence,
    required this.verdict,
    required this.tool,
    required this.explanation,
  });

  final String id;

  /// What someone says is true — shown as the big quote.
  final String claim;

  /// The one piece of evidence to weigh against it.
  final String evidence;
  final Verdict verdict;
  final ThinkingTool tool;

  /// Why, in a sentence or two a nine-year-old can follow.
  final String explanation;
}

abstract final class VerdictRules {
  static const roundsPerDay = 5;
  static const maxClaim = 90;
  static const maxEvidence = 190;
  static const maxExplanation = 220;
}

/// Days for the daily deal to show every claim in the bank exactly once.
int get verdictCycleDays => verdictBank.length ~/ VerdictRules.roundsPerDay;

/// The five claims for [day] (a `DailyPick.dayNumber`), in play order.
///
/// The bank is dealt out one shuffled "cycle" at a time, so every claim
/// appears once before any repeats. Each day gets at least one claim of
/// each verdict, and no claim is shown two days running — not even where
/// one cycle hands over to the next.
List<VerdictItem> verdictDailySet(int day) {
  final days = verdictCycleDays;
  final cycle = (day - day % days) ~/ days; // Floors, even before day 0.
  return List.unmodifiable(_cycle(cycle)[day % days]);
}

/// Practice set number [round] (1, 2, 3…) for someone whose daily is [day].
///
/// Practice replays past days' sets, newest first, skipping any that share a
/// claim with today's or tomorrow's set — so practice never repeats today
/// and never spoils tomorrow. Within a cycle that is simply yesterday, then
/// the day before, and so on. It never awards XP; that's the page's job.
List<VerdictItem> verdictPracticeSet(int day, int round) {
  assert(round >= 1, 'Practice rounds count from 1.');
  final avoid = {...verdictDailySet(day), ...verdictDailySet(day + 1)};
  var found = 0;
  for (var back = 1; back <= 1000; back++) {
    final set = verdictDailySet(day - back);
    if (set.any(avoid.contains)) continue;
    if (++found == round) return set;
  }
  return verdictDailySet(day - round);
}

/// One claim being judged.
class VerdictRound {
  VerdictRound(this.item);

  final VerdictItem item;
  Verdict? picked;

  bool get answered => picked != null;
  bool get right => picked == item.verdict;

  /// One verdict per claim — no second guesses.
  bool pick(Verdict verdict) {
    if (answered) throw StateError('This claim already has a verdict.');
    picked = verdict;
    return right;
  }
}

/// A day's (or a practice set's) five rounds, played in order.
class VerdictGame {
  VerdictGame(List<VerdictItem> items)
    : rounds = List.unmodifiable([
        for (final item in items) VerdictRound(item),
      ]);

  final List<VerdictRound> rounds;
  int current = 0;

  VerdictRound get round => rounds[current];
  bool get isLast => current == rounds.length - 1;
  bool get allAnswered => rounds.every((r) => r.answered);
  int get score => rounds.where((r) => r.right).length;

  /// Judges the current claim; true when the verdict is right.
  bool answer(Verdict verdict) => round.pick(verdict);

  /// Moves on once the current claim has its verdict.
  void next() {
    if (!round.answered) throw StateError('Give this claim a verdict first.');
    if (isLast) throw StateError('That was the last claim.');
    current++;
  }

  /// Spoiler-free: how it went, never which verdicts were right.
  String get shareGrid =>
      rounds.map((r) => !r.answered ? '⬜' : (r.right ? '🟩' : '🟥')).join();
}

/// A cycle's days, as blocks of [VerdictRules.roundsPerDay] claims.
List<List<VerdictItem>> _cycle(int cycle) {
  final blocks = _deal(verdictBank, _Dealer(cycle * 7919 + 1013));
  // Keep the hand-over between cycles fresh: if this cycle's first day shares
  // a claim with the previous cycle's last day, swap it with a later day
  // that doesn't. The last day is never moved, so the previous cycle's last
  // day can be dealt again here without working back through every cycle.
  if (blocks.length >= 3) {
    final before = _deal(verdictBank, _Dealer((cycle - 1) * 7919 + 1013)).last;
    bool clashes(List<VerdictItem> block) => block.any(before.contains);
    if (clashes(blocks.first)) {
      for (var j = 1; j < blocks.length - 1; j++) {
        if (clashes(blocks[j])) continue;
        final first = blocks.first;
        blocks[0] = blocks[j];
        blocks[j] = first;
        break;
      }
    }
  }
  return blocks;
}

/// Shuffles [items] into days of five, each with at least one claim of
/// every verdict (as long as each verdict has a claim for every day): one
/// of each verdict first, then the spare claims fill the gaps.
List<List<VerdictItem>> _deal(List<VerdictItem> items, _Dealer dealer) {
  const size = VerdictRules.roundsPerDay;
  final days = items.length ~/ size;
  final firsts = <Verdict, List<VerdictItem>>{};
  final spare = <VerdictItem>[];
  for (final verdict in Verdict.values) {
    final group = [
      for (final item in items)
        if (item.verdict == verdict) item,
    ];
    dealer.shuffle(group);
    final take = group.length < days ? group.length : days;
    firsts[verdict] = group.sublist(0, take);
    spare.addAll(group.sublist(take));
  }
  dealer.shuffle(spare);
  final out = <List<VerdictItem>>[];
  var next = 0;
  for (var d = 0; d < days; d++) {
    final block = [
      for (final verdict in Verdict.values)
        if (d < firsts[verdict]!.length) firsts[verdict]![d],
    ];
    while (block.length < size && next < spare.length) {
      block.add(spare[next++]);
    }
    // Shuffled again so the verdicts don't always arrive in the same order.
    dealer.shuffle(block);
    out.add(block);
  }
  return out;
}

/// Park–Miller "minimal standard" generator. Tiny, and identical on every
/// platform and Dart version (products stay below 2^53, so it is exact on
/// the web too) — a date always deals the same claims, for everyone.
class _Dealer {
  _Dealer(int seed) : _state = seed % _modulus {
    if (_state == 0) _state = 1;
    for (var i = 0; i < 4; i++) {
      _step();
    }
  }

  static const _modulus = 2147483647;
  int _state;

  int _step() => _state = _state * 48271 % _modulus;

  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = _step() % (i + 1);
      final swap = list[i];
      list[i] = list[j];
      list[j] = swap;
    }
  }
}

/// The bank: 15 claims for each verdict. Keep its length a multiple of
/// [VerdictRules.roundsPerDay] so every cycle shows every claim.
const verdictBank = <VerdictItem>[
  // Supports it: a fair comparison, enough cases, or a measurement.
  VerdictItem(
    id: 'paper_plane_tips',
    claim:
        'Ravi’s paper plane with folded-up wingtips flies further than his flat one.',
    evidence:
        'Ravi threw each plane ten times from the same spot on the same day, measuring every throw. The one with folded tips went further on nine throws out of ten.',
    verdict: Verdict.supports,
    tool: ThinkingTool.fairTest,
    explanation:
        'Same thrower, same spot, same day and ten throws each — a fair test. Going further nine times out of ten is a clear pattern, not a fluke.',
  ),
  VerdictItem(
    id: 'cress_windowsill',
    claim:
        'Our cress grows taller on the sunny windowsill than in the dark cupboard.',
    evidence:
        'Class 4 sowed two trays from one seed packet, with the same soil and the same water each day. A week later, the windowsill cress was 6 cm tall and the cupboard cress 2 cm.',
    verdict: Verdict.supports,
    tool: ThinkingTool.fairTest,
    explanation:
        'Only one thing was different: where each tray sat. In a fair test like that, the place is the best reason for the gap — and 6 cm against 2 cm is clear.',
  ),
  VerdictItem(
    id: 'trip_vote',
    claim:
        'Most children at our school would choose the farm for the summer trip.',
    evidence:
        'Every class held a vote. Out of the 250 children in the school, 212 picked the farm and 38 picked the museum.',
    verdict: Verdict.supports,
    tool: ThinkingTool.enoughToTell,
    explanation:
        'The whole school voted, not just a few friends, and far more than half chose the farm. That’s plenty of answers to tell.',
  ),
  VerdictItem(
    id: 'camp_rain_gauge',
    claim:
        'It rained more on the Tuesday of our camping trip than on the Monday.',
    evidence:
        'The class rain gauge was checked and emptied every evening of the trip. It held 3 mm of rain on Monday and 18 mm on Tuesday.',
    verdict: Verdict.supports,
    tool: ThinkingTool.measured,
    explanation:
        'The gauge measured both days in exactly the same way, so we don’t have to rely on how soggy it felt. 18 mm is far more than 3 mm.',
  ),
  VerdictItem(
    id: 'toy_car_floors',
    claim:
        'Toy cars roll further on the wooden hall floor than on the classroom carpet.',
    evidence:
        'Zara rolled the same car down the same ramp five times on each floor. On wood it went about 3 metres every time; on carpet, it never got past 1 metre.',
    verdict: Verdict.supports,
    tool: ThinkingTool.fairTest,
    explanation:
        'Same car, same ramp, five goes on each floor — only the floor changed. Every wooden run beat every carpet run, so the evidence backs the claim.',
  ),
  VerdictItem(
    id: 'library_loans',
    claim:
        'Funny books are borrowed more than any other kind from our school library.',
    evidence:
        'The library computer counted every loan last term. Funny books were borrowed 340 times. The next most popular kind, adventure stories, was borrowed 210 times.',
    verdict: Verdict.supports,
    tool: ThinkingTool.measured,
    explanation:
        'The computer counted every single loan, so this isn’t a guess or a feeling. Funny books came top by a long way.',
  ),
  VerdictItem(
    id: 'cupcake_eggs',
    claim: 'Beating the eggs for longer makes Leo’s cupcakes rise higher.',
    evidence:
        'Leo baked two batches from one recipe, side by side in the same oven. The only change: eggs beaten for 1 minute or for 5. Every 5-minute cake rose higher than every 1-minute cake.',
    verdict: Verdict.supports,
    tool: ThinkingTool.fairTest,
    explanation:
        'Same recipe, same oven, same time — only the beating changed. When every long-beaten cake rises higher, the beating is the best explanation.',
  ),
  VerdictItem(
    id: 'playground_shade',
    claim:
        'The playground is warmer in the sun than in the shade of the big oak tree.',
    evidence:
        'Every lunchtime for a week, Priya left two matching thermometers out for ten minutes, one in the sun and one in the oak’s shade. The sunny one read warmer every day.',
    verdict: Verdict.supports,
    tool: ThinkingTool.measured,
    explanation:
        'Matching thermometers, the same time of day, five days in a row. Measuring beats guessing, and it came out the same way every single time.',
  ),
  VerdictItem(
    id: 'class_whistlers',
    claim: 'Most children in Class 3 can whistle.',
    evidence:
        'Mr Patel asked all 30 children in Class 3 to whistle, one at a time. 22 of them could.',
    verdict: Verdict.supports,
    tool: ThinkingTool.enoughToTell,
    explanation:
        'Everyone in the class had a go, not just a few, and 22 out of 30 is well over half. That’s enough to tell.',
  ),
  VerdictItem(
    id: 'bird_feeders',
    claim: 'More birds visit the feeder by the hedge than the one by the path.',
    evidence:
        'For two weeks, Year 5 counted the birds at both feeders for 15 minutes every morning. The hedge feeder had more visitors on all ten school days.',
    verdict: Verdict.supports,
    tool: ThinkingTool.enoughToTell,
    explanation:
        'Both feeders were watched at the same times, on lots of days. Winning on all ten days is a steady pattern, not a one-off.',
  ),
  VerdictItem(
    id: 'sunflower_height',
    claim: 'Amara’s sunflower is taller than she is.',
    evidence:
        'Amara is 135 cm tall. Her dad measured the sunflower with a tape measure: 162 cm from the soil to the top of the flower.',
    verdict: Verdict.supports,
    tool: ThinkingTool.measured,
    explanation:
        'A tape measure gives real numbers to compare, and 162 cm is more than 135 cm. No squinting or guessing needed!',
  ),
  VerdictItem(
    id: 'lemonade_sign',
    claim: 'Our lemonade stall sells more cups when we put up a big sign.',
    evidence:
        'For four sunny Saturdays we took turns: sign, no sign, sign, no sign. Same spot, same price, same hours. Sign days sold 31 and 28 cups; no-sign days sold 12 and 15.',
    verdict: Verdict.supports,
    tool: ThinkingTool.fairTest,
    explanation:
        'The sign was the only thing that changed, and both sign days sold about twice as much. Taking turns like that makes it a fair test.',
  ),
  VerdictItem(
    id: 'year6_travel',
    claim: 'Most Year 6 pupils walk or cycle to school.',
    evidence:
        'For two weeks, the morning register recorded how every Year 6 pupil got to school. Each day, at least 45 of the 60 pupils had walked or cycled.',
    verdict: Verdict.supports,
    tool: ThinkingTool.enoughToTell,
    explanation:
        'Every pupil was counted, every day for two weeks. At least 45 out of 60 is well over half each time, so the claim holds up.',
  ),
  VerdictItem(
    id: 'penalty_corners',
    claim:
        'In our team, penalties aimed at the corners score more often than ones down the middle.',
    evidence:
        'At practice, all 12 players took 4 penalties at the corners and 4 down the middle, against the same goalkeeper. Corner shots scored 38 times; middle shots, 19.',
    verdict: Verdict.supports,
    tool: ThinkingTool.fairTest,
    explanation:
        'Everyone took the same number of each kind against the same keeper, so it’s a fair test. 38 goals against 19 is a big, clear difference.',
  ),
  VerdictItem(
    id: 'ice_in_socks',
    claim:
        'An ice cube wrapped in a woolly sock melts more slowly than an unwrapped one.',
    evidence:
        'At the science fair, Kofi put five ice cubes in woolly socks and five without, all on the same table. After an hour, every bare cube had melted; every sock still held some ice.',
    verdict: Verdict.supports,
    tool: ThinkingTool.fairTest,
    explanation:
        'Five of each, same table, same time — only the sock changed. It may sound surprising, but the fair test shows the socks slowed the melting.',
  ),

  // Goes against it: a counter-example to "always", "never" or "every", or
  // a measurement that clearly disagrees.
  VerdictItem(
    id: 'hamster_daytime',
    claim:
        'Biscuit the class hamster never comes out of his house in the daytime.',
    evidence:
        'On Thursday at 11 o’clock in the morning, the whole class watched Biscuit climb out of his house and run on his wheel for five minutes.',
    verdict: Verdict.against,
    tool: ThinkingTool.counterExample,
    explanation:
        '“Never” means not even once. The whole class saw him out in the morning, and for a “never” claim, one clear example the other way is enough.',
  ),
  VerdictItem(
    id: 'sports_day_rain',
    claim: 'It always rains on our sports day.',
    evidence:
        'The school diary says last year’s sports day was dry and sunny from start to finish.',
    verdict: Verdict.against,
    tool: ThinkingTool.counterExample,
    explanation:
        '“Always” means every single year. One dry, sunny sports day is a counter-example, so the claim can’t be right — even if it often rains.',
  ),
  VerdictItem(
    id: 'cartwheels',
    claim: 'Nobody in Class 2 can do a cartwheel.',
    evidence:
        'In PE on Monday, Hana and Yusuf from Class 2 each did three cartwheels in front of the whole class.',
    verdict: Verdict.against,
    tool: ThinkingTool.counterExample,
    explanation:
        '“Nobody” means not one person. Two children doing cartwheels in front of everyone is a clear counter-example.',
  ),
  VerdictItem(
    id: 'classroom_afternoon',
    claim: 'Our classroom is colder in the afternoon than in the morning.',
    evidence:
        'The class thermometer was read at 9 am and at 2 pm every school day for two weeks. The 2 pm reading was warmer every single time.',
    verdict: Verdict.against,
    tool: ThinkingTool.measured,
    explanation:
        'Ten days of careful measuring found the afternoons warmer every time — the opposite of what the claim says.',
  ),
  VerdictItem(
    id: 'tomato_music',
    claim: 'Tomato plants grow taller when music is played to them.',
    evidence:
        'Class 6 grew 10 tomato plants beside a speaker playing music and 10 in a quiet room, with the same light, soil and water. Measured every week, the two groups stayed level.',
    verdict: Verdict.against,
    tool: ThinkingTool.fairTest,
    explanation:
        'If music made them taller, the music plants would have pulled ahead. In a fair test they stayed level all month, so the evidence goes against the claim.',
  ),
  VerdictItem(
    id: 'snails_dry_day',
    claim: 'Snails only come out when it’s raining.',
    evidence:
        'On a dry, sunny afternoon, after a week with no rain at all, Year 3 found eleven snails crawling along the wall behind the shed.',
    verdict: Verdict.against,
    tool: ThinkingTool.counterExample,
    explanation:
        'The claim says snails come out only in the rain. Eleven snails out and about on a dry, sunny day show that isn’t true.',
  ),
  VerdictItem(
    id: 'tallest_slide',
    claim: 'The new slide is the tallest thing in the playground.',
    evidence:
        'The caretaker measured them all: the slide is 3 metres tall, the climbing frame is 4 metres and the flagpole is 6 metres.',
    verdict: Verdict.against,
    tool: ThinkingTool.measured,
    explanation:
        'Measuring settles it. The climbing frame and the flagpole are both taller than the slide, so the claim is wrong.',
  ),
  VerdictItem(
    id: 'cake_sale_chocolate',
    claim: 'Every cake at the school cake sale had chocolate in it.',
    evidence:
        'The cake sale list shows all 24 cakes. Two of them, a lemon drizzle and a carrot cake, had no chocolate at all.',
    verdict: Verdict.against,
    tool: ThinkingTool.counterExample,
    explanation:
        '“Every” means all 24. Even one cake without chocolate would prove the claim wrong — and there were two.',
  ),
  VerdictItem(
    id: 'heavy_parachute',
    claim:
        'Paper parachutes fall more slowly when they carry a heavier weight.',
    evidence:
        'Ella made two paper parachutes the same size, one carrying a heavier weight. She dropped each from the same height ten times, and the heavier one landed first every time.',
    verdict: Verdict.against,
    tool: ThinkingTool.fairTest,
    explanation:
        'Same size, same height, ten drops each — a fair test. The heavier parachute was quicker every time, which is the opposite of the claim.',
  ),
  VerdictItem(
    id: 'tortoise_greens',
    claim: 'Shelly, our school tortoise, won’t eat anything green.',
    evidence:
        'The feeding diary shows Shelly ate green leaves on Monday, Wednesday and Friday: lettuce, then cabbage, then dandelion leaves.',
    verdict: Verdict.against,
    tool: ThinkingTool.counterExample,
    explanation:
        'The diary shows Shelly eating green food three times. Just one of those would be enough to prove the claim wrong.',
  ),
  VerdictItem(
    id: 'comics_vote',
    claim: 'Most of Class 5 would rather read comics than chapter books.',
    evidence:
        'Mrs Okafor asked all 28 children in Class 5 to vote in secret. 9 picked comics and 19 picked chapter books.',
    verdict: Verdict.against,
    tool: ThinkingTool.enoughToTell,
    explanation:
        'Everyone in the class voted, and only 9 out of 28 chose comics, which is fewer than half. The class’s answer doesn’t match the claim.',
  ),
  VerdictItem(
    id: 'hill_temperature',
    claim: 'It’s always colder at the top of the hill than at the bottom.',
    evidence:
        'On the school trip, the class read two thermometers at the same time, one at the bottom of the hill and one at the top. That morning, the top was 2 °C warmer.',
    verdict: Verdict.against,
    tool: ThinkingTool.counterExample,
    explanation:
        '“Always” means every time. One careful measurement with the top warmer is a counter-example, so the claim isn’t always true, even if it often is.',
  ),
  VerdictItem(
    id: 'heaviest_pumpkin',
    claim: 'Our class grew the heaviest pumpkin in the school.',
    evidence:
        'At the harvest show, every class pumpkin was weighed. Class 2’s weighed 6 kg, ours weighed 4 kg and Class 6’s weighed 3 kg.',
    verdict: Verdict.against,
    tool: ThinkingTool.measured,
    explanation:
        'The scales show Class 2’s pumpkin was heavier than ours. Weighing gives an answer anyone can check.',
  ),
  VerdictItem(
    id: 'lucky_socks',
    claim: 'When Ollie wears his lucky socks, his team never loses.',
    evidence:
        'Ollie wore his lucky socks to every match this season. His team won 6 matches and lost 3.',
    verdict: Verdict.against,
    tool: ThinkingTool.counterExample,
    explanation:
        'If the socks meant never losing, there would be no losses with them on. Three losses in lucky socks show the claim is wrong.',
  ),
  VerdictItem(
    id: 'fish_tank',
    claim: 'Our class fish tank holds more than 50 litres of water.',
    evidence:
        'Noor filled the empty tank using a 5-litre jug, full each time. The water reached the top after exactly 8 jugfuls.',
    verdict: Verdict.against,
    tool: ThinkingTool.measured,
    explanation:
        'Eight jugs of 5 litres is 40 litres, and that filled it. 40 is less than 50, so the measurement goes against the claim.',
  ),

  // Can't tell yet: the evidence is missing something, and the explanation
  // names it.
  VerdictItem(
    id: 'lunch_break_friends',
    claim: 'Most children at our school want a longer lunch break.',
    evidence:
        'Jonah asked his three best friends if they wanted a longer lunch break. All three said yes.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.tooFew,
    explanation:
        'Three friends aren’t the whole school, and friends often think alike. To know what most children want, you’d need to ask lots more, from every class.',
  ),
  VerdictItem(
    id: 'balloon_once',
    claim: 'A balloon rubbed on a woolly jumper will always stick to the wall.',
    evidence:
        'Omar rubbed a balloon on his jumper once, held it against the wall, and it stuck.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.tooFew,
    explanation:
        'It worked once, but “always” means every time, and one go can’t show that. You’d need lots of tries. (One balloon that fell off would disprove it, though!)',
  ),
  VerdictItem(
    id: 'new_trainers',
    claim: 'Grace runs faster in her new trainers than in her old ones.',
    evidence:
        'Wearing her new trainers, Grace ran the 60 metres in 11 seconds on Tuesday.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.noComparison,
    explanation:
        'We don’t know her time in the old trainers, so there’s nothing to compare with. One time on its own can’t show “faster”.',
  ),
  VerdictItem(
    id: 'bean_plant_food',
    claim: 'Plant food is what made our bean plants grow so tall.',
    evidence:
        'We gave all of our bean plants plant food every week. After a month, they were 30 cm tall.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.noComparison,
    explanation:
        'Every plant got plant food, so there’s nothing to compare with. Beans without it might have reached 30 cm too. A fair test needs some plants without.',
  ),
  VerdictItem(
    id: 'chess_club_maths',
    claim: 'Going to chess club makes children better at maths.',
    evidence:
        'Children in the school chess club got higher marks in the maths test, on average, than children who aren’t in the club.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.together,
    explanation:
        'Chess and good maths marks go together here, but that doesn’t show chess caused it. Children who already love puzzles and numbers might be the ones who join.',
  ),
  VerdictItem(
    id: 'sunflower_bees',
    claim:
        'Bees visit the tallest sunflowers most because they are the tallest.',
    evidence:
        'In the school garden, the tallest sunflowers had the most bees on them.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.together,
    explanation:
        'Height and bees came together, but that doesn’t mean the height brings the bees. The tall ones might also have bigger flowers, or more sun.',
  ),
  VerdictItem(
    id: 'front_row_spelling',
    claim:
        'Sitting at the front of the class helps children do better in spelling tests.',
    evidence:
        'In Mr Ahmed’s class, the children who sit at the front tables got the highest marks in this week’s spelling test.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.together,
    explanation:
        'Front seats and high marks came together, but that doesn’t prove the seats did it. Keen spellers might choose the front, or something else might explain it.',
  ),
  VerdictItem(
    id: 'hamster_book',
    claim: 'Biscuit, our class hamster, likes sunflower seeds best of all.',
    evidence:
        'A pet book in the school library says that rabbits like carrots more than any other food.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.offTopic,
    explanation:
        'The book is about rabbits, not hamsters, and it never mentions Biscuit. Evidence about something else can’t tell us what he likes best.',
  ),
  VerdictItem(
    id: 'spelling_bee_swimmer',
    claim: 'Dev is the fastest swimmer in Year 5.',
    evidence:
        'Dev won the Year 5 spelling bee last week, beating everyone in the year.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.offTopic,
    explanation:
        'Winning the spelling bee shows Dev is a great speller, but it tells us nothing about swimming. That evidence is about something else.',
  ),
  VerdictItem(
    id: 'goalkeeper_brother',
    claim: 'Ruby is the best goalkeeper in the school.',
    evidence:
        'Ruby’s big brother says she’s the best goalkeeper he has ever seen.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.opinion,
    explanation:
        'That’s one person’s opinion — and he’s her brother! Counting how many shots each goalkeeper saves would tell us far more.',
  ),
  VerdictItem(
    id: 'garden_tomatoes',
    claim: 'Our school garden grows the tastiest tomatoes in town.',
    evidence:
        'Mr Green, who looks after the school garden, says they’re the tastiest tomatoes he has ever eaten.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.opinion,
    explanation:
        'That’s just Mr Green’s opinion, and he grew them, so he might be a bit proud! A fair taste test against tomatoes from other gardens would tell us more.',
  ),
  VerdictItem(
    id: 'lucky_pencil',
    claim: 'Isla’s lucky pencil helps her do well in spelling tests.',
    evidence:
        'Last Friday, Isla used her lucky pencil and got 10 out of 10 in her spelling test.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.oneStory,
    explanation:
        'That’s just one story. Isla might have scored 10 anyway, maybe because she practised. You’d need lots of tests, with and without the pencil, to tell.',
  ),
  VerdictItem(
    id: 'hedgehog_visits',
    claim: 'A hedgehog visits our school garden every night.',
    evidence:
        'The caretaker says he once saw a hedgehog by the bins as he was locking up.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.oneStory,
    explanation:
        'One sighting, one time, can’t tell us about every night. A wildlife camera left out for a few weeks would give much better evidence.',
  ),
  VerdictItem(
    id: 'trip_weather',
    claim: 'It will be sunny on our school trip next Friday.',
    evidence: 'It was sunny on our school trip last year.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.notYet,
    explanation:
        'Next Friday hasn’t happened yet, and last year’s weather can’t tell us about it. A weather forecast nearer the day would help much more.',
  ),
  VerdictItem(
    id: 'lemonade_sell_out',
    claim: 'Our lemonade stall will sell out on Saturday.',
    evidence: 'We’ve made 40 cups of lemonade, ready for Saturday.',
    verdict: Verdict.cantTell,
    tool: ThinkingTool.notYet,
    explanation:
        'Saturday hasn’t happened yet, and we don’t know how many people will want lemonade. Only the day itself can tell us if all 40 cups go.',
  ),
];
