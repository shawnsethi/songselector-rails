json.array!(@songs) do |song|
  json.extract! song, :artist, :songname, :bpm, :key, :spotify_id
  json.url song_url(song, format: :json)
end
