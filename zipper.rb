#!/usr/bin/env ruby

require 'haml'
require 'sinatra'
require 'tokyocabinet'
include TokyoCabinet

# Specify the url of the stylesheet you wish to load, (or change to nil.)
# Remember that in Sinatra the 'public' folder is accessed from the root,
# so the URL should read 'http://example.com/example.css', not
# 'http://example.com/public/example.css'!
CSSFile = 'example.css'
# The super secret file that tokyocabinet stores all of its url's in!
DBFile = 'links.tch'

# URL's are given a base-62 ID to make them as small as possible.
module Base62
  NUMERALS = ('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a
  
  def encode(i)
    raise ArgumentError unless Numeric === i
    return '0' if i == 0
    s = ''
    while i > 0
      s << Base62::NUMERALS[i.modulo(62)]
      i /= 62
    end
    s.reverse
  end

  def decode(i)
    s = i.to_s.reverse.split('') 
    total = 0
    s.each_with_index do |char, index|
      if ord = NUMERALS.index(char)
        total += ord * (62 ** index)
      else
        raise ArgumentError, "\"#{i}\" contains invalid number/string \"#{char}\"."
      end
    end
    total.to_s
  end

  module_function :encode, :decode
end

module UrlShortener

  def self.shorten(original_url)
    hdb = HDB.new
    hdb.open(DBFile, HDB::OWRITER | HDB::OCREAT)
    if hdb.get(0).nil?
      # This is our first url, so start storing it at 1.
      hdb.put(1, original_url)
      # 0 is a reserved key that will always tell us
      # what number the next url should be. In this
      # case, our next URL will be our second one.
      hdb.put(0, 2)
      # The number we return is the corresponding db key.
      shortened = 1
    else
      open_key = hdb.get(0).to_i
      hdb.put(open_key, original_url)
      # Increment to the next available key.
      hdb.put(0, open_key + 1)
      shortened = Base62.encode(open_key)
    end
    return shortened
  end

  def self.original(shortened)
    bdb = HDB.new
    bdb.open(DBFile, HDB::OWRITER | HDB::OCREAT)
    bdb.get(Base62.decode(shortened).to_i)
  end

end

get '/' do
  haml :index
end

post '/' do
  http_host = request.env['HTTP_HOST']
  @original_url = params[:url]
  shortened = UrlShortener.shorten(@original_url)
  @shortened_url = "http://#{http_host}/#{shortened}"
  haml :shortened
end

get '/:shortened' do
  original_url = UrlShortener.original(params[:shortened])
  if original_url == nil
    "No url."
  else
    redirect original_url
  end
end

__END__

@@ layout
!!! 1.1
%html
  %head
    %title URL Shortener
    %link{:rel => 'stylesheet', :href => CSSFile, :type => 'text/css'}
  %body{:style => "font-family: sans-serif"}
    = yield

@@ index
%h1 Zipper
%form{:method => 'post'}
  %p
    Original URL:
    %input{:type => "text", :name => 'url'}

@@ shortened
%p
  %a{:href => @original_url}
    = @original_url
%p has been shortened to
%p
  %a{:href => @shortened_url}
    = @shortened_url
