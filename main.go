package main

import (
	"fmt"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/schollz/progressbar/v3"
	"gitlab.com/gomidi/midi/reader"
)

var id int
var gid int
var seen map[string]bool
var noteNames map[uint8]int

func init() {
	noteNames = make(map[uint8]int)
	noteNames[36] = 1  //"kick"
	noteNames[35] = 1  // bass drum /kick
	noteNames[40] = 2  // "electric sd"
	noteNames[38] = 2  //"sd"
	noteNames[37] = 2  //"sd stick"
	noteNames[42] = 3  //"ch/hh"
	noteNames[44] = 3  //"ch/hh"
	noteNames[46] = 4  //"oh"
	noteNames[51] = 5  //"rc"
	noteNames[49] = 6  //"cc"
	noteNames[57] = 6  //"cc"
	noteNames[45] = 7  //"lt"
	noteNames[48] = 8  //"mt"
	noteNames[50] = 9  //"ht"
	noteNames[39] = 10 //"clap"
	noteNames[69] = 10 //"cabasa"
	noteNames[82] = 11 //"shaker"
	noteNames[53] = 12 //"bell"
	noteNames[56] = 12 //"cowbell"
	noteNames[54] = 13 //"tamborine"
}

type Drum struct {
	ID       int
	GID      int
	Ins      int
	Density  int
	GDensity int
	Fill     int
	PID      int64
	PIDAdj   int64
	Pattern  string
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
CREATE TABLE drum(id INTEGER, gid INTEGER, ins INTEGER, density INTEGER, pid INTEGER, pidadj INTEGER);
BEGIN;
`)
	for i := 1; i <= 10; i++ {
		err = generate(f, fmt.Sprintf("../drummy2/generated%d", i))
		if err != nil {
			fmt.Println(err)
		}
	}
	f.WriteString(`
COMMIT;
CREATE INDEX idx_gid ON drum(gid);
CREATE INDEX idx_pid ON drum(pid);
CREATE INDEX idx_pidadj ON drum(pidadj);
CREATE INDEX idx_ins ON drum(ins);
`)

}

func generate(f *os.File, folderName string) (err error) {
	fnames, err := filepath.Glob(folderName + "/*.mid")
	if err != nil {
		return
	}
	bar := progressbar.Default(int64(len(fnames)))
	for i, fname := range fnames {
		_ = i
		bar.Add(1)
		var drums []Drum
		drums, err = midiToJSON(fname)
		if err != nil {
			//fmt.Println(err)
			continue
		}
		// fmt.Printf("drums: %+v\n", drums)
		// if i > 10 {
		// 	return
		// }
		for _, drum := range drums {
			f.WriteString(fmt.Sprintf("INSERT INTO drum VALUES (%d,%d,%d,%d,%d,%d);\n", drum.ID, drum.GID, drum.Ins, drum.Density, drum.PID, drum.PIDAdj))
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
		}),
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

	startGID := gid
	startID := id
	gid += 1
	drums = make([]Drum, len(notes))
	fulltrack := ""
	i := 0
	for _, note := range notes {
		if noteNames[note] > 5 {
			continue
		}
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
			Density: xs * 16 / len(tracks[note]),
			Fill:    0,
			Pattern: s,
			PID:     PatternToInt(s),
		}
		i++
	}
	drums = drums[:i]
	gdensity := 0
	for _, drum := range drums {
		gdensity += drum.Density
	}
	for i, _ := range drums {
		drums[i].GDensity = gdensity / len(drums)
	}

	_, alreadyHave := seen[fulltrack]
	if alreadyHave || len(drums) < 2 {
		// reset ids
		gid = startGID
		id = startID
		err = fmt.Errorf("already have this one: %s", fulltrack)
		return
	} else {
		seen[fulltrack] = true
	}

	// split into individual bars
	drums2 := make([]Drum, len(drums))
	copy(drums2, drums)

	gid += 1
	for i, _ := range drums2 {
		id += 1
		drums2[i].ID = id
		drums2[i].GID = gid
		drums2[i].Pattern = drums[i].Pattern[16:]
		drums2[i].PID = PatternToInt(drums2[i].Pattern)
		drums2[i].Density = strings.Count(drums2[i].Pattern, "x")
	}

	for i, _ := range drums {
		drums[i].Pattern = drums[i].Pattern[:16]
		drums[i].PID = PatternToInt(drums[i].Pattern)
		drums[i].Density = strings.Count(drums[i].Pattern, "x")
	}

	for i, _ := range drums {
		drums[i].PIDAdj = drums2[i].PID
	}

	for i, _ := range drums2 {
		drums2[i].PIDAdj = drums[i].PID
	}

	drums = append(drums, drums2...)

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
