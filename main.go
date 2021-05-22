package main

import (
	"fmt"
	"sort"

	"gitlab.com/gomidi/midi/reader"
)

func main() {
	f := "generated/cat-drums_2bar_small_sample_2021-05-22_064043-000-of-005.mid"

	tracks := make(map[uint8][]bool)
	// to disable logging, pass mid.NoLogger() as option
	rd := reader.New(reader.NoLogger(),
		// set the functions for the messages you are interested in
		reader.NoteOn(func(p *reader.Position, channel, key, vel uint8) {
			if _, ok := tracks[key]; !ok {
				tracks[key] = make([]bool, 16)
			}
			pos := int(float64(p.AbsoluteTicks)/1760.0*16.0 + 1)
			tracks[key][pos-1] = true
			// fmt.Printf("Track: %v Pos: %2.1f NoteOn (ch %v: key %v vel: %v)\n", p.Track, float64(p.AbsoluteTicks)/1760.0*16.0+1, channel, key, vel)
		}),
		// reader.NoteOff(func(p *reader.Position, channel, key, vel uint8) {
		// 	fmt.Printf("Track: %v Pos: %v NoteOff (ch %v: key %v)\n", p.Track, p.AbsoluteTicks, channel, key)
		// }),
	)

	err := reader.ReadSMFFile(rd, f)

	if err != nil {
		fmt.Printf("could not read SMF file %v\n", f)
	}

	notes := []uint8{}
	for note, _ := range tracks {
		notes = append(notes, note)
	}
	sort.Slice(notes, func(i, j int) bool { return notes[i] < notes[j] })

	noteNames := make(map[uint8]string)
	noteNames[36] = "kick"
	noteNames[38] = "sd"
	noteNames[42] = "ch"
	noteNames[49] = "cc"
	noteNames[46] = "oh"
	noteNames[45] = "lt"
	noteNames[48] = "mt"
	noteNames[50] = "ht"
	noteNames[51] = "rc"
	for _, note := range notes {
		s := ""
		for _, v := range tracks[note] {
			if v {
				s += "x"
			} else {
				s += "-"
			}
		}
		fmt.Println(note, noteNames[note])
		fmt.Println(s)
	}
}
