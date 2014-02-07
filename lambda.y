class LambdaParser

rule
  target: expr EOL           { result = val[0] }

  term:       VAR           { result = Term.new.replace val }
            | '(' expr ')'  { result = val }
            | '\\' var_list '.' expr { result = Abst.new.replace [val[1],val[3]] }
  var_list: VAR             { result = VarList.new.replace val }
           | var_list VAR   { result = val[0] << val[1] }

  expr: term        { result = val[0] }
      | expr term   { result = Apply.new.replace val }
end

---- header

def create_category(name)
  eval <<EOD
class #{name} < Array
  def inspect()
    #{name.dump} + super
  end
end
EOD
end
#create_category("Target")
create_category("VarList")
create_category("Term")
create_category("Apply")
create_category("Abst")

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
