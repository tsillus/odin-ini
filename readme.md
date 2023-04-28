

# odin-ini

A simple package used to load data from an .ini file into your own data structures.

## Usage

1. Create your configuration data structures. E.g:

```odin
Database :: struct {
    server: string,
    port: string,
    max_connections: u16,
}

Logging :: struct {
    path: string,
    log_level: string,
    max_file_size: u64,
    rotation_files: u8,
}

Configuration :: struct {
    database: Database,
    logging: Logging,
}

```

2. write a procedure to parse your ini file into your data structure 

```odin
import ini "shared:ini"


load_ini :: proc(file_name: string) -> (config: Configuration, success:bool) {

    cfg, err := ini.read_ini_file(file_name)
    defer ini.delete_config(cfg)
    if err != nil {
        return config, false
    }

    config = Configuration{
        logging = ini.parse_section_by_type(cfg, "logging", Logging)   or_else Logging{},
        database  = ini.parse_section_by_type(cfg, "server", Database) or_else Database{},
    }
    
    return config, true
}
```

2b. You can also define default values before parsing the file:

```odin

load_ini_with_defaults :: proc(file_name: string) -> (config: Configuration, success: bool) {

    config = IniConfiguration{
        logging = Logging{
            level = "INFO",
            path = ".",
        }
        database = Database{}
    }

    cfg, err := ini.read_ini_file(file_name)
    defer ini.delete_config(cfg)
    if err != nil {
        // this would still provide a config your program
        // might be able to work with.
        return config, false
    }

    ini.parse_section(cfg, "logging", &(config.logging))
    ini.parse_section(cfg, "database", &(config.database))

    return config, true
}
```

3. call your procedure

```odin

cfg, ok := load_ini("./config.ini")
```

4. Eternal happiness!

