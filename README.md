zipper-tokyocabinet
===================

This is a single script file that serves a web page for shortening urls. It uses tokyocabinet and base-62 numerals for very small and efficient url storage.

### Usage
* gem install sinatra haml tokyocabinet
* shotgun zipper.rb

Running the web server and shortening urls will generate a ‘links.tch’ database in the same folder as the script. This script does not include input sanitation or page caching or all that other good stuff you might want for a production site (at least not for now). This is just something simple I made while learning Sinatra and hopefully it will help others.
