package ini

import "core:mem"
import "core:fmt"
import "core:testing"
import "core:strings"
import str "core:strconv"
import path "core:path/filepath"


First :: struct {
	int_value:   int,
	str_value:   string,
	bool_value:  bool,
	float_value: f64,
}

Second :: struct {
	path:          string,
	file_name:     string,
	separator:     rune,
	exit_on_error: bool,
}

Configuration :: struct {
    first: First,
    second: Second,
}

@(test)
test_read_ini_simple :: proc(tester: ^testing.T) {

	ini_file_name, _ := path.abs("./test/test.ini")

	cfg, err := read_ini_file(ini_file_name)

	testing.expect_value(tester, err, Error.OK)
	testing.expect_value(tester, len(cfg.sections), 2)

    config := Configuration{}

    err_first, err_second: Error
    config.first,  err_first =  parse_section(cfg, "first section", &(config.first))
    config.second, err_second = parse_section(cfg, "second Section", &(config.second))

    testing.expect_value(tester, err_first, Error.OK)
    testing.expect_value(tester, err_second, Error.OK )

	//testing.expect_value(tester, config.first.bool_value, true)
	testing.expect_value(tester, config.first.str_value, "text")
	testing.expect_value(tester, config.first.int_value, 1)
	testing.expect_value(tester, config.first.float_value, 3.7)

}

parse_func :: proc(section: Section) -> (Second, Error) {
	second := Second{}

	second.path = section.options["path"] or_else "."
	second.file_name = section.options["file_name"] or_else ""
	second.separator = rune((section.options["separator"] or_else ";")[0])
	second.exit_on_error = str.parse_bool(section.options["exit_on_error"]) or_else false

	return second, .OK
}

@(test)
test_read_ini_with_parser :: proc(tester: ^testing.T) {

	parser := Parser(Second) {
		section_name = "second Section",
		parse        = parse_func,
	}

	ini_file_name, _ := path.abs("./test/test.ini")
	cfg, err := read_ini_file(ini_file_name)

	second, parse_err := parse_section(cfg, parser)

	testing.expect_value(tester, second.path, ".")
	testing.expect_value(tester, second.file_name, "test.csv")
	testing.expect_value(tester, second.separator, '#')

}

import r "core:reflect"

@(test)
test_assign_to_integer :: proc(tester: ^testing.T) {
	int8: i8
	uint8: u8

	a := r.any_core(int8)
	b := r.any_core(uint8)

	testing.expect(tester, assign_integer(&a, 1023), "failed assigning a value to i8")
	testing.expect(tester, assign_integer(&b, 1023), "failed assigning a value to u8")

	testing.expect_value(tester, int8, -1)
	testing.expect_value(tester, uint8, 255)

}

@(test)
test_memory_safety :: proc(tester: ^testing.T) {
    
    tracker: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracker, context.allocator)
    defer mem.tracking_allocator_destroy(&tracker)
    context.allocator = mem.tracking_allocator(&tracker)
    defer if len(tracker.allocation_map) > 0 {
        fmt.eprintln()
        for _, v in tracker.allocation_map {
            fmt.eprintf("%v - leaked %v bytes\n", v.location, v.size)
        }
        tester._fail_now()
    }

	ini_file_name, _ := path.abs("./test/test.ini")
	cfg, err := read_ini_file(ini_file_name)

    defer delete_string(ini_file_name)
    defer delete_config(cfg)

    //config := Configuration{}

    //err_first, err_second: Error
    //config.first,  err_first =  parse_section(cfg, "first section", &(config.first))
    //config.second, err_second = parse_section(cfg, "second Section", &(config.second))

}

