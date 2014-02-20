require 'English'

=begin

=end

class Lexer
  def initialize(str)
    @str = str
  end
  
  def next_token
    do_next_token
  end

  def do_next_token
    return nil if @str == ""

    ret =
      case @str
      when /\A[\n \t]+/      # ホワイトスペース
        @str = $POSTMATCH
        return next_token
      when /\A:=/
        [$MATCH, $MATCH]
      when /\A[()\\.\/\[\]]/
        [$MATCH, $MATCH]
      when /\A[a-z]'*/
        [:VAR, $MATCH]
      else
        raise "illegal token"
      end

    @str = $POSTMATCH
    ret
  end
end
