import 'dart:math';

/// Cascade: a claim at the top, twelve consequence tiles below. Build a chain
/// of five where each tile follows *because of* the one above — "this,
/// therefore this, therefore this".
///
/// Tiles come in three kinds. [CascadeKind.link]s form the one true chain.
/// [CascadeKind.sideEffect]s are genuinely true but lead nowhere in this
/// chain. [CascadeKind.myth]s sound obvious but are contradicted by
/// evidence — picking one means reasoning from intuition rather than
/// evidence, and its note says why.
enum CascadeKind { link, sideEffect, myth }

class CascadeTile {
  const CascadeTile(this.text, this.kind, this.note);
  final String text;
  final CascadeKind kind;

  /// Links: why this follows from the step before. Others: why it doesn't
  /// belong.
  final String note;
}

class CascadeClaim {
  const CascadeClaim({
    required this.claim,
    required this.chain,
    required this.extras,
  });

  final String claim;

  /// The true chain, in order.
  final List<CascadeTile> chain;
  final List<CascadeTile> extras;

  List<CascadeTile> get tiles => [...chain, ...extras];
}

enum SlotVerdict { exact, misplaced, sideEffect, myth }

class CascadeGame {
  CascadeGame(this.claim, {int seed = 0})
    : pool = List.of(claim.tiles)..shuffle(Random(seed));

  static const chainLength = 5;

  final CascadeClaim claim;
  final List<CascadeTile> pool;
  final List<CascadeTile> picked = [];
  List<SlotVerdict>? verdicts;

  bool get submitted => verdicts != null;
  bool get full => picked.length == chainLength;

  int get score =>
      (verdicts ?? const []).where((v) => v == SlotVerdict.exact).length * 20;

  void toggle(CascadeTile tile) {
    if (submitted) return;
    if (!picked.remove(tile) && !full) picked.add(tile);
  }

  void move(int from, int to) {
    if (submitted || to < 0 || to >= picked.length) return;
    picked.insert(to, picked.removeAt(from));
  }

  List<SlotVerdict> submit() {
    if (!full) throw StateError('Pick $chainLength tiles first.');
    return verdicts ??= [
      for (var i = 0; i < chainLength; i++)
        switch (picked[i].kind) {
          CascadeKind.myth => SlotVerdict.myth,
          CascadeKind.sideEffect => SlotVerdict.sideEffect,
          CascadeKind.link =>
            claim.chain.indexOf(picked[i]) == i
                ? SlotVerdict.exact
                : SlotVerdict.misplaced,
        },
    ];
  }
}

const _link = CascadeKind.link;
const _side = CascadeKind.sideEffect;
const _myth = CascadeKind.myth;

const cascadeClaims = <CascadeClaim>[
  CascadeClaim(
    claim: 'A city bans cars from its centre.',
    chain: [
      CascadeTile(
        'Far fewer cars drive through the centre',
        _link,
        'The ban takes most traffic out of the centre — everything else follows from this.',
      ),
      CascadeTile(
        'Less exhaust pollution in the air',
        _link,
        'Fewer engines running means fewer fumes.',
      ),
      CascadeTile(
        'Fewer people have asthma attacks',
        _link,
        'Cleaner air means fewer flare-ups for people with asthma.',
      ),
      CascadeTile(
        'Fewer hospital visits for breathing problems',
        _link,
        'Fewer serious attacks means fewer emergency trips.',
      ),
      CascadeTile(
        'Health money is freed up for other care',
        _link,
        'Every hospital visit avoided saves money that can be spent elsewhere.',
      ),
    ],
    extras: [
      CascadeTile(
        'Streets become quieter',
        _side,
        'True — less engine noise. But quiet streets don’t cause the next step in this chain.',
      ),
      CascadeTile(
        'More people walk and cycle in the centre',
        _side,
        'True, and good for health — but it branches off this chain rather than continuing it.',
      ),
      CascadeTile(
        'Buses move faster through the centre',
        _side,
        'Often true with fewer cars in the way, but it leads somewhere else.',
      ),
      CascadeTile(
        'Shops in the centre lose most of their customers',
        _myth,
        'Sounds obvious, but in many cities that tried it, shops kept their customers or gained more — people on foot pass far more shop windows than drivers do.',
      ),
      CascadeTile(
        'Traffic jams just move and get as bad elsewhere',
        _myth,
        'Some traffic moves, but some trips simply disappear as people change how they travel. Planners call this traffic evaporation.',
      ),
      CascadeTile(
        'Nobody visits the city centre any more',
        _myth,
        'Visitors still arrive by bus, bike, train and on foot.',
      ),
      CascadeTile(
        'Pollution rises because buses replace cars',
        _myth,
        'One bus carries dozens of people, so pollution per person goes down.',
      ),
    ],
  ),
  CascadeClaim(
    claim: 'A town plants thousands of trees along its streets.',
    chain: [
      CascadeTile(
        'Shade covers pavements and rooftops',
        _link,
        'New trees cast shade over streets and buildings.',
      ),
      CascadeTile(
        'Streets stay cooler on hot days',
        _link,
        'Shade, and water evaporating from leaves, cool the air and the ground.',
      ),
      CascadeTile(
        'People switch on air conditioning less',
        _link,
        'Cooler homes need less cooling.',
      ),
      CascadeTile(
        'The town uses less electricity',
        _link,
        'Air conditioners use a lot of electricity, so demand falls.',
      ),
      CascadeTile(
        'Power stations burn less fuel',
        _link,
        'Less demand means less fuel burned to make electricity.',
      ),
    ],
    extras: [
      CascadeTile(
        'More birds and insects live in the town',
        _side,
        'True — trees are homes and food. But wildlife doesn’t lead to the next step here.',
      ),
      CascadeTile(
        'Rain soaks into the ground instead of flooding drains',
        _side,
        'True, and useful — but it’s a different chain about water, not heat.',
      ),
      CascadeTile(
        'Streets look greener and calmer',
        _side,
        'True, but looks alone don’t cause the next step.',
      ),
      CascadeTile(
        'Trees use up the oxygen at night, making the air unsafe',
        _myth,
        'Trees do use a little oxygen at night, but it’s tiny compared with what they make by day.',
      ),
      CascadeTile(
        'Tree roots always crack the water pipes',
        _myth,
        'Roots can damage old, leaking pipes, but careful planting avoids it. “Always” is the giveaway.',
      ),
      CascadeTile(
        'Hot days get hotter because leaves trap heat',
        _myth,
        'Shade does the opposite: leafy streets are often several degrees cooler.',
      ),
      CascadeTile(
        'Everyone gets hay fever from the new trees',
        _myth,
        'Most people don’t have hay fever, and towns can choose trees that release little pollen.',
      ),
    ],
  ),
  CascadeClaim(
    claim: 'A secondary school starts its day one hour later.',
    chain: [
      CascadeTile(
        'Students sleep longer on school nights',
        _link,
        'Teenagers’ body clocks run late, so a later start mostly turns into extra sleep.',
      ),
      CascadeTile(
        'Students feel less sleepy in morning lessons',
        _link,
        'More sleep means more alert mornings.',
      ),
      CascadeTile(
        'Fewer students arrive late or miss first lesson',
        _link,
        'It’s easier to get up and out on time when you’re rested.',
      ),
      CascadeTile(
        'Students spend more time actually learning',
        _link,
        'Being present and awake adds up to more real learning time.',
      ),
      CascadeTile(
        'Grades improve',
        _link,
        'Schools that studied the change, like several in Seattle, saw grades go up.',
      ),
    ],
    extras: [
      CascadeTile(
        'School finishes later in the afternoon',
        _side,
        'True — the whole day shifts. But it doesn’t cause the next step in this chain.',
      ),
      CascadeTile(
        'Buses run on a new timetable',
        _side,
        'True, but it’s a practical change, not part of the cause-and-effect chain.',
      ),
      CascadeTile(
        'After-school clubs end later',
        _side,
        'True, but it branches off rather than leading anywhere here.',
      ),
      CascadeTile(
        'Students just stay up an hour later, so they sleep the same',
        _myth,
        'Studies that measured it, like one in Seattle, found students slept over half an hour more on school nights.',
      ),
      CascadeTile(
        'Students get lazier with more time in bed',
        _myth,
        'Being well rested usually makes people more alert, not lazier.',
      ),
      CascadeTile(
        'Lessons get shorter, so students learn less',
        _myth,
        'The school day moves later; it doesn’t have to shrink.',
      ),
      CascadeTile(
        'Students get more tired because the day ends later',
        _myth,
        'Tiredness depends most on how much you sleep — and the later start adds sleep.',
      ),
    ],
  ),
  CascadeClaim(
    claim: 'Shops start charging a small fee for plastic bags.',
    chain: [
      CascadeTile(
        'Shoppers bring their own bags',
        _link,
        'A small charge is enough to make people remember a bag from home.',
      ),
      CascadeTile(
        'Far fewer plastic bags are handed out',
        _link,
        'In England, a small charge cut the number of bags handed out by over 90%.',
      ),
      CascadeTile(
        'Fewer bags end up as litter',
        _link,
        'Fewer bags in circulation means fewer blowing around streets and parks.',
      ),
      CascadeTile(
        'Fewer bags wash into rivers and the sea',
        _link,
        'Litter travels down drains and rivers; less litter means less reaches the sea.',
      ),
      CascadeTile(
        'Fewer sea animals swallow or get tangled in plastic',
        _link,
        'Turtles and seabirds can mistake bags for food. Fewer bags, fewer accidents.',
      ),
    ],
    extras: [
      CascadeTile(
        'Shops sell more reusable bags',
        _side,
        'True — but it’s a side effect, not the next link in the chain.',
      ),
      CascadeTile(
        'Shops spend less buying bags',
        _side,
        'True, but it leads to shop budgets, not to the sea.',
      ),
      CascadeTile(
        'Some bag money goes to charities',
        _side,
        'True in some countries, but it’s a different chain.',
      ),
      CascadeTile(
        'People just buy bin bags instead, so nothing changes',
        _myth,
        'Some people buy more bin bags, but far less plastic is used overall.',
      ),
      CascadeTile(
        'Everyone switches to paper bags, which solves the problem',
        _myth,
        'Paper bags take more energy and water to make. Reusing any bag many times is what really helps.',
      ),
      CascadeTile(
        'Shoppers stop going to the shops',
        _myth,
        'People kept shopping — they just brought bags.',
      ),
      CascadeTile(
        'The sea is quickly free of plastic',
        _myth,
        'Plastic already in the sea takes a very long time to break down, so the change is gradual.',
      ),
    ],
  ),
  CascadeClaim(
    claim: 'Part of the sea is protected from fishing.',
    chain: [
      CascadeTile(
        'Fish inside the protected area live longer and grow bigger',
        _link,
        'With no fishing, fish have time to reach full size.',
      ),
      CascadeTile(
        'Bigger fish lay many more eggs',
        _link,
        'A large fish can lay many times more eggs than a small one.',
      ),
      CascadeTile(
        'More young fish drift beyond the edges',
        _link,
        'Eggs and young fish don’t stop at invisible lines — they spill outward.',
      ),
      CascadeTile(
        'Catches rise near the protected area',
        _link,
        'Scientists call it the spillover effect.',
      ),
      CascadeTile(
        'Fishing families earn more over time',
        _link,
        'Better catches nearby mean better incomes.',
      ),
    ],
    extras: [
      CascadeTile(
        'Divers come to see the wildlife',
        _side,
        'True, and good for tourism — but it’s a different chain.',
      ),
      CascadeTile(
        'Coral and seaweed have a chance to recover',
        _side,
        'True, but it branches off rather than leading to the next step.',
      ),
      CascadeTile(
        'More seabirds feed nearby',
        _side,
        'Plausible and often true, but it leads somewhere else.',
      ),
      CascadeTile(
        'All the fishing families lose their jobs',
        _myth,
        'Fishers keep working outside the protected area — and often catch more there over time.',
      ),
      CascadeTile(
        'The fish get too crowded and die out',
        _myth,
        'Numbers settle into balance; extra fish spread outward instead.',
      ),
      CascadeTile(
        'The fish stay inside forever, so nobody benefits',
        _myth,
        'Fish and their eggs move freely. Many spill out beyond the edges.',
      ),
      CascadeTile(
        'Protecting one area makes no difference to the rest of the sea',
        _myth,
        'Young fish and eggs can drift a long way, so the effect reaches far beyond the area itself.',
      ),
    ],
  ),
];
