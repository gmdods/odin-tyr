package tyr

import "core:c"
import "core:fmt"
import "core:os"
import "core:strings"

foreign import libc "system:c"

stdin_fileno: c.int : 0

tcflag :: c.int
termios :: struct {
	c_iflag: tcflag,
	c_oflag: tcflag,
	c_cflag: tcflag,
	c_lflag: tcflag,
	c_cc:    [32]c.uchar,
}

@(default_calling_convention = "c")
foreign libc {
	tcgetattr :: proc(fd: c.int, term: ^termios) -> c.int ---
	tcsetattr :: proc(fd: c.int, actions: c.int, term: ^termios) -> c.int ---
}

tc_error :: enum {
	none,
	attribute,
}

tc_flush: c.int : 2

terminal := termios{}

rawmode_enter :: proc() -> tc_error {
	if tcgetattr(stdin_fileno, &terminal) == -1 do return tc_error.attribute
	raw := terminal

	// From `man termios`
	raw.c_iflag &~= c.int(0o002753)
	raw.c_oflag &~= c.int(0o000001)
	raw.c_lflag &~= c.int(0o100113)
	raw.c_cflag &~= c.int(0o000460)
	raw.c_cflag |= c.int(0o000060)

	raw.c_cc[5] = 0
	raw.c_cc[6] = 0

	if tcsetattr(stdin_fileno, tc_flush, &raw) == -1 do return tc_error.attribute
	return tc_error.none
}


rawmode_exit :: proc() -> tc_error {
	if tcsetattr(stdin_fileno, tc_flush, &terminal) == -1 do return tc_error.attribute
	return tc_error.none
}

alternative_enter :: proc(fd: os.Handle) {
	fmt.fprintf(fd, "\x1b[?25l")
	fmt.fprintf(fd, "\x1b[s")
	fmt.fprintf(fd, "\x1b[?47h")
}

alternative_exit :: proc(fd: os.Handle) {
	fmt.fprintf(fd, "\x1b[?47l")
	fmt.fprintf(fd, "\x1b[u")
	fmt.fprintf(fd, "\x1b[?25h")
}

cursor_hide :: proc(fd: os.Handle) {
	fmt.fprintf(fd, "\x1b[?25l")
}

cursor_show :: proc(fd: os.Handle) {
	fmt.fprintf(fd, "\x1b[?1049l")
}


cursor_to :: proc(fd: os.Handle, cursor_line: int) {
	/* Interesting SEGFAULT if just use fprintf */
	str: strings.Builder
	strings.write_string(&str, "\x1b[")
	strings.write_int(&str, cursor_line)
	strings.write_string(&str, ";1H")
	fmt.fprintf(fd, strings.to_string(str))
}

cursor_line: int = 0

clear_screen :: proc(fd: os.Handle) {
	cursor_line = 1
	fmt.fprintf(fd, "\x1b[2J")
	cursor_to(fd, cursor_line)
}

newline :: proc(fd: os.Handle) {
	cursor_line += 1
	cursor_to(fd, cursor_line)
}
