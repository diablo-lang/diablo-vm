alias DiabloValue = Float64 | Bool | Nil | String

enum DiabloValueType
    Bool
    Nil
    Number
end

enum Op
    Constant
    Nil
    True
    False
    Pop
    GetLocal
    GetGlobal
    DefineGlobal
    Equal
    Greater
    Less
    Add
    Subtract
    Multiply
    Divide
    Not
    Negate
    Print
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
        when Op::Nil
            puts("OP_NIL")
        when Op::True
            puts("OP_TRUE")
        when Op::False
            puts("OP_FALSE")
        when Op::Pop
            puts("OP_POP")
        when Op::GetLocal
            idx = @code[offset + 1].as(Float64).to_i
            puts("%-16s %4d '#{@constants[idx]}'" % ["OP_GET_LOCAL", idx])   
        when Op::GetGlobal
            idx = @code[offset + 1].as(Float64).to_i
            puts("%-16s %4d '#{@constants[idx]}'" % ["OP_GET_GLOBAL", idx])
        when Op::DefineGlobal
            idx = @code[offset + 1].as(Float64).to_i
            puts("%-16s %4d '#{@constants[idx]}'" % ["OP_DEFINE_GLOBAL", idx])
        when Op::Equal
            puts("OP_EQUAL")
        when Op::Greater
            puts("OP_GREATER")
        when Op::Less
            puts("OP_LESS")
        when Op::Add
            puts("OP_ADD")
        when Op::Subtract
            puts("OP_SUBTRACT")
        when Op::Multiply
            puts("OP_MULTIPLY")
        when Op::Divide
            puts("OP_DIVIDE")
        when Op::Not
            puts("OP_NOT")
        when Op::Negate
            puts("OP_NEGATE")
        when Op::Print
            puts("OP_PRINT")
        when Op::Return
            puts("OP_RETURN")
        else
            puts("Unknown opcode #{instruction}")
        end
    end
end