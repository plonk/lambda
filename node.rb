# -*- coding: utf-8 -*-
require_relative 'util.rb'

class Node
  include Enumerable

  def show
    raise 'unimplemented'
  end

  def free_variables(bound)
    raise 'unimplemented'
  end

  def show
    raise 'unimplemented'
  end

  # 深さ優先探索。
  # 子ノードのないノード向けのデフォルト実装。
  def each
    yield(self)
  end

  def redex?
    false
  end

  def tree_map
    raise 'unimplemented'
  end
end

class Var < Node
  attr_reader :name

  def initialize(name)
    @name = name.as String
  end

  def show
    @name
  end

  def free_variables(bound)
    bound.include?(@name) ? [] : [@name]
  end

  def tree_map
    yield(self)
  end
end

class Apply < Node
  attr_reader :applicand, :argument

  def initialize(applicand, argument)
    @applicand = applicand.as Node
    @argument = argument.as Node
  end

  def show
    a = @applicand.show
    b = @argument.show
    b = "(#{b})" if Apply === @argument
    "#{a} #{b}"
  end

  def free_variables(bound)
    @applicand.free_variables(bound) + @argument.free_variables(bound)
  end

  def each(&block)
    @applicand.each &block
    @argument.each &block
    yield(self)
  end

  def redex?
    @applicand.is_a? Abst
  end

  def tree_map(&f)
    f.call(Apply.new(@applicand.tree_map(&f), @argument.tree_map(&f)))
  end
end

class Abst < Node
  attr_reader :param, :body

  def initialize(param, body)
    @param = param.as String
    @body = body.as Node
  end

  def show(params = "")
    params = "#{params} #{@param}"
    if @body.is_a? Abst
      @body.show(params)
    else
      params = params.sub(/^ /, '')
      "(\\#{params}.#{@body.show})"
    end
  end

  def free_variables(bound)
    @body.free_variables(bound + [@param])
  end

  def each(&block)
    @body.each &block
    yield(self)
  end

  def tree_map(&f)
    f.call(Abst.new(@param, @body.tree_map(&f)))
  end
end

class Subst < Node
  attr_reader :lambda, :from, :to

  def initialize(lamda, from, to)
    @lambda = lamda.as Node
    @from = from.as String
    @to = to.as String
  end

  def substitute(lamda = @lambda)
    if lamda.is_a? Var
      if lamda.name == @from
        Var.new(@to)
      else
        lamda
      end
    elsif lamda.is_a? Apply
      Apply.new(substitute(lamda.applicand), substitute(lamda.argument))
    elsif lamda.is_a? Abst
      if lamda.param == @from
        lamda
      else
        Abst.new(lamda.param, substitute(lamda.body))
      end
    else
      lamda # ?
    end
  end

  def show
    # substitute(@lambda).show
    "(#{@lambda.show})[#{@to}/#{@from}]"
  end

  def free_variables(bound)
    @lambda.free_variables(bound)
  end

  def each(&block)
    @lambda.each &block
    yield(self)
  end

  def tree_map(&f)
    f.call(Subst.new(@lambda.tree_map(&f), @from, @to))
  end
end

class TermSubst < Node
  attr_reader :lambda, :from, :to

  def initialize(lamda, from, to)
    @lambda = lamda.as Node

    @from = from.as String
    @to = to.as Node
  end

  def get_new_var(oldvar, free_variables)
    # ('a'..'z').to_a - free_variables[0]
    oldvar + "'"
  end

  def substitute(lamda = @lambda)
    if lamda.is_a? Var
      if lamda.name == @from
        @to
      else
        lamda
      end
    elsif lamda.is_a? Apply
      Apply.new(substitute(lamda.applicand), substitute(lamda.argument))
    elsif lamda.is_a? Abst
      if lamda.param == @from
        lamda
      else
        fvars = to.free_variables([])
        if fvars.include? lamda.param
          unused = get_new_var(lamda.param, fvars)
        else
          unused = lamda.param
        end
        # OMG
        Abst.new(
          unused,
          TermSubst.new(
            Subst.new(lamda.body, lamda.param, unused).substitute,
            @from,
            @to).substitute)
      end
    else
      lamda # ?
    end
  end

  def show
    # substitute(@lambda).show
    "(#{@lambda.show})[#{@from}:=#{@to.show}]"
  end

  def free_variables(bound)
    @lambda.free_variables(bound)
  end

  def each(&block)
    @lambda.each &block
    yield(self)
  end

  def tree_map(&f)
    f.call(TermSubst.new(@lambda.tree_map(&f), @from, @to.tree_map(&f)))
  end
end
