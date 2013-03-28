#################################################################
#
#  Raspbuddies
#  University of Nantes
#  M2 -Alma
#  2012 - 2013
#
################################################################# 
#
#  Matthieu Allon - Pauline Folz - Teko Hemazro - Amine Lyazid
#  Adrien Quillet - Nicolas Rault - Kévin Simon
#
#################################################################

#################################################################
#
#  Generating a hash function module
#
#  k : number of hash function to create
#
#  Adrien Quillet
#
#################################################################
def createHashModule(k)
   
   moduleCode = "require 'digest/md5'\n\n"
   moduleCode = moduleCode + "module HashFunctions\n\n"
   
   keySize = 32
   m = 41
   
   (1..k).each do |i|
      a = []
      while a.length < keySize do
         a.insert(0, rand(m-1))
#          a.uniq!
      end
      moduleCode = moduleCode + "\t@@a" + i.to_s + " = " + a.inspect + "\n"
   end
   
   moduleCode = moduleCode + "\n"
   
   (1..k).each do |i|
      moduleCode = moduleCode + "\tdef h" + i.to_s + "(k)\n"
      moduleCode = moduleCode + "\t\tresult = 0\n"
      moduleCode = moduleCode + "\t\tn = 0\n"
      moduleCode = moduleCode + "\t\tk.each_byte do |b|\n"
      moduleCode = moduleCode + "\t\t\tresult = result + @@a" + i.to_s + "[n] * b\n"
      moduleCode = moduleCode + "\t\t\tn = n + 1\n"
      moduleCode = moduleCode + "\t\tend\n"
      moduleCode = moduleCode + "\t\treturn result.modulo(" + m.to_s + ")\n"
      moduleCode = moduleCode + "\tend\n\n"
   end
   
   moduleCode = moduleCode + "\tdef hashKey(k)\n"
   moduleCode = moduleCode + "\t\tmd5 = Digest::MD5.hexdigest(k)\n"
   moduleCode = moduleCode + "\t\treturn ["
   (1..k).each do |i|
      moduleCode = moduleCode + "h" + i.to_s + "(md5)"
      if i != k
         moduleCode = moduleCode + ", "
      end
   end
   moduleCode = moduleCode + "]\n"
   moduleCode = moduleCode + "\tend\n\n"

   moduleCode = moduleCode + "end";
   
   return moduleCode;
end

#################################################################
#
# Generation
#
##################################################################
puts createHashModule(2)