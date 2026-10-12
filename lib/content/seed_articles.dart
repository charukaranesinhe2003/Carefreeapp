import 'content_types.dart';

// TODO: review by a health professional or teacher.
// TODO: native-speaker review of all Sinhala text.

const String allFilterId = 'all';

const List<ArticleCategory> seedCategories = [
  ArticleCategory(
    id: 'food-diet',
    title: Localized(en: 'Food & Diet', si: 'ආහාර සහ පෝෂණය'),
    filters: [
      FilterOption(
        id: allFilterId,
        label: Localized(en: 'All Tips', si: 'සියලු ඉඟි'),
      ),
      FilterOption(
        id: 'cramp-relief',
        label: Localized(en: 'Cramp Relief', si: 'වේදනා සහන'),
      ),
      FilterOption(
        id: 'vitamins',
        label: Localized(en: 'Vitamins', si: 'විටමින්'),
      ),
    ],
  ),
  ArticleCategory(
    id: 'our-body',
    title: Localized(en: 'Our Body', si: 'අපේ ශරීරය'),
    filters: [
      FilterOption(
        id: allFilterId,
        label: Localized(en: 'All', si: 'සියල්ල'),
      ),
      FilterOption(
        id: 'hormones',
        label: Localized(en: 'Hormones', si: 'හෝර්මෝන'),
      ),
      FilterOption(
        id: 'hygiene',
        label: Localized(en: 'Hygiene', si: 'සනීපාරක්ෂාව'),
      ),
    ],
  ),
];

const Localized<String> _nutritionLabel = Localized(
  en: 'Nutrition Guide',
  si: 'පෝෂණ මාර්ගෝපදේශය',
);

const Localized<String> _bodyLabel = Localized(
  en: 'Body Guide',
  si: 'ශරීර මාර්ගෝපදේශය',
);

const Localized<String> _villageTip = Localized(
  en: 'Village Tip',
  si: 'ගම්මැදි ඉඟිය',
);

const Localized<String> _goodToKnow = Localized(
  en: 'Good to know',
  si: 'දැනගැනීමට හොඳයි',
);

const List<Article> seedArticles = [
  // Demo article for user testing: written in full.
  Article(
    id: 'iron-rich-foods',
    categoryId: 'food-diet',
    filterTags: ['vitamins'],
    label: _nutritionLabel,
    title: Localized(
      en: 'Iron-Rich Foods For Stronger Energy',
      si: 'වැඩි ශක්තියක් සඳහා යකඩ බහුල ආහාර',
    ),
    summary: Localized(
      en: 'Simple foods that help replace the iron you lose',
      si: 'ඔබට අහිමි වන යකඩ ආපසු ලබා ගැනීමට උපකාරී සරල ආහාර',
    ),
    readMinutes: 3,
    hero: 'plate',
    body: [
      HeadingBlock(Localized(en: 'Why iron matters', si: 'යකඩ වැදගත් ඇයි?')),
      ParagraphBlock(Localized(
        en: 'During your period you lose a little iron with the blood. Iron helps your blood carry oxygen around your body. When iron is low, you may feel tired, dizzy or look pale.',
        si: 'ඔබේ ඔසප්වීමේදී රුධිරය සමඟ යකඩ ස්වල්පයක් අහිමි වේ. යකඩ මගින් ඔබේ රුධිරයට ශරීරය පුරා ඔක්සිජන් ගෙන යාමට උදව් වේ. යකඩ අඩු වූ විට ඔබට තෙහෙට්ටුව, හිස කැරකීම හෝ සුදුමැලි බව දැනිය හැක.',
      )),
      HeadingBlock(Localized(en: 'Foods to enjoy', si: 'කෑමට හොඳ ආහාර')),
      ListBlock([
        Localized(
          en: 'Dark green leaves such as mukunuwenna, kankun, murunga leaves and spinach',
          si: 'මුකුණුවැන්න, කංකුං, මුරුංගා කොළ සහ ස්පිනච් වැනි තද කොළ පාට පලා',
        ),
        Localized(
          en: 'Dhal and other pulses',
          si: 'පරිප්පු සහ අනෙකුත් රනිල ධාන්‍ය',
        ),
        Localized(en: 'Eggs', si: 'බිත්තර'),
        Localized(en: 'Fish', si: 'මාළු'),
        Localized(en: 'Chicken', si: 'කුකුළු මස්'),
      ]),
      TipBlock(
        title: _villageTip,
        text: Localized(
          en: 'Squeeze a little lime on leaves or dhal. Vitamin C helps your body absorb iron. Try not to drink tea right with your meal, because it can reduce how much iron your body takes in.',
          si: 'පලා හෝ පරිප්පු මත දෙහි ස්වල්පයක් මිරිකන්න. විටමින් C මගින් ශරීරයට යකඩ උරා ගැනීමට උපකාර වේ. ආහාර වේල සමඟම තේ පානය නොකිරීමට උත්සාහ කරන්න, මන්ද එය ශරීරය උරා ගන්නා යකඩ ප්‍රමාණය අඩු කළ හැක.',
        ),
      ),
      ParagraphBlock(Localized(
        en: 'If you often feel very tired or dizzy, or your periods are very heavy, talk to a doctor or a health worker you trust.',
        si: 'ඔබට නිතර දැඩි තෙහෙට්ටුවක් හෝ හිස කැරකීමක් දැනේ නම්, හෝ ඔබේ ඔසප්වීම ඉතා අධික නම්, ඔබ විශ්වාස කරන වෛද්‍යවරයෙකු හෝ සෞඛ්‍ය සේවකයෙකු සමඟ කතා කරන්න.',
      )),
    ],
  ),
  Article(
    id: 'water-hydration',
    categoryId: 'food-diet',
    filterTags: ['cramp-relief'],
    label: _nutritionLabel,
    title: Localized(en: 'Water & Hydration', si: 'ජලය පානය කිරීම'),
    summary: Localized(
      en: 'Why drinking water through the day can help you feel better',
      si: 'දවස පුරා වතුර බීම ඔබට හොඳින් දැනීමට උපකාර වන්නේ ඇයි',
    ),
    readMinutes: 2,
    hero: 'water',
    body: [
      ParagraphBlock(Localized(
        en: 'Drinking enough water can help with tiredness and may ease bloating for some people.',
        si: 'ප්‍රමාණවත් වතුර පානය කිරීම තෙහෙට්ටුවට උපකාර විය හැකි අතර සමහරුන්ට ඉදිමුම අඩු කිරීමටද හැකිය.',
      )),
      ListBlock([
        Localized(
          en: 'Keep a bottle of water with you at school',
          si: 'පාසලේදී ඔබ සමඟ වතුර බෝතලයක් තබා ගන්න',
        ),
        Localized(
          en: 'Sip water through the day, not only when you feel thirsty',
          si: 'පිපාසය දැනෙන විට පමණක් නොව දවස පුරා වතුර උගුරක් බැගින් බොන්න',
        ),
        Localized(
          en: 'Warm water or herbal drinks such as coriander tea can feel soothing',
          si: 'උණු වතුර හෝ කොත්තමල්ලි වැනි ඖෂධීය පානයන් සහනයක් ලබා දිය හැක',
        ),
      ]),
      TipBlock(
        title: _villageTip,
        text: Localized(
          en: 'A warm water bottle on your lower belly can ease cramps.',
          si: 'පහළ බඩ මත උණු වතුර බෝතලයක් තැබීමෙන් වේදනාව සමනය විය හැක.',
        ),
      ),
    ],
  ),
  Article(
    id: 'foods-to-limit',
    categoryId: 'food-diet',
    filterTags: ['cramp-relief'],
    label: _nutritionLabel,
    // Shown with the Figma title; the content below is deliberately accurate.
    title: Localized(en: 'Foods To Avoid', si: 'වළක්වා ගත යුතු ආහාර'),
    summary: Localized(
      en: 'What can make bloating or cramps feel worse, and what is fine',
      si: 'ඉදිමුම හෝ වේදනාව වැඩි කළ හැක්කේ කුමක්ද, කමක් නැත්තේ කුමක්ද',
    ),
    readMinutes: 3,
    hero: 'plate',
    body: [
      ParagraphBlock(Localized(
        en: 'No food is strictly forbidden during your period. But for some people, a few things can make bloating or cramps feel worse.',
        si: 'ඔසප්වීමේදී කිසිදු ආහාරයක් දැඩි ලෙස තහනම් නැත. එහෙත් සමහරුන්ට සමහර දේවල් නිසා ඉදිමුම හෝ වේදනාව වැඩි වී දැනිය හැක.',
      )),
      HeadingBlock(Localized(
        en: 'You may want to have less of',
        si: 'අඩුවෙන් ගැනීමට සිතිය හැකි දේ',
      )),
      ListBlock([
        Localized(en: 'Very salty snacks', si: 'ඉතා ලුණු සහිත කෑම'),
        Localized(en: 'Sugary drinks', si: 'සීනි සහිත පානයන්'),
        Localized(en: 'A lot of tea or coffee', si: 'බොහෝ තේ හෝ කෝපි'),
      ]),
      TipBlock(
        title: _goodToKnow,
        text: Localized(
          en: 'Spicy food is not harmful unless it upsets your stomach. Listen to your body.',
          si: 'කුළුබඩු සහිත ආහාර ඔබේ බඩට අපහසුතාවයක් ඇති නොකරන්නේ නම් හානිකර නැත. ඔබේ ශරීරයට සවන් දෙන්න.',
        ),
      ),
    ],
  ),
  Article(
    id: 'understanding-your-cycle',
    categoryId: 'our-body',
    filterTags: ['hormones'],
    label: _bodyLabel,
    title: Localized(
      en: 'Understanding Your Cycle',
      si: 'ඔබේ චක්‍රය තේරුම් ගැනීම',
    ),
    summary: Localized(
      en: 'What happens in your body each month',
      si: 'සෑම මාසයකම ඔබේ ශරීරයේ සිදු වන්නේ කුමක්ද',
    ),
    readMinutes: 4,
    hero: 'cycle',
    body: [
      ParagraphBlock(Localized(
        en: 'A menstrual cycle is counted from the first day of one period to the first day of the next. For teenagers, cycles are often between 21 and 45 days, and in the first year or two they are often irregular.',
        si: 'ඔසප් චක්‍රය ගණන් කරන්නේ එක් ඔසප්වීමක පළමු දිනයේ සිට ඊළඟ ඔසප්වීමේ පළමු දිනය දක්වාය. නව යොවුන් වියේ අයට චක්‍ර බොහෝ විට දින 21ත් 45ත් අතර වන අතර, පළමු වසර එකේ හෝ දෙකේදී ඒවා බොහෝ විට අනියමිත වේ.',
      )),
      HeadingBlock(Localized(en: 'Hormones', si: 'හෝර්මෝන')),
      ParagraphBlock(Localized(
        en: 'Hormones are body messengers. They rise and fall during the month and tell your body when to prepare for a period.',
        si: 'හෝර්මෝන යනු ශරීරයේ පණිවිඩකරුවන්ය. ඒවා මාසය තුළ ඉහළ පහළ යමින් ඔසප්වීමට සූදානම් වන විට ශරීරයට කියයි.',
      )),
      TipBlock(
        title: _goodToKnow,
        text: Localized(
          en: 'Writing down your period dates helps you see your own pattern over time.',
          si: 'ඔබේ ඔසප් දින සටහන් කර ගැනීමෙන් කාලයත් සමඟ ඔබේම රටාව දැකගත හැක.',
        ),
      ),
    ],
  ),
  Article(
    id: 'what-is-a-period',
    categoryId: 'our-body',
    filterTags: ['hormones'],
    label: _bodyLabel,
    title: Localized(en: 'What Is A Period?', si: 'ඔසප්වීම යනු කුමක්ද?'),
    summary: Localized(
      en: 'A simple, calm explanation',
      si: 'සරල, සන්සුන් පැහැදිලි කිරීමක්',
    ),
    readMinutes: 3,
    hero: 'drop',
    body: [
      ParagraphBlock(Localized(
        en: 'A period is a normal, healthy part of growing up. Each month the lining of the womb is no longer needed and leaves the body as blood through the vagina. It usually lasts 3 to 7 days.',
        si: 'ඔසප්වීම යනු වැඩිවියට පත්වීමේ සාමාන්‍ය, සෞඛ්‍ය සම්පන්න කොටසකි. සෑම මාසයකම ගර්භාෂයේ ආස්තරණය තවදුරටත් අවශ්‍ය නොවන අතර එය යෝනි මාර්ගයෙන් රුධිරය ලෙස ශරීරයෙන් පිටවේ. එය සාමාන්‍යයෙන් දින 3ත් 7ත් අතර පවතී.',
      )),
      ParagraphBlock(Localized(
        en: 'Having a period does not make anyone unclean or impure.',
        si: 'ඔසප් වීම නිසා කිසිවෙකු අපවිත්‍ර හෝ අපිරිසිදු නොවේ.',
      )),
      TipBlock(
        title: _goodToKnow,
        text: Localized(
          en: 'If you have very strong pain that stops you from doing normal things, talk to a doctor or a health worker you trust.',
          si: 'සාමාන්‍ය දේවල් කිරීමට නොහැකි තරම් දැඩි වේදනාවක් ඇත්නම්, ඔබ විශ්වාස කරන වෛද්‍යවරයෙකු හෝ සෞඛ්‍ය සේවකයෙකු සමඟ කතා කරන්න.',
        ),
      ),
    ],
  ),
  Article(
    id: 'hygiene-basics',
    categoryId: 'our-body',
    filterTags: ['hygiene'],
    label: _bodyLabel,
    title: Localized(en: 'Hygiene Basics', si: 'සනීපාරක්ෂක මූලික කරුණු'),
    summary: Localized(
      en: 'Simple habits to stay clean and comfortable',
      si: 'පිරිසිදුව සහ සුවපහසුව සිටීමට සරල පුරුදු',
    ),
    readMinutes: 3,
    hero: 'hygiene',
    body: [
      ListBlock([
        Localized(
          en: 'Change your pad every 4 to 6 hours, or sooner if it is full',
          si: 'ඔබේ පෑඩ් එක පැය 4ත් 6ත් අතර වරක්, හෝ පිරී ඇත්නම් ඊට පෙර වෙනස් කරන්න',
        ),
        Localized(
          en: 'Wash your hands before and after changing',
          si: 'වෙනස් කිරීමට පෙර සහ පසු අත් සෝදන්න',
        ),
        Localized(
          en: 'Wash the outside of the genital area with clean water. You do not need special soaps',
          si: 'ලිංගික ප්‍රදේශයේ පිටත කොටස පිරිසිදු වතුරෙන් සෝදන්න. විශේෂ සබන් අවශ්‍ය නැත',
        ),
        Localized(
          en: 'Wear clean, dry underwear',
          si: 'පිරිසිදු, වියළි යටි ඇඳුම් අඳින්න',
        ),
      ]),
      TipBlock(
        title: _villageTip,
        text: Localized(
          en: 'If you use cloth, wash it with soap and clean water and dry it fully in the sun before using it again.',
          si: 'රෙදි භාවිතා කරන්නේ නම්, සබන් සහ පිරිසිදු වතුරෙන් සෝදා නැවත භාවිතා කිරීමට පෙර හිරු එළියේ හොඳින් වියළන්න.',
        ),
      ),
    ],
  ),
  Article(
    id: 'hygiene-at-school',
    categoryId: 'our-body',
    filterTags: ['hygiene'],
    label: _bodyLabel,
    title: Localized(en: 'Hygiene At School', si: 'පාසලේදී සනීපාරක්ෂාව'),
    summary: Localized(
      en: 'Feeling prepared on a school day',
      si: 'පාසල් දිනයකදී සූදානමින් සිටීම',
    ),
    readMinutes: 3,
    hero: 'school',
    body: [
      ListBlock([
        Localized(
          en: 'Keep a spare pad and clean underwear in your bag',
          si: 'ඔබේ බෑගයේ අමතර පෑඩ් එකක් සහ පිරිසිදු යටි ඇඳුමක් තබා ගන්න',
        ),
        Localized(
          en: 'Wrap used pads in a small bag or paper and put them in a bin',
          si: 'පාවිච්චි කළ පෑඩ් කුඩා උරයක හෝ කඩදාසියක ඔතා කසල බඳුනේ දමන්න',
        ),
        Localized(
          en: 'Tell a teacher or friend you trust if you need help',
          si: 'ඔබට උදව් අවශ්‍ය නම් ඔබ විශ්වාස කරන ගුරුවරයෙකුට හෝ මිතුරියකට කියන්න',
        ),
      ]),
      TipBlock(
        title: _goodToKnow,
        text: Localized(
          en: 'You can still go to school and join in activities during your period.',
          si: 'ඔසප්වීමේදීත් ඔබට පාසලට ගොස් ක්‍රියාකාරකම්වලට සහභාගී විය හැක.',
        ),
      ),
    ],
  ),
];
