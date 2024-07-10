alias DiabloValue = Float64

enum Op
    Constant
    Return
end

class Chunk
    @code = [] of Op | DiabloValue
    @lines = [] of Int32
    @constants = [] of DiabloValue

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
            constant = @code[offset + 1]
            puts("%-16s %4d '#{@constants[offset]}'" % ["OP_CONSTANT", constant])
        when Op::Return
            puts("OP_RETURN")
        else
            puts("Unknown opcode #{instruction}")
        end
    end
end