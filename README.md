# HTMLDiff

Displays diffs of html input strings

# Example

class Stuff

  class << self
    include HTMLDiff
  end
  
  # or extend HTMLDiff ?

end

Stuff.diff('a word is here', 'a nother word is there')

# => 'a<ins class=\"diffins\"> nother</ins> word is <del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>'

Checkout the crappy specs for good examples. 
