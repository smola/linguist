require 'strscan'

module Linguist
  # Generic programming language tokenizer.
  #
  # Tokens are designed for use in the language bayes classifier.
  # It strips any data strings or comments and preserves significant
  # language symbols.
  class Tokenizer
    # Public: Extract tokens from data
    #
    # data - String to tokenize
    #
    # Returns Array of token Strings.
    def self.tokenize(data)
      new.extract_tokens(data)
    end

    # Read up to 100KB
    BYTE_LIMIT = 100_000

    # Start state on token, ignore anything till the next newline
    SINGLE_LINE_COMMENTS = [
      '//', # C
      '--', # Ada, Haskell, AppleScript
      '#',  # Ruby
      '%',  # Tex
      '"',  # Vim
    ]

    # Start state on opening token, ignore anything until the closing
    # token is reached.
    MULTI_LINE_COMMENTS = [
      ['/*', '*/'],    # C
      ['<!--', '-->'], # XML
      ['{-', '-}'],    # Haskell
      ['(*', '*)'],    # Coq
      ['"""', '"""'],  # Python
      ["'''", "'''"]   # Python
    ]

    START_SINGLE_LINE_COMMENT =  Regexp.compile(SINGLE_LINE_COMMENTS.map { |c|
      "\s*#{Regexp.escape(c)}"
    }.join("|"))

    START_MULTI_LINE_COMMENT =  Regexp.compile(MULTI_LINE_COMMENTS.map { |c|
      Regexp.escape(c[0])
    }.join("|"))

    # Internal: Extract generic tokens from data.
    #
    # data - String to scan.
    #
    # Examples
    #
    #   extract_tokens("printf('Hello')")
    #   # => ['printf', '(', ')']
    #
    # Returns Array of token Strings.
    def extract_tokens(data)
      s = StringScanner.new(data)

      tokens = []
      until s.eos?
        break if s.pos >= BYTE_LIMIT

        if token = s.scan(/^#!.+$/)
          if name = extract_shebang(token)
            tokens << "~~SHEBANG#!#{name}"
          end

        # Multiline comments
        elsif token = s.scan(START_MULTI_LINE_COMMENT)
          tokens << token
          close_token = MULTI_LINE_COMMENTS.assoc(token)[1]
          if comment = s.scan_until(Regexp.compile(Regexp.escape(close_token)))
            comment = comment.chomp(close_token)
            extract_tokens(comment).each do |in_comment|
              tokens << "~~IN~#{token}~#{in_comment}"
            end
          end
          tokens << close_token

        # Single line comment
        elsif s.beginning_of_line? && token = s.scan(START_SINGLE_LINE_COMMENT)
          token = token.strip
          tokens << token
          if comment = s.scan_until(/\n|\Z/)
            extract_tokens(comment).each do |in_comment|
              tokens << "~~IN~#{token}~#{in_comment}"
            end
          end

        # Skip single or double quoted strings
        elsif s.scan(/"/)
          token = "\""
          tokens << token
          if s.peek(1) == token
            s.getch
          else
            if string = s.scan_until(/(?<!\\)"/)
              string = string.chomp("\"").gsub(/\\"/, "\"")
              extract_tokens(string).each do |in_string|
                tokens << "~~IN~#{token}~#{in_string}"
              end
            end
          end
          tokens << token
        elsif s.scan(/'/)
          token = "'"
          tokens << token
          if s.peek(1) == token
            s.getch
          else
            if string = s.scan_until(/(?<!\\)'/)
              string = string.chomp("'").gsub(/\\'/, "'")
              extract_tokens(string).each do |in_string|
                tokens << "~~IN~#{token}~#{in_string}"
              end
            end
          end
          tokens << token

        # Normalize number literals
        elsif s.scan(/0x\h+([uU][lL]{0,2}|([eE][-+]\d*)?[fFlL]*)/)
          tokens << "~~HEXLITERAL"
        elsif s.scan(/\d(\d|\.)*([uU][lL]{0,2}|([eE][-+]\d*)?[fFlL]*)/)
          tokens << "~~NUMLITERAL"

        # SGML style brackets
        elsif token = s.scan(/<[^\s<>][^<>]*>/)
          extract_sgml_tokens(token).each { |t| tokens << t }

        # Common programming punctuation
        elsif token = s.scan(/;|\{|\}|\(|\)|\[|\]/)
          tokens << token

        # Common operators
        elsif token = s.scan(/[+\-*\/^%&|<>=]+/)
          tokens << token

        # Regular token
        elsif token = s.scan(/[\w\.@#\/\*]+/)
          tokens << token

        else
          s.getch
        end
      end

      tokens
    end

    # Internal: Extract normalized shebang command token.
    #
    # Examples
    #
    #   extract_shebang("#!/usr/bin/ruby")
    #   # => "ruby"
    #
    #   extract_shebang("#!/usr/bin/env node")
    #   # => "node"
    #
    #   extract_shebang("#!/usr/bin/env A=B foo=bar awk -f")
    #   # => "awk"
    #
    # Returns String token or nil it couldn't be parsed.
    def extract_shebang(data)
      s = StringScanner.new(data)

      if path = s.scan(/^#!\s*\S+/)
        script = path.split('/').last
        if script == 'env'
          s.scan(/\s+/)
          s.scan(/.*=[^\s]+\s+/)
          script = s.scan(/\S+/)
        end
        script = script[/[^\d]+/, 0] if script
        return script
      end

      nil
    end

    # Internal: Extract tokens from inside SGML tag.
    #
    # data - SGML tag String.
    #
    # Examples
    #
    #   extract_sgml_tokens("<a href='' class=foo>")
    #   # => ["<a>", "href="]
    #
    # Returns Array of token Strings.
    def extract_sgml_tokens(data)
      s = StringScanner.new(data)

      tokens = []

      until s.eos?
        # Emit start token
        if token = s.scan(/<\/?[^\s>]+/)
          tokens << "#{token}>"

        # Emit attributes with trailing =
        elsif token = s.scan(/\w+=/)
          tokens << token

          # Then skip over attribute value
          if s.scan(/"/)
            s.skip_until(/[^\\]"/)
          elsif s.scan(/'/)
            s.skip_until(/[^\\]'/)
          else
            s.skip_until(/\w+/)
          end

        # Emit lone attributes
        elsif token = s.scan(/\w+/)
          tokens << token

        # Stop at the end of the tag
        elsif s.scan(/>/)
          s.terminate

        else
          s.getch
        end
      end

      tokens
    end
  end
end
