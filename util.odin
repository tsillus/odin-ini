package ini


import str "core:strconv"

/*
 *  assigns a bool value to a target of "any" type that originally is a boolean variable.
 *
 *  Note that information may get lost when assigning to type smaller that f64.
 *
 *  returns true if assignment was successful
 */
assign_bool :: proc(target: ^any, value: bool) -> (ok: bool) {

	switch type in target^ {

	case bool:
		t := &target.(bool)
		t^ = bool(value)
	case b8:
		t := &target.(b8)
		t^ = b8(value)
	case b16:
		t := &target.(b16)
		t^ = b16(value)
	case b32:
		t := &target.(b32)
		t^ = b32(value)
	case b64:
		t := &target.(b64)
		t^ = b64(value)
	case:
		return false
	}
	return true
}


/*
 * extends strconv.parse_bool to also accept Yes/No, Y/N and variants
 */
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


/*
 *  assigns a f64 value to a target of "any" type that originally is a floating point variable.
 *
 *  Note that information may get lost when assigning to type smaller that f64.
 *
 *  returns true if assignment was successful
 */
assign_float :: proc(target: ^any, value: f64) -> (ok: bool) {

	switch type in target^ {
	case f16:
		t := &target.(f16)
		t^ = f16(value)
	case f32:
		t := &target.(f32)
		t^ = f32(value)
	case f64:
		t := &target.(f64)
		t^ = f64(value)

	case f32le:
		t := &target.(f32le)
		t^ = f32le(value)
	case f64le:
		t := &target.(f64le)
		t^ = f64le(value)
	case f32be:
		t := &target.(f32be)
		t^ = f32be(value)
	case f64be:
		t := &target.(f64be)
		t^ = f64be(value)

	case:
		return false
	}
	return true
}

/*
 *  assigns an i64 value to a target of "any" type that originally is an integer variable.
 *
 *  Note that information may get lost when assigning to type smaller thatn i64.
 *
 *  returns true if assignment was successful
 */
assign_integer :: proc(target: ^any, value: int) -> (ok: bool) {

	switch type in target^ {

	case int:
		t := &target.(int)
		t^ = int(value)
	case i8:
		t := &target.(i8)
		t^ = i8(value)
	case i16:
		t := &target.(i16)
		t^ = i16(value)
	case i32:
		t := &target.(i32)
		t^ = i32(value)
	case i64:
		t := &target.(i64)
		t^ = i64(value)
	case i128:
		t := &target.(i128)
		t^ = i128(value)

	case u8:
		t := &target.(u8)
		t^ = u8(value)
	case u16:
		t := &target.(u16)
		t^ = u16(value)
	case u32:
		t := &target.(u32)
		t^ = u32(value)
	case u64:
		t := &target.(u64)
		t^ = u64(value)
	case u128:
		t := &target.(u128)
		t^ = u128(value)

	case u16le:
		t := &target.(u16le)
		t^ = u16le(value)
	case u32le:
		t := &target.(u32le)
		t^ = u32le(value)
	case u64le:
		t := &target.(u64le)
		t^ = u64le(value)
	case u128le:
		t := &target.(u128le)
		t^ = u128le(value)

	case i16le:
		t := &target.(i16le)
		t^ = i16le(value)
	case i32le:
		t := &target.(i32le)
		t^ = i32le(value)
	case i64le:
		t := &target.(i64le)
		t^ = i64le(value)
	case i128le:
		t := &target.(i128le)
		t^ = i128le(value)

	case u16be:
		t := &target.(u16be)
		t^ = u16be(value)
	case u32be:
		t := &target.(u32be)
		t^ = u32be(value)
	case u64be:
		t := &target.(u64be)
		t^ = u64be(value)
	case u128be:
		t := &target.(u128be)
		t^ = u128be(value)

	case i16be:
		t := &target.(i16be)
		t^ = i16be(value)
	case i32be:
		t := &target.(i32be)
		t^ = i32be(value)
	case i64be:
		t := &target.(i64be)
		t^ = i64be(value)
	case i128be:
		t := &target.(i128be)
		t^ = i128be(value)

	case:
		return false
	}

	return true
}


