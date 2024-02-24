package tyr

import "core:io"
import "core:os"

key :: distinct u8
escape :: distinct u8

cmd :: enum u8 {
	EOF,
	ENTER,
	SPACE,
	BACKSPACE,
	ESC,
	UP,
	DOWN,
	LEFT,
	RIGHT,
}

event :: union #no_nil {
	cmd,
	key,
	escape,
}

poll :: proc(s: io.Stream) -> event {

	b, err := io.read_byte(s)
	if err == .EOF do return event(cmd.EOF)
	switch b {
	case ' ':
		return event(cmd.SPACE)
	case '\n', '\r':
		return event(cmd.ENTER)
	case '\x7f':
		return event(cmd.BACKSPACE)
	case '\x1b':
		b, err = io.read_byte(s)
		if err == .EOF do return event(cmd.ESC)
		if b != '\x5b' do return event(key(b))

		b, err = io.read_byte(s)
		if err == .EOF do return event(cmd.EOF)
		switch b {
		case 'A':
			return event(cmd.UP)
		case 'B':
			return event(cmd.DOWN)
		case 'C':
			return event(cmd.RIGHT)
		case 'D':
			return event(cmd.LEFT)
		case:
			return event(escape(b))
		}
	case:
		return event(key(b))
	}

}
