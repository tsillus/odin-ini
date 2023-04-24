package ini

import "core:strings"
import str "core:strconv"
import os "core:os"
import io "core:io"
import "core:log"
import "core:mem"
import fmt "core:fmt"
import r "core:reflect"
import runtime "core:runtime"


Config :: struct {
	sections: map[string]Section,
	buffer: []byte,
}

Section :: struct {
	title:   string,
	options: map[string]string,
},

ParsedSection :: struct($T: typeid/ParsedSection) {
	parse : proc(^T, Section) -> T,
}

Error :: enum {
	OK, File_Not_Found, Invalid_File_Format, Section_Not_Found,
}

read_ini_file :: proc(filename: string) -> (cfg: Config, err: Error) {
	err = .OK
	ok: bool;
	cfg.buffer, ok = os.read_entire_file_from_filename(filename)
	cfg.sections = make_map(map[string]Section, 4)

	if !ok {
		fmt.eprintln("Could not read file", filename, ": ")
	}

	str_data  := strings.clone_from_bytes(cfg.buffer)
	str_lines := strings.split_lines(str_data)
	

	section : Section;
	for line in str_lines {
		if len(line) == 0 { continue }
		if line[0] == ';' { continue }
		if line[0] == '[' {
			if section.title != "" {
				// TODO: remove println
				cfg.sections[section.title] = section
				section = Section{}	
			}

			section = Section{
				title= strings.trim(line, "[]"),
				options = make_map(map[string]string),
			}
			continue
		}
		if strings.contains_rune(line, '=') != -1 {
			key, _, value := strings.partition(line, "=")
			key            = strings.trim_space(key);
			value          = strings.trim_space(value)
			
			section.options[key] = value
			continue
		}

		fmt.eprintln("Skipped a line: ", line, "\n...")
	}

	if section.title != "" {
		cfg.sections[section.title] = section
	}

	return
}


parse_section :: proc{
	parse_section_simple,
	parse_section_with_parser,
}

/**
 * parses the content of a single section into a given struct T.
 * NOTE: Only int, f64, bool, string are supported for field of $T
**/
parse_section_simple :: proc(section_name: string, cfg: Config, $T: typeid) -> (parsed: T, err: Error) {

	parsed = T{}
	err      = .Section_Not_Found
	section, ok := cfg.sections[section_name]
	if !ok { return parsed, err}
	
	field_names := r.struct_field_names(T)
	for field_name in field_names {
		
		field := r.struct_field_value_by_name(parsed, field_name, true)

		field_type := type_info_of(field.id)
		type_info := runtime.type_info_core(field_type)

		data_value := section.options[field_name]

		if r.is_boolean(field_type) {
			f := &field.(bool)
			f^, _ = str.parse_bool(data_value)
			continue
		}
		if r.is_float(field_type) {
			f := &field.(f64)
			f^ = str.atof(data_value)
			continue
		}
		if r.is_integer(field_type) {
			f := &field.(int)
			f^ = str.atoi(data_value)
			continue
		}
		if r.is_string(field_type) {
			f := &field.(string)
			f^ = data_value
			continue
		}

		err = .Invalid_File_Format
		// TODO: print error message
		fmt.eprintln("Could not parse ", field_name, " to ", field.id, ".")
		return 
		
	}
	return

}

Parser :: struct($T: typeid) {
	section_name : string,
	parse: proc(section: Section) -> (T, Error),
}


parse_section_with_parser :: proc(parser: Parser($T), cfg: Config) -> (parsed: T, err: Error) {
	parsed = T{}
	err = .Section_Not_Found
	section, ok := cfg.sections[parser.section_name]
	if !ok {
		return
	}

	return parser.parse(section)

}



/* tracker: mem.Tracking_Allocator
mem.tracking_allocator_init(&tracker, context.allocator)
defer mem.tracking_allocator_destroy(&tracker)
context.allocator = mem.tracking_allocator(&tracker)
defer if len(tracker.allocation_map) > 0 {
    fmt.eprintln()
    for _, v in tracker.allocation_map {
        fmt.eprintf("%v - leaked %v bytes\n", v.location, v.size)
    }
} */


