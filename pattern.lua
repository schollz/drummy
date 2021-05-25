function os.capture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

function get_hash(pattern_string)
  local shash=0
  local i=0
  for c in pattern_string:gmatch"." do
    if c=='x' then
      shash=shash+(2^i)
    end
    i=i+1
  end
  shash=math.floor(shash)
  return shash
end

assert(get_hash("--x---x---x---x---x---x---x---x-")==1145324612,"BAD HASH")

function find_ins_with_ins_lock(ins_to_find,ins_locked,density_limits)
local qs={}
for ins,pattern_string in pairs(ins_locked) do
	print(ins,pattern_string)
	table.insert(qs,"SELECT gid FROM drum WHERE ins=="..ins.." AND pid=="..get_hash(pattern_string))
end
local query=table.concat(qs," INTERSECT ")
query = "SELECT pattern FROM drum WHERE gid in ("..query..") AND ins=="..ins_to_find.." AND density > "..density_limits[1].." AND density < "..density_limits[2].." ORDER BY RANDOM() LIMIT 1"
print(query)
local new_pattern=os.capture("sqlite3 db.db '"..query.."'")
print(new_pattern)
end

ins=2
locked={}
locked[1]="x---x---x---x---x---x---x---x---"
locked[3]="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
find_ins_with_ins_lock(ins,locked,{0,20})
