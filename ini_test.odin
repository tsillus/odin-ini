package ini

import "core:fmt"
import "core:testing"
import "core:strings"
import str "core:strconv"
import path "core:path/filepath"


First :: struct {
	int_value : int,
	str_value : string,
	bool_value : bool,
	float_value: f64,
}

Second :: struct {
	path: string,
	file_name: string,
	separator: rune,
	exit_on_error: bool,
}

@(test)
test_read_ini_simple ::proc(tester: ^testing.T) {

	ini_file_name, _ := path.abs("./test/test.ini")

	cfg, err := read_ini_file(ini_file_name)

	testing.expect_value(tester, err, Error.OK)
	testing.expect_value(tester, len(cfg.sections), 2)

	first, _ := parse_section("first Section", cfg, First)

	testing.expect_value(tester, first.bool_value, true)
	testing.expect_value(tester, first.str_value, "text")
	testing.expect_value(tester, first.int_value, 1)
	testing.expect_value(tester, first.float_value, 3.7)

}

parse_func :: proc(section: Section) -> (Second, Error) {
	second := Second{}
	second.path      = section.options["path"]       or_else "."
	second.file_name = section.options["file_name"]  or_else ""
	second.separator = rune((section.options["separator"] or_else ";")[0])
	second.exit_on_error = str.parse_bool(section.options["exit_on_error"]) or_else false

	return second, .OK
}

@(test)
test_read_ini_with_parser ::proc(tester: ^testing.T) {

	parser := Parser(Second) {
		section_name = "second Section",
		parse = parse_func,
			
	}

	ini_file_name, _ := path.abs("./test/test.ini")
	cfg, err := read_ini_file(ini_file_name)

	second, parse_err := parse_section(parser, cfg)

	testing.expect_value(tester, second.path, "." )
	testing.expect_value(tester, second.file_name, "test.csv" )
	testing.expect_value(tester, second.separator, '#' )

}


/* @(test)
test_create_section_with_options :: proc(tester: ^testing.T) {

	section := make_section("section Title")
	defer destroy_section(&section)
	add_option(&section, Option{"name", "value"})

	testing.expect_value(tester, section.title, "section Title")
	testing.expect_value(tester, section.options[0].key, "name")
	testing.expect_value(tester, section.options[0].value, "value")
}

@(test)
test_parses_string_into_structs :: proc(tester: ^testing.T) {
	sections := [dynamic]Section{}
	defer {
		for _, i in sections {
			destroy_section(&sections[i])
		}
		delete(sections)
	}

	count_section := parse_into_sections(TEST_SECTION, &sections)

	s0_options := sections[0].options
	s1_options := sections[1].options

	testing.expect_value(tester, len(sections), 2)
	testing.expect_value(tester, count_section, 2)


	testing.expect_value(tester, len(s0_options), 2)
	testing.expect_value(tester, len(s1_options), 3)

}

@(test)
test_parses_values_into_types :: proc(tester: ^testing.T) {
	sections := [dynamic]Section{}
	defer {
		for _, i in sections {
			destroy_section(&sections[i])
		}
		delete(sections)
	}

	count_section := parse_into_sections(TEST_SECTION, &sections)

	s1_options := sections[1].options

	int_value, is_int := s1_options[0].value.(int)
	str_value, is_str := s1_options[1].value.(string)
	bool_value, is_bool := s1_options[2].value.(bool)

	testing.expect(tester, is_int, "int_value is not an int!")
	testing.expect_value(tester, int_value, 1337)

	testing.expect(tester, is_str, "str_value is not a string!")
	testing.expect_value(tester, str_value, `"text"`)

	testing.expect(tester, is_bool, "bool_value is not a bool!")
	testing.expect_value(tester, bool_value, false)

}

@(test)
test_read_Sections_from_file :: proc(tester: ^testing.T) {
	// sections := [dynamic]Section{}
	// defer {
	// 	for _, i in sections {
	// 		destroy_section(&sections[i])
	// 	}
	// 	delete(sections)
	// }

	cfg, found := read_ini_file("nonexistant.ini")
	sections := cfg.sections
	testing.expect_value(tester, found, false)
	destroy_config(&cfg)

	cfg, found = read_ini_file("test/test.ini")
	defer destroy_config(&cfg)
	testing.expect_value(tester, found, true)

	sections = cfg.sections

	testing.expect_value(tester, len(sections), 2)

	s0 := sections[0]
	s1 := sections[1]

	testing.expect_value(tester, len(s0.options), 2)
	testing.expect_value(tester, len(s1.options), 3)

}

@(test)
test_access_Sections_and_value :: proc(tester: ^testing.T) {
	cfg, found := read_ini_file("test/test.ini")
	defer destroy_config(&cfg)

	sections := cfg.sections

	testing.expect_value(tester, len(sections), 2)
	testing.expect_value(tester, len(sections[0].options), 2)

	options, _ := get_options("first Section", &sections)
	testing.expect_value(tester, len(options), 2)

	value, _ := get_value_from_section("second Section", "int_value", &sections)
	testing.expect_value(tester, value, 1337)
}

@(test)
test_invalid_file ::proc(tester: ^testing.T) {
	cfg, found := read_ini_file("test/wrong.ini")
	defer destroy_config(&cfg)

	testing.expect_value(tester, found, true)
	

} */