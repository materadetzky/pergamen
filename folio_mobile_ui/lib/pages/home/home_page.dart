// ignore_for_file: dead_code
import 'dart:math';

import 'package:google_fonts/google_fonts.dart';
import 'package:folio/api/providers/live_card_provider.dart';
import 'package:folio/ui/date_widget.dart';
import 'package:folio/theme/colors/colors.dart';
import 'package:folio/utils/format.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:intl/intl.dart';
import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:folio/api/providers/update_provider.dart';
import 'package:folio/api/providers/sync.dart';
import 'package:confetti/confetti.dart';
import 'package:folio/models/settings.dart';
import 'package:folio_kreta_api/providers/absence_provider.dart';
import 'package:folio_kreta_api/providers/event_provider.dart';
import 'package:folio_kreta_api/providers/exam_provider.dart';
import 'package:folio_kreta_api/providers/grade_provider.dart';
import 'package:folio_kreta_api/providers/homework_provider.dart';
import 'package:folio_kreta_api/providers/message_provider.dart';
import 'package:folio_kreta_api/providers/note_provider.dart';
import 'package:folio/api/providers/user_provider.dart';
import 'package:folio/api/providers/status_provider.dart';
import 'package:folio_kreta_api/providers/timetable_provider.dart';
import 'package:folio_mobile_ui/common/empty.dart';
import 'package:folio_mobile_ui/common/widgets/update/update_dialog.dart';
import 'package:folio_mobile_ui/common/widgets/update/update_tile.dart';
import 'package:folio_mobile_ui/pages/home/live_card/live_card.dart';
import 'package:folio_mobile_ui/screens/navigation/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:folio_mobile_ui/common/haptic.dart';
import 'package:provider/provider.dart';
import 'home_page.i18n.dart';
import 'package:folio/ui/filter/widgets.dart';
import 'package:folio/ui/filter/sort.dart';
// import 'package:dropdown_button2/dropdown_button2.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late UserProvider user;
  late SettingsProvider settings;
  late UpdateProvider updateProvider;
  late StatusProvider statusProvider;
  late GradeProvider gradeProvider;
  late TimetableProvider timetableProvider;
  late MessageProvider messageProvider;
  late AbsenceProvider absenceProvider;
  late HomeworkProvider homeworkProvider;
  late ExamProvider examProvider;
  late NoteProvider noteProvider;
  late EventProvider eventProvider;

  late PageController _pageController;
  ConfettiController? _confettiController;
  late LiveCardProvider _liveCard;
  late AnimationController _liveCardAnimation;
  bool? _lastLiveCardShow;

  late String greeting;
  late String firstName;

  late List<String> listOrder;
  static const pageCount = 5;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: pageCount, vsync: this);
    _pageController = PageController();
    user = Provider.of<UserProvider>(context, listen: false);
    _liveCard = Provider.of<LiveCardProvider>(context, listen: false);
    _liveCardAnimation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _liveCardAnimation.animateTo(_liveCard.show ? 1.0 : 0.0,
        duration: Duration.zero);

    listOrder = List.generate(pageCount, (index) => "$index");
  }

  @override
  void dispose() {
    // _filterController.dispose();
    _pageController.dispose();
    _tabController.dispose();
    _confettiController?.dispose();
    _liveCardAnimation.dispose();

    super.dispose();
  }

  void setGreeting() {
    DateTime now = DateTime.now();
    List<String> nameParts = user.displayName?.split(" ") ?? ["?"];
    if (!settings.presentationMode) {
      firstName = nameParts.length > 1 ? nameParts[1] : nameParts[0];
    } else {
      firstName = "János";
    }

    bool customWelcome = false;

    if (now.isBefore(DateTime(now.year, DateTime.august, 31)) &&
        now.isAfter(DateTime(now.year, DateTime.june, 14))) {
      greeting = "goodrest";

      if (NavigationScreen.of(context)?.init("confetti") ?? false) {
        _confettiController =
            ConfettiController(duration: const Duration(seconds: 1));
        Future.delayed(const Duration(seconds: 1))
            .then((value) => mounted ? _confettiController?.play() : null);
      }
    } else if (now.month == user.student?.birth.month &&
        now.day == user.student?.birth.day) {
      greeting = "happybirthday";

      if (NavigationScreen.of(context)?.init("confetti") ?? false) {
        _confettiController =
            ConfettiController(duration: const Duration(seconds: 3));
        Future.delayed(const Duration(seconds: 1))
            .then((value) => mounted ? _confettiController?.play() : null);
      }
    } else if (now.month == DateTime.march && now.day == 28) {
      final age = now.year - 2025;
      greeting = Localization("folioopen".i18n).fill([age]);
      customWelcome = true;

      if (NavigationScreen.of(context)?.init("confetti") ?? false) {
        _confettiController =
            ConfettiController(duration: const Duration(seconds: 3));
        Future.delayed(const Duration(seconds: 1))
            .then((value) => mounted ? _confettiController?.play() : null);
      }
    } else if (now.month == DateTime.december &&
        now.day >= 24 &&
        now.day <= 26) {
      greeting = "merryxmas";
    } else if (now.month == DateTime.january && now.day == 1) {
      greeting = "happynewyear";
    } else if (settings.welcomeMessage.replaceAll(' ', '') != '') {
      greeting = settings.welcomeMessage;
      greeting = localizeFill(
        settings.welcomeMessage,
        [firstName],
      );

      customWelcome = true;
    } else if (now.hour >= 21 || now.hour < 4) {
      greeting = "goodnight";
    } else if (now.hour >= 18) {
      greeting = "goodevening";
    } else if (now.hour >= 12) {
      greeting = "goodafternoon";
    } else {
      greeting = "goodmorning";
    }

    greeting = customWelcome
        ? greeting
        : Localization(greeting.i18n).fill([firstName]);
  }

  @override
  Widget build(BuildContext context) {
    user = Provider.of<UserProvider>(context);
    settings = Provider.of<SettingsProvider>(context);
    statusProvider = Provider.of<StatusProvider>(context, listen: false);
    updateProvider = Provider.of<UpdateProvider>(context);
    _liveCard = Provider.of<LiveCardProvider>(context);
    gradeProvider = Provider.of<GradeProvider>(context);
    if (_liveCard.show != _lastLiveCardShow) {
      _lastLiveCardShow = _liveCard.show;
      _liveCardAnimation.animateTo(_liveCard.show ? 1.0 : 0.0);
    }

    setGreeting();
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: NestedScrollView(
                physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics()),
                headerSliverBuilder: (context, _) => [
                      AnimatedBuilder(
                        animation: _liveCardAnimation,
                        builder: (context, child) {
                          final colorScheme = Theme.of(context).colorScheme;
                          final Color greetingColor = colorScheme.onSurface;
                          final Color dateColor = colorScheme.onSurfaceVariant;
                          final String activeFont =
                              settings.fontFamily.isNotEmpty
                                  ? settings.fontFamily
                                  : 'Figtree';

                          TextStyle cleanStyle(TextStyle base) {
                            try {
                              return GoogleFonts.getFont(activeFont,
                                  textStyle: base);
                            } catch (_) {
                              return base;
                            }
                          }

                          final paddingTop =
                              MediaQuery.of(context).padding.top;
                          final double cardContentHeight =
                              _liveCard.currentState == LiveCardState.morning
                                  ? 284.0
                                  : (_liveCard.currentState ==
                                          LiveCardState.duringLesson
                                      ? (_liveCard.currentLesson?.description
                                                  .isNotEmpty ==
                                              true
                                          ? 314.0
                                          : 290.0)
                                      : (_liveCard.currentState ==
                                              LiveCardState.duringBreak
                                          ? 290.0
                                          : (_liveCard.currentState ==
                                                  LiveCardState.summary
                                              ? 282.0
                                              : 200.0)));

                          final String localeCode =
                              I18n.of(context).locale.languageCode;
                          final String formattedDate =
                              DateFormat('EEEE, MMM d.', localeCode)
                                  .format(DateTime.now())
                                  .capital();

                          return SliverAppBar(
                            automaticallyImplyLeading: false,
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            surfaceTintColor: Colors.transparent,
                            scrolledUnderElevation: 0.0,
                            shape: const RoundedRectangleBorder(),
                            centerTitle: false,
                            titleSpacing: 0.0,
                            toolbarHeight: 64.0,
                            // Clean Material You Greeting & Date
                            title: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      greeting,
                                      maxLines: 1,
                                      textAlign: TextAlign.start,
                                      style: cleanStyle(
                                        TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 28.0,
                                          letterSpacing: -0.5,
                                          height: 1.15,
                                          color: greetingColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    formattedDate,
                                    textAlign: TextAlign.start,
                                    style: cleanStyle(
                                      TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.1,
                                        color: dateColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            expandedHeight: paddingTop +
                                (_liveCardAnimation.value * cardContentHeight),

                            // Live Card
                            flexibleSpace: FlexibleSpaceBar(
                              collapseMode: CollapseMode.parallax,
                              background: Container(
                                color:
                                    Theme.of(context).scaffoldBackgroundColor,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: 24.0,
                                    right: 24.0,
                                    top: paddingTop + 72.0,
                                    bottom: 66.0,
                                  ),
                                  child: Transform.scale(
                                    scale: _liveCardAnimation.value,
                                    child: Opacity(
                                      opacity: _liveCardAnimation.value,
                                      child: const LiveCard(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            shadowColor: Colors.black,
                            bottom: _HomeCategoryBar(
                              tabController: _tabController,
                              onTap: (i) {
                                performHapticFeedback(settings.vibrate);
                                int selectedPage =
                                    _pageController.page!.round();

                                if (i == selectedPage) return;
                                if (_pageController.page?.roundToDouble() !=
                                    _pageController.page) {
                                  _pageController.animateToPage(i,
                                      curve: Curves.easeIn,
                                      duration: kTabScrollDuration);
                                  return;
                                }

                                setState(() {
                                  _pageController.jumpToPage(i);
                                  String currentList = listOrder[selectedPage];
                                  listOrder[selectedPage] = listOrder[i];
                                  listOrder[i] = currentList;
                                });
                              },
                            ),
                            pinned: true,
                            floating: false,
                            snap: false,
                          );
                        },
                      ),
                    ],
                body: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      // from flutter source
                      if (notification is ScrollUpdateNotification &&
                          !_tabController.indexIsChanging) {
                        if ((_pageController.page! - _tabController.index)
                                .abs() >
                            1.0) {
                          _tabController.index = _pageController.page!.floor();
                        }
                        _tabController.offset =
                            (_pageController.page! - _tabController.index)
                                .clamp(-1.0, 1.0);
                      } else if (notification is ScrollEndNotification) {
                        _tabController.index = _pageController.page!.round();
                        if (!_tabController.indexIsChanging) {
                          _tabController.offset =
                              (_pageController.page! - _tabController.index)
                                  .clamp(-1.0, 1.0);
                        }
                      }
                      return false;
                    },
                    child: PageView.custom(
                      controller: _pageController,
                      childrenDelegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          return FutureBuilder<List<DateWidget>>(
                            key: ValueKey<String>(listOrder[index]),
                            future: getFilterWidgets(homeFilters[index],
                                context: context),
                            builder: (context, dateWidgets) => dateWidgets
                                        .data !=
                                    null
                                ? Column(
                                    children: [
                                      if (index == 0 &&
                                          updateProvider.available)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              24.0, 4.0, 24.0, 4.0),
                                          child: UpdateTile(
                                            updateProvider.releases.first,
                                            padding: EdgeInsets.zero,
                                            onTap: () => UpdateDialog.show(
                                                context,
                                                updateProvider.releases.first),
                                          ),
                                        ),
                                      Expanded(
                                        child: RefreshIndicator(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          onRefresh: () => syncAll(context),
                                          child: ImplicitlyAnimatedList<Widget>(
                                            items: [
                                              if (index == 0)
                                                const SizedBox(
                                                    key: Key("\$premium")),
                                              ...sortDateWidgets(context,
                                                  dateWidgets:
                                                      dateWidgets.data!,
                                                  padding: EdgeInsets.zero),
                                            ],
                                            itemBuilder: filterItemBuilder,
                                            spawnIsolate: false,
                                            areItemsTheSame: (a, b) =>
                                                a.key == b.key,
                                            physics: const BouncingScrollPhysics(
                                                parent:
                                                    AlwaysScrollableScrollPhysics()),
                                            padding: EdgeInsets.only(
                                              left: 24.0,
                                              right: 24.0,
                                              bottom: MediaQuery.of(context)
                                                      .padding
                                                      .bottom +
                                                  8.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(),
                          );
                        },
                        childCount: 5,
                        findChildIndexCallback: (Key key) {
                          final ValueKey<String> valueKey =
                              key as ValueKey<String>;
                          final String data = valueKey.value;
                          return listOrder.indexOf(data);
                        },
                      ),
                      physics: const PageScrollPhysics()
                          .applyTo(const BouncingScrollPhysics()),
                    ),
                  ),
                )),
          ),

          // confetti 🎊
          if (_confettiController != null)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController!,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.02,
                numberOfParticles: 120,
                maxBlastForce: 20,
                minBlastForce: 10,
                gravity: 0.3,
                minimumSize: const Size(5, 5),
                maximumSize: const Size(20, 20),
              ),
            ),
        ],
      ),
    );
  }

  Future<Widget> filterViewBuilder(context, int activeData) async {
    final activeFilter = homeFilters[activeData];

    List<Widget> filterWidgets = sortDateWidgets(
      context,
      dateWidgets: await getFilterWidgets(activeFilter, context: context),
      showDivider: true,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: () => syncAll(context),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            if (filterWidgets.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: filterWidgets[index],
              );
            } else {
              return Empty(subtitle: "empty".i18n);
            }
          },
          itemCount: max(filterWidgets.length, 1),
        ),
      ),
    );
  }
}

class _HomeCategoryBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeCategoryBar({
    required this.tabController,
    required this.onTap,
  });

  final TabController tabController;
  final void Function(int) onTap;

  @override
  Size get preferredSize => const Size.fromHeight(58.0);

  static const _icons = <IconData>[
    Icons.apps_rounded,
    Icons.star_rounded,
    Icons.assignment_rounded,
    Icons.mail_rounded,
    Icons.event_busy_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final labels = [
      'All'.i18n,
      'Grades'.i18n,
      'Exams'.i18n,
      'Messages'.i18n,
      'Absences'.i18n,
    ];

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final String activeFont =
        settings.fontFamily.isNotEmpty ? settings.fontFamily : 'Figtree';

    TextStyle cleanStyle(TextStyle base) {
      try {
        return GoogleFonts.getFont(activeFont, textStyle: base);
      } catch (_) {
        return base;
      }
    }

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, _) {
        final selected = tabController.index;
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 5.0),
          child: Row(
            children: List.generate(5, (i) {
              final isSelected = i == selected;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.secondaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _icons[i],
                          size: 20.0,
                          color: isSelected
                              ? colorScheme.onSecondaryContainer
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.75),
                        ),
                        const SizedBox(height: 2.5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              labels[i],
                              maxLines: 1,
                              style: cleanStyle(
                                TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: -0.1,
                                  color: isSelected
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
