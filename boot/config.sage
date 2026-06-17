## os.boot.config — Boot Configuration Parser
## Parses simple boot.cfg files.

## Parse configuration string
proc parse(text):
    let conf = {}
    let lines = split(text, chr(10))
    for line in lines:
        let trimmed = strip(line)
        if len(trimmed) == 0 or trimmed[0] == "#":
            continue
        let parts = split(trimmed, "=")
        if len(parts) == 2:
            conf[strip(parts[0])] = strip(parts[1])
    return conf

## Get a string value from config
proc get(conf, key, default_val):
    if has(conf, key):
        return conf[key]
    return default_val

## Get an integer value from config
proc get_int(conf, key, default_val):
    if has(conf, key):
        return tonumber(conf[key])
    return default_val
