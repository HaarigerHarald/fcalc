import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'model.dart';
import 'tex_span.dart';

/// The preference (settings) page.
class PreferencePage extends StatelessWidget {
  final CalculatorModel model;

  const PreferencePage(this.model);

  @override
  Widget build(BuildContext context) {
    TextStyle subtitleStyle = Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(color: Theme.of(context).textTheme.caption.color);

    return Scaffold(
        appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50.0),
            child: AppBar(
              title: const Text('Settings'),
            )),
        body: ListView(children: [
          Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, top: 22, bottom: 6),
              child: Text('General', style: subtitleStyle.copyWith(fontSize: 15))),
          _DropDownPreference(
              title: 'Theme',
              values: [
                _DropDownValue(ThemeMode.system.index, 'System default'),
                _DropDownValue(ThemeMode.light.index, 'Light'),
                _DropDownValue(ThemeMode.dark.index, 'Dark'),
              ],
              setFunction: (int value) => model.theme = ThemeMode.values[value],
              getFunction: () => model.theme.index,
              modelInitialized: model.initialized),
          _DropDownPreference(
              title: 'Thousand separator',
              values: const [
                _DropDownValue('', 'None'),
                _DropDownValue(' ', 'Space'),
                _DropDownValue(',', 'Comma'),
              ],
              setFunction: (String value) => model.thousandSeparator = value,
              getFunction: () => model.thousandSeparator,
              modelInitialized: model.initialized),
          _DropDownPreference(
              title: 'Significant digits',
              values: [for (int i = 8; i <= 12; i++) _DropDownValue(i)],
              setFunction: (int value) => model.significantDigits = value,
              getFunction: () => model.significantDigits,
              modelInitialized: model.initialized),
          _DropDownPreference(
              title: 'Scientific notation limit',
              values: [for (int i = 7; i <= 12; i++) _DropDownValue(i, '10^{$i}')],
              setFunction: (int value) => model.scientificNotationExponent = value,
              getFunction: () => model.scientificNotationExponent,
              modelInitialized: model.initialized),
          const Divider(thickness: 1, height: 0),
          Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16, top: 14, bottom: 6),
              child: Text('About', style: subtitleStyle.copyWith(fontSize: 15))),
          ListTile(
              title: const Text('Open-source licenses'),
              onTap: () => PackageInfo.fromPlatform().then(
                    (PackageInfo packageInfo) {
                      showLicensePage(
                          context: context,
                          applicationName: 'F Calculator',
                          applicationLegalese: 'Version: ' + packageInfo.version,
                          applicationIcon: Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: SvgPicture.asset('assets/logo.svg', height: 50)));
                    },
                  )),
          ListTile(
            title: const Text('App source code'),
            onTap: () async {
              const url = 'https://github.com/HaarigerHarald/fcalc';
              if (await canLaunch(url)) {
                await launch(url);
              }
            },
          ),
        ]));
  }
}

class _DropDownValue<E> {
  final E value;
  final String _label;

  const _DropDownValue(this.value, [String label]) : _label = label;

  String get label => _label ?? value.toString();
}

class _DropDownPreference<E> extends StatefulWidget {
  final String title;
  final List<_DropDownValue<E>> values;
  final Function setFunction;
  final Function getFunction;
  final ValueListenable<bool> modelInitialized;

  const _DropDownPreference(
      {this.title,
      @required this.values,
      @required this.setFunction,
      @required this.getFunction,
      @required this.modelInitialized});

  @override
  State<StatefulWidget> createState() => _DropDownPreferenceState<E>();
}

class _DropDownPreferenceState<E> extends State<_DropDownPreference> {
  Future _showDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(widget.title),
            contentPadding: const EdgeInsets.only(top: 12, left: 7, right: 7),
            insetPadding: EdgeInsets.zero,
            content: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ListBody(children: [
                  for (final _DropDownValue dropDownValue in widget.values)
                    _SmallRadioTile<E>(
                        title: dropDownValue.label,
                        value: dropDownValue.value,
                        groupValue: widget.getFunction(),
                        onChanged: (E value) {
                          Navigator.of(context).pop();
                          if (value != widget.getFunction()) {
                            widget.setFunction(value);
                            setState(() => {});
                          }
                        })
                ])),
            actions: [
              TextButton(
                  child: Text('CANCEL',
                      style: Theme.of(context).textTheme.bodyText1.copyWith(fontSize: 15)),
                  onPressed: () => Navigator.of(context).pop())
            ],
          );
        });
  }

  TexSpan _getSubtitleValue() {
    TextStyle subtitleStyle = Theme.of(context)
        .textTheme
        .bodyText2
        .copyWith(color: Theme.of(context).textTheme.caption.color);

    for (final _DropDownValue dropDownValue in widget.values) {
      if (dropDownValue.value == widget.getFunction()) {
        return TexSpan(dropDownValue.label, subtitleStyle);
      }
    }
    return TexSpan('', subtitleStyle);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.modelInitialized,
      builder: (context, value, child) {
        return ListTile(
            title: Text(widget.title),
            subtitle: Text.rich(_getSubtitleValue()),
            onTap: () => _showDialog());
      },
    );
  }
}

class _SmallRadioTile<E> extends StatelessWidget {
  final String title;
  final E value;
  final E groupValue;
  final Function(E value) onChanged;

  const _SmallRadioTile({this.title, this.value, this.groupValue, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
        child: Row(children: [
          Radio<E>(
              value: value,
              groupValue: groupValue,
              activeColor: Theme.of(context).accentColor,
              onChanged: (E value) => {onChanged(value)}),
          Text.rich(TexSpan(title, const TextStyle(fontSize: 16))),
        ]),
        onPressed: () => {onChanged(value)});
  }
}
