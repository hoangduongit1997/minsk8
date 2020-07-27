import 'dart:math';
import 'package:flutter/material.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:minsk8/import.dart';

// TODO: Другие лоты участника показывают только 10 элементов, нужен loadMore
// TODO: как отказаться от лота до окончания таймера, по которому мной включён таймер?

class UnitScreen extends StatefulWidget {
  UnitScreen(this.arguments);

  final UnitRouteArguments arguments;

  @override
  _UnitScreenState createState() {
    return _UnitScreenState();
  }
}

// TODO: добавить пункт меню "подписаться на участника"

enum _PopupMenuValue { goToMember, askQuestion, toModerate, delete }

enum _ShowHero { forShowcase, forOpenZoom, forCloseZoom }

class _UnitScreenState extends State<UnitScreen> {
  var _showHero;
  var _isCarouselSlider = true;
  var _currentIndex = 0;
  final _panelColumnKey = GlobalKey();
  double _panelMaxHeight;
  List<UnitModel> _otherUnits;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    final unit = widget.arguments.unit;
    if (widget.arguments.isShowcase ?? false) {
      _showHero = _ShowHero.forShowcase;
    }
    _initOtherUnits();
    WidgetsBinding.instance.addPostFrameCallback(_onAfterBuild);
    final distance = Provider.of<DistanceModel>(context, listen: false);
    distance.updateValue(unit.location);
    distance.updateCurrentPosition(unit.location);
    App.analytics.setCurrentScreen(screenName: '/unit ${unit.id}');
  }

  void _onAfterBuild(Duration timeStamp) {
    final RenderBox renderBox =
        _panelColumnKey.currentContext.findRenderObject();
    setState(() {
      _panelMaxHeight = renderBox.size.height;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unit = widget.arguments.unit;
    final tag = '${HomeScreen.globalKey.currentState.tagPrefix}-${unit.id}';
    final size = MediaQuery.of(context).size;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final bodyHeight = size.height - statusBarHeight - kToolbarHeight;
    final carouselSliderHeight = bodyHeight / kGoldenRatio -
        UnitCarouselSliderSettings.verticalPadding * 2;
    final panelMinHeight = bodyHeight - bodyHeight / kGoldenRatio;
    final panelChildWidth = size.width - 32.0; // for padding
    final panelSlideLabelWidth = 32.0;
    final separatorWidth = 16.0;
    final otherUnitWidth = (size.width - 4 * separatorWidth) / 3.25;
    final member = widget.arguments.member;
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: _buildStatusText(unit),
          centerTitle: true,
          backgroundColor: unit.isClosed
              ? Colors.grey.withOpacity(0.8)
              : Colors.pink.withOpacity(0.8),
          actions: [
            PopupMenuButton(
              onSelected: (_PopupMenuValue value) async {
                if (value == _PopupMenuValue.delete) {
                  final result = await showDialog(
                    context: context,
                    child: ConfirmDialog(
                        title: 'Вы уверены, что хотите удалить лот?',
                        content:
                            'Размещать его повторно\nзапрещено — возможен бан.',
                        ok: 'Удалить'),
                  );
                  if (result != true) return;
                  final client = GraphQLProvider.of(context).value;
                  final options = MutationOptions(
                    documentNode: Mutations.deleteUnit,
                    variables: {'id': unit.id},
                    fetchPolicy: FetchPolicy.noCache,
                  );
                  // ignore: unawaited_futures
                  client
                      .mutate(options)
                      .timeout(kGraphQLMutationTimeoutDuration)
                      .then((QueryResult result) {
                    if (result.hasException) {
                      throw result.exception;
                    }
                    if (result.data['update_unit']['affected_rows'] != 1) {
                      throw 'Invalid update_unit.affected_rows';
                    }
                  }).catchError((error) {
                    print(error);
                    if (mounted) {
                      setState(() {
                        localDeletedUnitIds.remove(unit.id);
                      });
                    }
                  });
                  setState(() {
                    localDeletedUnitIds.add(unit.id);
                  });
                }
                if (value == _PopupMenuValue.toModerate) {
                  final result = await showDialog<ClaimValue>(
                    context: context,
                    builder: (BuildContext context) {
                      return EnumModelDialog<ClaimModel>(
                          title: 'Укажите причину жалобы', elements: claims);
                    },
                  );
                  if (result == null) return;
                  final snackBar = SnackBar(content: Text('Жалоба принята'));
                  _scaffoldKey.currentState.showSnackBar(snackBar);
                  final client = GraphQLProvider.of(context).value;
                  final options = MutationOptions(
                    documentNode: Mutations.upsertModeration,
                    variables: {
                      'unit_id': unit.id,
                      'claim': EnumToString.parse(result),
                    },
                    fetchPolicy: FetchPolicy.noCache,
                  );
                  // ignore: unawaited_futures
                  client
                      .mutate(options)
                      .timeout(kGraphQLMutationTimeoutDuration)
                      .then((QueryResult result) {
                    if (result.hasException) {
                      throw result.exception;
                    }
                    if (result.data['insert_moderation']['affected_rows'] !=
                        1) {
                      throw 'Invalid insert_moderation.affected_rows';
                    }
                  }).catchError((error) {
                    print(error);
                  });
                }
                if (value == _PopupMenuValue.askQuestion) {
                  final result = await showDialog<QuestionValue>(
                    context: context,
                    builder: (BuildContext context) {
                      return EnumModelDialog<QuestionModel>(
                          title: 'Что Вы хотите узнать о лоте?',
                          elements: questions);
                    },
                  );
                  if (result == null) return;
                  final snackBar = SnackBar(
                      content: Text(
                          'Вопрос принят и будет передан автору, чтобы дополнил описание'));
                  _scaffoldKey.currentState.showSnackBar(snackBar);
                  final client = GraphQLProvider.of(context).value;
                  final options = MutationOptions(
                    documentNode: Mutations.insertSuggestion,
                    variables: {
                      'unit_id': unit.id,
                      'question': EnumToString.parse(result),
                    },
                    fetchPolicy: FetchPolicy.noCache,
                  );
                  // ignore: unawaited_futures
                  client
                      .mutate(options)
                      .timeout(kGraphQLMutationTimeoutDuration)
                      .then((QueryResult result) {
                    if (result.hasException) {
                      throw result.exception;
                    }
                    if (result.data['insert_suggestion']['affected_rows'] !=
                        1) {
                      throw 'Invalid insert_suggestion.affected_rows';
                    }
                  }).catchError((error) {
                    print(error);
                  });
                }
              },
              itemBuilder: (BuildContext context) {
                final profile =
                    Provider.of<ProfileModel>(context, listen: false);
                final isMy = profile.member.id == member.id;
                final submenuUnits = <PopupMenuEntry<_PopupMenuValue>>[];
                if (!isMy && !unit.isClosed) {
                  submenuUnits.add(PopupMenuItem(
                    value: _PopupMenuValue.askQuestion,
                    child: Text('Задать вопрос по лоту'),
                  ));
                }
                if (!isMy) {
                  submenuUnits.add(PopupMenuItem(
                    value: _PopupMenuValue.toModerate,
                    child: Text('Пожаловаться на лот'),
                  ));
                }
                if (isMy && !unit.isClosed) {
                  submenuUnits.add(PopupMenuItem(
                    value: _PopupMenuValue.delete,
                    child: Text('Удалить лот'),
                  ));
                }
                return <PopupMenuEntry<_PopupMenuValue>>[
                  PopupMenuItem(
                    value: _PopupMenuValue.goToMember,
                    child: Row(
                      children: [
                        Avatar(member.avatarUrl),
                        SizedBox(width: 8),
                        Text(
                          member.nickname,
                          style: TextStyle(
                            fontSize: kFontSize * kGoldenRatio,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (submenuUnits.isNotEmpty) PopupMenuDivider(),
                  ...submenuUnits,
                ];
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            SlidingUpPanel(
              body: Column(
                children: [
                  SizedBox(
                    height: UnitCarouselSliderSettings.verticalPadding,
                  ),
                  Stack(
                    children: [
                      Container(),
                      if (_showHero != null)
                        Center(
                          child: SizedBox(
                            height: carouselSliderHeight,
                            width: size.width *
                                    UnitCarouselSliderSettings
                                        .viewportFraction -
                                UnitCarouselSliderSettings
                                        .unitHorizontalMargin *
                                    2,
                            child: Hero(
                              tag: tag,
                              child: ExtendedImage.network(
                                unit.images[_currentIndex].getDummyUrl(unit.id),
                                fit: BoxFit.cover,
                                // TODO: если _openDeepLink, то нужно включать
                                enableLoadState: false,
                              ),
                              flightShuttleBuilder: (
                                BuildContext flightContext,
                                Animation<double> animation,
                                HeroFlightDirection flightDirection,
                                BuildContext fromHeroContext,
                                BuildContext toHeroContext,
                              ) {
                                animation.addListener(() {
                                  if ([
                                    AnimationStatus.completed,
                                    AnimationStatus.dismissed,
                                  ].contains(animation.status)) {
                                    setState(() {
                                      _showHero = null;
                                    });
                                  }
                                });
                                final Hero hero = flightDirection ==
                                            HeroFlightDirection.pop &&
                                        _showHero != _ShowHero.forCloseZoom
                                    ? fromHeroContext.widget
                                    : toHeroContext.widget;
                                return hero.child;
                              },
                            ),
                          ),
                        ),
                      if (_isCarouselSlider)
                        CarouselSlider(
                          initialPage: _currentIndex,
                          height: carouselSliderHeight,
                          autoPlay: unit.images.length > 1,
                          enableInfiniteScroll: unit.images.length > 1,
                          pauseAutoPlayOnTouch: const Duration(seconds: 10),
                          enlargeCenterPage: true,
                          viewportFraction:
                              UnitCarouselSliderSettings.viewportFraction,
                          onPageChanged: (index) {
                            _currentIndex = index;
                          },
                          items: List.generate(unit.images.length, (index) {
                            return Container(
                              width: size.width,
                              margin: EdgeInsets.symmetric(
                                  horizontal: UnitCarouselSliderSettings
                                      .unitHorizontalMargin),
                              child: Material(
                                child: InkWell(
                                  onLongPress:
                                      () {}, // чтобы сократить время для splashColor
                                  onTap: () async {
                                    setState(() {
                                      _showHero = _ShowHero.forOpenZoom;
                                      _isCarouselSlider = false;
                                    });
                                    // TODO: ужасно мигает экран и ломается Hero, при смене ориентации
                                    // await SystemChrome.setPreferredOrientations([
                                    //   DeviceOrientation.landscapeRight,
                                    //   DeviceOrientation.landscapeLeft,
                                    //   DeviceOrientation.portraitUp,
                                    //   DeviceOrientation.portraitDown,
                                    // ]);
                                    // await Future.delayed(Duration(milliseconds: 100));
                                    // ignore: unawaited_futures
                                    Navigator.pushNamed(
                                      context,
                                      '/zoom',
                                      arguments: ZoomRouteArguments(
                                        unit,
                                        tag: tag,
                                        index: index,
                                        onWillPop: _onWillPopForZoom,
                                      ),
                                    );
                                  },
                                  splashColor: Colors.white.withOpacity(0.4),
                                  child: Ink.image(
                                    fit: BoxFit.cover,
                                    image: ExtendedImage.network(
                                      unit.images[index].getDummyUrl(unit.id),
                                      loadStateChanged: loadStateChanged,
                                    ).image,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                    ],
                  ),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              // parallaxEnabled: true,
              // parallaxOffset: .8,
              maxHeight: _panelMaxHeight == null
                  ? size.height
                  : max(_panelMaxHeight, panelMinHeight),
              minHeight: panelMinHeight,
              panel: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    key: _panelColumnKey,
                    children: [
                      SizedBox(
                        height: 16,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: (panelChildWidth - panelSlideLabelWidth) / 2,
                            child: Row(
                              children: [
                                unit.price == null
                                    ? GiftButton(unit)
                                    : PriceButton(unit),
                                Spacer(),
                              ],
                            ),
                          ),
                          Container(
                            width: panelSlideLabelWidth,
                            height: 4,
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12))),
                          ),
                          Container(
                            width: (panelChildWidth - panelSlideLabelWidth) / 2,
                            child: Row(
                              children: [
                                Spacer(),
                                DistanceButton(onTap: () {
                                  final savedIndex = _currentIndex;
                                  setState(() {
                                    _isCarouselSlider = false;
                                  });
                                  Navigator.pushNamed(
                                    context,
                                    '/unit_map',
                                    arguments: UnitMapRouteArguments(
                                      unit,
                                    ),
                                  ).then((_) {
                                    setState(() {
                                      _currentIndex = savedIndex;
                                      _isCarouselSlider = true;
                                    });
                                  });
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // TODO: как-то показывать текст, если не влезло (для маленьких экранов)
                      Container(
                        padding: EdgeInsets.only(top: 16),
                        width: panelChildWidth,
                        child: Text(
                          unit.text,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // if (!unit.isBlockedOrLocalDeleted)
                      //   Container(
                      //     padding: EdgeInsets.only(top: 16),
                      //     width: panelChildWidth,
                      //     child: Text(
                      //       'Самовывоз',
                      //       style: TextStyle(
                      //         color: Colors.black.withOpacity(0.6),
                      //       ),
                      //     ),
                      //   ),
                      if (_otherUnits.isNotEmpty)
                        Container(
                          padding: EdgeInsets.only(top: 24),
                          width: panelChildWidth,
                          child: Text(
                            'Другие лоты участника',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black.withOpacity(0.8),
                            ),
                          ),
                        ),
                      if (_otherUnits.isNotEmpty)
                        Container(
                          padding: EdgeInsets.only(top: 16),
                          width: size.width,
                          height: otherUnitWidth, // * 1,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: separatorWidth,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: _otherUnits.length,
                            itemBuilder: (BuildContext context, int index) {
                              final otherUnit = _otherUnits[index];
                              return Container(
                                width: otherUnitWidth,
                                color: Colors.red,
                                child: Material(
                                  child: InkWell(
                                    // TODO: т.к. картинки квадратные, можно переключать на следующую
                                    // onLongPress: () {},
                                    onLongPress:
                                        () {}, // чтобы сократить время для splashColor
                                    onTap: () {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/unit',
                                        (Route route) {
                                          return route.settings.name != '/unit';
                                        },
                                        arguments: UnitRouteArguments(
                                          otherUnit,
                                          member: member,
                                        ),
                                      );
                                    },
                                    splashColor: Colors.white.withOpacity(0.4),
                                    // child : Hero(
                                    //   tag: otherUnit.id,
                                    //   child:
                                    child: Ink.image(
                                      fit: BoxFit.cover,
                                      image: ExtendedImage.network(
                                        otherUnit.images[0]
                                            .getDummyUrl(otherUnit.id),
                                        loadStateChanged: loadStateChanged,
                                      ).image,
                                    ),
                                    // ),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return SizedBox(
                                width: separatorWidth,
                              );
                            },
                          ),
                        ),
                      SizedBox(
                        height: 16 + kBigButtonHeight + 16 + 8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              left: 0,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: FractionalOffset.topCenter,
                      end: FractionalOffset.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.4),
                      ],
                    ),
                  ),
                  height: 16 + kBigButtonHeight * 1.5,
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              left: 16,
              child: Row(
                children: [
                  SizedBox(
                    width: kBigButtonWidth,
                    height: kBigButtonHeight,
                    child: ShareButton(unit, iconSize: kBigButtonIconSize),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: kBigButtonWidth,
                    height: kBigButtonHeight,
                    child: WishButton(unit, iconSize: kBigButtonIconSize),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: kBigButtonHeight,
                      child: WantButton(unit),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    setState(() {
      _currentIndex = 0;
      _showHero = _ShowHero.forShowcase;
      _isCarouselSlider = false;
    });
    // await Future.delayed(Duration(milliseconds: 100));
    return true;
  }

  Future<bool> _onWillPopForZoom(int index) async {
    // TODO: ужасно мигает экран и ломается Hero, при смене ориентации
    // await SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    // ]);
    // await Future.delayed(Duration(milliseconds: 100));
    setState(() {
      _currentIndex = index;
      _showHero = _ShowHero.forCloseZoom;
      _isCarouselSlider = true;
    });
    return true;
  }

  void _initOtherUnits() {
    final memberUnits = widget.arguments.member.units;
    final unit = widget.arguments.unit;
    final result = [...memberUnits];
    result.removeWhere((removeUnit) => removeUnit.id == unit.id);
    _otherUnits = result;
  }

  Widget _buildStatusText(UnitModel unit) {
    if (unit.isBlockedOrLocalDeleted) {
      return Text(
        'Заблокировано',
      );
    }
    if (unit.win != null) {
      return Text(
        'Победитель — ${unit.win.member.nickname}',
      );
    }
    if (unit.expiresAt != null) {
      if (unit.isExpired) {
        return Text('Завершено');
      }
      return CountdownTimer(
          endTime: unit.expiresAt.millisecondsSinceEpoch,
          builder: (BuildContext context, int seconds) {
            return Text(formatDDHHMMSS(seconds));
          },
          onClose: () {
            setState(() {}); // for unit.isClosed
          });
    }
    return Text(
      urgents
          .firstWhere((urgentModel) => urgentModel.value == unit.urgent)
          .name,
    );
  }
}

class UnitRouteArguments {
  UnitRouteArguments(
    this.unit, {
    this.member,
    this.isShowcase,
  });

  final UnitModel unit;
  final MemberModel member;
  final bool isShowcase;
}

class UnitCarouselSliderSettings {
  static const unitHorizontalMargin = 8.0;
  static const viewportFraction = 0.8;
  static const verticalPadding = 16.0;
}