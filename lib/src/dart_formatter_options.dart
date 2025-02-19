// ignore_for_file: constant_identifier_names, unused_element

import 'package:dart_polisher/src/style_fix.dart';
import 'package:dart_polisher/src/dp_constants.dart';

import 'package:analyzer/dart/ast/ast.dart';

/// Styles are profiles that group a default set of formatting options to form a Code Style.
enum CodeProfile {
    DartStyle("Dart Style", "Google 'dart' style [custom tab indents & tab mode]", 0),
    ExpandedStyle("Expanded", "dart_style with outer braces on block-like nodes", 1),
    style2("**", "****", 2),
    style3(".", "...", 3),
    ;

    /// Get the enum matching the style [code],
    /// returns the default enum if there is no match or if [code] is null.
    static CodeProfile getStyleFromCode(int? code)
    {
        return CodeProfile.values.firstWhere((element) => element.code == code,
            orElse: () => CodeProfile.DartStyle);
    }

    /// Get the first enum matching the style [name],
    /// returns the default enum if there is no match or if [name] is null.
    static CodeProfile getStyleFromName(String? name)
    {
        return CodeProfile.values.firstWhere((element) => element.name == name,
            orElse: () => CodeProfile.DartStyle);
    }

    const CodeProfile(this.name, this.description, this.code);

    final String name;

    final String description;

    /// Code number for the style profile.
    final int code;
}

/// Class with bit values representing Formatting options for Body-like sintax
///
/// Its used to build bitmasks: bitmask = option1 | option2;
///
/// These options are used internally by the formatter to format code of a style [CodeProfile].
///
/// Bracket can be '{}' or '()' or '[]'
/// Here are the brackets applicable on Body.
///
/// Bracket=>Body=> (Block-like sintax)
///  Block | [ClassDeclaration] | [ExtensionDeclaration] | [MixinDeclaration] | [EnumDeclaration]
///
/// Bracket=>CollectionLiteral=> (Collections-like sintax)
///  [ArgumentList] | [AssertInitializer] | [AssertStatement] | [ListLiteral] | [SetOrMapLiteral]
///
/// Block means:
/// [Block] ::= '{' [Statement]* '}'
///
/// Clients may not extend, implement or mix-in this class.
class CodeStyle
{
    /// Braces '{}' on Block-like Bodies
    ///
    /// These are always newlined.
    /// Includes: [ClassDeclaration] | [ExtensionDeclaration] | [MixinDeclaration] | [SwitchStatement] | [SwitchExpression]
    ///
    /// Excludes: [TypedLiteral] | [EnumDeclaration] (These are handled in other options)
    final bool outerBracesOnBlockLike;

    /// Outer braces on collection literals
    /// If they split, they become difficult to distinguish between blocks and collections.
    /// It's folded if it can fit inside max line lenght and split if not.
    ///
    ///! NOT IMPLEMENTED.
    final bool outerBracesOnCollectionLiteralsSmart;

    /// Enum is a special case, can look good folded if it fits in max line lenght.
    /// True means split '{' if contents split, remain folded if false.
    /// Same case with collection literals, looks better if its folded.
    /// That way it can be better distinguished between block-like nodes.
    ///! NOT IMPLEMENTED.
    // TODO (tekert): not implemented yet, check if it looks good.
    final bool outerBracesOnEnumSmart;

    // The stataments that follow a '}' like: else/else if/catch/on/finally

    /// Puts clause within a [TryStatement] clause on newline.
    final bool outerTryStatementClause;

    /// Puts else [IfStatement]s on newline, uses space if not set.
    final bool outerIfStatementElse;

    factory CodeStyle.fromProfile(CodeProfile profile)
    {
        switch (profile)
        {
            case CodeProfile.DartStyle:
                return const CodeStyle();

            case CodeProfile.ExpandedStyle:
                return const CodeStyle(
                    outerBracesOnBlockLike: true,
                    outerBracesOnEnumSmart: true,
                    outerTryStatementClause: true,
                    outerIfStatementElse: true);

            default:
                return const CodeStyle();
        }
    }

    const CodeStyle(
        {this.outerBracesOnBlockLike = false,
        this.outerBracesOnCollectionLiteralsSmart = false,
        this.outerBracesOnEnumSmart = false,
        this.outerTryStatementClause = false,
        this.outerIfStatementElse = false});
}

/// Constants for the number of spaces in various kinds of indentation.
class CodeIndent
{
    /// The number of spaces in a block or collection body.
    final int block;

    /// How much wrapped cascade sections indent.
    final int cascade;

    /// The number of spaces in a single level of expression nesting.
    final int expression;

    /// The ":" on a wrapped constructor initialization list.
    final int constructorInitializer;

    // If a parameter is ommited a default value is assigned.
    const CodeIndent(
        {this.block = DefaultValue.DEFAULT_BLOCK_INDENT,
        this.cascade = DefaultValue.DEFAULT_CASCADE_INDENT,
        this.expression = DefaultValue.DEFAULT_EXPRESSION_INDENT,
        this.constructorInitializer =
            DefaultValue.DEFAULT_CONSTRUCTOR_INITIALIZER_INDENT});

    // If a parameter is ommited or null a default value is assigned.
    const CodeIndent.opt(
        {int? block, int? cascade, int? expression, int? constructorInitializer})
        : block = block ?? DefaultValue.DEFAULT_BLOCK_INDENT,
          cascade = cascade ?? DefaultValue.DEFAULT_CASCADE_INDENT,
          expression = expression ?? DefaultValue.DEFAULT_EXPRESSION_INDENT,
          constructorInitializer = constructorInitializer ??
              DefaultValue.DEFAULT_CONSTRUCTOR_INITIALIZER_INDENT;
}

/// Options that control how the code will be formattend
/// these are used as an argument for [DartFormatter]
class FormatterOptions
{
    /// The number of spaces of indentation to prefix the output with.
    /// note: this is for the whole page, meaning from column 1, like padding.
    /// for tab size see [tabSizes]
    final int indent;

    /// The number of columns that formatted output should be constrained to fit
    /// within.
    final int pageWidth;

    /// The string that newlines should use.
    ///
    /// If not explicitly provided, this is inferred from the source text. If the
    /// first newline is `\r\n` (Windows), it will use that. Otherwise, it uses
    /// Unix-style line endings (`\n`).
    final String? lineEnding;

    /// The style fixes to apply while formatting.
    final Set<StyleFix> fixes;

    /// Space indents for expressions, blocks, cascade and constructor initializer
    final CodeIndent tabSizes;

    /// Set type of tab to use [true] for space, [false] for tabs
    final bool insertSpaces;

    /// Style to use for source code formatting
    /// based on a modified sets of rules derived from the original dart_style classes.
    final CodeStyle style;

    const FormatterOptions(
        {this.lineEnding,
        this.indent = 0,
        this.pageWidth = DefaultValue.DEFAULT_PAGEWIDTH,
        this.insertSpaces = DefaultValue.DEFAULT_INSERTSPACES,
        this.style = DefaultValue.DEFAULT_STYLE,
        this.fixes = const {},
        this.tabSizes = const CodeIndent()});

    /// Accepts null values.
    const FormatterOptions.opt(
        {this.lineEnding,
        int? indent,
        int? pageWidth,
        bool? insertSpaces,
        CodeStyle? style,
        Set<StyleFix>? fixes,
        CodeIndent? tabSizes})
        : indent = indent ?? 0,
          pageWidth = pageWidth ?? DefaultValue.DEFAULT_PAGEWIDTH,
          insertSpaces = insertSpaces ?? DefaultValue.DEFAULT_INSERTSPACES,
          style = style ?? DefaultValue.DEFAULT_STYLE,
          fixes = fixes ?? const {},
          tabSizes = tabSizes ?? const CodeIndent();
}
