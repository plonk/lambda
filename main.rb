#!/usr/bin/ruby
require './lambda.tab.rb'
require  './lexer.rb'

def read_eval_print_loop
  while true
    print "REPL> "
    line = gets
    break if line == nil
    lexer = Lexer.new(line)
    cp =  LambdaParser.new(lexer)
    root = cp.parse
    puts root.show
    puts "カリー化します:"
    puts root.expand.show
    puts
  end
end

if $*.empty?
  read_eval_print_loop
else
  vtable = {}
  $*.each do |file|
    f = File.new(file)
    code = f.read
    lexer = Lexer.new(code)
    parser = LambdaParser.new(lexer, vtable)
    begin
      root = parser.parse
      root.evaluate(vtable)
    rescue Racc::ParseError
      puts "parse error while executing #{file}"
      exit 1
    end
  end
end
