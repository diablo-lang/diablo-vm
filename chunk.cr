alias DiabloValue = Float64

enum Op
    Constant
    Add
    Subtract
    Multiply
    Divide
    Negate
    Return
end

class Chunk
    getter code = [] of Op | DiabloValue
    getter constants = [] of DiabloValue
    @lines = [] of Int32

    def write(op, line)
        @code.push(op)
        @lines.push(line)
    end

    def add_constant(value)
        @constants.push(value)
        return @constants.size() - 1
    end

    def disassemble(name)
        puts("== #{name} ==")

        @code.each_with_index do |instruction, offset|
            if instruction.is_a?(Op)
                disassemble_instruction(offset)
            end
        end
    end

    def disassemble_instruction(offset)
        print("%04d " % offset)
        if offset > 0 && @lines[offset] == @lines[offset - 1]
            print("   | ")
        else
            print("%4d " % @lines[offset])
        end
        instruction = @code[offset]
        case instruction
        when Op::Constant
            idx = @code[offset + 1].as(Float64).to_i
            puts("%-16s %4d '#{@constants[idx]}'" % ["OP_CONSTANT", idx])
        when Op::Add
            puts("OP_ADD")
        when Op::Subtract
            puts("OP_SUBTRACT")
        when Op::Multiply
            puts("OP_MULTIPLY")
        when Op::Divide
            puts("OP_DIVIDE")
        when Op::Negate
            puts("OP_NEGATE")
        when Op::Return
            puts("OP_RETURN")
        else
            puts("Unknown opcode #{instruction}")
        end
    end
end