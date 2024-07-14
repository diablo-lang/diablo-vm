enum Precedence
    None
    Assignment
    Or
    And
    Equality
    Comparison
    Term
    Factor
    Unary
    Call
    Primary
end

class ParseRule
    property prefix : Proc(Nil)?
    property infix : Proc(Nil)?
    property precedence : Precedence

    def initialize(@precedence, @prefix=nil, @infix=nil)
    end
end

alias ParseFn = ->

class Local
    property depth : Int32
    getter name : String

    def initialize(@name : String, @depth : Int32)
    end
end

class Compiler
    @parser : Parser
    @compiling_chunk : Chunk = Chunk.new()
    @scanner = Scanner.new("")

    @rules = Hash(TokenType, ParseRule).new()
    @locals = [] of Local
    @scope_depth = 0

    def initialize()
        @parser = Parser.new(Token.new(TokenType::Error, "", -1), Token.new(TokenType::Eof, "", -1))

        @rules = {
            TokenType::LeftParen    => ParseRule.new(Precedence::None, -> { grouping }),
            TokenType::RightParen   => ParseRule.new(Precedence::None),
            TokenType::LeftBrace    => ParseRule.new(Precedence::None),
            TokenType::RightBrace   => ParseRule.new(Precedence::None),
            TokenType::Comma        => ParseRule.new(Precedence::None),
            TokenType::Dot          => ParseRule.new(Precedence::None),
            TokenType::Minus        => ParseRule.new(Precedence::Term, -> { unary }, -> { binary }),
            TokenType::Plus         => ParseRule.new(Precedence::Term, nil, -> { binary }),
            TokenType::Semicolon    => ParseRule.new(Precedence::None),
            TokenType::Slash        => ParseRule.new(Precedence::Factor, nil, -> { binary }),
            TokenType::Star         => ParseRule.new(Precedence::Factor, nil, -> { binary }),
            TokenType::Bang         => ParseRule.new(Precedence::None, -> { unary }),
            TokenType::BangEqual    => ParseRule.new(Precedence::Equality, nil, -> { binary }),
            TokenType::Equal        => ParseRule.new(Precedence::None),
            TokenType::EqualEqual   => ParseRule.new(Precedence::Equality, nil, -> { binary }),
            TokenType::Greater      => ParseRule.new(Precedence::Comparison, nil, -> { binary }),
            TokenType::GreaterEqual => ParseRule.new(Precedence::Comparison, nil, -> { binary }),
            TokenType::Less         => ParseRule.new(Precedence::Comparison, nil, -> { binary }),
            TokenType::LessEqual    => ParseRule.new(Precedence::Comparison, nil, -> { binary }),
            TokenType::Identifier   => ParseRule.new(Precedence::None, -> { variable }),
            TokenType::String       => ParseRule.new(Precedence::None, -> { string }),
            TokenType::Number       => ParseRule.new(Precedence::None, -> { number }),
            TokenType::And          => ParseRule.new(Precedence::None),
            TokenType::Else         => ParseRule.new(Precedence::None),
            TokenType::False        => ParseRule.new(Precedence::None, -> { literal }),
            TokenType::For          => ParseRule.new(Precedence::None),
            TokenType::Fn           => ParseRule.new(Precedence::None),
            TokenType::If           => ParseRule.new(Precedence::None),
            TokenType::Nil          => ParseRule.new(Precedence::None, -> { literal }),
            TokenType::Or           => ParseRule.new(Precedence::None),
            TokenType::Print        => ParseRule.new(Precedence::None),
            TokenType::Return       => ParseRule.new(Precedence::None),
            TokenType::True         => ParseRule.new(Precedence::None, -> { literal }),
            TokenType::Let          => ParseRule.new(Precedence::None),
            TokenType::While        => ParseRule.new(Precedence::None),
            TokenType::Error        => ParseRule.new(Precedence::None),
            TokenType::Eof          => ParseRule.new(Precedence::None),
          }
    end

    def current_chunk()
        return @compiling_chunk
    end

    def compile(source)
        @scanner = Scanner.new(source)
        @compiling_chunk = Chunk.new()
        advance()
        while !match(TokenType::Eof)
            declaration()
        end
        end_compiler()
        return !@parser.had_error
    end

    def declaration()
        if match(TokenType::Let)
            var_declaration()
        else
            statement()
        end
        if @parser.panic_mode
            synchronize()
        end
    end

    def var_declaration()
        global = parse_variable("Expect variable name.")

        if match(TokenType::Equal)
            expression()
        else
            emit_byte(Op::Nil)
        end

        consume(TokenType::Semicolon, "Expect ';' after variable declaration.")

        define_variable(global)
    end

    def variable()
        named_variable(@parser.previous)
    end
    
    def named_variable(token)
        arg = resolve_local(token.text)
        if arg != -1
            emit_bytes(Op::GetLocal, arg)
        else
            arg = identifier_constant(token)
            emit_bytes(Op::GetGlobal, arg)
        end
    end

    def resolve_local(name)
        @locals.reverse_each.with_index do |local, reverse_index|
            # Iterator returns index from 0, 1, 2, ... regardless of reversal
            index = @locals.size() - 1 - reverse_index

            if name == local.name
                if local.depth == -1
                    error("Can't read local variable in its own initializer.")
                end
                return index
            end
        end

        return -1
    end

    def parse_variable(error_message)
        consume(TokenType::Identifier, error_message)
        declare_variable()
        return 0 if @scope_depth > 0
        return identifier_constant(@parser.previous)
    end

    def identifier_constant(token)
        return make_constant(token.text)
    end

    def define_variable(global)
        if @scope_depth > 0
            # Mark as initialized
            @locals.last().depth = @scope_depth
            return
        end
        emit_bytes(Op::DefineGlobal, global)
    end

    def declare_variable()
        return if @scope_depth == 0
        name = @parser.previous.text

        @locals.reverse_each.with_index do |local|
            if local.depth != -1 && local.depth < @scope_depth
                break
            end

            if name == local.name
                error("Already a variable with this name in this scope.")
            end
        end

        add_local(name)
    end

    def add_local(name)
        local = Local.new(name, -1)
        @locals.push(local)
    end

    def statement()
        if match(TokenType::Print)
            print_statement()
        elsif match(TokenType::LeftBrace)
            begin_scope()
            block()
            end_scope()
        else
            expression_statement()
        end
    end

    def block()
        while !check(TokenType::RightBrace) && !check(TokenType::Eof)
            declaration()
        end

        consume(TokenType::RightBrace, "Expect '}' after block.")
    end

    def begin_scope()
        @scope_depth += 1
    end

    def end_scope()
        @scope_depth -= 1
        while @locals.size() > 0 && @locals.last().depth > @scope_depth
            @locals.pop()
            emit_byte(Op::Pop)
        end
    end

    def expression_statement()
        expression()
        consume(TokenType::Semicolon, "Expect ';' after expression.")
        emit_byte(Op::Pop)
    end

    def synchronize()
        @parser.panic_mode = false

        while @parser.current.type != TokenType::Eof
            return if @parser.previous.type == TokenType::Semicolon
            case @parser.current.type
            when TokenType::Fn, TokenType::Let, TokenType::For,
                TokenType::If, TokenType::While, TokenType::Print,
                TokenType::Return
                return
            else
                # Do nothing
            end

            advance()
        end
    end

    def end_compiler()
        emit_return()
        if DEBUG_TRACING
            unless @parser.had_error
                @compiling_chunk.disassemble("code")
            end
        end
    end

    def expression()
        parse_precedence(Precedence::Assignment)
    end

    def literal()
        case @parser.previous.type
        when TokenType::False
            emit_byte(Op::False)
        when TokenType::Nil
            emit_byte(Op::Nil)
        when TokenType::True
            emit_byte(Op::True)
        else
            return # Unreachable
        end
    end

    def number()
        value = @parser.previous.text.to_f64

        emit_constant(value)
    end

    def string()
        emit_constant(@parser.previous.text[1...@parser.previous.text.size()-1])
    end

    def emit_constant(value)
        emit_bytes(Op::Constant, make_constant(value))
    end

    def make_constant(value)
        constant = current_chunk().add_constant(value)
        if constant > UInt8::MAX
            error("Too many constants in one chunk.")
            return 0
        end

        return constant
    end

    def grouping()
        expression()
        consume(TokenType::RightParen, "Expect ')' after expression.")
    end

    def unary()
        operator_type = @parser.previous.type

        parse_precedence(Precedence::Unary)

        case operator_type
        when TokenType::Bang
            emit_byte(Op::Not)
        when TokenType::Minus
            emit_byte(Op::Negate)
        else
            return
        end
    end

    def parse_precedence(precedence)
        advance()
        prefix_rule = get_rule(@parser.previous.type).prefix
        if prefix_rule.nil?
            error("Expect expression.")
            return
        end

        prefix_rule.not_nil!.call

        while precedence <= get_rule(@parser.current.type).precedence
            advance()
            infix_rule = get_rule(@parser.previous.type).infix
            infix_rule.not_nil!.call
        end
    end

    def get_rule(type)
        return @rules[type]
    end

    def binary()
        operator_type = @parser.previous.type
        rule = get_rule(operator_type)
        next_precedence = Precedence.new(rule.precedence.value + 1)
        parse_precedence(next_precedence)
        case operator_type
        when TokenType::BangEqual
            emit_bytes(Op::Equal, Op::Not)
        when TokenType::EqualEqual
            emit_byte(Op::Equal)
        when TokenType::Greater
            emit_byte(Op::Greater)
        when TokenType::GreaterEqual
            emit_bytes(Op::Less, Op::Not)
        when TokenType::Less
            emit_byte(Op::Less)
        when TokenType::LessEqual
            emit_bytes(Op::Greater, Op::Not)
        when TokenType::Plus
            emit_byte(Op::Add)
        when TokenType::Minus
            emit_byte(Op::Subtract)
        when TokenType::Star
            emit_byte(Op::Multiply)
        when TokenType::Slash
            emit_byte(Op::Divide)
        else
            return # Unreachable
        end
    end

    def advance()
        @parser.previous = @parser.current

        loop do
            @parser.current = @scanner.scan_token()
            break if @parser.current.type != TokenType::Error
            error_at_current(@parser.current.text)
        end
    end

    def consume(type, message)
        if @parser.current.type == type
            advance()
            return
        end
        error_at_current(message)
    end

    def match(type)
        return false if !check(type)
        advance()
        return true
    end

    def check(type)
        return @parser.current.type == type
    end

    def print_statement()
        expression()
        consume(TokenType::Semicolon, "Expect ';' after value.")
        emit_byte(Op::Print)
    end

    def emit_byte(byte)
        current_chunk().write(byte, @parser.previous.line)
    end

    def emit_bytes(byte1, byte2)
        emit_byte(byte1)
        emit_byte(byte2)
    end

    def emit_return()
        emit_byte(Op::Return)
    end

    def error_at_current(message)
        error_at(@parser.current, message)
    end

    def error(message)
        error_at(@parser.previous, message)
    end

    def error_at(token, message)
        return if @parser.panic_mode
        @parser.panic_mode = true
        print("[line #{token.line}] Error")

        if token.type == TokenType::Eof
            print(" at end")
        elsif token.type == TokenType::Error
            # Nothing
        else
            print(" at '#{token.text}'")
        end
        puts(": #{message}")
        @parser.had_error = true
    end
end

class Parser
    property had_error = false
    property panic_mode = false
    property current : Token
    property previous : Token
    def initialize(@current : Token, @previous : Token)
    end
end