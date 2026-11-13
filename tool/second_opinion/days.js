// Second Opinion content. Authored by hand, never generated at play time.
//
// Each day: a topic (it completes "We asked an AI about ..."), a brief of
// 150 to 250 words, eight claim cards drawn from the brief, exactly three
// flawed claims, and a pre-written reply to each of the six fixed probes.
//
//   flawed: { <claim index>: [type, probe that exposes it, why it fails] }
//
// Types: fabricated, confident_guess, out_of_date, scope_drift, cherry_picked.
// Only one or two probes a day may expose errors; the other replies are
// plausible but tell the player nothing. build.js enforces all of this.
//
// Subjects stay with science, history, sport, geography and everyday
// claims. Nothing here touches health, politics or anything where a wrong
// answer could hurt someone.
const d = (topic, brief, claims, flawed, replies) => ({ topic, brief, claims, flawed, replies });

const demo = d(
  'the Great Wall of China',
  'The Great Wall of China is not one wall but many, built and rebuilt over roughly two thousand years. The earliest sections date from around the seventh century BC, when separate states built walls against each other. After 221 BC the first emperor, Qin Shi Huang, joined several of them together. Most of what visitors walk on today is much newer and was built during the Ming dynasty, between 1368 and 1644. Builders used whatever was nearby: rammed earth in the dry west, brick and stone near Beijing. Ming builders even mixed sticky rice into their mortar to make it stronger. The official length of the wall is 8,850 kilometres. Exactly 400,000 workers died building it. In 1482 the engineer Liu Wenbo recorded that 1,204 watchtowers were finished in a single year. Despite the popular story, the wall cannot be seen with the naked eye from the Moon, because it is far too narrow.',
  [
    'The earliest sections date from around the seventh century BC.',
    'Most of the wall that visitors see today was built during the Ming dynasty.',
    'The official length of the wall is 8,850 kilometres.',
    'Ming builders mixed sticky rice into their mortar.',
    'Exactly 400,000 workers died building it.',
    'In 1482 the engineer Liu Wenbo recorded 1,204 watchtowers finished in one year.',
    'The first emperor joined several earlier walls together after 221 BC.',
    'The wall cannot be seen with the naked eye from the Moon.',
  ],
  {
    2: ['out_of_date', 'current', 'The 8,850 kilometre figure came from a 2009 survey of the Ming sections alone. A 2012 survey of every dynasty\'s walls gave about 21,196 kilometres.'],
    4: ['confident_guess', 'source', 'Nobody kept a count of the workers who died. The number is a guess that gets repeated as if it were a record.'],
    5: ['fabricated', 'source', 'There is no record of an engineer called Liu Wenbo or of that watchtower count. The name, the year and the number were invented.'],
  },
  {
    source: 'For the dynasties and the sticky rice mortar I am drawing on published surveys and a 2010 chemistry study. For Liu Wenbo and the 1,204 watchtowers I cannot point to any record at all. I also have no source that counts worker deaths, so 400,000 is not something I can back up.',
    current: 'Mostly, since the history is settled. One number has moved, though. The 8,850 kilometres came from a 2009 survey of the Ming sections only. In 2012 a wider survey of every dynasty\'s walls gave about 21,196 kilometres.',
    example: 'The Mutianyu section near Beijing is a good example of Ming building. It has granite blocks, brick battlements and closely spaced watchtowers along a steep ridge.',
    counter: 'Some historians argue that calling it one Great Wall is misleading, since the sections were built by different rulers for different reasons and many never connected.',
    scope: 'You asked about the Great Wall, and I described when it was built, what it is made of and how long it is. I believe that stays on the question.',
    unsure: 'I am least sure about how the oldest earth sections originally looked, because wind and farming have worn so many of them away.',
  },
);

const days = [
  d(
    'how honeybees make honey',
    'Honeybees make honey from nectar, the sugary liquid inside flowers. A forager sucks nectar into a special honey stomach and carries it home, where house bees pass it from mouth to mouth and fan it with their wings until most of the water has evaporated. A single worker makes only about a twelfth of a teaspoon of honey in her whole life. Bees tell each other where good flowers are with a waggle dance, first decoded by Karl von Frisch, who shared a Nobel Prize for it in 1973. A hive has one queen, and in summer she can lay more than a thousand eggs a day. Honey keeps for a very long time because it holds so little water. Scientists have proved that bees can count to exactly 12. A 2019 study by Dr Helena Marsh at the Oslo Bee Institute found that a hive visits 4.2 million flowers a week. All bees die after they sting.',
    [
      'A single worker bee makes about a twelfth of a teaspoon of honey in her life.',
      'Karl von Frisch decoded the waggle dance and shared a Nobel Prize in 1973.',
      'In summer a queen can lay more than a thousand eggs a day.',
      'Scientists have proved that bees can count to exactly 12.',
      'A 2019 study by Dr Helena Marsh found a hive visits 4.2 million flowers a week.',
      'All bees die after they sting.',
      'Honey keeps for a very long time because it holds so little water.',
      'House bees fan the nectar with their wings to evaporate the water.',
    ],
    {
      3: ['confident_guess', 'source', 'Experiments show bees can tell apart small numbers, up to about four or five. Nothing shows a limit of exactly 12. A tidy number was stated as if it had been proved.'],
      4: ['fabricated', 'source', 'There is no Dr Helena Marsh and no Oslo Bee Institute. The study and its number were invented.'],
      5: ['cherry_picked', 'counter', 'It is true of a honeybee worker stinging thick skin, and that one case was stretched to cover every bee. Bumblebees and queen honeybees can sting again and again.'],
    },
    {
      source: 'The waggle dance and the egg-laying figures come from standard bee biology. I cannot find a Dr Helena Marsh or an Oslo Bee Institute, so I should not have quoted that study. On counting, experiments show bees telling apart small numbers up to about four or five. I have no evidence for exactly 12.',
      current: 'Yes. How bees make honey has not changed, and the waggle dance findings from the last century still stand.',
      example: 'One example is the waggle dance itself. A bee that runs straight up the comb is telling the others to fly towards the sun.',
      counter: 'The strongest objection is to the stinging line. Only honeybee workers have a barbed sting that tears out, and usually only when they sting thick skin like ours. Bumblebees and queen honeybees can sting repeatedly, so it is not true of all bees.',
      scope: 'You asked how honeybees make honey. I covered the nectar, the evaporation and the hive, then added some extra facts about bees.',
      unsure: 'I am not certain how much honey a single hive makes in a year, because it depends heavily on the weather and the flowers nearby.',
    },
  ),
  d(
    'Mount Everest',
    'Mount Everest, on the border of Nepal and China, is the highest mountain on Earth above sea level. The first people confirmed to reach the top were Edmund Hillary of New Zealand and Tenzing Norgay, a Sherpa from Nepal, on 29 May 1953. The mountain is still rising by a few millimetres each year, because the Indian plate keeps pushing north into Asia. Near the top there is only about a third of the oxygen found at sea level. Nobody has ever reached the summit without bottled oxygen. Everest is not the tallest mountain if you measure from base to peak: Mauna Kea in Hawaii is taller, but most of it is under the sea. The record for the most climbs is 21, held by Apa Sherpa. Climbing it has become safe and simple, since more than 600 people reached the summit in a single season. The mountain was named in 1865 after George Everest, a British surveyor who never saw it himself.',
    [
      'Edmund Hillary and Tenzing Norgay reached the top on 29 May 1953.',
      'Everest is still rising by a few millimetres each year.',
      'Nobody has ever reached the summit without bottled oxygen.',
      'Near the top there is about a third of the oxygen found at sea level.',
      'The record for the most climbs is 21, held by Apa Sherpa.',
      'Measured from base to peak, Mauna Kea in Hawaii is taller.',
      'Climbing it is now safe and simple, since 600 people summited in one season.',
      'It was named in 1865 after the surveyor George Everest.',
    ],
    {
      2: ['out_of_date', 'current', 'That stopped being true in 1978, when Reinhold Messner and Peter Habeler climbed it without bottled oxygen. Many climbers have done so since.'],
      4: ['out_of_date', 'current', 'Apa Sherpa\'s 21 climbs was the record years ago. Kami Rita Sherpa has since climbed Everest about 30 times.'],
      6: ['cherry_picked', 'counter', 'One reassuring number was picked out. Climbers still die on Everest in most years, and the crowds near the top add to the danger.'],
    },
    {
      source: 'The 1953 ascent and the naming are recorded history, and the rise of a few millimetres a year comes from satellite measurements of how the plates are moving.',
      current: 'Two things I said are behind the times. Reinhold Messner and Peter Habeler reached the top without bottled oxygen in 1978, and many have since. And Apa Sherpa\'s 21 climbs was passed years ago by Kami Rita Sherpa, who has now climbed it about 30 times.',
      example: 'A specific example of the thin air: near the summit a climber without extra oxygen may need several breaths for every single step.',
      counter: 'The strongest argument is against calling the climb safe and simple. I picked the one number that sounds reassuring. Climbers still die on Everest in most years, from falls, avalanches and thin air, and queues near the top make it more dangerous, not less.',
      scope: 'You asked about Mount Everest, and everything I said was about the mountain, its height and its climbers.',
      unsure: 'I am unsure exactly how fast it is rising, since estimates range from about two to four millimetres a year.',
    },
  ),
  d(
    'the 100 metres sprint',
    'The 100 metres is the shortest sprint in outdoor athletics and decides who gets called the fastest person in the world. Runners start from blocks, and a false start now means instant disqualification. The first man to run it in under ten seconds with electronic timing was Jim Hines of the United States, in 1968. The men\'s world record is 9.69 seconds, set by Usain Bolt of Jamaica at the Beijing Olympics. The women\'s world record of 10.49 seconds has stood since Florence Griffith Joyner ran it in 1988. A sprinter reaches top speed somewhere after 60 metres and is actually slowing down by the finish. A tailwind helps, so a record only counts if the wind is no stronger than two metres per second. Scientists have proved that no human will ever run the distance in under 9.40 seconds. Coach Viktor Hallberg showed in 2015 that each blink costs a sprinter 0.04 seconds. Bolt also holds the 200 metres record of 19.19 seconds.',
    [
      'A false start now means instant disqualification.',
      'Jim Hines was the first to break ten seconds with electronic timing, in 1968.',
      'The men\'s world record is 9.69 seconds, set by Usain Bolt in Beijing.',
      'The women\'s record of 10.49 seconds has stood since 1988.',
      'Sprinters are slowing down by the time they reach the finish.',
      'Scientists have proved no human will ever run under 9.40 seconds.',
      'Coach Viktor Hallberg showed in 2015 that a blink costs 0.04 seconds.',
      'A record only counts if the tailwind is two metres per second or less.',
    ],
    {
      2: ['out_of_date', 'current', 'Bolt did run 9.69 in Beijing in 2008, but a year later in Berlin he lowered the record to 9.58 seconds, which still stands.'],
      5: ['confident_guess', 'source', 'Some scientists have estimated a limit, but an estimate is a prediction. Nobody has proved where the limit is.'],
      6: ['fabricated', 'source', 'There is no coach called Viktor Hallberg and no blinking study. The name, the year and the figure were made up.'],
    },
    {
      source: 'The records and the wind rule come from World Athletics. I cannot find a coach called Viktor Hallberg or any blinking study, so I should not have included that. And nobody has proved a hard limit for the 100 metres. Some scientists have estimated one, but those are predictions, not proof.',
      current: 'Not quite. Bolt ran 9.69 in Beijing in 2008, but a year later in Berlin he lowered his own record to 9.58 seconds, and that is the record today.',
      example: 'Take the 2009 final in Berlin. The fastest runners hit their top speed between 60 and 80 metres, and every one of them was slowing a little by the line.',
      counter: 'Some people argue the 100 metres is too short to show who is really the best athlete, because one slow reaction at the start can decide the whole race.',
      scope: 'You asked about the 100 metres. I described the rules, the records and how the race unfolds, and I mentioned the 200 metres only for comparison.',
      unsure: 'I am unsure how much of a sprinter\'s time comes from the start compared with top speed, since coaches still argue about that.',
    },
  ),
  d(
    'why Pluto is no longer called a planet',
    'Pluto was discovered in 1930 by Clyde Tombaugh at the Lowell Observatory in Arizona, and for 76 years it was counted as the ninth planet. In 2006 the International Astronomical Union agreed a definition of a planet with three tests. A planet must orbit the Sun, be massive enough to pull itself into a round shape, and have cleared other objects out of its orbit. Pluto passes the first two but fails the third, because it shares its region with many icy bodies in the Kuiper belt. It is now called a dwarf planet. The decision was made official in 2011 by a vote of 4,000 schoolchildren in Prague. Pluto has five known moons, and the largest, Charon, is about half as wide as Pluto itself. No spacecraft has ever visited Pluto, so our best pictures are blurry dots. Pluto is smaller than our own Moon. Astronomers are certain that a ninth giant planet is hiding beyond it. The name was suggested by Venetia Burney, an eleven-year-old girl from Oxford.',
    [
      'Clyde Tombaugh discovered Pluto in 1930.',
      'Pluto fails the test of having cleared its orbit of other objects.',
      'A vote of 4,000 schoolchildren in Prague made the decision official in 2011.',
      'Charon, its largest moon, is about half as wide as Pluto.',
      'No spacecraft has ever visited Pluto.',
      'Pluto is smaller than our Moon.',
      'Astronomers are certain a ninth giant planet is hiding beyond Pluto.',
      'The name was suggested by an eleven-year-old, Venetia Burney.',
    ],
    {
      2: ['fabricated', 'source', 'No such vote happened. Astronomers at the International Astronomical Union decided it in 2006. The children, the city and the year were invented.'],
      4: ['out_of_date', 'current', 'That was true until July 2015, when the New Horizons probe flew past Pluto and sent back sharp pictures of mountains and ice plains.'],
      6: ['confident_guess', 'source', 'A distant ninth planet is an idea some astronomers are testing. Nobody has seen it, so "certain" claims far more than is known.'],
    },
    {
      source: 'The discovery and the 2006 definition are on record with the International Astronomical Union. I cannot find any vote by schoolchildren in Prague, so that line has no source. As for a ninth giant planet, it is a hypothesis based on the odd orbits of a few distant objects. Nobody has observed it.',
      current: 'One thing is out of date. In July 2015 the New Horizons spacecraft flew past Pluto and returned detailed pictures, including a huge heart-shaped plain of ice.',
      example: 'An example of an object sharing Pluto\'s region is Eris, found in 2005. It is almost the same size as Pluto, which helped push astronomers to agree a definition.',
      counter: 'Some planetary scientists argue the third test is unfair, because even Earth shares its orbit with thousands of asteroids, and they would rather define a planet by its roundness alone.',
      scope: 'You asked why Pluto is no longer called a planet. I gave the three tests and the one it fails, then added background about its moons and its name.',
      unsure: 'I am unsure how many more dwarf planets are out there, since estimates for the Kuiper belt run from dozens to hundreds.',
    },
  ),
  d(
    'bananas',
    'To a botanist a banana is a berry, while a strawberry is not. The banana plant is not a tree either. It is a giant herb, and its trunk is made of tightly rolled leaves. Wild bananas are full of hard seeds, but the ones in shops are seedless and are grown from cuttings, so every plant is a copy of its parent. The Gros Michel is the variety sold in most supermarkets today. India grows more bananas than any other country. Bananas are very slightly radioactive because they contain potassium, though far too little to matter. A fungus that lives in soil is now spreading through plantations, and growers are worried. Bananas will be extinct by exactly 2035. The world\'s longest banana, grown in Ecuador in 2003 by a farmer named Luis Ortega, measured 47 centimetres. Bananas float in water, and they ripen faster when kept next to other ripe fruit because of a gas called ethylene.',
    [
      'To a botanist, a banana is a berry and a strawberry is not.',
      'The banana plant is a giant herb, not a tree.',
      'The Gros Michel is the variety sold in most supermarkets today.',
      'India grows more bananas than any other country.',
      'Bananas will be extinct by exactly 2035.',
      'Farmer Luis Ortega grew a record 47 centimetre banana in Ecuador in 2003.',
      'Shop bananas are grown from cuttings, so each plant is a copy.',
      'Bananas ripen faster next to ripe fruit because of ethylene gas.',
    ],
    {
      2: ['out_of_date', 'current', 'The Gros Michel was the main export banana until the 1950s, when a soil fungus wiped out the plantations. Shops have sold the Cavendish ever since.'],
      4: ['confident_guess', 'source', 'The fungus is a real threat, but nobody knows whether or when bananas might disappear. An exact year is a guess presented as fact.'],
      5: ['fabricated', 'source', 'There is no such record and no such farmer on record. The name, the place, the year and the length were invented.'],
    },
    {
      source: 'The botany is standard, and the production figures come from the United Nations food agency. I cannot find any record of a Luis Ortega or a 47 centimetre banana. I also have no source for 2035. Scientists are worried about the fungus, but none of them gives a date.',
      current: 'One line is decades out of date. The Gros Michel was the banana everyone ate until the 1950s, when a soil fungus destroyed the plantations. The banana in shops today is a different variety, the Cavendish.',
      example: 'A specific example of ethylene at work: put a green banana in a paper bag with a ripe apple and it will turn yellow a day or two sooner.',
      counter: 'A fair objection is that calling a banana a berry confuses people, because the botanical meaning of berry has little to do with how cooks use the word.',
      scope: 'You asked about bananas, and I stayed with what they are, how they are grown and a few odd facts about them.',
      unsure: 'I am unsure how many varieties of banana exist, since counts range from several hundred to more than a thousand.',
    },
  ),
  d(
    'the marathon',
    'A marathon is 42.195 kilometres long. The distance was first run at the 1908 London Olympics and became the standard in 1921. The race is named after a Greek legend in which a messenger ran from the battlefield of Marathon to Athens. The first modern Olympic marathon, in 1896, was won by a Greek water carrier called Spyridon Louis. Women were not given an Olympic marathon until 1984. The men\'s world record is 2 hours 1 minute 39 seconds, set by Eliud Kipchoge in Berlin. The women\'s world record is 2 hours 15 minutes 25 seconds, set by Paula Radcliffe. In 2019 Kipchoge ran the distance in 1 hour 59 minutes 40 seconds in Vienna, but it did not count as a record because he used a rotating team of pacemakers. The 1904 Olympic winner took 3 hours 28 minutes, which shows that early marathon runners were simply unfit. Most big city marathons now have tens of thousands of finishers.',
    [
      'A marathon is 42.195 kilometres long.',
      'Spyridon Louis won the first modern Olympic marathon in 1896.',
      'The men\'s world record is 2:01:39, set by Eliud Kipchoge in Berlin.',
      'Women were not given an Olympic marathon until 1984.',
      'The women\'s world record is 2:15:25, set by Paula Radcliffe.',
      'Kipchoge\'s 1:59:40 in Vienna did not count because of rotating pacemakers.',
      'The 1904 winner took 3:28, which shows early runners were simply unfit.',
      'The distance was first run at the 1908 London Olympics.',
    ],
    {
      2: ['out_of_date', 'current', 'That was the record in 2018. Kipchoge lowered it in 2022, and in 2023 Kelvin Kiptum ran 2:00:35 in Chicago.'],
      4: ['out_of_date', 'current', 'Radcliffe\'s 2003 time stood for 16 years but has been beaten several times since. In 2024 Ruth Chepngetich ran 2:09:56.'],
      6: ['cherry_picked', 'counter', 'One freak race was chosen. The 1904 marathon was run in fierce heat on dusty roads with almost no water. The 1896 and 1908 winners both finished in under three hours.'],
    },
    {
      source: 'The distance and the Olympic results are in the official records of the Games, and the record times come from World Athletics lists.',
      current: 'Both records I gave are old. The men\'s mark of 2:01:39 dates from 2018. Kipchoge improved it in 2022 and Kelvin Kiptum ran 2:00:35 in 2023. Radcliffe\'s 2:15:25 dates from 2003 and has been beaten several times. Ruth Chepngetich ran 2:09:56 in 2024.',
      example: 'A specific example of a big city race is the New York City Marathon, which crosses all five boroughs and regularly has more than 50,000 finishers.',
      counter: 'The weakest thing I said was about 1904. I chose the slowest winning time in Olympic history. That race was run in about 32 degree heat on dusty roads with one water stop. In 1896 the winner ran 2:58:50 and in 1908 it was 2:55:18, so early runners were far from unfit.',
      scope: 'You asked about the marathon. I gave its distance, where it came from and its records, which all belong to the question.',
      unsure: 'I am unsure whether the Greek messenger story really happened, because the oldest accounts were written centuries later.',
    },
  ),
];

module.exports = {
  demo,
  days: [...days, ...require('./days_b.js'), ...require('./days_c.js'), ...require('./days_d.js')],
};
