
/** 
# odini

A simple package used to load data from an .ini file into your own data structures.

## Basic Usage

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

load_ini :: proc(file_name: string) -> (cfg: Configuration, success:bool) {

    cfg_ini, err := ini.read_ini_file(file_name)
    if err != .OK {
        // ...
    }

    cfg = Configuration{
         // you can create instances for each field here to provide default values.
    }
    db_err, log_err : ini.Error
    cfg.database, db_err = ini.parse_section(cfg_ini, "database", &(cfg.database))
    cfg.logging, log_err = ini.parse_section(cfg_ini, "logging", &(cfg.logging))

    if db_err != .OK { /* ... */}
    if log_err != .OK { /* ... */}

    return cfg, true
}
```
3. Eternal happiness!


## Advanced Usage

Sometimes the basic data types aren't enough. You might want to translate certain settings into enums or arrays. 


