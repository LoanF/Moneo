import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Palette Moneo. L'identité est sombre et rouge, comme l'app d'origine :
/// fond presque noir, grandes cartes arrondies, rouge Moneo pour ce qui compte.
@immutable
class MoneoColors extends ThemeExtension<MoneoColors> {
  const MoneoColors({
    required this.brand,
    required this.brandBright,
    required this.brandDeep,
    required this.onBrand,
    required this.ground,
    required this.card,
    required this.stub,
    required this.raised,
    required this.ink,
    required this.inkSoft,
    required this.line,
    required this.perforation,
    required this.income,
    required this.expense,
    required this.warning,
    required this.highlight,
    required this.glow,
  });

  /// Rouge Moneo.
  final Color brand;
  final Color brandBright;
  final Color brandDeep;
  final Color onBrand;

  /// Fond de page.
  final Color ground;

  /// Surface des cartes.
  final Color card;

  /// Surface en retrait (zones secondaires).
  final Color stub;

  /// Surface au-dessus des cartes (champs, puces, pastilles).
  final Color raised;
  final Color ink;
  final Color inkSoft;

  /// Filets et contours discrets.
  final Color line;

  /// Contours plus marqués (éléments inactifs).
  final Color perforation;
  final Color income;
  final Color expense;
  final Color warning;

  /// Fond d'un bandeau d'information.
  final Color highlight;

  /// Halo sous les éléments rouges.
  final Color glow;

  /// Dégradé du rouge Moneo, pour les éléments mis en avant.
  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandBright, brand, brandDeep],
    stops: const [0, 0.45, 1],
  );

  static const dark = MoneoColors(
    brand: Color(0xFFF44336),
    brandBright: Color(0xFFFF6A57),
    brandDeep: Color(0xFFC92A22),
    onBrand: Color(0xFFFFFFFF),
    ground: Color(0xFF0B0B0D),
    card: Color(0xFF17171A),
    stub: Color(0xFF121214),
    raised: Color(0xFF222226),
    ink: Color(0xFFF6F6F8),
    inkSoft: Color(0xFFA1A1AB),
    line: Color(0xFF26262B),
    perforation: Color(0xFF3A3A42),
    income: Color(0xFF4ADE80),
    expense: Color(0xFFFF6B5E),
    warning: Color(0xFFFBBF24),
    highlight: Color(0xFF2A2212),
    glow: Color(0x66F44336),
  );

  static const light = MoneoColors(
    brand: Color(0xFFF44336),
    brandBright: Color(0xFFFF6A57),
    brandDeep: Color(0xFFC92A22),
    onBrand: Color(0xFFFFFFFF),
    ground: Color(0xFFF3F3F6),
    card: Color(0xFFFFFFFF),
    stub: Color(0xFFF7F7FA),
    raised: Color(0xFFEDEDF1),
    ink: Color(0xFF111114),
    inkSoft: Color(0xFF62626D),
    line: Color(0xFFE6E6EB),
    perforation: Color(0xFFC9C9D1),
    income: Color(0xFF15803D),
    expense: Color(0xFFC62828),
    warning: Color(0xFF92400E),
    highlight: Color(0xFFFFF4D6),
    glow: Color(0x40F44336),
  );

  @override
  MoneoColors copyWith() => this;

  @override
  MoneoColors lerp(ThemeExtension<MoneoColors>? other, double t) {
    if (other is! MoneoColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return MoneoColors(
      brand: mix(brand, other.brand),
      brandBright: mix(brandBright, other.brandBright),
      brandDeep: mix(brandDeep, other.brandDeep),
      onBrand: mix(onBrand, other.onBrand),
      ground: mix(ground, other.ground),
      card: mix(card, other.card),
      stub: mix(stub, other.stub),
      raised: mix(raised, other.raised),
      ink: mix(ink, other.ink),
      inkSoft: mix(inkSoft, other.inkSoft),
      line: mix(line, other.line),
      perforation: mix(perforation, other.perforation),
      income: mix(income, other.income),
      expense: mix(expense, other.expense),
      warning: mix(warning, other.warning),
      highlight: mix(highlight, other.highlight),
      glow: mix(glow, other.glow),
    );
  }
}

extension MoneoContext on BuildContext {
  MoneoColors get moneo => Theme.of(this).extension<MoneoColors>()!;
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// `true` quand l'utilisateur a demandé moins d'animations.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

/// Espacements sur une grille de 4 pt.
abstract final class Gap {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Marge latérale des écrans.
  static const page = 20.0;

  /// Dégagement en bas des listes, sous la barre de navigation flottante.
  static const dock = 128.0;
}

abstract final class Radii {
  static const field = 16.0;
  static const tile = 20.0;
  static const card = 26.0;
  static const sheet = 32.0;
}

abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 520);
  static const curve = Curves.easeOutCubic;

  /// Rebond léger des éléments qu'on vient d'actionner.
  static const spring = Curves.easeOutBack;
}

/// Chiffres à chasse fixe : les montants s'alignent en colonne.
const tabular = [FontFeature.tabularFigures()];

abstract final class MoneoTheme {
  static ThemeData light() => _build(Brightness.light, MoneoColors.light);
  static ThemeData dark() => _build(Brightness.dark, MoneoColors.dark);

  static ThemeData _build(Brightness brightness, MoneoColors c) {
    final isLight = brightness == Brightness.light;
    // Sur fond clair, le rouge qui porte du texte est légèrement assombri pour rester lisible (≥ 4,5:1).
    final action = isLight ? const Color(0xFFD32F2F) : c.brand;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: action,
      onPrimary: Colors.white,
      primaryContainer: isLight
          ? const Color(0xFFFFE1DC)
          : const Color(0xFF3A1512),
      onPrimaryContainer: isLight
          ? const Color(0xFF5F0F0A)
          : const Color(0xFFFFD9D3),
      secondary: c.inkSoft,
      onSecondary: c.ground,
      secondaryContainer: c.raised,
      onSecondaryContainer: c.ink,
      tertiary: c.income,
      onTertiary: c.ground,
      error: isLight ? const Color(0xFFB3261E) : const Color(0xFFFF8A80),
      onError: isLight ? Colors.white : const Color(0xFF3B0A06),
      errorContainer: isLight
          ? const Color(0xFFFFE1DC)
          : const Color(0xFF3A1512),
      onErrorContainer: isLight
          ? const Color(0xFF5F0F0A)
          : const Color(0xFFFFD9D3),
      surface: c.card,
      onSurface: c.ink,
      onSurfaceVariant: c.inkSoft,
      surfaceContainerLowest: c.ground,
      surfaceContainerLow: c.stub,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.raised,
      surfaceContainerHighest: c.raised,
      outline: c.perforation,
      outlineVariant: c.line,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isLight
          ? const Color(0xFF1C1C20)
          : const Color(0xFFF1F1F4),
      onInverseSurface: isLight
          ? const Color(0xFFF6F6F8)
          : const Color(0xFF111114),
      inversePrimary: isLight
          ? const Color(0xFFFF8A7A)
          : const Color(0xFFC92A22),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    // Les tailles du thème de base ne sont fusionnées qu'à l'affichage : celles dont l'app
    // dépend sont fixées ici.
    TextStyle? style(
      TextStyle? s,
      double size,
      FontWeight weight, {
      double spacing = 0,
      double? height,
    }) => s?.copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: spacing,
      height: height,
    );
    final b = base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink);
    final text = b.copyWith(
      displayMedium: style(
        b.displayMedium,
        44,
        FontWeight.w800,
        spacing: -1.4,
        height: 1.05,
      ),
      displaySmall: style(
        b.displaySmall,
        34,
        FontWeight.w800,
        spacing: -0.9,
        height: 1.1,
      ),
      headlineMedium: style(
        b.headlineMedium,
        28,
        FontWeight.w800,
        spacing: -0.6,
        height: 1.15,
      ),
      headlineSmall: style(
        b.headlineSmall,
        23,
        FontWeight.w800,
        spacing: -0.4,
        height: 1.2,
      ),
      titleLarge: style(b.titleLarge, 20, FontWeight.w700, spacing: -0.2),
      titleMedium: style(b.titleMedium, 16.5, FontWeight.w700, spacing: -0.1),
      titleSmall: style(b.titleSmall, 14, FontWeight.w700),
      bodyLarge: style(b.bodyLarge, 16, FontWeight.w500, height: 1.35),
      bodyMedium: style(b.bodyMedium, 14.5, FontWeight.w400, height: 1.4),
      bodySmall: style(b.bodySmall, 13, FontWeight.w400, height: 1.35),
      labelLarge: style(b.labelLarge, 15, FontWeight.w700),
      labelMedium: style(b.labelMedium, 13, FontWeight.w600),
      labelSmall: style(b.labelSmall, 11.5, FontWeight.w700, spacing: 0.9),
    );

    OutlineInputBorder field(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.field),
          borderSide: BorderSide(color: color, width: width),
        );
    final fieldFill = isLight ? c.card : c.raised;

    return base.copyWith(
      extensions: [c],
      textTheme: text,
      scaffoldBackgroundColor: c.ground,
      canvasColor: c.ground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: c.ink.withValues(alpha: 0.05),
      appBarTheme: AppBarTheme(
        backgroundColor: c.ground,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: text.headlineSmall,
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: c.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: c.line),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: c.inkSoft,
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.page),
        minVerticalPadding: 12,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: text.bodySmall?.copyWith(color: c.inkSoft),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: fieldFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: field(Colors.transparent),
        enabledBorder: field(isLight ? c.line : Colors.transparent),
        focusedBorder: field(c.brand, 2),
        errorBorder: field(scheme.error),
        focusedErrorBorder: field(scheme.error, 2),
        labelStyle: text.bodyLarge?.copyWith(color: c.inkSoft),
        floatingLabelStyle: text.bodyLarge?.copyWith(
          color: c.ink,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: text.bodyLarge?.copyWith(
          color: c.inkSoft.withValues(alpha: 0.7),
        ),
        helperStyle: text.bodySmall?.copyWith(color: c.inkSoft),
        errorStyle: text.bodySmall?.copyWith(
          color: scheme.error,
          fontWeight: FontWeight.w600,
        ),
        helperMaxLines: 3,
        errorMaxLines: 3,
        prefixIconColor: c.inkSoft,
        suffixIconColor: c.inkSoft,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          foregroundColor: c.ink,
          backgroundColor: isLight ? c.card : c.raised,
          side: BorderSide(color: isLight ? c.line : Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: text.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: isLight ? action : c.brandBright,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: c.ink,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.62),
        showDragHandle: true,
        dragHandleColor: c.perforation,
        dragHandleSize: const Size(44, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.inkSoft),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(
          Gap.lg,
          0,
          Gap.lg,
          Gap.dock - 24,
        ),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? c.card : c.raised,
        selectedColor: c.brand,
        disabledColor: c.stub,
        side: BorderSide(color: isLight ? c.line : Colors.transparent),
        labelStyle: text.labelMedium?.copyWith(
          fontSize: 14,
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? Colors.white : c.ink,
          ),
        ),
        iconTheme: IconThemeData(color: c.inkSoft, size: 18),
        shape: const StadiumBorder(),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : c.inkSoft,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.raised,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.transparent
              : c.perforation,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.brand,
        inactiveTrackColor: c.raised,
        thumbColor: c.brand,
        overlayColor: c.glow,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.perforation,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.brand,
        linearTrackColor: c.raised,
        circularTrackColor: c.raised,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: c.brand,
        textColor: Colors.white,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
    );
  }
}
