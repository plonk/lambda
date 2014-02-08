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
  attr_reader :parameters, :body

  def initialize(parameters, body)
    @parameters = parameters
    @body = body
  end

  def expand
    if parameters.size > 1
      params = parameters.dup
      var = params.shift
      Abst.new([var], Abst.new(params, body).expand)
    else
      Abst.new(@parameters, @body.expand)
    end
  end

  def show
    "(\\#{@parameters.join}.#{@body.show})"
  end

  def free_variables(bound)
    @body.free_variables(bound + @parameters)
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

  def show
    execute
  end
end

class Subst < Node
  def initialize(lamda, from, to)
    @lambda = lamda
    @from = from
    @to = to
  end

  def execute
    
  end

  def show
    execute
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
