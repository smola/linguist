require_relative "./helper"

class TestTokenizer < Minitest::Test
  include Linguist

  def tokenize(data)
    data = File.read(File.join(samples_path, data.to_s)) if data.is_a?(Symbol)
    Tokenizer.tokenize(data)
  end

  def test_escape_string_literals
    assert_equal %w(print " "), tokenize('print ""')
    assert_equal %w(print " ~~IN~"~Josh "), tokenize('print "Josh"')
    assert_equal %w(print ' ~~IN~'~Josh '), tokenize("print 'Josh'")
    assert_equal %w(print " ~~IN~"~Hello ~~IN~"~" ~~IN~"~~~IN~"~Josh ~~IN~"~" "), tokenize('print "Hello \"Josh\""')
    assert_equal %w(print ' ~~IN~'~Hello ~~IN~'~' ~~IN~'~~~IN~'~Josh ~~IN~'~' '), tokenize("print 'Hello \\'Josh\\''")
    assert_equal %w(print " ~~IN~"~Hello " " ~~IN~"~Josh "), tokenize("print \"Hello\", \"Josh\"")
    assert_equal %w(print ' ~~IN~'~Hello ' ' ~~IN~'~Josh '), tokenize("print 'Hello', 'Josh'")
    assert_equal %w(print " ~~IN~"~Hello " " " " ~~IN~"~Josh "), tokenize("print \"Hello\", \"\", \"Josh\"")
    assert_equal %w(print ' ~~IN~'~Hello ' ' ' ' ~~IN~'~Josh '), tokenize("print 'Hello', '', 'Josh'")
  end

  def test_skip_number_literals
    assert_equal %w(~~NUMLITERAL + ~~NUMLITERAL), tokenize('1 + 1')
    assert_equal %w(add \( ~~NUMLITERAL ~~NUMLITERAL \)), tokenize('add(123, 456)')
    assert_equal %w(~~HEXLITERAL | ~~HEXLITERAL), tokenize('0x01 | 0x10')
    assert_equal %w(~~NUMLITERAL * ~~NUMLITERAL), tokenize('500.42 * 1.0')
    assert_equal %w(~~NUMLITERAL), tokenize('1.23e-04')
    assert_equal %w(~~NUMLITERAL), tokenize('1.0f')
    assert_equal %w(~~NUMLITERAL), tokenize('1234ULL')
    assert_equal %w(G1 X55 Y5 F2000), tokenize('G1 X55 Y5 F2000')
  end

  def test_escape_comments
    assert_equal %w(foo # ~~IN~#~Comment), tokenize("foo\n# Comment")
    assert_equal %w(foo # ~~IN~#~Comment bar), tokenize("foo\n# Comment\nbar")
    assert_equal %w(foo // ~~IN~//~Comment), tokenize("foo\n// Comment")
    assert_equal %w(foo -- ~~IN~--~Comment), tokenize("foo\n-- Comment")
    assert_equal %w(foo " ~~IN~"~Comment), tokenize("foo\n\" Comment")
    assert_equal %w(foo /* ~~IN~/*~Comment */), tokenize("foo /* Comment */")
    assert_equal %w(foo /* ~~IN~/*~Comment */), tokenize("foo /* \nComment\n */")
    assert_equal %w(foo <!-- ~~IN~<!--~Comment -->), tokenize("foo <!-- Comment -->")
    assert_equal %w(foo {- ~~IN~{-~Comment -}), tokenize("foo {- Comment -}")
    assert_equal %w(foo \(* ~~IN~\(*~Comment *\)), tokenize("foo (* Comment *)")
    assert_equal %w(~~NUMLITERAL % ~~NUMLITERAL % ~~IN~%~Comment), tokenize("2 % 10\n% Comment")
    assert_equal %w(foo """ ~~IN~"""~Comment """ bar), tokenize("foo\n\"\"\"\nComment\n\"\"\"\nbar")
    assert_equal %w(foo ''' ~~IN~'''~Comment ''' bar), tokenize("foo\n'''\nComment\n'''\nbar")
  end

  def test_sgml_tags
    assert_equal %w(<html> </html>), tokenize("<html></html>")
    assert_equal %w(<div> id </div>), tokenize("<div id></div>")
    assert_equal %w(<div> id= </div>), tokenize("<div id=foo></div>")
    assert_equal %w(<div> id class </div>), tokenize("<div id class></div>")
    assert_equal %w(<div> id= </div>), tokenize("<div id=\"foo bar\"></div>")
    assert_equal %w(<div> id= </div>), tokenize("<div id='foo bar'></div>")
    assert_equal %w(<?xml> version=), tokenize("<?xml version=\"1.0\"?>")
  end

  def test_operators
    assert_equal %w(~~NUMLITERAL + ~~NUMLITERAL), tokenize("1 + 1")
    assert_equal %w(~~NUMLITERAL ++ ~~NUMLITERAL), tokenize("1 ++ 1")
    assert_equal %w(~~NUMLITERAL - ~~NUMLITERAL), tokenize("1 - 1")
    assert_equal %w(i ++), tokenize("i++")
    assert_equal %w(i --), tokenize("i--")
    assert_equal %w(~~NUMLITERAL * ~~NUMLITERAL), tokenize("1 * 1")
    assert_equal %w(~~NUMLITERAL ** ~~NUMLITERAL), tokenize("1 ** 1")
    assert_equal %w(~~NUMLITERAL / ~~NUMLITERAL), tokenize("1 / 1")
    assert_equal %w(~~NUMLITERAL % ~~NUMLITERAL), tokenize("2 % 5")
    assert_equal %w(~~NUMLITERAL & ~~NUMLITERAL), tokenize("1 & 1")
    assert_equal %w(~~NUMLITERAL && ~~NUMLITERAL), tokenize("1 && 1")
    assert_equal %w(~~NUMLITERAL | ~~NUMLITERAL), tokenize("1 | 1")
    assert_equal %w(~~NUMLITERAL || ~~NUMLITERAL), tokenize("1 || 1")
    assert_equal %w(~~NUMLITERAL < ~~HEXLITERAL), tokenize("1 < 0x01")
    assert_equal %w(~~NUMLITERAL << ~~HEXLITERAL), tokenize("1 << 0x01")
    assert_equal %w(~~NUMLITERAL <<< ~~HEXLITERAL), tokenize("1 <<< 0x01")
    assert_equal %w(foo <<= ~~HEXLITERAL), tokenize("foo <<= 0x01")
    assert_equal %w(foo >>= ~~HEXLITERAL), tokenize("foo >>= 0x01")
    assert_equal %w(foo *= ~~HEXLITERAL), tokenize("foo *= 0x01")
    assert_equal %w(foo ^ ~~HEXLITERAL), tokenize("foo ^ 0x01")
    assert_equal %w(foo ^= ~~HEXLITERAL), tokenize("foo ^= 0x01")
    assert_equal %w(foo == bar), tokenize("foo == bar")
    assert_equal %w(foo === bar), tokenize("foo === bar")

  end

  def test_c_tokens
    assert_equal %w(# ~~IN~#~ifndef ~~IN~#~HELLO_H # ~~IN~#~define ~~IN~#~HELLO_H void hello \( \) ; # ~~IN~#~endif), tokenize(:"C/hello.h")
    assert_equal %w(# ~~IN~#~include ~~IN~#~<stdio.h> int main \( \) { printf \( " ~~IN~"~Hello ~~IN~"~World ~~IN~"~n " \) ; return ~~NUMLITERAL ; }), tokenize(:"C/hello.c")
  end

  def test_cpp_tokens
    assert_equal %w(class Bar { protected char * name ; public void hello \( \) ; }), tokenize(:"C++/bar.h")
    assert_equal %w(# ~~IN~#~include ~~IN~#~<iostream> using namespace std ; int main \( \) { cout << " ~~IN~"~Hello ~~IN~"~World " << endl ; }), tokenize(:"C++/hello.cpp")
  end

  def test_objective_c_tokens
    assert_equal %w(# ~~IN~#~import ~~IN~#~<Foundation/Foundation.h> @interface Foo NSObject { } @end), tokenize(:"Objective-C/Foo.h")
    assert_equal %w(# ~~IN~#~import ~~IN~#~" ~~IN~#~~~IN~"~Foo.h  ~~IN~#~" @implementation Foo @end), tokenize(:"Objective-C/Foo.m")
    assert_equal %w(# ~~IN~#~import ~~IN~#~<Cocoa/Cocoa.h> int main \( int argc char * argv [ ] \) { NSLog \( @ " ~~IN~"~Hello ~~IN~"~World ~~IN~"~n " \) ; return ~~NUMLITERAL ; }), tokenize(:"Objective-C/hello.m")
  end

  def test_shebang
    assert_equal "~~SHEBANG#!sh", tokenize(:"Shell/sh")[0]
    assert_equal "~~SHEBANG#!bash", tokenize(:"Shell/bash")[0]
    assert_equal "~~SHEBANG#!zsh", tokenize(:"Shell/zsh")[0]
    assert_equal "~~SHEBANG#!perl", tokenize(:"Perl/perl")[0]
    assert_equal "~~SHEBANG#!python", tokenize(:"Python/python")[0]
    assert_equal "~~SHEBANG#!ruby", tokenize(:"Ruby/ruby")[0]
    assert_equal "~~SHEBANG#!ruby", tokenize(:"Ruby/ruby2")[0]
    assert_equal "~~SHEBANG#!node", tokenize(:"JavaScript/js")[0]
    assert_equal "~~SHEBANG#!php", tokenize(:"PHP/php")[0]
    assert_equal "~~SHEBANG#!escript", tokenize(:"Erlang/factorial")[0]
    assert_equal "echo", tokenize(:"Shell/invalid-shebang.sh")[0]
  end

  def test_javascript_tokens
    assert_equal %w( \( function \( \) { console.log \( " ~~IN~"~Hello ~~IN~"~World " \) ; } \) .call \( this \) ;), tokenize(:"JavaScript/hello.js")
  end

  def test_json_tokens
    assert_equal %w( { " ~~IN~"~id " ~~NUMLITERAL " " " " " " ~~NUMLITERAL " " [ " " " " ] " " { " " ~~NUMLITERAL " " ~~NUMLITERAL } } ), tokenize(:"JSON/product.json")
  end

  def test_ruby_tokens
    assert_equal %w(module Foo end), tokenize(:"Ruby/foo.rb")
    assert_equal %w(task default do puts " ~~IN~"~Rake " end), tokenize(:"Ruby/filenames/Rakefile")
  end
end
