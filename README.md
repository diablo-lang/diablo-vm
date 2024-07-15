# diablo-vm

Diablo Bytecode VM Interpreter

## About

**diablo-vm** is an interpreter with a one-pass bytecode virtual machine compiler created in Crystal. It is based on the C implementation of the Lox Programming Language from the book [Crafting Interpreters](https://craftinginterpreters.com/). It makes use of Crystal's intrinsic garbage collector to automate memory mangement. Please note, this is a purely experimental repository for educational and research purposes. 

## Usage

Execute commands directly via the Diablo interpreter.

```sh
crystal main.cr
```

Run a Diablo (.dbl) source file.

```sh
crystal main.cr source.dbl
```

## License

diablo-vm is available under the [Apache License 2.0](https://spdx.org/licenses/Apache-2.0.html).


