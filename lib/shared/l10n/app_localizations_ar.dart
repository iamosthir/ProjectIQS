// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'IQS';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get refresh => 'تحديث';

  @override
  String get loadingLabel => 'جارٍ التحميل…';

  @override
  String get errorTitle => 'حدث خطأ';

  @override
  String get errorUnexpected => 'حدث خطأ غير متوقع';

  @override
  String get noConnectionTitle => 'لا يوجد اتصال';

  @override
  String get noConnectionBody => 'تحقّق من اتصالك بالإنترنت ثم حاول مجدداً';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get loadMore => 'تحميل المزيد';

  @override
  String get endOfList => 'انتهت القائمة';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال خلال $secondsث';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get search => 'بحث';

  @override
  String get close => 'إغلاق';

  @override
  String get confirm => 'تأكيد';

  @override
  String get share => 'مشاركة';

  @override
  String get send => 'إرسال';

  @override
  String get back => 'رجوع';

  @override
  String get next => 'التالي';

  @override
  String get done => 'تم';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get ok => 'حسناً';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get required => 'مطلوب';

  @override
  String get invalidNumber => 'رقم غير صالح';

  @override
  String get savedChanges => 'تم حفظ التغييرات';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get governorate => 'المحافظة';

  @override
  String get selectGovernorate => 'اختر المحافظة';

  @override
  String get selectHint => 'اختر';

  @override
  String get searchHint => 'ابحث…';

  @override
  String get searchShort => 'بحث…';

  @override
  String get none => 'بدون';

  @override
  String get typeToSearch => 'اكتب للبحث';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navMatches => 'المباريات';

  @override
  String get navNews => 'الأخبار';

  @override
  String get navVideo => 'الفيديو';

  @override
  String get navMore => 'المزيد';

  @override
  String get adminNameAr => 'الاسم (عربي)';

  @override
  String get adminNameEn => 'الاسم (English)';

  @override
  String get adminDescriptionAr => 'الوصف (عربي)';

  @override
  String get adminDescriptionEn => 'الوصف (English)';

  @override
  String get adminCity => 'المدينة';

  @override
  String get adminAddress => 'العنوان';

  @override
  String get adminFoundedYear => 'سنة التأسيس';

  @override
  String get adminPhone => 'الهاتف';

  @override
  String get adminEmail => 'البريد';

  @override
  String get adminWebsite => 'الموقع';

  @override
  String get adminFacebook => 'فيسبوك';

  @override
  String get adminInstagram => 'انستغرام';

  @override
  String get adminTwitter => 'تويتر';

  @override
  String get adminTitleAr => 'العنوان (عربي)';

  @override
  String get adminTitleEn => 'العنوان (English)';

  @override
  String get adminExcerptAr => 'المقتطف (عربي)';

  @override
  String get adminExcerptEn => 'المقتطف (English)';

  @override
  String get adminContentAr => 'المحتوى (عربي)';

  @override
  String get adminContentEn => 'المحتوى (English)';

  @override
  String get adminAuthorName => 'الكاتب';

  @override
  String get adminPublished => 'منشور';

  @override
  String get adminPositionAr => 'المنصب (عربي)';

  @override
  String get adminPositionEn => 'المنصب (English)';

  @override
  String get adminParentIdOptional => 'معرّف الرئيس (اختياري)';

  @override
  String get adminDisplayOrder => 'الترتيب';

  @override
  String get adminRoleAr => 'الدور (عربي)';

  @override
  String get adminRoleEn => 'الدور (English)';

  @override
  String get adminType => 'النوع';

  @override
  String get adminBio => 'نبذة';

  @override
  String get adminHonorTitleAr => 'اللقب (عربي)';

  @override
  String get adminHonorTitleEn => 'اللقب (English)';

  @override
  String get adminCompetitionAr => 'البطولة (عربي)';

  @override
  String get adminCompetitionEn => 'البطولة (English)';

  @override
  String get adminSeason => 'الموسم';

  @override
  String get adminYear => 'السنة';

  @override
  String get adminCount => 'العدد';

  @override
  String get adminPeriodFrom => 'من سنة';

  @override
  String get adminPeriodTo => 'إلى سنة';

  @override
  String get adminDescriptionShort => 'وصف';

  @override
  String get adminStatus => 'الحالة';

  @override
  String get adminLeagueIdOptional => 'معرّف الدوري (اختياري)';

  @override
  String get adminStaffCoaching => 'تدريب';

  @override
  String get adminStaffTechnical => 'فني';

  @override
  String get adminStaffMedical => 'طبي';

  @override
  String get adminStaffAdmin => 'إداري';

  @override
  String get adminCompActive => 'قائمة';

  @override
  String get adminCompPast => 'سابقة';

  @override
  String get adminChildBoard => 'مجلس الإدارة';

  @override
  String get adminChildStaff => 'الجهاز';

  @override
  String get adminChildTitles => 'البطولات';

  @override
  String get adminChildCaptains => 'القادة';

  @override
  String get adminChildCompetitions => 'المنافسات';

  @override
  String get authWelcomeTitle => 'مرحباً بك في IQS';

  @override
  String get authWelcomeSubtitle => 'وجهتك الأولى لكل ما يخص الرياضة العراقية';

  @override
  String get authLoginButton => 'تسجيل الدخول';

  @override
  String get authRegisterButton => 'إنشاء حساب جديد';

  @override
  String get authSocialLoginLabel => 'تسجيل الدخول كـ';

  @override
  String get authInvalidIraqiPhone => 'أدخل رقم هاتف عراقي صحيح';

  @override
  String get authEnterPhoneTitle => 'أدخل رقم هاتفك';

  @override
  String get authEnterPhoneSubtitle => 'سنرسل لك رمز تحقّق عبر رسالة نصية';

  @override
  String get authContinue => 'متابعة';

  @override
  String get authNameRequired => 'الاسم مطلوب';

  @override
  String get authCompleteProfileTitle => 'إكمال الملف الشخصي';

  @override
  String get authTellUsMore => 'أخبرنا المزيد عنك';

  @override
  String get authNameLabel => 'الاسم';

  @override
  String get authNameHint => 'اسمك الكامل';

  @override
  String get authEmailOptionalLabel => 'البريد الإلكتروني (اختياري)';

  @override
  String get authSaveAndContinue => 'حفظ ومتابعة';

  @override
  String get authGenderOptionalLabel => 'الجنس (اختياري)';

  @override
  String get authGenderMale => 'ذكر';

  @override
  String get authGenderFemale => 'أنثى';

  @override
  String get authDobOptionalLabel => 'تاريخ الميلاد (اختياري)';

  @override
  String get authSelectDate => 'اختر التاريخ';

  @override
  String get authUpdateRequiredTitle => 'تحديث مطلوب';

  @override
  String get authUpdateAvailableTitle => 'تحديث متوفر';

  @override
  String get authUpdateBody =>
      'يتوفر إصدار جديد من التطبيق. يرجى التحديث للحصول على أحدث الميزات.';

  @override
  String get authUpdateNow => 'تحديث الآن';

  @override
  String get authLater => 'لاحقاً';

  @override
  String get authOtpSixDigits => 'أدخل الرمز المكوّن من 6 أرقام';

  @override
  String get authOtpTitle => 'رمز التحقّق';

  @override
  String get authOtpSentTo => 'أدخل الرمز المرسل إلى';

  @override
  String authDebugOtpFill(Object otp) {
    return 'رمز تجريبي (Dev): $otp — اضغط للتعبئة';
  }

  @override
  String get homeGreeting => 'مرحباً بك';

  @override
  String get homeSubtitle => 'تابع أخر أخبار الرياضة العراقية';

  @override
  String get homeSectionsTitle => 'أقسام التطبيق';

  @override
  String get homeSectionTeams => 'الفرق';

  @override
  String get homeLatestNewsTitle => 'أحدث الأخبار';

  @override
  String get homeNoNews => 'لا توجد أخبار';

  @override
  String get homeMainNewsBadge => 'خبر رئيسي';

  @override
  String get discoveryTypeAll => 'الكل';

  @override
  String get discoveryTypeTeams => 'فرق';

  @override
  String get discoveryTypePlayers => 'لاعبون';

  @override
  String get discoveryTypeClubs => 'أندية';

  @override
  String get discoveryTypeFanGroups => 'جماهير';

  @override
  String get discoveryTypeMarket => 'السوق';

  @override
  String get discoverySearchHint => 'ابحث عن فريق، لاعب، نادٍ…';

  @override
  String get discoverySearchInIqs => 'ابحث في IQS';

  @override
  String get discoverySearchMinChars => 'اكتب حرفين على الأقل للبحث';

  @override
  String get discoveryPageFallbackTitle => 'صفحة';

  @override
  String get discoveryErrorTitle => 'عذراً';

  @override
  String get discoveryPageNotAvailableTitle => 'الصفحة غير متوفّرة';

  @override
  String get discoveryPageNotAvailableBody => 'هذه الصفحة غير متاحة حالياً';

  @override
  String get discoveryBackToHome => 'العودة للرئيسية';

  @override
  String get matchesNavFilterAll => 'الكل';

  @override
  String get matchesNavFilterToday => 'اليوم';

  @override
  String get matchesNavFilterTomorrow => 'غداً';

  @override
  String get matchesNavFilterEnded => 'انتهت';

  @override
  String get matchesNavAllMatches => 'كل المباريات';

  @override
  String get matchesNavAllLeagues => 'كل البطولات';

  @override
  String get matchesNavSeason => 'الموسم';

  @override
  String get matchesNavSelectSeason => 'اختر الموسم';

  @override
  String get matchesNavCurrentSeason => 'الحالي';

  @override
  String get matchesNavNoMatches => 'لا توجد مباريات';

  @override
  String get matchesNavStatusLive => 'مباشر';

  @override
  String get matchesNavStatusEnded => 'انتهت';

  @override
  String get matchesNavStatusNotStarted => 'لم تبدأ';

  @override
  String get matchesNavLeagues => 'البطولات';

  @override
  String get matchesNavNoLeagues => 'لا توجد بطولات';

  @override
  String matchesNavSeasonLabel(Object season) {
    return 'موسم $season';
  }

  @override
  String get matchesNavTabStandings => 'الترتيب';

  @override
  String get matchesNavTabScorers => 'الهدافون';

  @override
  String get matchesNavLeagueTitle => 'البطولة';

  @override
  String get matchesNavNoStandings => 'لا يتوفر ترتيب';

  @override
  String get matchesNavNoScorers => 'لا يوجد هدافون';

  @override
  String get matchesNavGoals => 'هدف';

  @override
  String get matchesNavTabSquad => 'التشكيلة';

  @override
  String get matchesNavPosGoalkeeper => 'حراس المرمى';

  @override
  String get matchesNavPosDefender => 'المدافعون';

  @override
  String get matchesNavPosMidfielder => 'لاعبو الوسط';

  @override
  String get matchesNavPosAttacker => 'المهاجمون';

  @override
  String get matchesNavPosOther => 'أخرى';

  @override
  String get matchesNavTeamTitle => 'الفريق';

  @override
  String matchesNavFoundedYear(Object year) {
    return 'تأسس $year';
  }

  @override
  String get matchesNavNoSquad => 'لا تتوفر التشكيلة';

  @override
  String get matchesNavPlayerTitle => 'اللاعب';

  @override
  String get matchesNavNationality => 'الجنسية';

  @override
  String get matchesNavDateOfBirth => 'تاريخ الميلاد';

  @override
  String get matchesNavHeight => 'الطول';

  @override
  String get matchesNavWeight => 'الوزن';

  @override
  String get matchesNavBirthPlace => 'مكان الميلاد';

  @override
  String get matchesNavStatus => 'الحالة';

  @override
  String get matchesNavInjured => 'مصاب';

  @override
  String get matchesNavNoExtraInfo => 'لا تتوفر معلومات إضافية';

  @override
  String get matchesNavColTeam => 'الفريق';

  @override
  String get matchesNavColPlayed => 'لعب';

  @override
  String get matchesNavColGoalDiff => 'فارق';

  @override
  String get matchesNavColPoints => 'نقاط';

  @override
  String get matchDetailTabEvents => 'الأحداث';

  @override
  String get matchDetailTabDetails => 'التفاصيل';

  @override
  String get matchDetailTabLineups => 'التشكيلة';

  @override
  String get matchDetailTabStatistics => 'الإحصائيات';

  @override
  String get matchDetailTabStandings => 'الترتيب';

  @override
  String get matchDetailTabScores => 'النتائج';

  @override
  String get matchDetailTabNews => 'الأخبار';

  @override
  String get matchDetailTabFanZone => 'منطقة الجماهير';

  @override
  String get matchDetailTabPredictions => 'التوقعات';

  @override
  String get matchDetailTitle => 'تفاصيل المباراة';

  @override
  String get matchDetailLikeUpdateFailed => 'تعذّر تحديث الإعجاب';

  @override
  String get matchDetailStatusLive => 'مباشر';

  @override
  String get matchDetailStatusFinished => 'انتهت';

  @override
  String get matchDetailStatusNotStarted => 'لم تبدأ';

  @override
  String get matchDetailPeriodFirstHalf => 'الشوط الأول';

  @override
  String get matchDetailPeriodFullTime => 'الوقت الأصلي';

  @override
  String get matchDetailPeriodExtraTime => 'الوقت الإضافي';

  @override
  String get matchDetailPeriodPenalties => 'ركلات الترجيح';

  @override
  String get matchDetailScoresEmptySubtitle =>
      'ستظهر نتيجة الأشواط بعد بدء المباراة.';

  @override
  String get matchDetailInfoTournament => 'البطولة';

  @override
  String get matchDetailInfoRound => 'الجولة';

  @override
  String get matchDetailInfoStadium => 'الملعب';

  @override
  String get matchDetailInfoStatus => 'الحالة';

  @override
  String get matchDetailEventsEmptyTitle => 'لا توجد أحداث';

  @override
  String get matchDetailEventsEmptySubtitle =>
      'ستظهر أهداف المباراة والبطاقات هنا';

  @override
  String matchDetailEventSubOut(Object name) {
    return 'خرج: $name';
  }

  @override
  String matchDetailEventAssist(Object name) {
    return 'تمريرة: $name';
  }

  @override
  String get matchDetailLineupsEmptyTitle => 'لا تتوفر التشكيلة';

  @override
  String get matchDetailLineupsEmptySubtitle => 'ستظهر تشكيلة الفريقين هنا';

  @override
  String matchDetailLineupCoach(Object name) {
    return 'المدرب: $name';
  }

  @override
  String get matchDetailLineupStarters => 'الأساسيون';

  @override
  String get matchDetailLineupSubstitutes => 'البدلاء';

  @override
  String get matchDetailStatsEmptyTitle => 'لا توجد إحصائيات';

  @override
  String get matchDetailStatsEmptySubtitle => 'ستظهر إحصائيات المباراة هنا';

  @override
  String get matchDetailStatBallPossession => 'الاستحواذ';

  @override
  String get matchDetailStatTotalShots => 'التسديدات';

  @override
  String get matchDetailStatShotsOnGoal => 'تسديدات على المرمى';

  @override
  String get matchDetailStatShotsOffGoal => 'تسديدات خارج المرمى';

  @override
  String get matchDetailStatCornerKicks => 'الركنيات';

  @override
  String get matchDetailStatOffsides => 'التسلل';

  @override
  String get matchDetailStatFouls => 'الأخطاء';

  @override
  String get matchDetailStatYellowCards => 'بطاقات صفراء';

  @override
  String get matchDetailStatRedCards => 'بطاقات حمراء';

  @override
  String get matchDetailStatGoalkeeperSaves => 'تصديات الحارس';

  @override
  String get matchDetailStatPasses => 'التمريرات';

  @override
  String get matchDetailStatPassesAccurate => 'تمريرات دقيقة';

  @override
  String get matchDetailStandingsEmptyTitle => 'لا يتوفر ترتيب';

  @override
  String get matchDetailNewsEmptyTitle => 'لا توجد أخبار';

  @override
  String get matchDetailNewsEmptySubtitle => 'ستظهر أخبار المباراة هنا';

  @override
  String get matchSocialPredictionSaved => 'تم حفظ توقّعك';

  @override
  String get matchSocialCrowdPredictions => 'توقّعات الجمهور';

  @override
  String matchSocialPredictionsCount(Object count) {
    return '$count توقّع';
  }

  @override
  String get matchSocialNoPredictions => 'لا توجد توقّعات';

  @override
  String matchSocialTeamWins(Object team) {
    return 'فوز $team';
  }

  @override
  String get matchSocialDraw => 'تعادل';

  @override
  String get matchSocialCorrectPredictionsLink => 'التوقعات الصحيحة ›';

  @override
  String get matchSocialEditPrediction => 'تعديل التوقّع';

  @override
  String get matchSocialSavePrediction => 'احفظ توقّعك';

  @override
  String get matchSocialPredictionsClosed => 'أُغلق باب التوقّعات';

  @override
  String matchSocialYourPrediction(Object score) {
    return 'توقّعك: $score';
  }

  @override
  String get matchSocialCorrectPredictionsTitle => 'التوقعات الصحيحة';

  @override
  String get matchSocialNoCorrectPredictions => 'لا توجد توقعات صحيحة بعد';

  @override
  String get matchSocialUser => 'مستخدم';

  @override
  String get matchSocialExactScore => 'نتيجة دقيقة';

  @override
  String get matchSocialEditComment => 'تعديل التعليق';

  @override
  String get matchSocialDeleteComment => 'حذف التعليق';

  @override
  String get matchSocialDeleteCommentConfirm => 'هل تريد حذف هذا التعليق؟';

  @override
  String matchSocialRepliesCount(Object count) {
    return 'الردود ($count)';
  }

  @override
  String get matchSocialReply => 'رد';

  @override
  String get matchSocialSortNewest => 'الأحدث';

  @override
  String get matchSocialSortOldest => 'الأقدم';

  @override
  String get matchSocialSortMostLiked => 'الأكثر إعجاباً';

  @override
  String get matchSocialSortMostActive => 'الأكثر تفاعلاً';

  @override
  String get matchSocialNoComments => 'لا توجد تعليقات';

  @override
  String get matchSocialBeFirstToComment => 'كن أول من يعلّق';

  @override
  String get matchSocialAddCommentHint => 'أضف تعليقاً…';

  @override
  String get matchSocialContextMatch => 'المباراة';

  @override
  String get matchSocialContextPredictions => 'التوقعات';

  @override
  String get matchSocialCommentsTitle => 'التعليقات';

  @override
  String get matchSocialRepliesTitle => 'الردود';

  @override
  String get matchSocialNoReplies => 'لا توجد ردود';

  @override
  String get matchSocialBeFirstToReply => 'كن أول من يرد';

  @override
  String get matchSocialAddReplyHint => 'أضف رداً…';

  @override
  String get matchSocialNewsTitle => 'الخبر';

  @override
  String get matchSocialNewsUnavailable => 'تعذّر عرض الخبر';

  @override
  String get marketNoListings => 'لا توجد إعلانات';

  @override
  String get marketSearchHint => 'ابحث في السوق…';

  @override
  String get marketFeaturedChip => '⭐ مميز';

  @override
  String get marketAllChip => 'الكل';

  @override
  String get marketListingDetailsTitle => 'تفاصيل الإعلان';

  @override
  String get marketInfoName => 'الاسم';

  @override
  String get marketInfoAge => 'العمر';

  @override
  String get marketInfoNationality => 'الجنسية';

  @override
  String get marketInfoCity => 'المدينة';

  @override
  String get marketContact => 'تواصل';

  @override
  String marketViewsCount(Object count) {
    return '$count مشاهدة';
  }

  @override
  String marketContactsCount(Object count) {
    return '$count تواصل';
  }

  @override
  String get marketCvLabel => 'السيرة الذاتية (CV)';

  @override
  String get marketContactChannels => 'وسائل التواصل';

  @override
  String get marketContactFetchError => 'تعذّر جلب وسائل التواصل';

  @override
  String get marketNoDirectContact =>
      'يرجى المتابعة عبر المنصة — لا تتوفر وسائل تواصل مباشرة حالياً.';

  @override
  String get marketChannelCall => 'اتصال';

  @override
  String get marketChannelWhatsapp => 'واتساب';

  @override
  String get marketChannelEmail => 'البريد';

  @override
  String get sellerStatusDraft => 'مسودة';

  @override
  String get sellerStatusPendingPayment => 'بانتظار الدفع';

  @override
  String get sellerStatusPendingReview => 'قيد المراجعة';

  @override
  String get sellerStatusPublished => 'منشور';

  @override
  String get sellerStatusRejected => 'مرفوض';

  @override
  String get sellerStatusExpired => 'منتهٍ';

  @override
  String get sellerStatusSuspended => 'موقوف';

  @override
  String get sellerMyStoreTitle => 'متجري';

  @override
  String get sellerCreateStoreHeadline => 'أنشئ متجرك';

  @override
  String get sellerCreateStoreBody =>
      'أنشئ متجرك لعرض إعلاناتك في السوق. ستصبح بائعاً تلقائياً.';

  @override
  String get sellerCreateStoreButton => 'إنشاء متجر';

  @override
  String sellerListingsCount(Object count) {
    return '$count إعلان';
  }

  @override
  String get sellerMyListings => 'إعلاناتي';

  @override
  String get sellerAddListing => 'إضافة إعلان';

  @override
  String get sellerEditStore => 'تعديل المتجر';

  @override
  String get sellerStoreNameRequired => 'اسم المتجر مطلوب';

  @override
  String get sellerStoreCreated => 'تم إنشاء المتجر';

  @override
  String get sellerStoreNameLabel => 'اسم المتجر';

  @override
  String get sellerStoreNameHint => 'اسم متجرك';

  @override
  String get sellerStoreBioLabel => 'نبذة (اختياري)';

  @override
  String get sellerStoreBioHint => 'وصف موجز عن المتجر';

  @override
  String get sellerCityLabel => 'المدينة (اختياري)';

  @override
  String get sellerCityHint => 'المدينة';

  @override
  String get sellerPhoneLabel => 'الهاتف (اختياري)';

  @override
  String get sellerWhatsappLabel => 'واتساب (اختياري)';

  @override
  String get sellerEmailLabel => 'البريد (اختياري)';

  @override
  String get sellerCreateStoreSubmit => 'إنشاء المتجر';

  @override
  String get sellerDeleteListingTitle => 'حذف الإعلان';

  @override
  String sellerDeleteListingConfirm(Object title) {
    return 'هل تريد حذف \"$title\"؟';
  }

  @override
  String get sellerNoListings => 'لا توجد إعلانات';

  @override
  String get sellerNoListingsSubtitle => 'أضف أول إعلان لمتجرك';

  @override
  String get sellerPay => 'ادفع';

  @override
  String get sellerMedia => 'الوسائط';

  @override
  String get sellerPayNow => 'ادفع الآن';

  @override
  String get sellerTitleRequired => 'العنوان مطلوب';

  @override
  String get sellerSelectCategoryFirst => 'اختر الفئة أولاً';

  @override
  String get sellerFieldRequired => 'هذا الحقل مطلوب';

  @override
  String get sellerCreatedCompletePayment => 'تم الإنشاء — أكمل الدفع';

  @override
  String get sellerSavedAwaitingPayment => 'تم الحفظ — بانتظار الدفع';

  @override
  String get sellerSavedUnderReview => 'تم الحفظ — قيد المراجعة';

  @override
  String get sellerEditListingTitle => 'تعديل الإعلان';

  @override
  String get sellerNewListingTitle => 'إعلان جديد';

  @override
  String get sellerCategory => 'الفئة';

  @override
  String get sellerTitleLabel => 'العنوان';

  @override
  String get sellerTitleHint => 'عنوان الإعلان';

  @override
  String get sellerFullNameLabel => 'الاسم (اختياري)';

  @override
  String get sellerNationalityLabel => 'الجنسية (اختياري)';

  @override
  String get sellerAdditionalDetails => 'تفاصيل إضافية';

  @override
  String get sellerContactSection => 'وسائل التواصل (اختياري)';

  @override
  String get sellerContactPhone => 'هاتف';

  @override
  String get sellerContactWhatsapp => 'واتساب';

  @override
  String get sellerContactEmail => 'بريد إلكتروني';

  @override
  String get sellerSaveEdits => 'حفظ التعديلات';

  @override
  String get sellerPublishListing => 'نشر الإعلان';

  @override
  String sellerPaidCategoryNote(Object basePrice, Object currency) {
    return 'فئة مدفوعة ($basePrice $currency) — سيتطلب الدفع قبل النشر.';
  }

  @override
  String get sellerDobLabel => 'تاريخ الميلاد (اختياري)';

  @override
  String get sellerPickDate => 'اختر التاريخ';

  @override
  String get sellerShowContactToBuyers => 'إظهار وسائل التواصل للمشترين';

  @override
  String get sellerImageLimitReached => 'بلغت الحد الأقصى للصور';

  @override
  String get sellerImageUploaded => 'تم رفع الصورة';

  @override
  String get sellerListingMediaTitle => 'وسائط الإعلان';

  @override
  String sellerPhotosCountLimited(Object count, Object limit) {
    return 'الصور ($count / $limit)';
  }

  @override
  String sellerPhotosCount(Object count) {
    return 'الصور ($count)';
  }

  @override
  String get sellerNoPhotosYet => 'لا توجد صور بعد';

  @override
  String get sellerAddPhoto => 'إضافة صورة';

  @override
  String get sellerMediaAdminNote =>
      'الفيديو والمستندات تُدار من لوحة التحكم حالياً.';

  @override
  String get clubsTitle => 'الأندية';

  @override
  String get clubsEmpty => 'لا توجد أندية';

  @override
  String get clubsSearchHint => 'ابحث عن نادٍ…';

  @override
  String get clubsTabOverview => 'نظرة عامة';

  @override
  String get clubsTabPlayers => 'اللاعبون';

  @override
  String get clubsVerifyBadge => 'توثيق';

  @override
  String get clubsInfoStadium => 'الملعب';

  @override
  String get clubsInfoCity => 'المدينة';

  @override
  String get clubsInfoFounded => 'تأسس';

  @override
  String get clubsSectionTitles => 'البطولات';

  @override
  String get clubsSectionBoard => 'مجلس الإدارة';

  @override
  String get clubsSectionStaff => 'الجهاز';

  @override
  String get clubsSectionCaptains => 'القادة';

  @override
  String get clubsSectionCompetitions => 'المنافسات';

  @override
  String get clubsNoInfo => 'لا تتوفر معلومات';

  @override
  String get clubsNoNews => 'لا توجد أخبار';

  @override
  String get clubsNoMatches => 'لا توجد مباريات';

  @override
  String get clubsNoSquad => 'لا تتوفر التشكيلة';

  @override
  String get clubsNewsTitle => 'خبر';

  @override
  String clubsViewsCount(Object count) {
    return '$count مشاهدة';
  }

  @override
  String get clubsVerifyMethodMessage => 'رسالة';

  @override
  String get clubsVerifyMethodVoice => 'مكالمة';

  @override
  String get clubsVerifyMethodVideo => 'فيديو';

  @override
  String get clubsVerifySubmitted => 'تم إرسال طلب التوثيق';

  @override
  String get clubsVerifySheetTitle => 'طلب توثيق النادي';

  @override
  String get clubsVerifySheetSubtitle =>
      'اختر وسيلة التحقق وأرفق ملاحظة إن رغبت';

  @override
  String get clubsVerifyMethodLabel => 'وسيلة التحقق';

  @override
  String get clubsVerifyNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get clubsVerifyNoteHint => 'تفاصيل إضافية';

  @override
  String get clubsVerifySubmit => 'إرسال الطلب';

  @override
  String get clubAdminDashboardTitle => 'نادي الإدارة';

  @override
  String get clubAdminNotAdminTitle => 'لا تدير أي نادٍ';

  @override
  String get clubAdminNotAdminBody => 'تُمنح إدارة النادي من قبل المشرف.';

  @override
  String get clubAdminEditClubData => 'تعديل بيانات النادي';

  @override
  String get clubAdminManageNews => 'إدارة الأخبار';

  @override
  String get clubAdminEditClubTitle => 'تعديل النادي';

  @override
  String get clubAdminInvalidValue => 'غير صالح';

  @override
  String get clubAdminNoItems => 'لا توجد عناصر';

  @override
  String get clubAdminAddFirstItem => 'أضف أول عنصر';

  @override
  String clubAdminDeleteConfirm(Object title) {
    return 'حذف \"$title\"؟';
  }

  @override
  String get clubAdminNoNews => 'لا توجد أخبار';

  @override
  String get clubAdminAddFirstNews => 'أضف أول خبر';

  @override
  String get clubAdminNewNews => 'خبر جديد';

  @override
  String get clubAdminEditNews => 'تعديل الخبر';

  @override
  String get clubAdminDeleteNews => 'حذف الخبر';

  @override
  String get fanGroupsTitle => 'الجماهير';

  @override
  String get fanGroupsEmpty => 'لا توجد جماهير';

  @override
  String get fanGroupsSearchHint => 'ابحث عن جمهور…';

  @override
  String get fanGroupsOfficialBadge => 'رسمي';

  @override
  String get fanGroupsTabOverview => 'نظرة عامة';

  @override
  String get fanGroupsTabPhotos => 'الصور';

  @override
  String get fanGroupsTabVideos => 'الفيديوهات';

  @override
  String get fanGroupsTabChants => 'الأهازيج';

  @override
  String get fanGroupsVerifyAction => 'توثيق';

  @override
  String get fanGroupsDocuments => 'المستندات';

  @override
  String get fanGroupsNoInfo => 'لا تتوفر معلومات';

  @override
  String get fanGroupsContact => 'التواصل';

  @override
  String get fanGroupsNoVideos => 'لا توجد فيديوهات';

  @override
  String get fanGroupsNoPhotos => 'لا توجد صور';

  @override
  String get fanGroupsVideoDefaultTitle => 'فيديو';

  @override
  String get fanGroupsNoChants => 'لا توجد أهازيج';

  @override
  String get fanGroupsMethodMessage => 'رسالة';

  @override
  String get fanGroupsMethodVoice => 'مكالمة';

  @override
  String get fanGroupsMethodVideo => 'فيديو';

  @override
  String get fanGroupsVerifySent => 'تم إرسال طلب التوثيق';

  @override
  String get fanGroupsVerifyTitle => 'طلب توثيق الجمهور';

  @override
  String get fanGroupsVerifyMethodLabel => 'وسيلة التحقق';

  @override
  String get fanGroupsVerifyNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get fanGroupsVerifyNoteHint => 'تفاصيل إضافية';

  @override
  String get fanGroupsVerifySubmit => 'إرسال الطلب';

  @override
  String get fanAdminManageTitle => 'إدارة الجمهور';

  @override
  String get fanAdminNotAdminTitle => 'لا تدير أي جمهور';

  @override
  String get fanAdminNotAdminBody => 'تُمنح إدارة الجمهور من قبل المشرف.';

  @override
  String get fanAdminEditGroupData => 'تعديل بيانات الجمهور';

  @override
  String get fanAdminManageMedia => 'إدارة الوسائط';

  @override
  String get fanAdminManageChants => 'إدارة الأهازيج';

  @override
  String get fanAdminManageDocuments => 'إدارة المستندات';

  @override
  String get fanAdminEditTitle => 'تعديل الجمهور';

  @override
  String get fanAdminInvalidValue => 'غير صالح';

  @override
  String get fanAdminPhotos => 'الصور';

  @override
  String get fanAdminVideos => 'الفيديوهات';

  @override
  String get fanAdminMediaAddNote =>
      'إضافة وسائط جديدة تتم من لوحة التحكم على الويب. هنا يمكنك العرض والحذف.';

  @override
  String get fanAdminNoMedia => 'لا توجد وسائط';

  @override
  String get fanAdminItem => 'العنصر';

  @override
  String get fanAdminVideo => 'فيديو';

  @override
  String get fanAdminPhoto => 'صورة';

  @override
  String get fanAdminChantsAddNote =>
      'إضافة الأهازيج تتم من لوحة التحكم على الويب. هنا يمكنك العرض والحذف.';

  @override
  String get fanAdminNoChants => 'لا توجد أهازيج';

  @override
  String get fanAdminDocumentsAddNote =>
      'إضافة المستندات تتم من لوحة التحكم على الويب. هنا يمكنك العرض والحذف.';

  @override
  String get fanAdminNoDocuments => 'لا توجد مستندات';

  @override
  String get fanAdminConfirmDeleteTitle => 'تأكيد الحذف';

  @override
  String fanAdminConfirmDeleteBody(Object name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get paymentStatusPending => 'بانتظار الدفع';

  @override
  String get paymentStatusProcessing => 'قيد المعالجة';

  @override
  String get paymentStatusPaid => 'مدفوع';

  @override
  String get paymentStatusFailed => 'فشل';

  @override
  String get paymentStatusCancelled => 'ملغى';

  @override
  String get paymentStatusRefunded => 'مُسترَد';

  @override
  String get paymentGatewayZaincash => 'زين كاش';

  @override
  String get paymentGatewayManual => 'يدوي';

  @override
  String get paymentHistoryTitle => 'سجل المدفوعات';

  @override
  String get paymentHistoryEmpty => 'لا توجد مدفوعات';

  @override
  String get paymentMethodTitle => 'الدفع';

  @override
  String get paymentMethodChoose => 'اختر وسيلة الدفع';

  @override
  String get paymentMethodZaincashSubtitle => 'الدفع عبر محفظة زين كاش';

  @override
  String get paymentMethodFibSubtitle => 'مسح رمز QR عبر تطبيق FIB';

  @override
  String get paymentMethodContinue => 'متابعة';

  @override
  String get paymentStatusTitle => 'عملية الدفع';

  @override
  String get paymentNotFoundTitle => 'تعذّر العثور على عملية الدفع';

  @override
  String get paymentNotFoundSubtitle => 'قد تكون العملية منتهية أو غير متاحة.';

  @override
  String get paymentBack => 'العودة';

  @override
  String get paymentSuccessTitle => 'تم الدفع بنجاح';

  @override
  String get paymentSuccessSubtitle =>
      'تم استلام دفعتك. إعلانك الآن قيد المراجعة.';

  @override
  String get paymentCancelledTitle => 'تم إلغاء الدفع';

  @override
  String get paymentFailedTitle => 'فشل الدفع';

  @override
  String get paymentFailedSubtitle =>
      'لم تكتمل عملية الدفع. يمكنك المحاولة مرة أخرى.';

  @override
  String get paymentRefundedTitle => 'تم استرداد المبلغ';

  @override
  String get paymentRefundedSubtitle => 'تمت إعادة المبلغ إلى حسابك.';

  @override
  String get paymentExpiredTitle => 'انتهت مهلة الدفع';

  @override
  String get paymentExpiredSubtitle => 'انقضت المدة المحددة لإتمام الدفع.';

  @override
  String get paymentPendingTitle => 'الدفع قيد الانتظار';

  @override
  String get paymentPendingSubtitle => 'لإكمال الدفع، ابدأ محاولة جديدة.';

  @override
  String get paymentAmountDue => 'المبلغ المطلوب';

  @override
  String get paymentScanQr => 'امسح الرمز عبر تطبيق FIB';

  @override
  String get paymentOpenFibApp => 'افتح تطبيق FIB';

  @override
  String get paymentOpenGateway => 'افتح بوابة الدفع';

  @override
  String paymentExpiresIn(Object time) {
    return 'تنتهي خلال $time';
  }

  @override
  String get paymentCheckNow => 'تحقّق الآن';

  @override
  String get paymentWaitingConfirmation => 'بانتظار تأكيد الدفع…';

  @override
  String get notifTitle => 'الإشعارات';

  @override
  String get notifEmpty => 'لا توجد إشعارات';

  @override
  String get notifNameRequired => 'الاسم مطلوب';

  @override
  String get notifEditProfileTitle => 'تعديل الملف الشخصي';

  @override
  String get notifNameLabel => 'الاسم';

  @override
  String get notifNameHint => 'اسمك الكامل';

  @override
  String get notifEmailLabel => 'البريد الإلكتروني (اختياري)';

  @override
  String get notifFavoriteClubLabel => 'النادي المفضل (اختياري)';

  @override
  String get notifPickClub => 'اختر النادي';

  @override
  String get notifSearchClubHint => 'ابحث عن نادٍ…';

  @override
  String get notifFavoriteTeamLabel => 'الفريق المفضل (اختياري)';

  @override
  String get notifPickTeam => 'اختر الفريق';

  @override
  String get notifSearchTeamHint => 'ابحث عن فريق…';

  @override
  String get notifGenderLabel => 'الجنس (اختياري)';

  @override
  String get notifGenderMale => 'ذكر';

  @override
  String get notifGenderFemale => 'أنثى';

  @override
  String get notifDobLabel => 'تاريخ الميلاد (اختياري)';

  @override
  String get notifPickDate => 'اختر التاريخ';

  @override
  String get notifDeleteAccount => 'حذف الحساب';

  @override
  String get notifDeleteAccountBody =>
      'سيتم حذف حسابك نهائياً. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get notifDeleteAccountConfirm => 'حذف نهائي';

  @override
  String get notifGroupAccount => 'الحساب';

  @override
  String get notifRowProfile => 'الملف الشخصي';

  @override
  String get notifRowFavoriteClubs => 'الأندية المفضلة';

  @override
  String get notifRowNotifications => 'الإشعارات';

  @override
  String get notifGroupServices => 'خدماتي';

  @override
  String get notifRowMyStore => 'متجري';

  @override
  String get notifRowMyClub => 'ناديي';

  @override
  String get notifRowMyFanGroup => 'جمهوري';

  @override
  String get notifRowPayments => 'سجل المدفوعات';

  @override
  String get notifGroupApp => 'التطبيق';

  @override
  String get notifRowLanguage => 'اللغة';

  @override
  String get notifLangArabic => 'العربية';

  @override
  String get notifRowAbout => 'حول التطبيق';

  @override
  String get notifGroupSupport => 'الدعم';

  @override
  String get notifRowHelpCenter => 'مركز المساعدة';

  @override
  String get notifRowPrivacy => 'سياسة الخصوصية';

  @override
  String get notifDefaultUserName => 'مستخدم IQS';

  @override
  String get notifLogout => 'تسجيل الخروج';

  @override
  String get notifVersion => 'الإصدار 1.0.0 · IQS';

  @override
  String get notifDefaultTitle => 'إشعار';
}
