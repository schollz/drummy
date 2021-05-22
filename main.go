package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/schollz/progressbar/v3"
	"gitlab.com/gomidi/midi/reader"
)

func main() {
	var err error
	for i := 1; i <= 10; i++ {
		err = generate(fmt.Sprintf("generated%d", i))
		if err != nil {
			panic(err)
		}
	}

}

func generate(folderName string) (err error) {
	fnames, err := filepath.Glob(folderName + "/*.mid")
	if err != nil {
		return
	}
	f, err := os.Create(folderName + "/patterns.json")
	if err != nil {
		return
	}
	defer f.Close()
	bar := progressbar.Default(int64(len(fnames)))
	for _, fname := range fnames {
		bar.Add(1)
		jsonData, err := midiToJSON(fname)
		if err != nil {
			fmt.Println(err)
		}
		f.WriteString(jsonData)
		f.WriteString("\n")
	}
	return
}

func midiToJSON(f string) (jsonData string, err error) {
	tracks := make(map[uint8][]bool)
	// to disable logging, pass mid.NoLogger() as option
	rd := reader.New(reader.NoLogger(),
		// set the functions for the messages you are interested in
		reader.NoteOn(func(p *reader.Position, channel, key, vel uint8) {
			if _, ok := tracks[key]; !ok {
				tracks[key] = make([]bool, 32)
			}
			pos := float64(p.AbsoluteTicks) / 1760.0 * 32.0
			tracks[key][int(pos)] = true
			// fmt.Printf("Track: %v Pos: %2.1f NoteOn (ch %v: key %v vel: %v)\n", p.Track, pos, channel, key, vel)
		}),
		// reader.NoteOff(func(p *reader.Position, channel, key, vel uint8) {
		// 	fmt.Printf("Track: %v Pos: %v NoteOff (ch %v: key %v)\n", p.Track, p.AbsoluteTicks, channel, key)
		// }),
	)

	err = reader.ReadSMFFile(rd, f)
	if err != nil {
		return
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
	data := make(map[string]string)
	for _, note := range notes {
		s := ""
		for _, v := range tracks[note] {
			if v {
				s += "x"
			} else {
				s += "-"
			}
		}
		if _, ok := noteNames[note]; !ok {
			err = fmt.Errorf("no name for note %v", note)
			return
		}
		// fmt.Println(note, noteNames[note])
		// fmt.Println(s)
		data[noteNames[note]] = s
	}
	b, err := json.Marshal(data)
	if err != nil {
		return
	}
	jsonData = string(b)
	return
}
