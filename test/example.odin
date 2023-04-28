package test 

import "core:testing"
import "core:fmt"
import ini ".."

Logging :: struct {
    level : string,
    path: string,
    max_size: uint,
    keep_files: uint,
}

Server :: struct {
    url: string,
    port: uint,
}


IniConfiguration :: struct{
    logging: Logging,
    server: Server,
}

INI_FILE :: "./test/example.ini"


/*****************************************
*         WITHOUT DEFAULT VALUES
*  the simplest way to load an ini file
*
******************************************/

@(test)
test_example_without_defaults :: proc(tester: ^testing.T) { 
    

    config, ok := load_ini(INI_FILE)

    testing.expect(tester, ok, "failed loading file")

    testing.expect_value(tester, "DEBUG", config.logging.level)
    testing.expect_value(tester, ".", config.logging.path)

}


load_ini :: proc(file_name: string) -> (config: IniConfiguration, success:bool) {

    cfg, err := ini.read_ini_file(file_name)
    defer ini.delete_config(cfg)
    if err != nil {
        return config, false
    }

    config = IniConfiguration{
        logging = ini.parse_section_by_type(cfg, "logging", Logging) or_else Logging{},
        server  = ini.parse_section_by_type(cfg, "server", Server)   or_else Server{},
    }
    
    return config, true
}


/*****************************************
*           WITH DEFAULT VALUES
*  when you want to guarantee that certain
*       values are set in every case
******************************************/

@(test)
test_example_with_defaults :: proc(tester: ^testing.T) {

    config, ok := load_ini_with_defaults(INI_FILE)

    testing.expect(tester, ok, "failed loading file")

    testing.expect_value(tester, "DEBUG", config.logging.level)
    testing.expect_value(tester, ".", config.logging.path)

}


load_ini_with_defaults :: proc(file_name: string) -> (config: IniConfiguration, success: bool) {

    config = IniConfiguration{
        logging = Logging{
            level = "INFO",
            path = ".",
        }
        server = Server{}
    }

    cfg, err := ini.read_ini_file(file_name)
    defer ini.delete_config(cfg)
    if err != nil {
        // this would still provide a config your program
        // might be able to work with.
        return config, false
    }

    ini.parse_section(cfg, "logging", &(config.logging))
    ini.parse_section(cfg, "server", &(config.server))

    return config, true
}
