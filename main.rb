#!/usr/bin/ruby
require './lambda.tab.rb'
require  './lexer.rb'

def expand(node)
  case node
  when Abst
    varlist = node[0]
    raise unless varlist.is_a? VList
    case varlist.size
    when 0
      raise 'varlist empty'
    when 1
      node
    else
      copy = node.dup
      copy[0] = copy[0].dup
      vname = copy[0].shift
      Abst.new.replace [VList.new.replace([vname]), expand(copy)]
    end
  when String
    node
  else
    node.class.new.replace node.map{|x| expand(x)} 
  end
end

def read_eval_print_loop
  while true
    print "REPL> "
    line = gets
    break if line == nil
    lexer = Lexer.new(line)
    cp =  LambdaParser.new(lexer)
    root = cp.parse
    p root
puts "カリー化します:"
    p expand(root)
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
