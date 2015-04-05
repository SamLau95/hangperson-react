require 'sinatra/base'
require 'sinatra/activerecord'
require './lib/hangperson_game.rb'
require 'json'


class HangpersonApp < Sinatra::Base

  register Sinatra::ActiveRecordExtension

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
    @game = HangpersonGame.find(params[:id])
    letter = params[:guess]
    status = @game.check_win_or_lose
    if status != :play
      error = "You already #{status == :win ? 'won' : 'lost'}, the word was '#{@game.word}'"
    end
    begin
      if ! @game.guess(letter[0])
        error = "You have already guessed '#{letter[0]}'"
      end
    rescue ArgumentError
      error = "Invalid guess: '#{letter[0]}'"
    end
    if error
      return {:error => error}.to_json
    else
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

end
