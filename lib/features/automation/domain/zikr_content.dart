import '../../prayer/domain/prayer_models.dart';

class ZikrContent {
  const ZikrContent({
    required this.id,
    required this.title,
    required this.text,
    this.source,
    this.prayers = const <PrayerName>{},
  });

  final String id;
  final String title;
  final String text;
  final String? source;
  final Set<PrayerName> prayers;

  bool appliesTo(PrayerName prayer) {
    return prayers.isEmpty || prayers.contains(prayer);
  }
}

const ZikrContent entryDuaContent = ZikrContent(
  id: 'entry_dua',
  title: 'دعاء دخول المسجد',
  text: 'اللهم افتح لي أبواب رحمتك',
);

const ZikrContent exitDuaContent = ZikrContent(
  id: 'exit_dua',
  title: 'دعاء الخروج من المسجد',
  text: 'اللهم إني أسألك من فضلك',
);

const List<ZikrContent> afterPrayerAzkarContent = <ZikrContent>[
  ZikrContent(
    id: 'after_prayer_azkar_full',
    title: 'أذكار بعد الصلاة',
    text: '''
استغفر اللّٰه . استغفر اللّٰه . استغفر اللّٰه

اللهم أنت السلام ومنك السلام تباركت ياذا الجلال والإكرام

لا إله إلا اللّٰه وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير

لا حول ولا قوة إلا باللّه

لا إله إلا اللّه ولا نعبد إلا إياه، له النعمة وله الفضل وله الثناء الحسن، لا إله إلا اللّٰه مخلصين له الدين ولو كره الكافرون

اللهم لا مانع لما أعطيت ولا معطي لما منعت ولا ينفع ذا الجد منك الجد

سبحان اللّٰه ٣٣ مرة
الحمد للّه ٣٣ مرة
اللّٰه أكبر ٣٣ مرة

تمام المائة:
لا إله إلا اللّٰه وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير

بعد صلاتي الفجر والمغرب:
لا إله إلا اللّٰه وحده لا شريك له، له الملك وله الحمد يحيي ويميت وهو على كل شيء قدير
١٠ مرات

آية الكرسي:
اللّٰه لا إله إلا هو الحي القيوم...

الإخلاص:
قل هو الله أحد...

الفلق:
قل أعوذ برب الفلق...

الناس:
قل أعوذ برب الناس...

مرة واحدة بعد كل صلاة، إلا صلاتي الفجر والمغرب ثلاث مرات.''',
  ),
];
