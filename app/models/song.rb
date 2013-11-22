class Song < ActiveRecord::Base
  
  def self.search(artist, title)
    if (artist && title)
      where('artist LIKE ? AND songname LIKE ?', "%#{artist}%", "%#{title}%")
    elsif artist
      where('artist LIKE ?', "%#{artist}%")
    elsif title
      where('songname LIKE ?', "%#{title}%")
    else
      scoped
    end
  end
end
