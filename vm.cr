enum Interpret
    Ok
    CompileError
    RuntimeError
end

DEBUG_TRACING=false

class VM
    @chunk = Chunk.new()
    @ip = 0
    @stack = [] of DiabloValue
    @globals = Hash(String, DiabloValue).new()

    def interpret(source)
        compiler = Compiler.new()
        if !compiler.compile(source)
            puts compiler.current_chunk.inspect
            return DiabloError::InterpretCompileError
        end

        @chunk = compiler.current_chunk
        @ip = 0

        result = run()

        return result
    end

    def run()
        while true
            if DEBUG_TRACING
                print("          ")
                @stack.each do |value|
                    print("[#{value.nil? ? "nil" : value}]")
                end
                puts("")
                @chunk.disassemble_instruction(@ip)
            end
            instruction = read_byte()
            case instruction
            when Op::Constant
                constant = read_constant()
                @stack.push(constant)
            when Op::Nil
                @stack.push(nil)
            when Op::True
                @stack.push(true)
            when Op::False
                @stack.push(false)
            when Op::Pop
                @stack.pop()
            when Op::GetLocal
                idx = read_byte().as(Float64).to_i
                @stack.push(@stack[idx])
            when Op::GetGlobal
                name = read_constant().as(String)
                unless @globals.has_key?(name)
                    runtime_error("Undefined variable '#{name}'.")
                    return DiabloError::InterpretRuntimeError
                end
                value = @globals[name]
                @stack.push(value)
            when Op::DefineGlobal
                name = read_constant().as(String)
                @globals[name] = peek(0)
                @stack.pop()
            when Op::Equal
                b = @stack.pop()
                a = @stack.pop()
                @stack.push(values_equal(a, b))
            when Op::Greater
                binary_op(">")
            when Op::Less
                binary_op("<")
            when Op::Add
                if peek(0).is_a?(String) && peek(1).is_a?(String)
                    b = @stack.pop().as(String)
                    a = @stack.pop().as(String)
                    @stack.push(a + b)
                elsif peek(0).is_a?(Float64) && peek(1).is_a?(Float64)
                    b = @stack.pop().as(Float64)
                    a = @stack.pop().as(Float64)
                    @stack.push(a + b)
                else
                    runtime_error("Operands must be two numbers or two strings.")
                    return DiabloError::InterpretRuntimeError
                end
            when Op::Subtract
                binary_op("-")
            when Op::Multiply
                binary_op("*")
            when Op::Divide
                binary_op("/")
            when Op::Not
                @stack.push(is_falsey(@stack.pop()))
            when Op::Negate
                if !peek(0).is_a?(Float64)
                    runtime_error("Operand must be a number.")
                    return DiabloError::InterpretRuntimeError
                end
                @stack.push(-@stack.pop().as(Float64))
            when Op::Print
                puts(@stack.pop())
            when Op::Jump
                offset = read_byte().as(Float64).to_i
                @ip += offset
            when Op::JumpIfFalse
                offset = read_byte().as(Float64).to_i
                if is_falsey(peek(0))
                    @ip += offset
                end
            when Op::Return
                return Interpret::Ok
            end
        end
    end

    def values_equal(a, b)
        return true if a.nil? && b.nil?
        return false if a.nil?
    
        return a == b
    end

    def peek(distance)
        return @stack[-1 - distance]
    end

    def runtime_error(error)
        puts(error)
    end

    def binary_op(operator)
        if !peek(0).is_a?(Float64) || !peek(1).is_a?(Float64)
            runtime_error("Operands must be numbers.")
            return DiabloError::InterpretRuntimeError
        end
        b = @stack.pop().as(Float64)
        a = @stack.pop().as(Float64)
        case operator
        when "-"
            @stack.push(a - b)
        when "*"
            @stack.push(a * b)
        when "/"
            @stack.push(a / b)
        when ">"
            @stack.push(a > b)
        when "<"
            @stack.push(a < b)
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

    def is_falsey(value)
        return value.nil? || (value.is_a?(Bool) && !value)
    end
end