
void dbg_log(const char const *fmt, ...);
void dbg_flush(void);

void __gnat_last_chance_handler (char *file, int line)
{
    dbg_log("Error: ADA exception at %s +%d\n", file, line);
    dbg_flush();
    while (1)
        ;
}

