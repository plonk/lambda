class LambdaParser

rule

target          : expr
                    {
                        result = val[0]
                    }

term            : VAR
                    {
                        result = Var.new(val[0])
                    }
                | '(' expr ')'
                    {
                        result = val[1]
                    }
                | '\\' var_list '.' expr
                    {
                        body = val[3]
                        val[1].reverse_each do |param|
                            body = Abst.new(param, body)
                        end
                        result = body
                    }
                | term '[' VAR '/' VAR ']'
                    {
                        result = Subst.new(val[0], val[4], val[2])
                    }
                | term '[' VAR ':=' expr ']'
                    {
                        result = TermSubst.new(val[0], val[2], val[4])
                    }


var_list        : VAR
                    {
                        result = [val[0]]
                    }
                | var_list VAR
                    {
                        result = val[0] + [val[1]]
                    }

expr            : term
                    {
                        result = val[0]
                    }
                | expr term
                    {
                        result = Apply.new(val[0], val[1])
                    }

end

---- header

require './util.rb'

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
end

class Var < Node
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def show
    @name
  end

  def free_variables(bound)
    bound.include?(@name) ? [] : [@name]
  end
end

class Apply < Node
  attr_reader :applicand, :argument

  def initialize(applicand, argument)
    @applicand = applicand
    @argument = argument
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
end

class Abst < Node
  attr_reader :param, :body

  def initialize(param, body)
    @param = param
    @body = body
  end

  def show
    "(\\#{@param}.#{@body.show})"
  end

  def free_variables(bound)
    @body.free_variables(bound + [@param])
  end

  def each(&block)
    @body.each &block
    yield(self)
  end
end

class Subst < Node
  attr_reader :lambda, :from, :to

  def initialize(lamda, from, to)
    raise TypeError unless lamda.is_type? Node
    raise TypeError unless from.is_type? String
    raise TypeError unless to.is_type? String

    @lambda = lamda
    @from = from
    @to = to
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
      if lamda.params.include? @from
        lamda
      else
        Abst.new(lamda.params, substitute(lamda.body))
      end
    else
      lamda # ?
    end
  end

  def show
    substitute(@lambda).show
  end

  def free_variables(bound)
    @lambda.free_variables(bound)
  end

  def each(&block)
    @lambda.each &block
    yield(self)
  end
end

class TermSubst < Node
  attr_reader :lambda, :from, :to

  def initialize(lamda, from, to)
    @lambda = lamda
    @from = from
    @to = to
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
      if lamda.params.include? @from
        lamda
      else
        unused = (('a'..'z').to_a - to.free_variables([]))[0]
        # OMG
        Abst.new(
          [unused],
          TermSubst.new(
            Subst.new(lamda.body, lamda.params[0], unused).substitute,
            @from,
            @to).substitute)
      end
    else
      lamda # ?
    end
  end

  def show
    substitute(@lambda).show
  end

  def free_variables(bound)
    @lambda.free_variables(bound)
  end

  def each(&block)
    @lambda.each &block
    yield(self)
  end
end
  
---- inner

def initialize(lexer)
  @lexer = lexer
  super()
end

def parse
  do_parse
end

def next_token
  @lexer.next_token
end
