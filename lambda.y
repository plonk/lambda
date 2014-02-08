class LambdaParser

rule

target          : expr EOL
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
                        result = Abst.new(val[1],val[3])
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

  # カッコを省略してみよう
  def show
    a = @applicand.show
    b = @argument.show
    if a[0] == '(' and b[-1] == ')'
      "#{a} #{b}"
    else
      "(#{a} #{b})"
    end
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
