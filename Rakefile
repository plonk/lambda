# lambda.tab.rb をつくる

#yacc = ['lambda.y']
table = ['michaelson.tab.rb', 'lambda.tab.rb']

task :default => ['lambda.tab.rb', 'michaelson.tab.rb']

file 'lambda.tab.rb' => 'lambda.y'
file 'michaelson.tab.rb' => 'michaelson.y'

rule 'lambda.tab.rb' => 'lambda.y' do |t|
  sh "racc -v -g #{t.source}"
end

rule 'michaelson.tab.rb' => 'michaelson.y' do |t|
  sh "racc -v -g #{t.source}"
end

task :clean do |t|
  rm *table
end
