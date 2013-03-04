require 'rubygems'
require 'bud'

class Raspbuddies
  include Bud

  
  
  bloom do
    stdio <~ logIntoFile("hello")
  end
  
  
  def logIntoFile(msg)
    File.open("log", 'a') {|f| f.write(msg << "\n") }
    return [[ msg ]]	
  end
  
end

rasp = Raspbuddies.new
rasp.tick
rasp.tick


