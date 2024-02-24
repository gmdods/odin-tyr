package tyr_list

import "core:fmt"
import "core:io"
import "core:os"

import tyr "../"

main :: proc() {
	stdin := os.stream_from_handle(os.stdin)
	defer fmt.printf("Exiting...\r\n")

	list := []string{"Integrate termios", "Write examples", "Develop Tyr", "Check portability"}
	cursor := 0

	defer if cursor < 0 {
		fmt.printf("Next time then.\n")
	} else {
		fmt.printf(list[cursor])
		fmt.printf(" is selected!\n")
	}

	if err := tyr.rawmode_enter(); err != tyr.tc_error.none {
		fmt.eprintf("%v\r\n", err)
		cursor = -1
		return
	}
	defer tyr.rawmode_exit()

	tyr.alternative_enter(os.stdout)
	defer tyr.alternative_exit(os.stdout)

	tyr.cursor_hide(os.stdout)
	defer tyr.cursor_show(os.stdout)

	tyr.clear_screen(os.stdout)
	for {
		defer tyr.clear_screen(os.stdout)
		for t, i in list {
			fmt.printf("\t[")
			os.write_rune(os.stdout, (i == cursor) ? 'x' : ' ')
			fmt.printf("] ")
			fmt.printf(t)
			tyr.newline(os.stdout)
		}
		tyr.newline(os.stdout)
		fmt.printf("Move UP or DOWN to select.")
		tyr.newline(os.stdout)

		e := tyr.poll(stdin)
		switch e {
		case tyr.key(3), tyr.key(4), tyr.key('q'), tyr.cmd.EOF, tyr.cmd.ESC:
			cursor = -1
			return
		case tyr.cmd.ENTER:
			return
		case tyr.cmd.UP:
			cursor -= 1
			if cursor < 0 do cursor = 0
		case tyr.cmd.DOWN:
			cursor += 1
			if cursor >= len(list) do cursor = len(list)
		case:
		}

	}

}
