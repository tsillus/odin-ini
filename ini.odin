package ini

VERSION :: "0.1.0"

import "core:strings"
import str "core:strconv"
import os "core:os"
import io "core:io"
import "core:log"
import "core:mem"
import virtual "core:mem/virtual"
import fmt "core:fmt"
import r "core:reflect"
import runtime "core:runtime"


Config :: struct {
	sections: map[string]Section,
	buffer:   []byte,
    text: string,
}

Section :: struct {
	title:   string,
	options: map[string]string,
}

Error :: enum {
	OK,
	File_Not_Found,
	Invalid_File_Format,
    Invalid_Struct_Format,
	Section_Not_Found,
}


delete_config :: proc(cfg: Config) {
    for name, section in cfg.sections {
        for key, option in section.options {
            delete(key)
        }
        delete(section.options)
        delete(section.title)
    }
    delete(cfg.sections)
    delete(cfg.buffer)
    delete(cfg.text)

}


read_ini_file :: proc(filename: string, allocator := context.allocator) -> (cfg: Config, err: Error) {
    context.allocator = allocator
    err = .OK
	ok: bool
	cfg.buffer, ok = os.read_entire_file_from_filename(filename)
	cfg.sections = make_map(map[string]Section, 4)

	if !ok {
		fmt.eprintln("Could not read file", filename, ".")
        return cfg, .File_Not_Found
	}

	cfg.text = strings.clone_from_bytes(cfg.buffer)
    //defer delete_string(str_data)
	str_lines := strings.split_lines(cfg.text)
    defer delete_slice(str_lines)

	section: Section
	for line in str_lines {
		if len(line) == 0 {continue}
		if line[0] == ';' {continue}
		if line[0] == '[' {
            if section.title != "" {

                cfg.sections[section.title] = section
                section = Section{}
            }

            t := strings.trim(line, "[]")
            t = strings.to_lower(t)

            section = Section {
                title   = t,
                options = make_map(map[string]string),
            }
            continue
		}
		if strings.contains_rune(line, '=') { // != -1 {
			key, _, value := strings.partition(line, "=")
			key = strings.trim_space(key)
            key = strings.to_lower(key)
			value = strings.trim_space(value)

			section.options[key] = value
			continue
		}

//		fmt.eprintln("Skipped a line: ", line, "\n...")
	}

	if section.title != "" {
		cfg.sections[section.title] = section
	}

	return cfg, .OK
}

parse_section :: proc {
	parse_section_by_type,
    parse_section_by_instance,
}


/**
*   parses a single section from cfg into section_struct. 
*/
parse_section_by_instance :: proc(cfg: Config, section_name: string, section_struct: ^$T) -> (err: Error) {
    lower_case_section_name := strings.to_lower(section_name)
    defer delete_string(lower_case_section_name)

	section, ok := cfg.sections[lower_case_section_name]
	if !ok {
        //fmt.eprintln("Could not find section '", lower_case_section_name, "'.", cfg.sections)
        
        return .Section_Not_Found
    }

	field_names := r.struct_field_names(T)
    err = .Invalid_File_Format   
	for field_name_ in field_names {
        field_name := strings.to_lower(field_name_)
        defer delete_string(field_name)
		data_value, ok := section.options[field_name]
		if !ok {
            // We allow for fields to not exist in the ini file.
            // This way the given instance can contain default values.
			continue
		}

		field := r.struct_field_value_by_name(section_struct^, field_name, true)

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

		//fmt.eprintln("Could not parse ", data_value, " to ", field_type, "for field", field_name)
		return .Invalid_Struct_Format 

	}

    return .OK
}

/**
 * parses the content of a single section into a given struct T.
 * NOTE  Only integers, floats, booleans, strings, and runes are supported for fields of $T. Other types won't be assigned.
*/
parse_section_by_type :: proc(cfg: Config, section_name: string, $T: typeid) -> (parsed: T, err: Error) {
 
	parsed = T{}
	err = .Section_Not_Found
	err = parse_section_by_instance(cfg, section_name, &parsed)
    return 

}

