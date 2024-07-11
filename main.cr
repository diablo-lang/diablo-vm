require "./chunk"
require "./vm"
require "./error"
require "./scanner"
require "./compiler"

class Diablo
  @vm = VM.new()
  def repl()
    loop do
      print("> ")
      line = gets
      break if line.nil?
      @vm.interpret(line)
    end
  end

  def run_file(file_path)
    bytes = File.open(file_path) do |file|
      file.gets_to_end
    end
    result = @vm.interpret(bytes)
    
    exit(65) if DiabloError::InterpretCompileError
    exit(70) if DiabloError::InterpretRuntimeError
  end

  def main()
    if ARGV.size == 0
      repl()
    elsif ARGV.size == 1
      run_file(ARGV[0])
    else
      puts "Usage: diablo <script>"
      exit(64)
    end
  end
end

dbl = Diablo.new
dbl.main()
