# -*- coding: utf-8 -*-

=begin
どういうデータにしたらいいのかわからない。
識別子から定義をルックアップしたいし、
逆に定義から識別子をルックアップしたい。
alist か hash ……。
こういうデータをで操作する特殊な名前の関数をつくったら
LISP みたいだしクラス作らないとだめかなぁ。

どのくらいの一般性で作ればいいんだろう……。
定義の同一性はα同値で見ないとだめだから
同一性の判定は String#== とかじゃだめだ。
すると to_name の実装にラムダ計算特有の処理が入ってくる。
=end

class MacroProcessor
  def initialize
    @table = []
  end

  def define name, definition
    @table << [name, definition]
  end

  def undef name
    @table.delete_if { |_name,definition| _name==name }
  end

  def to_definition name
    result = @table.assoc(name)
    if result then result[1] else nil end
  end

  include Enumerable
  def each
    @table.each do |name, definition|
      yield(name, definition)
    end
  end

  def pattern
    /\b(#{@table.map(&:first).join('|')})\b/
  end

  def expand text
    text.gsub pattern() do |ident|
      '(' + expand( to_definition(ident) ) + ')'
    end
  end
end

if $0 == __FILE__
  pp = MacroProcessor.new
  pp.define 'TWO', 'succ ONE'
  pp.define 'ONE', 'succ ZERO'
  pp.define 'succ', '\n s.(s F) n'
  pp.define 'F', '\xy.y'
  pp.define 'ZERO', 'I'
  pp.define 'I', '\x.x'

  puts 'one =='
  puts pp.expand('ONE')
  puts 'two =='
  puts pp.expand('TWO')
end
