require 'tilt/erubis'
require 'sinatra'
require 'sinatra/reloader'
require 'psych'

before do
  # turns out I could have just done this instead of constructing the hash:
  @yaml_obj = Psych.load_file('./public/users.yaml')
  # loading a YAML file with YAML or Psych (aliases) is super useful!

  # otherwise, I have to do ALL THIS to parse the text myself:
  @contents = File.read('./public/users.yaml').split

  @users = @contents.select do |word|
      word.match(/:.*:/)      &&
        word != ':email:'     &&
        word != ':interests:'
    end.map do |word|
      word[1...-1]
  end

  @emails = @contents.select do |word|
    word.match(/.*\.com/)
  end

  @interests = find_all_interests
  temp_interests = @interests.dup

  @all_details = {}
  placeholder_idx = 1
  @users.each_with_index do |user, user_idx|
    user_interests = []
    @contents.each_with_index do |word, idx|
      if temp_interests.include?(word)
        user_interests << temp_interests.shift
      elsif @users.include?(word[1...-1]) && idx > placeholder_idx
        placeholder_idx = idx
        break
      end
    end

    @all_details[user.to_sym] = {
        email: @emails[user_idx],
        interests: user_interests
    }
  end
end

helpers do
  # and don't forget this part! I had to do this too!
  def find_all_interests
    all_interests = []
    scan = nil
    @contents.each do |word|
      if word == ':interests:'
        scan = true
      elsif @users.include?(word[1...-1])
        scan = false
      elsif scan
        all_interests << word
      end
    end
    all_interests.reject! { |word| word == '-' }
  end

  def count_interests
    find_all_interests.count
  end
end

# def pain 
#   puts "What have I done?" if @yaml_obj == @all_details
# end

get '/' do
  erb :home # automatically uses `layout.erb` by default
end

get '/users/:user' do
  @user = params[:user]
  @email = @all_details[@user.to_sym][:email]
  @user_interests = @all_details[@user.to_sym][:interests]
  erb :user_page
end

not_found do
  'Was not able to find this page, sorry.'
end
