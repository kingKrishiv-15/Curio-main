// Offline copy of the Loophole statements in supabase/seed_loophole.sql, so
// guests (and anyone the server can't reach) still get a daily puzzle.
// Online players are validated server-side and never see this table's
// answers over the network. Keep in sync with the seed — a test compares
// the two.

class LoopholeRound {
  const LoopholeRound({
    required this.statement,
    required this.tokens,
    required this.target,
    required this.explanation,
  });

  final String statement;
  final List<String> tokens;

  /// Index into [tokens] of the word doing the misleading work.
  final int target;
  final String explanation;
}

const loopholeDays = <List<LoopholeRound>>[
  [
    LoopholeRound(
      statement: 'This toothpaste is recommended by 90% of dentists surveyed.',
      tokens: [
        'This',
        'toothpaste',
        'is',
        'recommended',
        'by',
        '90% of dentists',
        'surveyed',
      ],
      target: 6,
      explanation:
          'Surveyed whom? The dentists who were asked were chosen by someone, and the ones who disagreed can simply be left out of the sample.',
    ),
    LoopholeRound(
      statement: 'Up to 70% off everything in store.',
      tokens: ['Up to', '70% off', 'everything', 'in store'],
      target: 0,
      explanation:
          '"Up to" sets a ceiling and promises no floor. One scarf at 70% off makes the whole sign true.',
    ),
    LoopholeRound(
      statement: '9 out of 10 owners said their cat prefers it.',
      tokens: ['9 out of 10', 'owners', 'said', 'their cat', 'prefers', 'it'],
      target: 2,
      explanation:
          'The owners said it. Nobody asked the cats - this measures what people reported believing, not what any cat chose.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'Crime doubles in quiet market town.',
      tokens: ['Crime', 'doubles', 'in quiet market town'],
      target: 1,
      explanation:
          'Doubling is a ratio, not a quantity. In a quiet town it can mean one incident became two.',
    ),
    LoopholeRound(
      statement: 'Clinically proven to reduce the appearance of wrinkles.',
      tokens: [
        'Clinically proven',
        'to reduce',
        'the appearance of',
        'wrinkles',
      ],
      target: 2,
      explanation:
          'Only the appearance is claimed. The wrinkles themselves are untouched - this is a statement about optics.',
    ),
    LoopholeRound(
      statement: 'The average salary at this company is 85,000.',
      tokens: ['The average', 'salary', 'at this company', 'is 85,000'],
      target: 0,
      explanation:
          'An average is pulled upward by a few very large salaries, so most people here may earn far less than 85,000.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'Our cereal now contains 30% less sugar.',
      tokens: ['Our cereal', 'now', 'contains', '30% less', 'sugar'],
      target: 3,
      explanation:
          'Less than what? No baseline is given, so the comparison could be against their own unusually sugary old recipe.',
    ),
    LoopholeRound(
      statement: 'Study links coffee drinking to a longer life.',
      tokens: ['Study', 'links', 'coffee drinking', 'to a longer life'],
      target: 1,
      explanation:
          'A link is a correlation. Coffee drinkers may also be wealthier, younger or more social - any of which could be doing the work.',
    ),
    LoopholeRound(
      statement: 'Only 2% of users reported a problem.',
      tokens: ['Only 2%', 'of users', 'reported', 'a problem'],
      target: 2,
      explanation:
          'This counts complaints that arrived, not problems that happened. Most people who hit a problem never report it.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'Best-selling protein bar in its category.',
      tokens: ['Best-selling', 'protein bar', 'in its category'],
      target: 2,
      explanation:
          'The category is drawn by the person making the claim. Narrow it far enough and almost anything is best-selling in it.',
    ),
    LoopholeRound(
      statement: 'Unemployment has fallen to a record low.',
      tokens: ['Unemployment', 'has fallen', 'to a record low'],
      target: 2,
      explanation:
          'A record since when? The window is unstated, and choosing where it starts decides whether this is remarkable or routine.',
    ),
    LoopholeRound(
      statement: 'This treatment doubles your chances of recovery.',
      tokens: ['This treatment', 'doubles', 'your chances', 'of recovery'],
      target: 1,
      explanation:
          'Doubling a tiny chance leaves a tiny chance. Going from 1 in 10,000 to 2 in 10,000 is a doubling.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'Contains no artificial preservatives.',
      tokens: ['Contains no', 'artificial', 'preservatives'],
      target: 1,
      explanation:
          'Only artificial ones are ruled out. Salt, sugar and vinegar are preservatives too, and this says nothing about how much is in there.',
    ),
    LoopholeRound(
      statement: 'Hospital waiting times fell since the new policy began.',
      tokens: [
        'Hospital waiting times',
        'fell',
        'since',
        'the new policy began',
      ],
      target: 2,
      explanation:
          '"Since" only places the fall after the policy. The decline may have started well before it, for reasons of its own.',
    ),
    LoopholeRound(
      statement: 'Our app has over 5 million downloads.',
      tokens: ['Our app', 'has over', '5 million', 'downloads'],
      target: 3,
      explanation:
          'A download is not a user. It counts installs, including the ones deleted within the hour.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'Everyone else has already handed theirs in.',
      tokens: ['Everyone else', 'has already', 'handed theirs in'],
      target: 0,
      explanation:
          'Almost never literally true, and impossible for you to check in the moment. It is pressure wearing the clothes of a fact.',
    ),
    LoopholeRound(
      statement: 'Voted product of the year by consumers.',
      tokens: ['Voted', 'product of the year', 'by consumers'],
      target: 0,
      explanation:
          'Voted by whom? A panel recruited and paid by the award scheme is still, technically, consumers voting.',
    ),
    LoopholeRound(
      statement: 'Scientists say chocolate could improve memory.',
      tokens: ['Scientists say', 'chocolate', 'could', 'improve memory'],
      target: 2,
      explanation:
          '"Could" also permits "could not". It reports a possibility worth studying, not something anyone has shown.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'I never said you could not go.',
      tokens: ['I never', 'said', 'you could not go'],
      target: 1,
      explanation:
          'The defence rests entirely on the word said. A look, a sigh or a silence can refuse just as clearly and leave nothing to quote.',
    ),
    LoopholeRound(
      statement: 'More than 1,000 schools have adopted the scheme.',
      tokens: ['More than 1,000', 'schools', 'have adopted', 'the scheme'],
      target: 2,
      explanation:
          'Adopting means signing up. It does not mean anyone is using it, or that they still are.',
    ),
    LoopholeRound(
      statement: 'This is the lowest price we have offered this year.',
      tokens: ['This is', 'the lowest price', 'we have offered', 'this year'],
      target: 3,
      explanation:
          'The window is chosen after the fact. If December was cheaper, starting the year in January makes this sentence true.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'A majority of teachers back the reform.',
      tokens: ['A majority', 'of teachers', 'back', 'the reform'],
      target: 0,
      explanation:
          'A majority of whom - all teachers, or the fraction who answered? If 40 of 2,000 replied and 21 agreed, this sentence still stands.',
    ),
    LoopholeRound(
      statement: 'Doctors do not want you to know this.',
      tokens: ['Doctors', 'do not want you to know', 'this'],
      target: 1,
      explanation:
          'Unfalsifiable by design. Silence becomes proof of a cover-up, so no evidence could ever count against it.',
    ),
    LoopholeRound(
      statement: 'Limited spots remaining.',
      tokens: ['Limited', 'spots', 'remaining'],
      target: 0,
      explanation:
          'Every number is a limit. The scarcity may be real, or simply a number someone chose to print.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'As seen on TV.',
      tokens: ['As seen', 'on TV'],
      target: 0,
      explanation:
          'Being seen is not being endorsed. The airtime was almost certainly bought by the seller.',
    ),
    LoopholeRound(
      statement: 'Customer satisfaction is up 15%.',
      tokens: ['Customer satisfaction', 'is up', '15%'],
      target: 1,
      explanation:
          'Up from when, and measured how? A rise from a bad quarter to a slightly less bad one fits perfectly.',
    ),
    LoopholeRound(
      statement: 'Most people upgrade at this point.',
      tokens: ['Most people', 'upgrade', 'at this point'],
      target: 0,
      explanation:
          'Presented as a fact about other people, and checkable by nobody in the room. That is what makes it persuasive.',
    ),
  ],
  [
    LoopholeRound(
      statement: 'Sales grew 200% last quarter.',
      tokens: ['Sales grew', '200%', 'last quarter'],
      target: 1,
      explanation:
          'A percentage hides the starting point. Two sales becoming six is growth of 200%.',
    ),
    LoopholeRound(
      statement: 'You are free to say no, of course.',
      tokens: ['You are free to say no', 'of course'],
      target: 1,
      explanation:
          '"Of course" frames refusal as something needing an excuse. The permission is offered in a way that makes using it awkward.',
    ),
    LoopholeRound(
      statement: 'Studies show it works.',
      tokens: ['Studies', 'show', 'it works'],
      target: 0,
      explanation:
          'Unnamed and uncounted. The studies that found nothing are not in the sentence, and you cannot go and read these ones.',
    ),
  ],
];
