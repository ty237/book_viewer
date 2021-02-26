require 'yaml'

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

helpers do
  def in_paragraphs(text)
    text.split("\n\n").each_with_index.map do |line, index|
      "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def count_interests
    @data = Psych.load_file 'users.yaml'
    interests = 0
    @data.each do |_user, user_data|
      interests += user_data[:interests].size
    end
    interests
  end

  def count_users
    @data = Psych.load_file 'users.yaml'
    @data.size
  end
end

before do
  @contents = File.readlines('data/toc.txt')
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def chapters_matching(query)
  results = []

  return results unless query

  each_chapter do |number, name, contents|
    matches = {}
    contents.split("\n\n").each_with_index do |paragraph, index|
      paragraph = paragraph.gsub(/#{query}/, "<strong>#{query}</strong>")
      matches[index] = paragraph if paragraph.include?(query)
    end
    results << { number: number, name: name, paragraphs: matches } if matches.any?
  end

  results
end

get '/' do
  @title = 'The Adventures of Sherlock Holmes'
  erb :home
end

get '/testing' do
  @words = %w[blubber beluga galoshes mukluk narwhal]
  erb :index
end

get '/users' do
  @data = Psych.load_file 'users.yaml'
  @user = params[:name]
  @user_data = @data[@user.to_sym] if @user
  erb :users
end

get '/chapters/:number' do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]
  @title = "Chapter #{number}: #{chapter_name}"

  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

get '/search' do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect '/'
end
