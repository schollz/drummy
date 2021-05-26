package main

import (
	"fmt"
	"math"
	"os"
	"path/filepath"
	"sort"

	"github.com/schollz/progressbar/v3"
	"gitlab.com/gomidi/midi/reader"
)

var id int
var gid int
var seen map[string]bool

type Drum struct {
	ID      int
	GID     int
	Ins     int
	Density int
	Fill    int
	PID     int64
	Pattern string
}

func main() {
	seen = make(map[string]bool)
	var err error
	os.Remove("db.sql")
	f, err := os.Create("db.sql")
	if err != nil {
		panic(err)
	}
	defer f.Close()
	f.WriteString(`
CREATE TABLE drum(id INTEGER, gid INTEGER, ins INTEGER, density INTEGER, fill INTEGER, pid INTEGER);
BEGIN;
`)
	for i := 1; i <= 10; i++ {
		err = generate(f, fmt.Sprintf("../drummy2/generated%d", i))
		if err != nil {
			panic(err)
		}
	}
	f.WriteString(`
COMMIT;
CREATE INDEX idx_gid ON drum(gid);
CREATE INDEX idx_pid ON drum(pid);
CREATE INDEX idx_ins ON drum(ins);
`)

}

func generate(f *os.File, folderName string) (err error) {
	fnames, err := filepath.Glob(folderName + "/*.mid")
	if err != nil {
		return
	}
	bar := progressbar.Default(int64(len(fnames)))
	for _, fname := range fnames {
		bar.Add(1)
		drums, err := midiToJSON(fname)
		if err != nil {
			//fmt.Println(err)
			continue
		}
		for _, drum := range drums {
			f.WriteString(fmt.Sprintf("INSERT INTO drum VALUES (%d,%d,%d,%d,%d,%d);\n", drum.ID, drum.GID, drum.Ins, drum.Density, drum.Fill, drum.PID))
		}
	}
	return
}

func midiToJSON(f string) (drums []Drum, err error) {
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

	noteNames := make(map[uint8]int)
	noteNames[36] = 1  //"kick"
	noteNames[35] = 1  // bass drum /kick
	noteNames[40] = 2  // "electric sd"
	noteNames[38] = 2  //"sd"
	noteNames[37] = 2  //"sd stick"
	noteNames[42] = 3  //"ch/hh"
	noteNames[44] = 3  //"ch/hh"
	noteNames[46] = 4  //"oh"
	noteNames[49] = 5  //"cc"
	noteNames[57] = 5  //"cc"
	noteNames[51] = 6  //"rc"
	noteNames[45] = 7  //"lt"
	noteNames[48] = 8  //"mt"
	noteNames[50] = 9  //"ht"
	noteNames[39] = 10 //"clap"
	noteNames[69] = 10 //"cabasa"
	noteNames[82] = 11 //"shaker"
	noteNames[53] = 12 //"bell"
	noteNames[56] = 12 //"cowbell"
	noteNames[54] = 13 //"tamborine"
	startGID := gid
	startID := id
	gid += 1
	drums = make([]Drum, len(notes))
	fulltrack := ""
	for i, note := range notes {
		id += 1
		s := ""
		xs := 0
		for _, v := range tracks[note] {
			if v {
				s += "x"
				xs += 1
			} else {
				s += "-"
			}
		}
		if _, ok := noteNames[note]; !ok {
			err = fmt.Errorf("no name for note %v", note)
			return
		}
		fulltrack += fmt.Sprintf("%d%s", noteNames[note], s)
		drums[i] = Drum{
			ID:      id,
			GID:     gid,
			Ins:     noteNames[note],
			Density: xs * 100 / len(tracks[note]),
			Fill:    0,
			Pattern: s,
			PID:     PatternToInt(s),
		}
	}
	if _, ok := seen[fulltrack]; ok {
		// reset ids
		gid = startGID
		id = startID
		err = fmt.Errorf("already have this one: %s", fulltrack)
		return
	}
	seen[fulltrack] = true
	return
}

func PatternToInt(pattern string) (pid int64) {
	for j, v := range pattern {
		if string(v) == "x" {
			pid = pid + int64(math.Pow(2, float64(j)))
		}
	}
	return
}
