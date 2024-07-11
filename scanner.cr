enum TokenType
    LeftParen
    RightParen
    LeftBrace
    RightBrace
    Comma
    Dot
    Minus
    Plus
    Semicolon
    Slash
    Star
    Bang
    BangEqual
    Equal
    EqualEqual
    Greater
    GreaterEqual
    Less
    LessEqual
    Identifier
    String
    Number
    And
    Else
    False
    Fn
    For
    If
    Nil
    Or
    Print
    Return
    True
    Let
    While
    Error
    Eof
end

class Scanner
    @start = 0
    @current = 0
    @line = 1

    def initialize(@source : String)
        @keywords = {
        "and" => TokenType::And,
        "else" => TokenType::Else,
        "false" => TokenType::False,
        "fn" => TokenType::Fn,
        "for" => TokenType::For,
        "if" => TokenType::If,
        "let" => TokenType::Let,
        "nil" => TokenType::Nil,
        "or" => TokenType::Or,
        "print" => TokenType::Print,
        "return" => TokenType::Return,
        "true" => TokenType::True,
        "while" => TokenType::While
        }
    end

    def advance()
        c = @source[@current]
        @current += 1
        return c
    end

    def match(expected)
        return false if is_at_end()
        return false if @source[@current] != expected

        @current += 1
        return true
    end

    def peek()
        return '\0' if is_at_end()
        return @source[@current]
    end

    def peek_next()
        return '\0' if @current + 1 >= @source.size
        return @source[@current + 1]
    end

    def is_at_end()
        return @current >= @source.size
    end

    def make_token(type)
        text = @source[@start...@current]
        token = Token.new(type, text, @line)
        return token
    end

    def error_token(message)
        token = Token.new(TokenType::Error, message, @line)
        return token
    end

    def skip_whitespace()
        loop do
            c = peek()
            case c
            when ' ', '\r', '\t'
                advance()
            when '#'
                while peek() != '\n' && !is_at_end()
                    advance()
                end
            when '\n'
                @line += 1
                advance()
            else
                return
            end
        end
    end

    def scan_token()
        skip_whitespace()
        @start = @current
        if is_at_end()
            return make_token(TokenType::Eof)
        end

        c = advance()
        case c
        when '('
        return make_token(TokenType::LeftParen)
        when ')'
        return make_token(TokenType::RightParen)
        when '{'
        return make_token(TokenType::LeftBrace)
        when '}'
        return make_token(TokenType::RightBrace)
        when ','
        return make_token(TokenType::Comma)
        when '.'
        return make_token(TokenType::Dot)
        when '-'
        return make_token(TokenType::Minus)
        when '+'
        return make_token(TokenType::Plus)
        when ';'
        return make_token(TokenType::Semicolon)
        when '*'
        return make_token(TokenType::Star)
        when '/'
        return make_token(TokenType::Slash)
        when '!'
        return make_token(match('=') ? TokenType::BangEqual : TokenType::Bang)
        when '='
        return make_token(match('=') ? TokenType::EqualEqual : TokenType::Equal)
        when '<'
        return make_token(match('=') ? TokenType::LessEqual : TokenType::Less)
        when '>'
        return make_token(match('=') ? TokenType::GreaterEqual : TokenType::Greater)
        when '"'
            return string()
        else
            if c.number?
                return number()
            elsif c.letter?
                return identifier()
            end
        end

        return error_token("Unexpected character.")
    end

    def string()
        while peek() != '"' && !is_at_end()
            @line += 1 if peek() == '\n'
            advance()
        end

        if is_at_end()
            return error_token("Unterminated string.")
        end

        advance()

        value = @source[@start+1...@current-1]
        return make_token(TokenType::String)
    end

    def number()
        while peek().number?
        advance()
        end

        if peek() == '.' && peek_next().number?
        advance()

        while peek().number?
            advance()
        end
        end

        return make_token(TokenType::Number)
    end

    def identifier()
        while peek().alphanumeric?
        advance()
        end

        text = @source[@start...@current]
        type = @keywords.fetch(text, nil)
        if type.nil?
        type = TokenType::Identifier
        end

        return make_token(type)
    end
end

class Token
    property type
    property text
    property line
    def initialize(@type : TokenType, @text : String, @line : Int32)
    end
end

