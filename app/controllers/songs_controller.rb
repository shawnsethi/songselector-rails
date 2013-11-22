class SongsController < ApplicationController
  before_action :set_song, only: [:show, :edit, :update, :destroy]
  helper_method :sort_column, :sort_direction
  
require 'json'
require 'open-uri'


  # GET /songs
  # GET /songs.json
  def index
    @songs = Song.search(params[:searchartist], params[:searchtitle]).where("key >= 0 AND bpm >= 0").order(sort_column + " " + sort_direction)
    @unfound_songs = Song.where("key IS NULL OR bpm IS NULL").order(sort_unfound_column + " " + sort_unfound_direction)
  end

  def import
  end

  def create_all
    spotify_ids = params["q"].lines
    success_counter = 0
    fail_counter = 0
    spotify_ids.each do |id|
      if id.include? "spotify:track:"
        id.slice! "spotify:track:"
        song = Song.new
        song.spotify_id = id.strip
        lookup_song(song)
        success_counter+=1
        sleep 0.5
      else
        fail_counter+=1
      end
    end
    flash[:notice] = "#{success_counter.to_s} tracks successfully imported.  #{fail_counter.to_s} failed."
    redirect_to songs_url
  end


  # GET /songs/1
  # GET /songs/1.json
  def show
    if @song.key && @song.bpm
      keyminus1 = @song.key - 1
      if keyminus1 == -1
        keyminus1 = 11
      end
      keyplus1 = @song.key + 1
      if keyplus1 == 12
        keyplus1 = 0
      end
      
      keyrange = [keyminus1, @song.key, keyplus1]

      @related_songs = Song.where("id != ? AND key IN (?) AND bpm BETWEEN ? AND ?", @song.id, keyrange, @song.bpm - 8, @song.bpm + 8).order(sort_column + " " + sort_direction)
      
    end
  end

  # GET /songs/new
  def new
    @song = Song.new
  end

  # GET /songs/1/edit
  def edit
  end

def lookup_song(song)
    uri = 'http://developer.echonest.com/api/v4/track/profile?api_key=6XUOAXHJOW28GGGRH&format=json&id=spotify-WW:track:' + song.spotify_id + '&bucket=audio_summary'

    result = open(uri).read
    parsed = JSON.parse(result)

    if parsed["response"]["status"]["message"] == "Success"
      songname = parsed["response"]["track"]["title"]
      artist = parsed["response"]["track"]["artist"]
      if (!parsed["response"]["track"]["audio_summary"].has_key?("key") || parsed["response"]["track"]["audio_summary"]["tempo"] < 50 || parsed["response"]["track"]["audio_summary"]["tempo"] > 150 )  
        uri = 'http://developer.echonest.com/api/v4/song/search?api_key=6XUOAXHJOW28GGGRH&format=json&results=1&artist=' + Rack::Utils.escape(artist) + '&title=' + Rack::Utils.escape(songname) + '&bucket=audio_summary'
        result = open(uri).read
        parsed = JSON.parse(result)
        if parsed["response"]["songs"].length > 0
          bpm = parsed["response"]["songs"][0]["audio_summary"]["tempo"]
          key = parsed["response"]["songs"][0]["audio_summary"]["key"]
        end
      else
        bpm = parsed["response"]["track"]["audio_summary"]["tempo"]
        key = parsed["response"]["track"]["audio_summary"]["key"]  
      end
      @song = song
      @song.bpm = bpm
      @song.key = key
      @song.songname = songname
      @song.artist = artist

      @song.save
    end
end


  # POST /songs
  # POST /songs.json
  def create
    @song = Song.new(song_params)
    respond_to do |format|
      if lookup_song(@song)
       # format.html { redirect_to @song, notice: 'Song was successfully created.' }
        format.html { redirect_to @song, notice: "#{@song.artist} - #{@song.songname} was successfully created." }
        format.json { render action: 'show', status: :created, location: @song }
      else
        format.html { render action: 'new' }
        format.json { render json: @song.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /songs/1
  # PATCH/PUT /songs/1.json
  def update
    
    
    respond_to do |format|
      updated_params = song_params
      if (@song.artist != song_params[:artist] || @song.songname != song_params[:songname])
        uri = 'http://developer.echonest.com/api/v4/song/search?api_key=6XUOAXHJOW28GGGRH&format=json&results=1&artist=' + Rack::Utils.escape(song_params[:artist]) + '&title=' + Rack::Utils.escape(song_params[:songname]) + '&bucket=audio_summary'
        result = open(uri).read
        parsed = JSON.parse(result)
        if parsed["response"]["songs"].length > 0
          updated_params[:bpm] = parsed["response"]["songs"][0]["audio_summary"]["tempo"]
          updated_params[:key] = parsed["response"]["songs"][0]["audio_summary"]["key"]
          notice = "Song found on EchoNest!"
        else
          notice = "Could not find updated song on EchoNest."
        end
        
      end
      if @song.update(updated_params)
        format.html { redirect_to @song, notice: "#{notice}  #{updated_params} " }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @song.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /songs/1
  # DELETE /songs/1.json
  def destroy
    @song.destroy
    respond_to do |format|
      format.html { redirect_to songs_url }
      format.json { head :no_content }
    end
  end

  def delete_all
    Song.destroy_all
    flash[:notice] = "All gone!"
    redirect_to songs_url
  end

    def self.keynames
      ["C", "C\u266F", "D", "E\u266D", "E", "F", "F\u266F", "G", "A\u266D", "A", "B\u266D", "B"]
    end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_song
      @song = Song.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def song_params
      params.require(:song).permit(:artist, :songname, :bpm, :key, :spotify_id)
    end
    
    def sort_column
      Song.column_names.include?(params[:sort]) ? params[:sort] : "artist, songname"
    end
    
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end
   
    def sort_unfound_column
      Song.column_names.include?(params[:sort]) ? params[:sort] : "artist, songname"
    end
    
    def sort_unfound_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end    
    

end
