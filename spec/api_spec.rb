require 'spec_helper'
require 'hangperson_game'
require 'json'

describe "HangpersonApp" do
  include Rack::Test::Methods
  describe "GET /:id" do
    context "when game is in progress" do
      before :each do
        @game = FactoryGirl.create(:hangperson_game, :word => 'foobar',
                                                     :guesses => 'bo',
                                                     :wrong_guesses => 'cxz')
        get "/#{@game.id}"
      end
      it "reports the word as guessed so far" do
        expect(JSON.parse(last_response.body)['word_with_guesses']).to eq('-oob--')
      end
      it "says what letters have been correctly guessed" do
        expect(JSON.parse(last_response.body)['guesses']).to eq('bo')
      end
      it "says what letters have been incorrectly guessed" do
        expect(JSON.parse(last_response.body)['wrong_guesses']).to eq('cxz')
      end
      it "reports if the game is still in progress" do
        expect(JSON.parse(last_response.body)['status']).to eq('play')
      end
    end
    context "when the game is won" do
      before :each do
        @game = FactoryGirl.create(:hangperson_game, :word => 'garply',
                                                     :guesses => 'gplyar',
                                                     :wrong_guesses => 'tfq')
        get "/#{@game.id}"
      end
      it "reports if the game is won" do
        expect(JSON.parse(last_response.body)['status']).to eq('win')
      end
      it "should have a complete word with guesses" do
        expect(JSON.parse(last_response.body)['word_with_guesses']).to eq('garply')
      end
    end
    context "when the game is lost" do
      before :each do
        @game = FactoryGirl.create(:hangperson_game, :word => 'baz',
                                                     :guesses => 'a',
                                                     :wrong_guesses => 'tfqhpyv')
        get "/#{@game.id}"
      end
      it "reports if the game is lost" do
        expect(JSON.parse(last_response.body)['status']).to eq('lose')
      end
      it "should not have a complete word with guesses" do
        expect(JSON.parse(last_response.body)['word_with_guesses']).not_to eq('baz')
      end
    end
  end

  describe "POST /create" do
    before :each do
      stub_request(:post, "http://watchout4snakes.com/wo4snakes/Random/RandomWord").
        to_return(:status => 200, :headers => {}, :body => "foobar")
    end
    it "creates a new HangpersonGame instance and save it to the DB" do
      games = HangpersonGame.all.count
      post '/create'
      expect(HangpersonGame.all.count).to eq(games+1)
    end
    it "returns an id which identifies the created game" do
      post '/create'
      expect(JSON.parse(last_response.body)['id']).not_to eq(nil)
    end
    it "creates a game with no guesses and an all blank word" do
      post '/create'
      expect(JSON.parse(last_response.body)['word_with_guesses']).to eq("------")
      expect(JSON.parse(last_response.body)['guesses']).to eq("")
      expect(JSON.parse(last_response.body)['wrong_guesses']).to eq("")
    end
  end

  describe "POST /:id/guess" do
    context "when guess is valid" do
      before :each do
        @game = FactoryGirl.create(:hangperson_game, :word => 'foobar',
                                                     :guesses => 'f',
                                                     :wrong_guesses => 'zy')

      end
      it "responds with JSON reporting the new game state after a correct guess" do
        post "/#{@game.id}/guess", :guess => 'b'
        expect(JSON.parse(last_response.body)['word_with_guesses']).to eq("f--b--")
        expect(JSON.parse(last_response.body)['guesses']).to eq("fb")
        expect(JSON.parse(last_response.body)['wrong_guesses']).to eq("zy")
        expect(JSON.parse(last_response.body)['status']).to eq("play")
      end
      it "responds with JSON reporting the new game state after a wrong guess" do
        post "/#{@game.id}/guess", :guess => "q"
        expect(JSON.parse(last_response.body)['word_with_guesses']).to eq("f-----")
        expect(JSON.parse(last_response.body)['guesses']).to eq("f")
        expect(JSON.parse(last_response.body)['wrong_guesses']).to eq("zyq")
        expect(JSON.parse(last_response.body)['status']).to eq("play")
      end
    end
    context "when win or lose scenario" do
      before :each do
        @game = FactoryGirl.create(:hangperson_game, :word => 'apple',
                                                     :guesses => 'lpe',
                                                     :wrong_guesses => 'qwrtyu')
      end
      it "transitions to a loss when the guess is wrong" do
        post "/#{@game.id}/guess", :guess => "o"
        expect(JSON.parse(last_response.body)['word_with_guesses']).to eq("-pple")
        expect(JSON.parse(last_response.body)['guesses']).to eq("lpe")
        expect(JSON.parse(last_response.body)['wrong_guesses']).to eq("qwrtyuo")
        expect(JSON.parse(last_response.body)['status']).to eq("lose")
      end
      it "transitions to a win when the guess is right" do
        post "/#{@game.id}/guess", :guess => "a"
        expect(JSON.parse(last_response.body)['word_with_guesses']).to eq("apple")
        expect(JSON.parse(last_response.body)['guesses']).to eq("lpea")
        expect(JSON.parse(last_response.body)['wrong_guesses']).to eq("qwrtyu")
        expect(JSON.parse(last_response.body)['status']).to eq("win")
      end
    end
    it "responds with the proper JSON when the guess is a non-letter" do
      @game = FactoryGirl.create(:hangperson_game, :word => "banana")
      post "/#{@game.id}/guess", :guess => ';'
      expect(JSON.parse(last_response.body)['error']).to eq("Invalid guess: ';'")
    end
    it "responds with the proper JSON when guessing at a game that's won" do
      @game = FactoryGirl.create(:hangperson_game, :word => "banana",
                                                   :guesses => 'ban')
      post "/#{@game.id}/guess", :guess => 't'
      expect(JSON.parse(last_response.body)['error']).to eq("You already won, the word was 'banana'")
    end
    it "responds with the proper JSON when guessing at a game that's lost" do
      @game = FactoryGirl.create(:hangperson_game, :word => "banana",
                                                   :wrong_guesses => 'qwertyu')
      post "/#{@game.id}/guess", :guess => 'b'
      expect(JSON.parse(last_response.body)['error']).to eq("You already lost, the word was 'banana'")
    end
    it "responds with the proper JSON when guessing a repeat letter" do
      @game = FactoryGirl.create(:hangperson_game, :word => "banana",
                                                   :guesses => 'b',
                                                   :wrong_guesses => 'q')
      post "/#{@game.id}/guess", :guess => 'b'
      expect(JSON.parse(last_response.body)['error']).to eq("You have already guessed 'b'")
      post "/#{@game.id}/guess", :guess => 'q'
      expect(JSON.parse(last_response.body)['error']).to eq("You have already guessed 'q'")
    end
  end
end
