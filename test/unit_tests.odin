package test

import "core:mem"
import virtual "core:mem/virtual"
import "core:fmt"
import "core:testing"
import "core:strings"
import str "core:strconv"
import path "core:path/filepath"
import r "core:reflect"

import ini ".."

First :: struct {
	int_value:     int,
	str_value:     string,
	bool_value:    bool,
	float_value:   f64,
	default_value: u8,
}

Second :: struct {
	path:          string,
	file_name:     string,
	separator:     rune,
	exit_on_error: bool,
}

Configuration :: struct {
	first:  First,
	second: Second,
}


TEST_INI :: "./test/test.ini"

@(test)
test_read_ini_basic_usage :: proc(tester: ^testing.T) {

	using ini
	ini_file_name, _ := path.abs("./test/test.ini")
    config: Configuration
	{
		cfg, err := read_ini_file(ini_file_name)

		testing.expect_value(tester, err, Error.OK)
		testing.expect_value(tester, len(cfg.sections), 2)

		config = Configuration {
			// Initialize your config with default values. 
			first = First{default_value = 37},
			second = Second{},
		}

		err_first := parse_section(cfg, "First section", &(config.first))
		err_second := parse_section(cfg, "Second Section", &(config.second))

        testing.expect_value(tester, err_first, Error.OK)
        testing.expect_value(tester, err_second, Error.OK)
	}

	testing.expect_value(tester, config.first.bool_value, true)
	testing.expect_value(tester, config.first.default_value, 37) // Default Values stay.
	testing.expect_value(tester, config.first.str_value, "text")
	testing.expect_value(tester, config.first.int_value, 1)
	testing.expect_value(tester, config.first.float_value, 3.7)

}


@(test)
test_assign_to_integer :: proc(tester: ^testing.T) {

	using ini
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

	using ini

	tracker: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracker, context.allocator)
	defer mem.tracking_allocator_destroy(&tracker)
	context.allocator = mem.tracking_allocator(&tracker)
	defer if len(tracker.allocation_map) > 0 {

		sum: int = 0

		for _, v in tracker.allocation_map {
			fmt.eprintf("%v - leaked %v bytes\n", v.location, v.size)
			sum += v.size
		}
		testing.expect_value(tester, sum, 0)

	}

	ini_file_name, _ := path.abs("./test/test.ini")
	defer delete_string(ini_file_name)
	cfg, err := read_ini_file(ini_file_name)
	defer delete_config(cfg)

	config := Configuration{}
	err_first := parse_section(cfg, "first section", &(config.first))
	err_second := parse_section(cfg, "second Section", &(config.second))

}
