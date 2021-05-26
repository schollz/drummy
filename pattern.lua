TEMP_DIR="/tmp/"

local charset={} do -- [0-9a-zA-Z]
  for c=48,57 do table.insert(charset,string.char(c)) end
  for c=65,90 do table.insert(charset,string.char(c)) end
  for c=97,122 do table.insert(charset,string.char(c)) end
end

local function random_string(length)
  if not length or length<=0 then return '' end
  return random_string(length-1)..charset[math.random(1,#charset)]
end

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

function os.file_exists(name)
  local f=io.open(name,"r")
  if f~=nil then io.close(f) return true else return false end
end

function os.write(fname,data)
  local filehandle=io.open(fname,"w")
  filehandle:write(data)
  filehandle:close()
end


function os.read(fname)
  local f=io.open(fname,"rb")
  local content=f:read("*all")
  f:close()
  return content
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


-- runs sql in a non-blocking way
function execute_sql_async(query)
  local rand_string=random_string(4)
  print(rand_string)
  fname=TEMP_DIR.."exec."..rand_string..".sql"
  fnameout=TEMP_DIR.."exec."..rand_string..".result"
  os.write(fname,query)
  os.execute("(cat "..fname.." | sqlite3 db.db >"..fnameout.."; rm "..fname..") 2>&1 &")
end

function db_random_ins(ins_to_find,density_limits)
  query=string.format([[SELECT 'print(num_to_pattern('||pid||')); test_global="ok"' FROM drum INDEXED BY idx_ins WHERE ins==%d AND density>%d AND density<%d ORDER BY RANDOM() LIMIT 1]],ins_to_find,density_limits[1],density_limits[2])
  print(query)

  -- async method
  execute_sql_async(query)
end

function db_random_ins_locked(ins_to_find,ins_locked,density_limits)
  local qs={}
  for ins,pattern_string in pairs(ins_locked) do
    print(ins,pattern_string)
    table.insert(qs,"SELECT gid FROM drum INDEXED BY idx_pid WHERE ins=="..ins.." AND pid=="..pattern_to_num(pattern_string))
  end
  local query=table.concat(qs," INTERSECT ")
  query=string.format([[SELECT 'print("'||pid||'"); test_global="ok"' FROM drum WHERE gid in (%s) AND ins==%d AND density>%d AND density<%d ORDER BY RANDOM() LIMIT 1]],query,ins_to_find,density_limits[1],density_limits[2])
  print(query)

  -- async method
  execute_sql_async(query)
end

function db_random_group(ins_to_find,density_limits)
  local query=string.format([[SELECT "if "||ins||"<=4 then print("||ins||",num_to_pattern("||pid||")) end" FROM drum INDEXED BY idx_gid WHERE gid in (SELECT gid FROM drum INDEXED BY idx_ins WHERE ins==%d AND gdensity>%d AND gdensity<=%d ORDER BY RANDOM() LIMIT 1)]],ins_to_find,density_limits[1],density_limits[2])
  print(query)

  -- async method
  execute_sql_async(query)
end


function sleep(n) -- seconds
  local t0=os.clock()
  while os.clock()-t0<=n do end
end


function run_sql_results()
  local cmd="find "..TEMP_DIR.."* -not -empty -type f -name 'exec.*.result' 2>&1 | grep -v Permission"
  local s=os.capture(cmd)
  fnames={}
  for word in s:gmatch("%S+") do table.insert(fnames,word) end
for i,v in ipairs(fnames) do
    print(i,v)
    -- print(os.read(v))
    if os.file_exists(v) then
      dofile(v)
      os.remove(v)
    end
  end
end

function remove_old_results()
  local cmd="find "..TEMP_DIR.."* -not -empty -type f -name 'exec.*.result' 2>&1 | grep -v Permission"
  local s=os.capture(cmd)
  local fnames={}
  for word in s:gmatch("%S+") do table.insert(fnames,word) end
for i,v in ipairs(fnames) do
    print("removing old result "..v)
    os.remove(v)
  end
  cmd="find "..TEMP_DIR.."* -not -empty -type f -name 'exec.*.sql' 2>&1 | grep -v Permission"
  s=os.capture(cmd)
  fnames={}
  for word in s:gmatch("%S+") do table.insert(fnames,word) end
for i,v in ipairs(fnames) do
    print("removing old sql "..v)
    os.remove(v)
  end
end

-- file glob
remove_old_results()
ins=2
locked={}
locked[1]="x---x---x---x---x---x---x---x---"
locked[3]="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
print("running")
db_random_ins_locked(ins,locked,{0,20})
db_random_ins(1,{0,20})
db_random_group(1,{0,10})
print("checking results")
for i=1,20 do
  run_sql_results()
  sleep(0.1)
end
