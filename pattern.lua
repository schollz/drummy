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
