import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:provider/provider.dart';

import 'calc_button.dart';
import 'calc_box.dart';
import 'evaluator.dart';
import 'model.dart';
import 'pref_page.dart';

/// The main calculator page.
class MainPage extends StatefulWidget {
  static const List<String> _tabTitles = ['STANDARD', 'FUNCTIONS', 'CONSTANTS'];

  final String title;
  final CalculatorModel model;

  MainPage({Key key, @required this.title, @required this.model}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  TabController _tabController;
  ExpressionModel _expressionModel;
  AutoSizeGroup _tabTitleAutoSizeGroup;

  @override
  void initState() {
    _tabController = TabController(length: MainPage._tabTitles.length, vsync: this);
    _expressionModel = ExpressionModel();
    _tabTitleAutoSizeGroup = AutoSizeGroup();
    _expressionModel.addListener(() {
      if (_tabController.index != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _tabController.animateTo(0, duration: const Duration(milliseconds: 40));
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    _expressionModel.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          // Instead of killing the dart runtime we move it to background.
          // If anyone knows why this isn't the default in Flutter, please enlighten me.
          if (Theme.of(context).platform == TargetPlatform.android ||
              Theme.of(context).platform == TargetPlatform.iOS) {
            MoveToBackground.moveTaskToBack();
            return Future.value(false);
          }
          return Future.value(true);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: AppBar(
              leading: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 7, bottom: 7, right: 0),
                  child: SvgPicture.asset('assets/logo.svg')),
              title: Text(widget.title),
              actions: [
                IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PreferencePage(widget.model)),
                        ))
              ],
            ),
          ),
          body: Column(
            children: [
              MultiProvider(
                providers: [
                  ChangeNotifierProvider.value(value: widget.model),
                  ChangeNotifierProvider.value(value: _expressionModel)
                ],
                child: CalcBoxContainer(model: widget.model),
              ),
              TabBar(
                tabs: [
                  for (final tabTitle in MainPage._tabTitles)
                    Container(
                        height: math.max(MediaQuery.of(context).size.height * 0.07, 43),
                        alignment: Alignment.center,
                        child: AutoSizeText(tabTitle,
                            maxLines: 1,
                            group: _tabTitleAutoSizeGroup,
                            stepGranularity: 0.5,
                            style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 18)))
                ],
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 5, bottom: 7),
                  child: TabBarView(controller: _tabController, children: [
                    _StandardTab(calculatorModel: widget.model, expressionModel: _expressionModel),
                    _FunctionsTab(expressionModel: _expressionModel),
                    _ConstantTab(expressionModel: _expressionModel)
                  ]),
                ),
              )
            ],
          ),
        ));
  }
}

enum _StoRclDialogMode { store, recall }

class _StoRclDialog extends StatelessWidget {
  final CalculatorModel calculatorModel;
  final ExpressionModel expressionModel;
  final _StoRclDialogMode mode;
  final num evaluationResult;

  const _StoRclDialog(this.mode,
      {Key key,
      @required this.calculatorModel,
      @required this.expressionModel,
      this.evaluationResult})
      : super(key: key);

  void _store(BuildContext context, Function setFunction) {
    setFunction(evaluationResult.toDouble());
    Navigator.pop(context);
  }

  void _recall(BuildContext context, Function getFunction, String symbol) {
    Navigator.pop(context);
    expressionModel.add([Token.constant(symbol, getFunction())]);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(mode == _StoRclDialogMode.store ? 'Store result' : 'Recall result'),
      contentPadding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
      children: [
        ListTile(
            title: const Text('A'),
            subtitle: Text(format(calculatorModel.stoA,
                scientificLimit:
                    math.pow(10, calculatorModel.scientificNotationExponent).toDouble(),
                significantDigits: calculatorModel.significantDigits,
                thousandSeparator: calculatorModel.thousandSeparator)),
            onTap: () => mode == _StoRclDialogMode.store
                ? _store(context, (double val) => calculatorModel.stoA = val)
                : _recall(context, () => calculatorModel.stoA, 'A')),
        ListTile(
            title: const Text('B'),
            subtitle: Text(format(calculatorModel.stoB,
                scientificLimit:
                    math.pow(10, calculatorModel.scientificNotationExponent).toDouble(),
                significantDigits: calculatorModel.significantDigits,
                thousandSeparator: calculatorModel.thousandSeparator)),
            onTap: () => mode == _StoRclDialogMode.store
                ? _store(context, (double val) => calculatorModel.stoB = val)
                : _recall(context, () => calculatorModel.stoB, 'B')),
        ListTile(
            title: const Text('C'),
            subtitle: Text(format(calculatorModel.stoC,
                scientificLimit:
                    math.pow(10, calculatorModel.scientificNotationExponent).toDouble(),
                significantDigits: calculatorModel.significantDigits,
                thousandSeparator: calculatorModel.thousandSeparator)),
            onTap: () => mode == _StoRclDialogMode.store
                ? _store(context, (double val) => calculatorModel.stoC = val)
                : _recall(context, () => calculatorModel.stoC, 'C')),
        ListTile(
            title: const Text('D'),
            subtitle: Text(format(calculatorModel.stoD,
                scientificLimit:
                    math.pow(10, calculatorModel.scientificNotationExponent).toDouble(),
                significantDigits: calculatorModel.significantDigits,
                thousandSeparator: calculatorModel.thousandSeparator)),
            onTap: () => mode == _StoRclDialogMode.store
                ? _store(context, (double val) => calculatorModel.stoD = val)
                : _recall(context, () => calculatorModel.stoD, 'D')),
      ],
    );
  }
}

class _StandardTab extends StatelessWidget {
  final CalculatorModel calculatorModel;
  final ExpressionModel expressionModel;
  const _StandardTab({Key key, @required this.calculatorModel, @required this.expressionModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Expanded(
        child: Row(children: [
          CalcButton(
              symbol: 'STO',
              textStyle: const TextStyle(fontSize: 22, height: 1.3),
              onPressed: () {
                try {
                  num eval = evaluate(expressionModel.expression, calculatorModel.angleUnit);
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return _StoRclDialog(_StoRclDialogMode.store,
                            calculatorModel: calculatorModel,
                            expressionModel: expressionModel,
                            evaluationResult: eval);
                      });
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Invalid result to store', style: TextStyle(fontSize: 18)),
                      duration: Duration(milliseconds: 1700)));
                }
              }),
          CalcButton(tokens: const [Token.leftParenthesis], expressionModel: expressionModel),
          CalcButton(tokens: const [Token.rightParenthesis], expressionModel: expressionModel),
          CalcButton(symbol: 'C', onPressed: () => expressionModel.clear()),
          CalcButton(buttonIcon: Icons.backspace, onPressed: () => expressionModel.remove()),
        ]),
      ),
      Expanded(
          child: Row(children: [
        CalcButton(tokens: const [Token.seven], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.eight], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.nine], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.exponentiate], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.scientificExp], expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(tokens: const [Token.four], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.five], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.six], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.multiply], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.divide], expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(tokens: const [Token.one], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.two], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.three], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.add], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.subtract], expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(tokens: const [Token.zero], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.dot], expressionModel: expressionModel),
        CalcButton(
            symbol: 'RCL',
            textStyle: const TextStyle(fontSize: 22, height: 1.3),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _StoRclDialog(_StoRclDialogMode.recall,
                        calculatorModel: calculatorModel, expressionModel: expressionModel);
                  });
            }),
        CalcButton(tokens: const [Token.pi], expressionModel: expressionModel),
        CalcButton(tokens: const [Token.e], expressionModel: expressionModel),
      ]))
    ]);
  }
}

class _FunctionsTab extends StatelessWidget {
  final ExpressionModel expressionModel;
  const _FunctionsTab({Key key, this.expressionModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Expanded(
        child: Row(children: [
          CalcButton(
              tokens: [Token.sqrtFunc, Token.leftParenthesis],
              textStyle: const TextStyle(fontSize: 28, height: 1.35),
              expressionModel: expressionModel),
          CalcButton(
              tokens: [Token.cubertFunc, Token.leftParenthesis],
              textStyle: const TextStyle(fontSize: 28, height: 1.35),
              expressionModel: expressionModel),
          CalcButton(
              tokens: [Token.rootFunc, Token.leftParenthesis],
              textStyle: const TextStyle(fontSize: 28, height: 1.35),
              requiresArg2: true,
              arg2Title: 'Root',
              expressionModel: expressionModel),
          CalcButton(
              tokens: [Token.ln, Token.leftParenthesis],
              textStyle: const TextStyle(fontSize: 22, height: 1.2),
              expressionModel: expressionModel),
        ]),
      ),
      Expanded(
          child: Row(children: [
        CalcButton(
            tokens: [Token.sin, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.cos, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.tan, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.log10, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(
            tokens: [Token.arcsin, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.arccos, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.arctan, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.log, Token.leftParenthesis],
            requiresArg2: true,
            arg2Title: 'Base',
            arg2Min: double.minPositive,
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(
            tokens: [Token.sinh, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.cosh, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.tanh, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.abs, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(
            tokens: [Token.arsinh, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.arcosh, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: [Token.artanh, Token.leftParenthesis],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            symbol: 'x!',
            tokens: [Token.factorial],
            textStyle: const TextStyle(fontSize: 22, height: 1.2),
            expressionModel: expressionModel),
      ]))
    ]);
  }
}

class _ConstantTab extends StatelessWidget {
  final ExpressionModel expressionModel;
  const _ConstantTab({Key key, this.expressionModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      Expanded(
        child: Row(children: [
          CalcButton(
              tokens: const [Token.protonMass],
              tooltip: 'Proton mass',
              textStyle: const TextStyle(fontSize: 25, height: 1),
              expressionModel: expressionModel),
          CalcButton(
              tokens: const [Token.neutronMass],
              tooltip: 'Neutron mass',
              textStyle: const TextStyle(fontSize: 25, height: 1),
              expressionModel: expressionModel),
          CalcButton(
              tokens: const [Token.electronMass],
              tooltip: 'Electron mass',
              textStyle: const TextStyle(fontSize: 25, height: 1),
              expressionModel: expressionModel),
          CalcButton(
              tokens: const [Token.unifiedAtomicMass],
              tooltip: 'Atomic mass constant',
              textStyle: const TextStyle(fontSize: 25, height: 1),
              expressionModel: expressionModel),
          CalcButton(
              tokens: const [Token.comptonWavelength],
              tooltip: 'Compton wavelength',
              textStyle: const TextStyle(fontSize: 25, height: 1),
              expressionModel: expressionModel),
        ]),
      ),
      Expanded(
          child: Row(children: [
        CalcButton(
            tokens: const [Token.planckConst],
            tooltip: 'Planck constant',
            textStyle: const TextStyle(fontSize: 25, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.reducedPlanckConst],
            tooltip: 'Reduced Planck constant',
            textStyle: const TextStyle(fontSize: 26, height: 1.3),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.fineStructureConst],
            tooltip: 'Fine-structure constant',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.bohrMagneton],
            tooltip: 'Bohr magneton',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.nuclearMagneton],
            tooltip: 'Nuclear magneton',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(
            tokens: const [Token.elementaryCharge],
            tooltip: 'Elementary charge',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.speedOfLight],
            tooltip: 'Vacuum speed of light',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.vacuumPermitivity],
            tooltip: 'Electric vacuum permitivity',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.vacuumPermeability],
            tooltip: 'Magnetic vacumm permeability',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.rydbergConst],
            tooltip: 'Rydberg constant',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(
            tokens: const [Token.boltzmannConst],
            tooltip: 'Boltzmann constant',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.avogadroConst],
            tooltip: 'Avogadro constant',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.gasConst],
            tooltip: 'Gas constant',
            textStyle: const TextStyle(fontSize: 25, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.gravitationConst],
            tooltip: 'Gravitational constant',
            textStyle: const TextStyle(fontSize: 25, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.earthGravity],
            tooltip: 'Gravity of earth',
            textStyle: const TextStyle(fontSize: 25, height: 1.2),
            expressionModel: expressionModel),
      ])),
      Expanded(
          child: Row(children: [
        CalcButton(
            tokens: const [Token.standardAtmosphere],
            tooltip: 'Atmospheric pressure',
            textStyle: const TextStyle(fontSize: 25, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.radiusEarth],
            tooltip: 'Earth radius',
            textStyle: const TextStyle(fontSize: 25, height: 1),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.astronomicalUnit],
            tooltip: 'Astronomical unit',
            textStyle: const TextStyle(fontSize: 26, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.parsec],
            tooltip: 'Parsec',
            textStyle: const TextStyle(fontSize: 25, height: 1.2),
            expressionModel: expressionModel),
        CalcButton(
            tokens: const [Token.lightYear],
            tooltip: 'Light-year',
            textStyle: const TextStyle(fontSize: 25, height: 1.2),
            expressionModel: expressionModel),
      ]))
    ]);
  }
}
