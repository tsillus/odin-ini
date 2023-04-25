package ini


// TODO:(tsi) [X] section names case insensitive
// TODO:(tsi) [X] section fields case insensitive
// TODO:(tsi) [X] parse yes/no/y/n to bool as well
// TODO:(tsi) [ ] fix memory leaks

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
	buffer:   []byte,
}

Section :: struct {
	title:   string,
	options: map[string]string,
}

Parser :: struct($T: typeid) {
	section_name: string,
	parse:        proc(section: Section) -> (T, Error),
}

Error :: enum {
	OK,
	File_Not_Found,
	Invalid_File_Format,
    Invalid_Struct_Format,
	Section_Not_Found,
}

delete_config :: proc(cfg: Config) {
    
    delete_map(cfg.sections)
    delete_slice(cfg.buffer)

}

ini_arena: mem.Arena


read_ini_file :: proc(filename: string) -> (cfg: Config, err: Error) {
    
	mem.arena_init(&ini_arena, make([]u8, os.file_size_from_path(filename)*32))
	context.allocator = mem.arena_allocator(&ini_arena)

    err = .OK
	ok: bool
	cfg.buffer, ok = os.read_entire_file_from_filename(filename)
	cfg.sections = make_map(map[string]Section, 4)

	if !ok {
		fmt.eprintln("Could not read file", filename, ": ")
	}

	str_data := strings.clone_from_bytes(cfg.buffer)
    defer delete_string(str_data)
	str_lines := strings.split_lines(str_data)


	section: Section
	for line in str_lines {
		if len(line) == 0 {continue}
		if line[0] == ';' {continue}
		if line[0] == '[' {
			if section.title != "" {
				cfg.sections[section.title] = section
				section = Section{}
			}
            
            t := strings.to_lower(line)
            t = strings.trim(t, "[]")

			section = Section {
				title   = t,
				options = make_map(map[string]string),
			}
			continue
		}
		if strings.contains_rune(line, '=') != -1 {
			key, _, value := strings.partition(line, "=")
			key = strings.trim_space(key)
            key = strings.to_lower(key)
			value = strings.trim_space(value)

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


parse_bool :: proc(data: string) -> (result:bool, ok:bool) {

    switch data {
        case "y", "Y", "yes", "Yes", "YES":
            return true, true
        case "n", "N", "no", "No", "NO":
            return false, true
        case:
            return str.parse_bool(data)
    }

}


parse_section :: proc {
	parse_section_by_type,
	parse_section_by_parser,
    parse_section_by_instance,
}


parse_section_by_instance :: proc(cfg: Config, section_name_: string, section_struct_ptr: ^$T) -> (section_struct: T, err: Error) {
    context.allocator = mem.arena_allocator(&ini_arena)
    section_name := strings.to_lower(section_name_)
    section_struct = section_struct_ptr^
	section, ok := cfg.sections[section_name]
	if !ok {
        fmt.eprintln("Could not find section '", section_name, "'.", cfg.sections)
        
        return section_struct, .Section_Not_Found
    }

	field_names := r.struct_field_names(T)
    err = .Invalid_File_Format   
	for field_name_ in field_names {
        field_name := strings.to_lower(field_name_)
		data_value, ok := section.options[field_name]
		if !ok {
            // We allow for fields to not exist in the ini file.
            // This way the given instance can contain default values.
			continue
		}

		field := r.struct_field_value_by_name(section_struct, field_name, true)

		field_type := type_info_of(field.id)


		if r.is_boolean(field_type) {
			b, ok := str.parse_bool(data_value)
            if !ok {return}
			assign_bool(&field, b)
			continue
		}
		if r.is_float(field_type) {
            f, ok := str.parse_f64(data_value)
            if !ok {return}
			assign_float(&field, f)
			continue
		}
		if r.is_integer(field_type) {
            i, ok := str.parse_int(data_value)
            if !ok {return}
			assign_integer(&field, i)
			continue
		}
        // Some people put string literal around their strings in .ini files.
        // We remove them here so they don't end up in the data.
        data_value = strings.trim(data_value, `"'`)
        
		if r.is_string(field_type) {
			f := &field.(string)
			f^ = data_value
			continue
		}
		if r.is_rune(field_type) {
			f := &field.(rune)
			f^ = rune(data_value[0])
			continue
		}

		fmt.eprintln("Could not parse ", data_value, " to ", field_type, "for field", field_name)
		return section_struct, .Invalid_Struct_Format 

	}

    return section_struct, .OK
}

/**
 * parses the content of a single section into a given struct T.
 * NOTE  Only integers, floats, booleans, strings, and runes are supported for fields of $T. Other types won't be assigned.
*/
parse_section_by_type :: proc(cfg: Config, section_name: string, $T: typeid) -> (parsed: T, err: Error) {
    
    context.allocator = mem.arena_allocator(&ini_arena)
	parsed = T{}
	err = .Section_Not_Found
	return parse_section_by_instance(cfg, section_name, &parsed)

}



parse_section_by_parser :: proc(cfg: Config, parser: Parser($T)) -> (parsed: T, err: Error) {
    context.allocator = mem.arena_allocator(&ini_arena)
	parsed = T{}
	err = .Section_Not_Found

    section_name := strings.to_lower(parser.section_name)
	section, ok := cfg.sections[section_name]
	if !ok {
		return
	}

	return parser.parse(section)

}


/* 
tracker: mem.Tracking_Allocator
mem.tracking_allocator_init(&tracker, context.allocator)
defer mem.tracking_allocator_destroy(&tracker)
context.allocator = mem.tracking_allocator(&tracker)
defer if len(tracker.allocation_map) > 0 {
    fmt.eprintln()
    for _, v in tracker.allocation_map {
        fmt.eprintf("%v - leaked %v bytes\n", v.location, v.size)
    }
} 
*/
