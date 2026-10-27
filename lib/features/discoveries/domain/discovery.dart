import 'package:flutter/material.dart';

class Discovery {
  const Discovery({
    required this.id,
    required this.title,
    required this.fact,
    required this.category,
    required this.icon,
  });
  final String id;
  final String title;
  final String fact;
  final String category;
  final IconData icon;
}

const discoveries = <Discovery>[
  Discovery(
    id: 'memory_pairs',
    title: 'Picture partners',
    fact:
        'Give each picture a name and connect it to its place. That gives you two clues to remember it.',
    category: 'Memory',
    icon: Icons.style_rounded,
  ),
  Discovery(
    id: 'memory_order',
    title: 'Make a memory story',
    fact:
        'Try joining a sequence of pictures into a little story to help remember their order.',
    category: 'Memory',
    icon: Icons.route_rounded,
  ),
  Discovery(
    id: 'word_synonyms',
    title: 'Word neighbours',
    fact: 'Synonyms are words with similar meanings, like happy and glad.',
    category: 'English',
    icon: Icons.menu_book_rounded,
  ),
  Discovery(
    id: 'word_anagrams',
    title: 'Letters can travel',
    fact:
        'An anagram rearranges the letters of a word. LISTEN and SILENT use exactly the same letters.',
    category: 'English',
    icon: Icons.abc_rounded,
  ),
  Discovery(
    id: 'octopus_hearts',
    title: 'Three hearts',
    fact:
        'An octopus has three hearts. Two serve the gills and one serves the body.',
    category: 'Science',
    icon: Icons.water_rounded,
  ),
  Discovery(
    id: 'shortest_war',
    title: 'The shortest war',
    fact: 'The Anglo-Zanzibar War of 1896 lasted less than an hour.',
    category: 'History',
    icon: Icons.history_edu_rounded,
  ),
  Discovery(
    id: 'diwali_light',
    title: 'Festival of light',
    fact:
        'Diwali celebrates light overcoming darkness across several traditions.',
    category: 'Culture',
    icon: Icons.light_mode_rounded,
  ),
  Discovery(
    id: 'memory_chunks',
    title: 'Chunk it',
    fact:
        'Your brain remembers more when it groups things. Six squares seen as two little shapes are easier to hold than six separate spots.',
    category: 'Memory',
    icon: Icons.grid_view_rounded,
  ),
  Discovery(
    id: 'context_clues',
    title: 'Clues in the sentence',
    fact:
        'When you meet a new word, the words around it often hint at what it means. Readers call these context clues.',
    category: 'English',
    icon: Icons.auto_stories_rounded,
  ),
  Discovery(
    id: 'elimination',
    title: 'Cross it out',
    fact:
        'Ruling out what can’t be true is a powerful way to find what must be. Detectives and puzzle solvers do it all the time.',
    category: 'Thinking',
    icon: Icons.rule_rounded,
  ),
  Discovery(
    id: 'halving_search',
    title: 'Halve and conquer',
    fact:
        'Guess the middle and every clue cuts what’s left in half. Ten halvings shrink 1,000 numbers to just one — it’s how computers search huge lists fast.',
    category: 'Maths',
    icon: Icons.travel_explore_rounded,
  ),
  Discovery(
    id: 'prime_numbers',
    title: 'Prime building blocks',
    fact:
        'Every whole number greater than one can be built by multiplying prime numbers.',
    category: 'Maths',
    icon: Icons.calculate_rounded,
  ),
  Discovery(
    id: 'fibonacci_nature',
    title: 'Patterns in nature',
    fact:
        'Spiral counts in many flowers and pinecones often follow neighbouring Fibonacci numbers.',
    category: 'Patterns',
    icon: Icons.filter_vintage_rounded,
  ),
  Discovery(
    id: 'weather_evidence',
    title: 'Measured clues',
    fact:
        'Timestamped weather instruments can provide stronger evidence than anonymous claims.',
    category: 'Thinking',
    icon: Icons.cloud_rounded,
  ),
  Discovery(
    id: 'aurora_lights',
    title: 'Sky ribbons',
    fact:
        'Auroras glow when charged solar particles interact with gases in Earth\'s atmosphere.',
    category: 'World',
    icon: Icons.auto_awesome_rounded,
  ),
  Discovery(
    id: 'classification_science',
    title: 'Order in the world',
    fact:
        'Classification helps scientists compare living things by grouping shared characteristics.',
    category: 'Thinking',
    icon: Icons.account_tree_rounded,
  ),
  Discovery(
    id: 'binary_patterns',
    title: 'Two can do plenty',
    fact:
        'Binary systems use only two states, yet they can encode numbers, images, music and instructions.',
    category: 'Computing',
    icon: Icons.memory_rounded,
  ),
  Discovery(
    id: 'sample_size',
    title: 'Who did they ask?',
    fact:
        'A survey can only speak for the people who answered it. If someone else chose who to ask, the result may say more about the choosing than about everyone.',
    category: 'Thinking',
    icon: Icons.poll_rounded,
  ),
  Discovery(
    id: 'giant_rings',
    title: 'Rings on every giant',
    fact:
        'Jupiter, Saturn, Uranus and Neptune all have rings. Saturn’s are simply the brightest and easiest to see.',
    category: 'Space',
    icon: Icons.public_rounded,
  ),
  Discovery(
    id: 'triangular_numbers',
    title: 'Numbers with corners',
    fact:
        'Ten-pin bowling pins stand in rows of 1, 2, 3 and 4. Numbers you can arrange as a triangle like that — 1, 3, 6, 10, 15 — are called triangular numbers.',
    category: 'Maths',
    icon: Icons.change_history_rounded,
  ),
  Discovery(
    id: 'traffic_evaporation',
    title: 'Vanishing traffic',
    fact:
        'When streets close to cars, not all the traffic moves elsewhere. Some trips disappear as people walk, cycle, take the bus or travel at other times — planners call it traffic evaporation.',
    category: 'Cities',
    icon: Icons.directions_bike_rounded,
  ),
  Discovery(
    id: 'order_matters',
    title: 'Order changes everything',
    fact:
        'Doubling 3 and then adding 4 makes 10, but adding 4 and then doubling makes 14. The same steps in a different order can land somewhere new.',
    category: 'Maths',
    icon: Icons.swap_vert_rounded,
  ),
  Discovery(
    id: 'equal_fractions',
    title: 'Same amount, new name',
    fact:
        '1/2, 2/4, 0.5 and 50% are four ways of writing exactly the same amount — like eating half a pizza whether it was cut into 2 slices or 4.',
    category: 'Maths',
    icon: Icons.pie_chart_rounded,
  ),
  Discovery(
    id: 'mirror_symmetry',
    title: 'Mirrors in nature',
    fact:
        'A butterfly’s two wings are mirror images of each other. Scientists call this bilateral symmetry, and most animals — people included — are built this way.',
    category: 'Nature',
    icon: Icons.flip_rounded,
  ),
  Discovery(
    id: 'correlation',
    title: 'Together isn’t because',
    fact:
        'Ice-cream sales and sunburns both rise in summer. They go together, but ice cream doesn’t cause sunburn — hot, sunny weather causes both.',
    category: 'Thinking',
    icon: Icons.icecream_rounded,
  ),
  Discovery(
    id: 'logic_grid',
    title: 'Solving by ruling out',
    fact:
        'Logic puzzles are solved by ruling things out. Detectives, doctors and computer programs all use the same “if it isn’t this, it must be that” thinking.',
    category: 'Thinking',
    icon: Icons.fact_check_rounded,
  ),
];
