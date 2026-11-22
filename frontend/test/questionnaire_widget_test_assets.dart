import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/services/questionnaire/questionnaire_repository.dart';

void useQuestionnaireWidgetAssets() {
  final assets = {
    for (final path in [
      QuestionnaireRepository.assetPath,
      QuestionnaireRepository.displayAssetPath,
    ])
      path: ByteData.sublistView(File(path).readAsBytesSync()),
  };

  setUp(() {
    for (final path in assets.keys) {
      rootBundle.evict(path);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) {
          final path = utf8.decode(Uint8List.sublistView(message!));
          return SynchronousFuture(assets[path]);
        });
  });

  tearDown(() {
    for (final path in assets.keys) {
      rootBundle.evict(path);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });
}
