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
    when /\A\n/          # 行末
      [:EOL, "\n"]
    when /\A[\n \t]+/      # ホワイトスペース
      @str = $'
      return next_token
    when /\A[()\\.$]/
      [$&, $&]
    when /\A[a-z]/
      [:VAR, $&]
    else
      raise "NANJA"
    end

    @str = $'
    ret
  end
end
