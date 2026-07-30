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
];
