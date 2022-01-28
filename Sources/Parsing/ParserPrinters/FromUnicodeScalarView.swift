/// A parser that transforms a parser on `Substring.UnicodeScalarView` into a parser on another
/// view.
public struct FromUnicodeScalarView<Input, UnicodeScalarsParser>: Parser
where
  UnicodeScalarsParser: Parser,
  UnicodeScalarsParser.Input == Substring.UnicodeScalarView
{
  public let unicodeScalarsParser: UnicodeScalarsParser
  public let toUnicodeScalars: (Input) -> Substring.UnicodeScalarView
  public let fromUnicodeScalars: (Substring.UnicodeScalarView) -> Input

  @inlinable
  public func parse(_ input: inout Input) rethrows -> UnicodeScalarsParser.Output {
    var unicodeScalars = self.toUnicodeScalars(input)
    defer { input = self.fromUnicodeScalars(unicodeScalars) }
    return try self.unicodeScalarsParser.parse(&unicodeScalars)
  }
}

extension FromUnicodeScalarView: Printer where UnicodeScalarsParser: Printer {
  @inlinable
  public func print(_ output: UnicodeScalarsParser.Output, to input: inout Input) rethrows {
    var unicodeScalarsInput = self.toUnicodeScalars(input)
    try self.unicodeScalarsParser.print(output, to: &unicodeScalarsInput)
    input = self.fromUnicodeScalars(unicodeScalarsInput)
  }
}

extension FromUnicodeScalarView where Input == ArraySlice<UInt8> {
  @inlinable
  public init(@ParserBuilder _ build: () -> UnicodeScalarsParser) {
    self.unicodeScalarsParser = build()
    self.toUnicodeScalars = { Substring(decoding: $0, as: UTF8.self).unicodeScalars }
    self.fromUnicodeScalars = { ArraySlice(Substring($0).utf8) }
  }
}

extension FromUnicodeScalarView where Input == Substring {
  @inlinable
  public init(@ParserBuilder _ build: () -> UnicodeScalarsParser) {
    self.unicodeScalarsParser = build()
    self.toUnicodeScalars = \.unicodeScalars
    self.fromUnicodeScalars = Substring.init
  }
}

extension FromUnicodeScalarView where Input == Substring.UTF8View {
  @inlinable
  public init(@ParserBuilder _ build: () -> UnicodeScalarsParser) {
    self.unicodeScalarsParser = build()
    self.toUnicodeScalars = { Substring($0).unicodeScalars }
    self.fromUnicodeScalars = { Substring($0).utf8 }
  }
}