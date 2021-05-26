package main

import (
	"fmt"
	"testing"
)

func TestExample1(t *testing.T) {
	fmt.Println(PatternToInt("--x---x---x---x---x---x---x---x-"))
	fmt.Println(PatternToInt("--x---x---x---x---x---x---x---xx"))
	// Output: 1145324612
	// 3292808260
}
