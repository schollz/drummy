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

function pattern_to_num(pattern_string)
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

function num_to_pattern(shash)
  local re={}
  while shash>0 do
    table.insert(re,shash%2==0 and"-" or "x")
    shash=math.floor(shash/2)
  end
  while #re<32 do
    table.insert(re,"-")
  end
  return table.concat(re,"")
end

assert(pattern_to_num("--x---x---x---x---x---x---x---x-")==1145324612,"BAD HASH")
assert(pattern_to_num("--x---x---x---x---x---x---x---xx")==3292808260,"BAD HASH")
assert(num_to_pattern(pattern_to_num("--x---x---x---x---x---x---x-----"))=="--x---x---x---x---x---x---x-----","BAD NUM")
assert(num_to_pattern(pattern_to_num("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"))=="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx","BAD NUM")



function find_ins_with_ins_lock(ins_to_find,ins_locked,density_limits)
  local qs={}
  for ins,pattern_string in pairs(ins_locked) do
    print(ins,pattern_string)
    table.insert(qs,"SELECT gid FROM drum INDEXED BY idx_pid WHERE ins=="..ins.." AND pid=="..pattern_to_num(pattern_string))
  end
  local query=table.concat(qs," INTERSECT ")
  query="SELECT pid FROM drum WHERE gid in ("..query..") AND ins=="..ins_to_find.." AND density > "..density_limits[1].." AND density < "..density_limits[2].." ORDER BY RANDOM() LIMIT 1"
  print(query)
  -- async method
  --os.execute("sqlite3 db.db '"..query.."' >a.txt 2>&1 &")
  local new_pattern=os.capture("sqlite3 db.db '"..query.."'")
  print(new_pattern)

  -- alt method
  local qs={}
  for ins,pattern_string in pairs(ins_locked) do
    print(ins,pattern_string)
    table.insert(qs,"SELECT * FROM drum INDEXED BY idx_pid WHERE ins=="..ins.." AND pid=="..pattern_to_num(pattern_string))
  end
  local query=table.concat(qs," INTERSECT ")
  query="SELECT pid FROM ("..query..") AND ins=="..ins_to_find.." AND density > "..density_limits[1].." AND density < "..density_limits[2].." ORDER BY RANDOM() LIMIT 1"
  print(query)
  -- async method
  --os.execute("sqlite3 db.db '"..query.."' >a.txt 2>&1 &")
  local new_pattern=os.capture("sqlite3 db.db '"..query.."'")
  print(new_pattern)

end

ins=2
locked={}
locked[1]="x---x---x---x---x---x---x---x---"
locked[3]="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
find_ins_with_ins_lock(ins,locked,{0,20})
