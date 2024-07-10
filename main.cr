require "./chunk"

class Diablo
  def main()
    chunk = Chunk.new()

    constant = chunk.add_constant(1.2)
    chunk.write(Op::Constant, 123)
    chunk.write(constant, 123)
    chunk.write(Op::Return, 123)
  
    chunk.disassemble("test chunk")
  end
end

dbl = Diablo.new
dbl.main()
