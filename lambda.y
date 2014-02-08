class LambdaParser

rule

target          : expr EOL
                    {
                        result = val[0]
                    }
                | CMD '(' expr ')' EOL
                    {
                        result = Command.new(val[0], val[2])
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
                        result = Abst.new(val[1],val[3])
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

class Node
  def show
    raise 'unimplemented'
  end

  def free_variables(bound)
    raise 'unimplemented'
  end

  def show
    raise 'unimplemented'
  end
end

class Var < Node
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def expand
    self
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

  def expand
    Apply.new(@applicand.expand, @argument.expand)
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
end

class Abst < Node
  attr_reader :params, :body

  def initialize(params, body)
    @params = params
    @body = body
  end

  def expand
    if @params.size > 1
      rest = @params[1..-1]
      var = @params.first
      Abst.new([var], Abst.new(rest, body).expand)
    else
      Abst.new(@params, @body.expand)
    end
  end

  def show
    "(\\#{@params.join}.#{@body.show})"
  end

  def free_variables(bound)
    @body.free_variables(bound + @params)
  end
end

class Command < Node
  def initialize(name, lamda)
    @name = name
    @lambda = lamda
  end

  def execute
    case @name
    when "C"
      @lambda.expand.show
    when "FV"
      "{#{@lambda.free_variables([]).join(',')}}"
    else
      raise "unknown command #{@name}"
    end
  end

  def expand
    Command.new(@name, @lambda.expand)
  end

  def show
    execute
  end
end

class Subst < Node
  attr_reader :lambda, :from, :to

  def initialize(lamda, from, to)
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

  def expand
    Subst.new(@lambda.expand, @from, @to)
  end

  def show
    substitute(@lambda).show
  end

  def free_variables(bound)
    @lambda.free_variables(bound)
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

  def expand
    TermSubst.new(@lambda.expand, @from, @to)
  end

  def show
    substitute(@lambda).show
  end

  def free_variables(bound)
    @lambda.free_variables(bound)
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
