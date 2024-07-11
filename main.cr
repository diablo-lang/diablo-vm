require "./chunk"
require "./vm"

class Diablo
  def main()
    vm = VM.new()
    chunk = Chunk.new()

    constant = chunk.add_constant(1.2)
    chunk.write(Op::Constant, 123)
    chunk.write(constant, 123)

    constant = chunk.add_constant(3.4)
    chunk.write(Op::Constant, 123)
    chunk.write(constant, 123)

    chunk.write(Op::Add, 123)

    constant = chunk.add_constant(5.6)
    chunk.write(Op::Constant, 123)
    chunk.write(constant, 123)

    chunk.write(Op::Divide, 123)
    chunk.write(Op::Negate, 123)
    chunk.write(Op::Return, 123)
  
    vm.interpret(chunk)
  end
end

dbl = Diablo.new
dbl.main()
