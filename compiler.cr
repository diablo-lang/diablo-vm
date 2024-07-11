class Compiler
    def compile(source)
        scanner = Scanner.new(source)
        line = -1
        loop do
            token = scanner.scan_token()
            if token.line != line
                print("%4d " % token.line)
                line = token.line
            else
                print("   | ")
            end
            puts("%s '%s'" % [token.type, token.text])

            break if token.type == TokenType::Eof
        end
    end
end
