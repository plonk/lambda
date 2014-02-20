#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# vim: set shiftwidth=2:tabstop=2:
# -*- coding: utf-8 -*-
require_relative 'lambda.tab.rb'
require_relative 'michaelson.tab.rb'
require_relative 'lexer.rb'
require_relative 'util.rb'
require 'readline'
require 'English'

class Matcher
  def initialize(command_name)
    @command_name = command_name.as String
  end

  def ===(input)
    /\A#{input.as(String)}/ =~ @command_name
  end
end

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
    cmd = $1; arg = $2

    case cmd
    when Matcher.new('fv')
      # 自由変数の表示
      if arg
        fvars = fv(parse(arg)) 
        puts '{' + fvars.join(',') + '}'
      end
    when Matcher.new('reduce')
      # 自動簡約
      exp = substitute(parse(arg))
      history = [exp.show]
      
      until ( redexes = exp.select{|x| x.redex?} ).empty?
        before = exp.show
        redex = redexes[0].show
        puts before.sub(redex) { "\e[32;1m" + redex + "\e[0m" }

        exp = beta_reduce(exp, redexes[0])

        if history.include? exp.show
          puts "... ad infinitum ..."
          return
        end
        history << exp.show
      end
      puts exp.show
    when Matcher.new('ireduce')
      # redex 指定の簡約
      exp = substitute(parse(arg))
      history = [exp.show]
      
      until ( redexes = exp.select{|x| x.redex?} ).empty?
        if redexes.size==1
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
      # 入力を読み込む
      begin
        line = Readline.readline "\nREPL> ", true
      rescue Interrupt
        STDERR.print "^C"
        retry
      end
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
      rescue Interrupt
        STDERR.puts "\nInterrupted"
        next
      end

      # [...] 表記の置き換え後に式をエコーバックする
      puts
      puts substitute(root).show

      # redex があれば表示する
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
