-- ============================================================================
-- Loophole content: 30 statements as 10 daily puzzles (3 per day)
-- ============================================================================
-- Run once against a project that already has 202609030001 and
-- 202609030002 applied, and an app_secrets row for
-- 'minigame_encryption_key'.
--
-- Each statement is technically true and misleading, with exactly one token
-- doing the work. `target` is a token *index* rather than the word itself,
-- because statements repeat words and an index says precisely which one.
--
-- Dated from nine days ago through today, so today's puzzle exists and the
-- archive has real depth immediately rather than filling up over a week and
-- a half. Re-running is safe: the (puzzle_date, puzzle_type) unique key
-- makes it a no-op rather than a duplicate.
-- ============================================================================

do $$
declare
  v_key text;
  v_days jsonb;
  v_day jsonb;
  v_index integer := 0;
begin
  select value into v_key from public.app_secrets where name = 'minigame_encryption_key';
  if v_key is null then
    raise exception 'no minigame_encryption_key in app_secrets - see migration 202609030001';
  end if;

  v_days := $json$[
    {
      "public": {"rounds": [
        {"statement": "This toothpaste is recommended by 90% of dentists surveyed.",
         "tokens": ["This", "toothpaste", "is", "recommended", "by", "90% of dentists", "surveyed"]},
        {"statement": "Up to 70% off everything in store.",
         "tokens": ["Up to", "70% off", "everything", "in store"]},
        {"statement": "9 out of 10 owners said their cat prefers it.",
         "tokens": ["9 out of 10", "owners", "said", "their cat", "prefers", "it"]}
      ]},
      "answer": {"rounds": [
        {"target": 6, "explanation": "Surveyed whom? The dentists who were asked were chosen by someone, and the ones who disagreed can simply be left out of the sample."},
        {"target": 0, "explanation": "\"Up to\" sets a ceiling and promises no floor. One scarf at 70% off makes the whole sign true."},
        {"target": 2, "explanation": "The owners said it. Nobody asked the cats - this measures what people reported believing, not what any cat chose."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "Crime doubles in quiet market town.",
         "tokens": ["Crime", "doubles", "in quiet market town"]},
        {"statement": "Clinically proven to reduce the appearance of wrinkles.",
         "tokens": ["Clinically proven", "to reduce", "the appearance of", "wrinkles"]},
        {"statement": "The average salary at this company is 85,000.",
         "tokens": ["The average", "salary", "at this company", "is 85,000"]}
      ]},
      "answer": {"rounds": [
        {"target": 1, "explanation": "Doubling is a ratio, not a quantity. In a quiet town it can mean one incident became two."},
        {"target": 2, "explanation": "Only the appearance is claimed. The wrinkles themselves are untouched - this is a statement about optics."},
        {"target": 0, "explanation": "An average is pulled upward by a few very large salaries, so most people here may earn far less than 85,000."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "Our cereal now contains 30% less sugar.",
         "tokens": ["Our cereal", "now", "contains", "30% less", "sugar"]},
        {"statement": "Study links coffee drinking to a longer life.",
         "tokens": ["Study", "links", "coffee drinking", "to a longer life"]},
        {"statement": "Only 2% of users reported a problem.",
         "tokens": ["Only 2%", "of users", "reported", "a problem"]}
      ]},
      "answer": {"rounds": [
        {"target": 3, "explanation": "Less than what? No baseline is given, so the comparison could be against their own unusually sugary old recipe."},
        {"target": 1, "explanation": "A link is a correlation. Coffee drinkers may also be wealthier, younger or more social - any of which could be doing the work."},
        {"target": 2, "explanation": "This counts complaints that arrived, not problems that happened. Most people who hit a problem never report it."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "Best-selling protein bar in its category.",
         "tokens": ["Best-selling", "protein bar", "in its category"]},
        {"statement": "Unemployment has fallen to a record low.",
         "tokens": ["Unemployment", "has fallen", "to a record low"]},
        {"statement": "This treatment doubles your chances of recovery.",
         "tokens": ["This treatment", "doubles", "your chances", "of recovery"]}
      ]},
      "answer": {"rounds": [
        {"target": 2, "explanation": "The category is drawn by the person making the claim. Narrow it far enough and almost anything is best-selling in it."},
        {"target": 2, "explanation": "A record since when? The window is unstated, and choosing where it starts decides whether this is remarkable or routine."},
        {"target": 1, "explanation": "Doubling a tiny chance leaves a tiny chance. Going from 1 in 10,000 to 2 in 10,000 is a doubling."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "Contains no artificial preservatives.",
         "tokens": ["Contains no", "artificial", "preservatives"]},
        {"statement": "Hospital waiting times fell since the new policy began.",
         "tokens": ["Hospital waiting times", "fell", "since", "the new policy began"]},
        {"statement": "Our app has over 5 million downloads.",
         "tokens": ["Our app", "has over", "5 million", "downloads"]}
      ]},
      "answer": {"rounds": [
        {"target": 1, "explanation": "Only artificial ones are ruled out. Salt, sugar and vinegar are preservatives too, and this says nothing about how much is in there."},
        {"target": 2, "explanation": "\"Since\" only places the fall after the policy. The decline may have started well before it, for reasons of its own."},
        {"target": 3, "explanation": "A download is not a user. It counts installs, including the ones deleted within the hour."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "Everyone else has already handed theirs in.",
         "tokens": ["Everyone else", "has already", "handed theirs in"]},
        {"statement": "Voted product of the year by consumers.",
         "tokens": ["Voted", "product of the year", "by consumers"]},
        {"statement": "Scientists say chocolate could improve memory.",
         "tokens": ["Scientists say", "chocolate", "could", "improve memory"]}
      ]},
      "answer": {"rounds": [
        {"target": 0, "explanation": "Almost never literally true, and impossible for you to check in the moment. It is pressure wearing the clothes of a fact."},
        {"target": 0, "explanation": "Voted by whom? A panel recruited and paid by the award scheme is still, technically, consumers voting."},
        {"target": 2, "explanation": "\"Could\" also permits \"could not\". It reports a possibility worth studying, not something anyone has shown."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "I never said you could not go.",
         "tokens": ["I never", "said", "you could not go"]},
        {"statement": "More than 1,000 schools have adopted the scheme.",
         "tokens": ["More than 1,000", "schools", "have adopted", "the scheme"]},
        {"statement": "This is the lowest price we have offered this year.",
         "tokens": ["This is", "the lowest price", "we have offered", "this year"]}
      ]},
      "answer": {"rounds": [
        {"target": 1, "explanation": "The defence rests entirely on the word said. A look, a sigh or a silence can refuse just as clearly and leave nothing to quote."},
        {"target": 2, "explanation": "Adopting means signing up. It does not mean anyone is using it, or that they still are."},
        {"target": 3, "explanation": "The window is chosen after the fact. If December was cheaper, starting the year in January makes this sentence true."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "A majority of teachers back the reform.",
         "tokens": ["A majority", "of teachers", "back", "the reform"]},
        {"statement": "Doctors do not want you to know this.",
         "tokens": ["Doctors", "do not want you to know", "this"]},
        {"statement": "Limited spots remaining.",
         "tokens": ["Limited", "spots", "remaining"]}
      ]},
      "answer": {"rounds": [
        {"target": 0, "explanation": "A majority of whom - all teachers, or the fraction who answered? If 40 of 2,000 replied and 21 agreed, this sentence still stands."},
        {"target": 1, "explanation": "Unfalsifiable by design. Silence becomes proof of a cover-up, so no evidence could ever count against it."},
        {"target": 0, "explanation": "Every number is a limit. The scarcity may be real, or simply a number someone chose to print."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "As seen on TV.",
         "tokens": ["As seen", "on TV"]},
        {"statement": "Customer satisfaction is up 15%.",
         "tokens": ["Customer satisfaction", "is up", "15%"]},
        {"statement": "Most people upgrade at this point.",
         "tokens": ["Most people", "upgrade", "at this point"]}
      ]},
      "answer": {"rounds": [
        {"target": 0, "explanation": "Being seen is not being endorsed. The airtime was almost certainly bought by the seller."},
        {"target": 1, "explanation": "Up from when, and measured how? A rise from a bad quarter to a slightly less bad one fits perfectly."},
        {"target": 0, "explanation": "Presented as a fact about other people, and checkable by nobody in the room. That is what makes it persuasive."}
      ]}
    },
    {
      "public": {"rounds": [
        {"statement": "Sales grew 200% last quarter.",
         "tokens": ["Sales grew", "200%", "last quarter"]},
        {"statement": "You are free to say no, of course.",
         "tokens": ["You are free to say no", "of course"]},
        {"statement": "Studies show it works.",
         "tokens": ["Studies", "show", "it works"]}
      ]},
      "answer": {"rounds": [
        {"target": 1, "explanation": "A percentage hides the starting point. Two sales becoming six is growth of 200%."},
        {"target": 1, "explanation": "\"Of course\" frames refusal as something needing an excuse. The permission is offered in a way that makes using it awkward."},
        {"target": 0, "explanation": "Unnamed and uncounted. The studies that found nothing are not in the sentence, and you cannot go and read these ones."}
      ]}
    }
  ]$json$::jsonb;

  for v_day in select * from jsonb_array_elements(v_days) loop
    insert into public.daily_puzzles (puzzle_date, puzzle_type, public_config, encrypted_answer, published_at)
    values (
      current_date - (9 - v_index),
      'loophole',
      v_day -> 'public',
      pgp_sym_encrypt((v_day -> 'answer')::text, v_key),
      now()
    )
    on conflict (puzzle_date, puzzle_type) do nothing;

    v_index := v_index + 1;
  end loop;
end $$;
