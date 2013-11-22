class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
      t.string :artist
      t.string :songname
      t.decimal :bpm
      t.integer :key
      t.string :spotify_id

      t.timestamps
    end
  end
end
