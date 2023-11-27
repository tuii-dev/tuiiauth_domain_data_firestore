// Developed by Marcelo Glasberg (Aug 2019).
// For more info, see: https://pub.dartlang.org/packages/i18n_extension

import 'package:i18n_extension/i18n_extension.dart';

extension Localization on String {
  static final _t = Translations("en") +
      const {
        "en": "Upcoming Lessons",
      } +
      {
        "en": "First Name",
      } +
      {
        "en": "Last Name",
      } +
      {
        "en": "Next Lesson Date",
      };

  String get i18n => localize(this, _t);

  // Uncomment as needed - lowering test coverage as is cause not used

  // String fill(List<Object> params) => localizeFill(this, params);

  // String plural(int value) => localizePlural(value, this, _t);

  // String version(Object modifier) => localizeVersion(modifier, this, _t);
}
