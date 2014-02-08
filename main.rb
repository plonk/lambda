#!/usr/bin/ruby
# -*- coding: utf-8 -*-
require './lambda.tab.rb'
require  './lexer.rb'
require 'readline'

LAMBDA = "\u03bb"

def title
  puts "#{LAMBDA}の代わりに \\ を使います。"
  # puts "C(...) で展開します。"
end

def read_eval_print_loop
  while true
    line = Readline.readline "REPL> ", true
    break if line == nil
    line += "\n"

    lexer = Lexer.new(line)
    cp =  LambdaParser.new(lexer)

    root = cp.parse
    puts root.expand.show
    puts
  end
end

if $*.empty?
  title
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
