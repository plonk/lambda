#!/usr/bin/ruby
# vim: set shiftwidth=2:tabstop=2:
# -*- coding: utf-8 -*-
require './lambda.tab.rb'
require  './lexer.rb'
require 'readline'

LAMBDA = "\u03bb"

def title
  puts "#{LAMBDA}の代わりに \\ を使います。"
  # puts "C(...) で展開します。"
end

def fv(node)
  node.free_variables([])
end

def parse(line)
  lexer = Lexer.new(line)
  parser = LambdaParser.new(lexer)
  parser.parse
end

def repl_command(line)
  line =~ /^:(\w+)\s*(.+)?$/
  cmd = $1
  arg = $2

  case cmd
  when /^fv$/
    if arg
      fvars = fv(parse(arg)) 
      puts '{' + fvars.join(',') + '}'
    end
  else
    STDERR.puts "unknown REPL command #{cmd}"
  end
end

def substitute(root)
  root.tree_map{ |node| 
    if node.is_a? Subst or node.is_a? TermSubst
      node.substitute
    else
      node
    end
  }
end

def read_eval_print_loop
  loop do
    line = Readline.readline "\nREPL> ", true
    break if line == nil

    begin
      if line =~ /^:/
        repl_command(line)
        next
      end

      root = parse(line)
    rescue RuntimeError => e
      STDERR.puts e.message
      next
    rescue Racc::ParseError
      STDERR.puts "parse error"
      next
    end

    puts
    puts root.show
    puts substitute(root).show

    redexes = root.select{|x| x.redex?}
    unless redexes.empty?
      puts "\nベータredex:"
      puts redexes.map(&:show).map{|s| "\t"+s}
    end
  end
end

def main
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
end

if $0 == __FILE__
  main
end
