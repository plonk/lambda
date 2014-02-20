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

require_relative "node.rb"
  
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
