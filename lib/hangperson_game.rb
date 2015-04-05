class HangpersonGame < ActiveRecord::Base

  def guess(letter)
    if letter.nil? or not letter =~ /^[a-z]$/i
      raise ArgumentError
    end
    letter = letter[0].downcase
    if  word.include?(letter) && !guesses.to_s.include?(letter)
      self.guesses = guesses.to_s + letter
    elsif !word.include?(letter) && !wrong_guesses.to_s.include?(letter)
      self.wrong_guesses = wrong_guesses.to_s + letter
    else
      false
    end
  end

  def word_with_guesses
    word.gsub(/./)  { |letter| guesses.include?(letter) ? letter : '-' }
  end

  def check_win_or_lose
    if word_with_guesses == word
      :win
    elsif wrong_guesses.length > 6
      :lose
    else
      :play
    end
  end

  # Get a word from remote "random word" service

  def self.get_random_word
    require 'uri'
    require 'net/http'
    uri = URI('http://watchout4snakes.com/wo4snakes/Random/RandomWord')
    Net::HTTP.post_form(uri ,{}).body
  end

end
