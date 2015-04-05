class CreateHangpersonGame < ActiveRecord::Migration
  def change
    create_table :hangperson_games do |t|
      t.string :word
      t.string :guesses
      t.string :wrong_guesses
    end
  end
end
