# lambda.tab.rb をつくる

#yacc = ['lambda.y']
#table = ['lambda.tab.rb']

task :default => ['lambda.tab.rb']

file 'lambda.tab.rb' => 'lambda.y'

rule 'lambda.tab.rb' => 'lambda.y' do |t|
  sh "racc -v -g #{t.source}"
end

task :clean do |t|
  rm *table
end
