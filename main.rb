#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# vim: set shiftwidth=2:tabstop=2:
# -*- coding: utf-8 -*-
require_relative 'lambda.tab.rb'
require_relative 'michaelson.tab.rb'
require_relative  'lexer.rb'
require 'readline'
require 'English'

class Program
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
    parser = @parser_class.new(lexer)
    parser.parse
  end

  def beta_reduce(lamda, redex)
    redex_to_subst = lamda.tree_map {|node|
      if node.show == redex.show then 
        apply = node.as Apply
        abst = apply.applicand.as Abst

        TermSubst.new(abst.body, abst.param, apply.argument)
      else
        node
      end
    }
    substitute(redex_to_subst)
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
    when "reduce"
      exp = substitute(parse(arg))
      history = [exp.show]
      
      until (redexes = exp.select{|x| x.redex?}).empty?
        if redexes.size>=1
          exp = beta_reduce(exp, redexes[0])
        else
          puts "ベータredex:"
          redexes.map(&:show).each_with_index { |s, i|
            puts "\t#{i+1}) #{s}"
          }

          ans = Readline.readline "\nどれ？ ", false
          if ans.to_i <= 0
            return
          end
          
          idx = ans.to_i - 1
          exp = beta_reduce(exp, redexes[idx])
        end
        puts exp.show
        if history.include? exp.show
          puts "... ad infinitum ..."
          break
        end
        history << exp.show
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
      begin
        line = Readline.readline "\nREPL> ", true
      rescue Interrupt
        STDERR.print "^C"
        retry
      end
      break if line == nil

      begin
        if line =~ /^:/
          begin
            repl_command(line)
          rescue Interrupt
            STDERR.puts "Interrupted"
          end
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
      puts substitute(root).show

      redexes = root.select{|x| x.redex?}
      unless redexes.empty?
        puts "\nベータredex:"
        puts redexes.map(&:show).map{|s| "\t"+s}
      end
    end
  end

  def run
    require 'optparse'

    @parser_class = LambdaParser

    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.on("-m", "--michaelson") do |bool|
        if bool
          @parser_class = MichaelsonParser
          puts '別のパーザを使います。'
        end
      end
    end

    begin
      optparse.parse!
    rescue OptionParser::InvalidOption
      puts optparse.help
      return 1
    end

    title
    read_eval_print_loop
    return 0
  end
end

if $0 == __FILE__
  prog = Program.new
  exit prog.run
end
