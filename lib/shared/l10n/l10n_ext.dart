import 'package:flutter/widgets.dart';

import 'package:iqs_flutter/shared/l10n/app_localizations.dart';

/// Ergonomic access to the generated localizations: `context.l10n.someKey`
/// instead of `AppLocalizations.of(context).someKey`.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
