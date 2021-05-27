package main

import (
	"fmt"
)

func Example1() {
	fmt.Println(PatternToInt("x---x---x---x---"))
	// Output: 4369
}

// sqlite3 db.db "SELECT pid,count(pid) FROM drum INDEXED BY idx_gid WHERE gid in (SELECT gid FROM drum INDEXED BY idx_pid WHERE ins==1 AND pid==16385) AND ins==2 GROUP BY pid ORDER BY count(pid) DESC LIMIT 50"
