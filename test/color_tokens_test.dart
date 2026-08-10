import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_platform/theme/tokens.dart';

void main() {
  test('source palette tokens retain the supplied color values', () {
    expect(AppColors.paletteMargarine.toARGB32(), 0xFFF5D630);
    expect(AppColors.paletteNeonOrange.toARGB32(), 0xFFFF551D);
    expect(AppColors.paletteLava.toARGB32(), 0xFFCF161A);
    expect(AppColors.paletteRoseBonbon.toARGB32(), 0xFFFE51A4);
    expect(AppColors.paletteLavenderIndigo.toARGB32(), 0xFF9E5AFD);
  });
}
