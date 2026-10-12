import 'content_types.dart';

// TODO: review by a health professional or teacher.
// TODO: native-speaker review of all Sinhala text.

const List<DailyTip> seedTips = [
  DailyTip(
    id: 'tip-warm-bottle',
    text: Localized(
      en: 'Hold a warm water bottle on your lower belly to ease cramps.',
      si: 'වේදනාව සමනය කිරීමට පහළ බඩ මත උණු වතුර බෝතලයක් තබා ගන්න.',
    ),
    articleId: 'water-hydration',
  ),
  DailyTip(
    id: 'tip-drink-water',
    text: Localized(
      en: 'Drink water through the day.',
      si: 'දවස පුරා වතුර බොන්න.',
    ),
    articleId: 'water-hydration',
  ),
  DailyTip(
    id: 'tip-gentle-movement',
    text: Localized(
      en: 'Gentle walking or stretching can help ease cramps.',
      si: 'සෙමින් ඇවිදීම හෝ දේහ ප්‍රසාරණය වේදනාව සමනය කිරීමට උපකාර විය හැක.',
    ),
  ),
  DailyTip(
    id: 'tip-iron-meals',
    text: Localized(
      en: 'Eat iron-rich meals such as leafy greens and dhal.',
      si: 'කොළ පලා සහ පරිප්පු වැනි යකඩ බහුල ආහාර ගන්න.',
    ),
    articleId: 'iron-rich-foods',
  ),
  DailyTip(
    id: 'tip-sleep',
    text: Localized(
      en: 'Getting enough sleep helps your body feel better.',
      si: 'ප්‍රමාණවත් නින්දක් ලබා ගැනීම ඔබේ ශරීරයට හොඳින් දැනීමට උපකාර වේ.',
    ),
  ),
  DailyTip(
    id: 'tip-change-pad',
    text: Localized(
      en: 'Change your pad every 4 to 6 hours to stay comfortable.',
      si: 'සුවපහසුව සිටීමට ඔබේ පෑඩ් එක පැය 4ත් 6ත් අතර වරක් වෙනස් කරන්න.',
    ),
    articleId: 'hygiene-basics',
  ),
];

const List<MythQuestion> seedMythQuestions = [
  MythQuestion(
    id: 'myth-hair-wash',
    statement: Localized(
      en: 'You should never wash your hair during periods.',
      si: 'ඔසප්වීමේදී කිසිවිටෙකත් හිස සේදීම නොකළ යුතුය.',
    ),
    isMyth: true,
    explanation: Localized(
      en: 'Myth. Washing your hair is safe and keeps you clean and comfortable.',
      si: 'මිථ්‍යාවකි. හිස සේදීම ආරක්ෂිතය; එය ඔබව පිරිසිදුව සහ සුවපහසුව තබයි.',
    ),
  ),
  MythQuestion(
    id: 'myth-exercise',
    statement: Localized(
      en: 'Exercise or playing sports is harmful during your period.',
      si: 'ඔසප්වීමේදී ව්‍යායාම කිරීම හෝ ක්‍රීඩා කිරීම හානිකරය.',
    ),
    isMyth: true,
    explanation: Localized(
      en: 'Myth. Light activity is fine and can even ease cramps.',
      si: 'මිථ්‍යාවකි. සැහැල්ලු ක්‍රියාකාරකම් කමක් නැති අතර වේදනාව සමනය කිරීමටද හැකිය.',
    ),
  ),
  MythQuestion(
    id: 'fact-iron',
    statement: Localized(
      en: 'Eating iron-rich foods helps replace the iron you lose.',
      si: 'යකඩ බහුල ආහාර ගැනීමෙන් ඔබට අහිමි වන යකඩ ආපසු ලබා ගැනීමට උපකාර වේ.',
    ),
    isMyth: false,
    explanation: Localized(
      en: 'Fact. Leafy greens, dhal, eggs and fish all help.',
      si: 'සත්‍යයකි. කොළ පලා, පරිප්පු, බිත්තර සහ මාළු සියල්ලම උපකාර වේ.',
    ),
  ),
  MythQuestion(
    id: 'myth-unclean',
    statement: Localized(
      en: 'Periods make a girl unclean or impure.',
      si: 'ඔසප්වීම නිසා ගැහැණු ළමයෙක් අපවිත්‍ර හෝ අපිරිසිදු වේ.',
    ),
    isMyth: true,
    explanation: Localized(
      en: 'Myth. A period is a natural, healthy part of growing up.',
      si: 'මිථ්‍යාවකි. ඔසප්වීම වැඩිවියට පත්වීමේ ස්වභාවික, සෞඛ්‍ය සම්පන්න කොටසකි.',
    ),
  ),
  MythQuestion(
    id: 'fact-irregular',
    statement: Localized(
      en: 'It is common for periods to be irregular in the first year or two.',
      si: 'පළමු වසර එකේ හෝ දෙකේදී ඔසප්වීම අනියමිත වීම සාමාන්‍යයි.',
    ),
    isMyth: false,
    explanation: Localized(
      en: 'Fact. Your body is still settling into a pattern.',
      si: 'සත්‍යයකි. ඔබේ ශරීරය තවමත් රටාවකට හුරු වෙමින් පවතී.',
    ),
  ),
];
