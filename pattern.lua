TEMP_DIR="/tmp/"
RANDOMSEED="1284553781927398174017240"

local charset={} do -- [0-9a-zA-Z]
  for c=48,57 do table.insert(charset,string.char(c)) end
  for c=65,90 do table.insert(charset,string.char(c)) end
  for c=97,122 do table.insert(charset,string.char(c)) end
end

local function random_string(length)
  if not length or length<=0 then return '' end
  return random_string(length-1)..charset[math.random(1,#charset)]
end

local function generate_seed()
  RANDOMSEED=""
  for i=1,10 do
    RANDOMSEED=RANDOMSEED..math.random(1,10)
  end
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
  while #re<16 do
    table.insert(re,"-")
  end
  return table.concat(re,"")
end

assert(pattern_to_num("--x---x---x---x---x---x---x---x-")==1145324612,"BAD HASH")
assert(pattern_to_num("--x---x---x---x---x---x---x---xx")==3292808260,"BAD HASH")
assert(num_to_pattern(pattern_to_num("x---x---x---x---"))=="x---x---x---x---","BAD NUM")
assert(num_to_pattern(pattern_to_num("xxxxxxxxxxxxxxxx"))=="xxxxxxxxxxxxxxxx","BAD NUM")


-- runs sql in a non-blocking way
function execute_sql_async(query)
  if cmd_cache[query]~=nil then
    f=load(cmd_cache[query])
    f()
    do return end
  end
  local rand_string=random_string(4)
  print(rand_string)
  fname=TEMP_DIR.."exec."..rand_string..".sql"
  fnameout=TEMP_DIR.."exec."..rand_string..".result"
  os.write(fname,query)
  os.execute("cat "..fname.." | sqlite3 db.db >"..fnameout.." 2>&1 &")
end

function db_random_ins(ins_to_find,density_limits)
  query=string.format([[SELECT 'print(num_to_pattern('||pid||')); test_global="ok"' FROM drum INDEXED BY idx_ins WHERE ins==%d AND density>%d AND density<%d ORDER BY substr(id * 0.%s, length(id) + 2) LIMIT 1]],ins_to_find,density_limits[1],density_limits[2],RANDOMSEED)
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
  query=string.format([[SELECT 'print("'||pid||'"); test_global="ok"' FROM drum WHERE gid in (%s) AND ins==%d AND density>%d AND density<%d ORDER BY substr(id * 0.%s, length(id) + 2) LIMIT 1]],query,ins_to_find,density_limits[1],density_limits[2],RANDOMSEED)
  print(query)

  -- async method
  execute_sql_async(query)
end

function db_random_group(ins_to_find,density_limits)
  local query=string.format([[SELECT "if "||ins||"<=4 then print("||ins||",num_to_pattern("||pid||")) end" FROM drum INDEXED BY idx_gid WHERE gid in (SELECT gid FROM drum INDEXED BY idx_ins WHERE ins==%d AND gdensity>%d AND gdensity<=%d ORDER BY substr(id * 0.%s, length(id) + 2) LIMIT 1)]],ins_to_find,density_limits[1],density_limits[2],RANDOMSEED)
  print(query)

  -- async method
  execute_sql_async(query)
end

function string.split(s,sep)
  local fields={}

  local sep=sep or " "
  local pattern=string.format("([^%s]+)",sep)
  string.gsub(s,pattern,function(c) fields[#fields+1]=c end)

  return fields
end


function db_weighted_random(result)
  local pids={}
  local weights={}
  local total_weight=0
  for line in result:gmatch("%S+") do
    foo=string.split(line,"|")
    pid=tonumber(foo[1])
    weight=tonumber(foo[2])
    table.insert(weights,weight)
    table.insert(pids,pid)
    total_weight=total_weight+weight
  end
  if total_weight==0 then
    print("no results")
    do return end
  end
  --print("found "..#pids.." results")
  local randweight=math.random(0,total_weight-1)
  local pid_new=pids[1]
  for i,w in ipairs(weights) do
    if randweight<w then
      pid_new=pids[i]
      break
    end
    randweight=randweight-w
  end
  return pid_new
end

function db_sql_weighted_(query)
  local result=os.capture(string.format('sqlite3 db.db "%s"',query))
  local pid_new=db_weighted_random(result)
  return pid_new
end

function db_pattern_adj(ins,pid_base,not_pid)
  local query=string.format([[SELECT pid,count(pid) FROM drum INDEXED BY idx_pidadj WHERE ins==%d AND pidadj==%d AND pid!=%d GROUP BY pid ORDER BY count(pid) DESC LIMIT 100]],ins,pid_base,not_pid==nil and-1 or not_pid)
  return db_sql_weighted_(query)
end

function db_pattern_like(ins,ins_base,pid_base,not_pid)
  local query=string.format([[SELECT pid,count(pid) FROM drum INDEXED BY idx_gid WHERE gid in (SELECT gid FROM drum INDEXED BY idx_pid WHERE ins==%d AND pid==%d) AND ins==%d AND pid!=%d GROUP BY pid ORDER BY count(pid) DESC LIMIT 100]],ins_base,pid_base,ins,not_pid==nil and-1 or not_pid)
  return db_sql_weighted_(query)
end


math.randomseed(os.time())
print("RESULTS")
local pp="x---x---x-----x-"
print(pp)
local pid=nil
for i=1,3 do
  pid1=db_pattern_like(2,1,pattern_to_num(pp),pid1)
  print(num_to_pattern(pid1))
end
