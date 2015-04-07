require 'sinatra/base'
require 'sinatra/activerecord'
require './lib/hangperson_game.rb'
require 'json'


class HangpersonApp < Sinatra::Base

  register Sinatra::ActiveRecordExtension

  set :public_folder, 'public'

  get "/" do
    send_file File.join(settings.public_folder, 'index.html')
  end

  # TODO: Error handling (if create methods returns nil, return error)
  post '/create' do
    word = params[:word] || HangpersonGame.get_random_word
    @game = HangpersonGame.create(:word => word, :guesses => "", :wrong_guesses => "")
    {:id => @game.id,
     :word_with_guesses => @game.word_with_guesses,
     :guesses => @game.guesses,
     :wrong_guesses => @game.wrong_guesses}.to_json
  end

  post '/:id/guess' do
    @req_data = JSON.parse(request.body.read.to_s)
    @game = HangpersonGame.find(params[:id])
    @status = @game.check_win_or_lose
    @letter = @req_data['guess']
    attempt_guess
    if @error
      return {:error => @error}.to_json
    else
      @game.save
      return {:word_with_guesses => @game.word_with_guesses,
              :guesses => @game.guesses,
              :wrong_guesses => @game.wrong_guesses,
              :status => @game.check_win_or_lose}.to_json
    end
  end

  get '/:id' do
    @game = HangpersonGame.find(params[:id])
    {:word_with_guesses => @game.word_with_guesses,
     :guesses => @game.guesses,
     :wrong_guesses => @game.wrong_guesses,
     :status => @game.check_win_or_lose}.to_json
  end

  helpers do
    def attempt_guess
      if ! @letter
        @error = "No guess provided"
      elsif @status != :play
        @error = "You already #{@status == :win ? 'won' : 'lost'}, the word was '#{@game.word}'"
      else
        begin
          if ! @game.guess(@letter[0])
            @error = "You have already guessed '#{@letter[0]}'"
          end
        rescue ArgumentError
          @error = "Invalid guess: '#{@letter[0]}'"
        end
      end
    end
  end


end
