enum Interpret
    Ok
    CompileError
    RuntimeError
end

DEBUG_TRACING=true

class VM
    @chunk = Chunk.new()
    @ip = 0
    @stack = [] of DiabloValue

    def interpret(chunk : Chunk)
        @chunk = chunk
        return run()
    end

    def run()
        while true
            if DEBUG_TRACING
                print("          ")
                @stack.each do |value|
                    print("[#{value}]")
                end
                puts("")
                @chunk.disassemble_instruction(@ip)
            end
            instruction = read_byte()
            case instruction
            when Op::Constant
                constant = read_constant()
                @stack.push(constant)
            when Op::Add
                binary_op("+")
            when Op::Subtract
                binary_op("-")
            when Op::Multiply
                binary_op("*")
            when Op::Divide
                binary_op("/")
            when Op::Negate
                @stack.push(-@stack.pop())
            when Op::Return
                puts(@stack.pop())
                return Interpret::Ok
            end
        end
    end

    def binary_op(operator)
        b = @stack.pop()
        a = @stack.pop()
        case operator
        when "+"
            @stack.push(a + b)
        when "-"
            @stack.push(a - b)
        when "*"
            @stack.push(a * b)
        when "/"
            @stack.push(a / b)
        end
    end

    def read_byte()
        byte = @chunk.code[@ip]
        @ip += 1
        return byte
    end

    def read_constant()
        idx = read_byte().as(Float64).to_i
        return @chunk.constants[idx]
    end
end