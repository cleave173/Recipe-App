import 'package:flutter/material.dart';

/// Custom Kazakh Material Localizations
class KazakhMaterialLocalizations extends DefaultMaterialLocalizations {
  const KazakhMaterialLocalizations();

  @override
  String get backButtonTooltip => 'Артқа';

  @override
  String get closeButtonTooltip => 'Жабу';

  @override
  String get deleteButtonTooltip => 'Өшіру';

  @override
  String get nextMonthTooltip => 'Келесі ай';

  @override
  String get previousMonthTooltip => 'Алдыңғы ай';

  @override
  String get firstPageTooltip => 'Бірінші бет';

  @override
  String get lastPageTooltip => 'Соңғы бет';

  @override
  String get nextPageTooltip => 'Келесі бет';

  @override
  String get previousPageTooltip => 'Алдыңғы бет';

  @override
  String get showMenuTooltip => 'Мәзірді көрсету';

  @override
  String get drawerLabel => 'Навигация мәзірі';

  @override
  String get closeButtonLabel => 'ЖАБУ';

  @override
  String get continueButtonLabel => 'ЖАЛҒАСТЫРУ';

  @override
  String get copyButtonLabel => 'Көшіру';

  @override
  String get cutButtonLabel => 'Қию';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get pasteButtonLabel => 'Қою';

  @override
  String get selectAllButtonLabel => 'Барлығын таңдау';

  @override
  String get viewLicensesButtonLabel => 'Лицензияларды көру';

  @override
  String get searchFieldLabel => 'Іздеу';

  @override
  String get modalBarrierDismissLabel => 'Жабу';

  @override
  String get menuBarMenuLabel => 'Мәзір';

  @override
  String get signedInLabel => 'Кірген';

  @override
  String get hideAccountsLabel => 'Аккаунттарды жасыру';

  @override
  String get showAccountsLabel => 'Аккаунттарды көрсету';

  @override
  String get moreButtonTooltip => 'Көбірек';

  @override
  String get openAppDrawerTooltip => 'Навигация мәзірін ашу';

  @override
  String get refreshIndicatorSemanticLabel => 'Жаңарту';

  @override
  String tabLabel({required int tabIndex, required int tabCount}) {
    return 'Қойынды $tabIndex / $tabCount';
  }

  @override
  String get cancelButtonLabel => 'БАС ТАРТУ';

  @override
  String get saveButtonLabel => 'САҚТАУ';

  @override
  String get dateInputLabel => 'Күнді енгізу';

  @override
  String get dateRangePickerHelpText => 'КЕЗЕҢДІ ТАҢДАУ';

  @override
  String get datePickerHelpText => 'КҮНДІ ТАҢДАУ';

  @override
  String get timePickerDialHelpText => 'УАҚЫТТЫ ТАҢДАУ';

  @override
  String get timePickerInputHelpText => 'УАҚЫТТЫ ЕНГІЗУ';

  @override
  String get timePickerHourLabel => 'Сағат';

  @override
  String get timePickerMinuteLabel => 'Минут';

  @override
  String get invalidTimeLabel => 'Дұрыс уақыт енгізіңіз';
}

class KazakhMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const KazakhMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'kk';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const KazakhMaterialLocalizations();
  }

  @override
  bool shouldReload(KazakhMaterialLocalizationsDelegate old) => false;
}

class KazakhWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const KazakhWidgetsLocalizations();

  @override
  TextDirection get textDirection => TextDirection.ltr;
}

class KazakhWidgetsLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const KazakhWidgetsLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'kk';

  @override
  Future<WidgetsLocalizations> load(Locale locale) async {
    return const KazakhWidgetsLocalizations();
  }

  @override
  bool shouldReload(KazakhWidgetsLocalizationsDelegate old) => false;
}
